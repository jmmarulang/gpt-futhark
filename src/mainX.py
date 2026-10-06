import numpy as np
import matplotlib.pyplot as plt
import python.microgpt_libX as mp
import time
import random
import futhark_server
import torch
import torch.nn as nn
from torch.nn import functional as F
import pytorch.microgpt_torch_lib as mt

seed = 5
random.seed(seed)
torch.manual_seed(seed)

def softmax(logits):
    max_val = max(val for val in logits)
    exps = [np.exp(val - max_val) for val in logits]
    total = np.sum(exps)
    return [e / total for e in exps]

futhark = "futhark/microgptX"
# print(futhark)

# Data
file = open('input-mgpt/input.txt')
docs = [line.strip() for line in file if line.strip()]
random.shuffle(docs)

# Tokenizer
uchars = sorted(set(''.join(docs)))
BOS = len(uchars)
vocab_size = len(uchars) + 1
vocab = uchars + ["end"]

# Initialize the parameters, to store the knowledge of the model
num_type = np.float64
num_steps = 2
ed = 16     # width of the network (embedding dimension)
sl = 16 # maximum context length of the attention window (note: the longest name is 15 characters)
ah = 4      # number of attention heads
hd = ed // ah # derived dimension of each head
big_num = 1000000000000000000000000000000000000000

# -------------------------------------
# DEFINE TORCH MODEL
if (num_type == np.float64):
    print("f64")
    torch_model = mt.GPT().double()
else:
    print("f32")
    torch_model = mt.GPT()
learning_rate = 0.01

optimizer = torch.optim.Adam(torch_model.parameters(), lr=learning_rate, betas=(0.85, 0.99), eps=1e-8)
scheduler = torch.optim.lr_scheduler.LinearLR(optimizer, start_factor=1.0, end_factor=0.0, total_iters=num_steps)


# -------------------------------------
# EXTRACT WEIGHTS

twdict = torch_model.state_dict().copy()
for k , t in twdict.items():
    twdict[k] = t.numpy().astype(num_type)

dimdic = {'wt' : (vocab_size, ed), 'wp' : (sl, ed),
          'wkey' : (ah, hd, ed), 'wqry' : (ah, hd, ed), 'wval' : (ah, hd, ed),
          'wo' : (ed, ed), 'wu' : (4 * ed, ed), 'wd' :(ed, 4 * ed),
          'wc': (vocab_size, ed)}
fwdic = {}
fmdic = {}
fvdic = {}
pmdic = {}
pvdic = {}
pwdic = {}

for k , dim in dimdic.items():
    fwdic[k] = np.zeros(dim)
    fmdic[k] = np.zeros(dim)
    fvdic[k] = np.zeros(dim)
    pmdic[k] = np.zeros(dim)
    pvdic[k] = np.zeros(dim)
    pwdic[k] = np.zeros(dim)

fwdic['wt'] = twdict['token_embedding_table.weight'].copy()
fwdic['wp'] = twdict['position_embedding_table.weight'].copy()
fwdic['wo'] = twdict['blocks.0.sa_heads.proj.weight'].copy()
fwdic['wu'] = twdict['blocks.0.ffwd.net.0.weight'].copy()
fwdic['wd'] = twdict['blocks.0.ffwd.net.2.weight'].copy()
fwdic['wc'] = twdict['lm_head.weight'].copy()

pwdic['wt'] = fwdic['wt'].copy()
pwdic['wp'] = fwdic['wp'].copy()
pwdic['wo'] = fwdic['wo'].copy()
pwdic['wu'] = fwdic['wu'].copy()
pwdic['wd'] = fwdic['wd'].copy()
pwdic['wc'] = fwdic['wc'].copy()
pwdic['wkey'] = np.zeros((dimdic['wkey'][0]*dimdic['wkey'][1],dimdic['wkey'][2])).copy()
pwdic['wqry'] = np.zeros((dimdic['wqry'][0]*dimdic['wqry'][1],dimdic['wqry'][2])).copy()
pwdic['wval'] = np.zeros((dimdic['wval'][0]*dimdic['wval'][1],dimdic['wval'][2])).copy()

for step in range(ah):
    fwdic['wkey'][step] = \
            twdict[f"blocks.0.sa_heads.heads.{step}.key.weight"].copy()
    fwdic['wqry'][step] = \
        twdict[f"blocks.0.sa_heads.heads.{step}.query.weight"].copy()
    fwdic['wval'][step] = \
        twdict[f"blocks.0.sa_heads.heads.{step}.value.weight"].copy()

    pwdic['wqry'][step*hd : hd*(step + 1)] = \
            twdict[f"blocks.0.sa_heads.heads.{step}.query.weight"].copy()
    pwdic['wkey'][step*hd : hd*(step + 1)] = \
        twdict[f"blocks.0.sa_heads.heads.{step}.key.weight"].copy()
    pwdic['wval'][step*hd : hd*(step + 1)] = \
            twdict[f"blocks.0.sa_heads.heads.{step}.value.weight"].copy()

pwdic = { k : np.vectorize(mp.to_val)(v) for k, v in pwdic.items()}
print(pwdic['wkey'].shape)

ones = np.ones((sl,sl))
cau_mask = (ones - np.tril(ones))

#-------------------------------------
# PROBS

# input
doc = list("wakuntchapinka")
# doc = list("marulanda")
dl = len(doc) + 2

# sequence ids
python_tokens = [BOS] + [vocab.index(ch) for ch in doc] + [BOS]
# add padding
futhark_tokens = [python_tokens + ([BOS] * (sl - dl))]
# to numpy
futhark_tokens = np.array(futhark_tokens)
print("".join(doc))

pad_mask = np.ones((sl,sl))
for i in range(dl):
    pad_mask[i][ 0 : dl] = 0

mask = np.where(cau_mask + pad_mask >= 1, 1, 0).astype(num_type)
mask = -1*mask*big_num

# Futhark
with futhark_server.Server(futhark) as server:
    server.put_value('tokens', futhark_tokens)
    server.put_value('mask', mask)
    for k , data in fwdic.items():
        server.put_value(k, data)
    server.cmd_call('to_params', 'fparams', *fwdic.keys())
    server.cmd_call('forward_seq', 'fmlogits', 'fparams', 'tokens', 'mask')
    futhark_logits = server.get_value('fmlogits')
# futhark_probs = np.array([softmax(logits) for logits in futhark_logits])
# futhark_probs = futhark_probs[: dl]

# # Python
python_logits = mp.forward_seq(python_tokens, pwdic)
python_logits = np.array([[val.data for val in logits] for logits in python_logits])
# python_probs = np.array([softmax(logits) for logits in python_logits])

#### Torch
torch_tokens = torch.tensor([python_tokens], dtype=torch.long)
torch_model.eval()
with torch.no_grad():
    torch_logits, _ = torch_model(torch_tokens)
torch_logits = torch_logits.numpy()[0]
# torch_probs = np.array([softmax(logits) for logits in torch_logits])

print(futhark_logits.shape)
print(torch_logits.shape)
#-------------------------------------
# TESTS


#-------------------------------------
# PLOTS

# # Losses
# last = 100
# n = min(last, num_steps)
# futhark_data = np.log(futhark_losses[-n:])
# # python_data = np.log(python_losses[-n:])
# torch_data = np.log(torch_losses[-last:])
# plt.plot(futhark_data, label="futhark")
# # plt.plot(python_data, '-.', label="python")
# plt.plot(torch_data, '--', label="torch")
# plt.xlabel('log losses', fontsize = 12)
# plt.legend()
# plt.savefig('figures/main_' + "".join(doc) + "_losses_" + "_seed_" + str(seed) + "_iter_" + str(num_steps) + "_matrix_" + str(matrix_type) +  '_.png')
# plt.show()

# # # # loss errors
# # data = (np.abs(futhark_losses - torch_losses))
# # plt.plot(data)
# # plt.xlabel('absolute error of losses', fontsize = 12)
# # plt.locator_params(axis='x', nbins=40)
# # plt.show()

# # # # loss errors boxplot
# # data = (np.abs(futhark_losses - torch_losses))
# # plt.boxplot(data, showfliers=False, orientation= 'horizontal')
# # plt.xlabel('absolute error of losses', fontsize = 12)
# # plt.locator_params(axis='x', nbins=40)
# # plt.show()

# # # # loss ratios
# # data = np.minimum(np.abs(futhark_losses), np.abs(torch_losses))/np.maximum(np.abs(futhark_losses), np.abs(torch_losses))
# # plt.boxplot(data, showfliers=False, orientation= 'horizontal')
# # plt.xlabel('ratio of losses', fontsize = 12)
# # plt.locator_params(axis='x', nbins=40)
# # plt.show()

# # Probs
while True:
    index = int(input("index <- "))
    if index == -1: break

    barWidth = 0.25
    futhark_data = futhark_logits[0][index]
    python_data = python_logits[index]
    torch_data = torch_logits[index]

    br1 = np.arange(len(futhark_data))
    br2 = [x + barWidth for x in br1]
    br3 = [x + barWidth for x in br2]
    plt.bar(br1, futhark_data, width=barWidth, label="futhark")
    plt.bar(br2, python_data, width=barWidth, label="python")
    plt.bar(br3, torch_data, width=barWidth, label="torch")
    plt.xticks([r + barWidth for r in range(len(futhark_data))], vocab)
    plt.xlabel('next token probability', fontsize = 12)
    plt.legend()
    plt.savefig('figures/main_' + "".join(doc) + "_index_" + str(index) + "_seed_" + str(seed) + "_iter_" + str(num_steps) + "_matrix_" +  '_.png')
    plt.show()
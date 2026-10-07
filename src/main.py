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

futhark = "futhark/microgpt"
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
# num_steps = 3351
num_steps = 2
matrix_type = 'rand'
ed = 16     # width of the network (embedding dimension)
sl = 16 # maximum context length of the attention window (note: the longest name is 15 characters)
ah = 4      # number of attention heads
hd = ed // ah # derived dimension of each head
big_num = 1000000000000000000000000000000000000000


# -------------------------------------
# DEFINE TORCH MODEL
torch_model = mt.GPT().double()
learning_rate = 0.01

optimizer = torch.optim.Adam(torch_model.parameters(), lr=learning_rate, betas=(0.85, 0.99), eps=1e-8)
scheduler = torch.optim.lr_scheduler.LinearLR(optimizer, start_factor=1.0, end_factor=0.0, total_iters=num_steps)


# -------------------------------------
# EXTRACT WEIGHTS

twdict = torch_model.state_dict().copy()
for k , t in twdict.items():
    twdict[k] = t.numpy().astype(np.float64)

dimdic = {'wt' : (vocab_size, ed), 'wp' : (sl, ed),
          'wqry' : (ed, ed), 'wkey' : (ed, ed), 'wval' : (ed, ed),
          'wo' : (ed, ed), 'wu' : (4 * ed, ed), 'wd' :(ed, 4 * ed),
          'wc': (vocab_size, ed)}
fwdic = {}
fmdic = {}
fvdic = {}
pmdic = {}
pvdic = {}

for k , dim in dimdic.items():
    fwdic[k] = np.zeros(dim)
    fmdic[k] = np.zeros(dim)
    fvdic[k] = np.zeros(dim)
    pmdic[k] = np.zeros(dim)
    pvdic[k] = np.zeros(dim)

fwdic['wt'] = twdict['token_embedding_table.weight']
fwdic['wp'] = twdict['position_embedding_table.weight']
fwdic['wo'] = twdict['blocks.0.sa_heads.proj.weight']
fwdic['wu'] = twdict['blocks.0.ffwd.net.0.weight']
fwdic['wd'] = twdict['blocks.0.ffwd.net.2.weight']
fwdic['wc'] = twdict['lm_head.weight']

for step in range(ah):
    fwdic['wqry'][step*hd : hd*(step + 1)] = \
        twdict[f"blocks.0.sa_heads.heads.{step}.query.weight"]
    fwdic['wkey'][step*hd : hd*(step + 1)] = \
        twdict[f"blocks.0.sa_heads.heads.{step}.key.weight"]
    fwdic['wval'][step*hd : hd*(step + 1)] = \
            twdict[f"blocks.0.sa_heads.heads.{step}.value.weight"]

pwdic = { k : np.vectorize(mp.to_val)(v) for k, v in fwdic.items()}


ones = np.ones((sl,sl))
cau_mask = (ones - np.tril(ones))


# # # # -------------------------------------
# # # TRAINING PY

# print("Training Python")

# start = time.time()
# python_losses = mp.train(docs, uchars, BOS, num_steps, pwdic)
# end = time.time()

# print("python training time", end - start)
# print("python final loss", python_losses[-1])

# # -------------------------------------
# # TRAINING FUT

# print("Training Futhark")

# futhark_losses = np.zeros((num_steps)).astype(np.float64)

# # Preprocessing
# masks = np.zeros((num_steps, sl, sl)).astype(np.float64)
# dls = np.zeros((num_steps)).astype(np.int64)
# seqs = np.zeros((num_steps, sl)).astype(np.int64, copy=False)

# for step in range(num_steps):
#     # doc lengths
#     doc = docs[step % len(docs)]
#     doc = doc[:sl - 2]
#     dl = len(doc) + 2
#     dls[step] = dl
#     # Masking
#     pad_mask = np.ones((sl,sl))
#     for i in range(dl):
#         pad_mask[i][ 0 : dl] = 0
#     mask = np.where(cau_mask + pad_mask >= 1, 1, 0).astype(np.float64)
#     mask = -1*mask*big_num
#     masks[step] = mask

# with futhark_server.Server(futhark) as server:
#     server.put_value('num_steps',
#                      np.array(num_steps).astype(np.int64, copy=False))
#     for k , data in fwdic.items():
#         server.put_value(k, data)
#     server.cmd_call('to_params', 'p', *fwdic.keys())
#     server.cmd_call('zero_params', 'mp')
#     server.cmd_call('zero_params', 'vp')
#     server.put_value('masks', masks)
#     server.put_value('dls', dls)

#     # start timer
#     start = time.time()
#     # Tokenization
#     for step in range(num_steps):
#         doc = docs[step % len(docs)]
#         doc = doc[:sl - 2]
#         dl = len(doc) + 2
#         tokens = [BOS] + [uchars.index(ch) for ch in doc] + [BOS]
#         # Padding
#         futhark_tokens = tokens + ([BOS] * (sl - dl))
#         seqs[step] = futhark_tokens
#     server.put_value('seqs', seqs)
#     # server.cmd_call('cal_loss', 'loss', 'fparams', 'tokens', 'mask')
#     server.cmd_call('train', 'p_mp_vp_loss', 'p', 'mp', 'vp', 'masks',
#                     'dls', 'seqs')
#     end = time.time()
#     print("futhark training time", end - start)
#     p_mp_vp_loss = server.get_value('p_mp_vp_loss')

# for i , k in enumerate(dimdic.keys()):
#     fwdic[k] = p_mp_vp_loss[i]
#     fmdic[k] = p_mp_vp_loss[i + 9]
#     fmdic[k] = p_mp_vp_loss[i + 18]

# futhark_losses = p_mp_vp_loss[-1]
# print("futhark final loss", futhark_losses[-1])

# try:
#     np.save("fwdic.npy", fwdic, allow_pickle=True)
#     file = open('fwdic.txt', 'wt')
#     file.write(str(fwdic))
#     file.close()
# except :
#     print("It refused")

# # -------------------------------------
# # TRAINING TORCH

# print("Training Torch")

# torch_losses = np.zeros((num_steps)).astype(np.float64)

# torch_model.train()
# for step in range(num_steps):
#     doc = docs[step % len(docs)]
#     tokens = [BOS] + [uchars.index(ch) for ch in doc] + [BOS]
#     n = min(sl, len(tokens) - 1)

#     x = torch.tensor([tokens[:n]], dtype=torch.long)
#     y = torch.tensor([tokens[1:n+1]], dtype=torch.long)

#     logits, loss = torch_model(x, y)

#     optimizer.zero_grad(set_to_none=True)
#     loss.backward()
#     optimizer.step()
#     scheduler.step()

#     # Danger: Not used during computation
#     torch_losses[step] = loss.detach().numpy()

#     print(f"step {step+1:4d} / {num_steps:4d} | loss {loss.item():.4f}", end='\r')

# end = time.time()
# print("torch training time", end - start)
# print("torch final loss", torch_losses[-1])

#-------------------------------------
# PROBS

# input
# doc = list("wakuntchapinka")
doc = list("marulanda")
dl = len(doc) + 2

# sequence ids
python_tokens = [BOS] + [vocab.index(ch) for ch in doc] + [BOS]
# add padding
futhark_tokens = python_tokens + ([BOS] * (sl - dl))
# to numpy
futhark_tokens = np.array(futhark_tokens)
print("".join(doc))

pad_mask = np.ones((sl,sl))
for i in range(dl):
    pad_mask[i][ 0 : dl] = 0

# print(pad_mask)
mask = np.where(cau_mask + pad_mask >= 1, 1, 0).astype(np.float64)
mask = -1*mask*big_num

# Futhark
with futhark_server.Server(futhark) as server:
    server.put_value('tokens', futhark_tokens)
    server.put_value('mask', mask)
    server.put_value('dl', np.array(dl).astype(np.int64, copy=False))
    for k , data in fwdic.items():
        server.put_value(k, data)
    server.cmd_call('to_params', 'fparams', *fwdic.keys())
    server.cmd_call('forward_seq', 'flogits', 'fparams', 'tokens', 'mask')
    server.cmd_call('cal_loss', 'floss', 'dl', 'fparams', 'tokens', 'mask')
    futhark_logits = server.get_value('flogits')
    futhark_loss = server.get_value('floss')
futhark_probs = np.array([softmax(logits) for logits in futhark_logits])
futhark_probs = futhark_probs[: dl]

# # Python
python_logits, python_loss = mp.forward_seq(python_tokens, pwdic)
python_logits = np.array([[val.data for val in logits] for logits in python_logits])
python_probs = np.array([softmax(logits) for logits in python_logits])
python_loss = python_loss.data

#### Torch
n = min(sl, len(python_tokens) - 1)
# torch_tokens = torch.tensor([python_tokens], dtype=torch.long)
torch_model.eval()
with torch.no_grad():
    x = torch.tensor([python_tokens[:n]], dtype=torch.long)
    y = torch.tensor([python_tokens[1:n+1]], dtype=torch.long)
    torch_logits, torch_loss = torch_model(x , y)
torch_logits = torch_logits.numpy()[0]
torch_loss = torch_loss.numpy()

#-------------------------------------
# TESTS

print("futhark loss", futhark_loss)
print("python  loss", python_loss)
print("torch   loss", torch_loss)

#-------------------------------------
# PLOTS

# Losses
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

# # # loss errors
# data = (np.abs(futhark_losses - torch_losses))
# plt.plot(data)
# plt.xlabel('absolute error of losses', fontsize = 12)
# plt.locator_params(axis='x', nbins=40)
# plt.show()

# # # loss errors boxplot
# data = (np.abs(futhark_losses - torch_losses))
# plt.boxplot(data, showfliers=False, orientation= 'horizontal')
# plt.xlabel('absolute error of losses', fontsize = 12)
# plt.locator_params(axis='x', nbins=40)
# plt.show()

# # # loss ratios
# data = np.minimum(np.abs(futhark_losses), np.abs(torch_losses))/np.maximum(np.abs(futhark_losses), np.abs(torch_losses))
# plt.boxplot(data, showfliers=False, orientation= 'horizontal')
# plt.xlabel('ratio of losses', fontsize = 12)
# plt.locator_params(axis='x', nbins=40)
# plt.show()

# Probs
while True:
    index = int(input("index <- "))
    if index == -1: break

    barWidth = 0.25
    futhark_data = futhark_logits[index]
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
    plt.savefig('figures/main_' + "".join(doc) + "_index_" + str(index) + "_seed_" + str(seed) + "_iter_" + str(num_steps) + "_matrix_" + str(matrix_type) +  '_.png')
    plt.show()
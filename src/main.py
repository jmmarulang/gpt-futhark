import numpy as np
import matplotlib.pyplot as plt
import python.microgpt_lib as mp
import time
import random
import futhark_server
import torch
import torch.nn as nn
from torch.nn import functional as F
import pytorch.microgpt_torch_lib as mt

seed = 100
random.seed(seed)
torch.manual_seed(seed)

def npsoftmax(x, axis=-1):
    return np.exp(x) / np.sum(np.exp(x), axis=axis, keepdims=True)

# npsoftmax = np.vectorize(_npsoftmax)

futhark = "futhark/microgpt"

# Data
file = open('input-mgpt/input.txt')
docs = [line.strip() for line in file if line.strip()]
random.shuffle(docs)

# Tokenizer
uchars = sorted(set(''.join(docs)))
BOS = len(uchars)
bos = "_"
vocab_size = len(uchars) + 1
vocab = uchars + [bos]

# Initialize the parameters, to store the knowledge of the model
matrix_type = 'rand'
steps = 100
bs = 5
iters = bs * steps
ed = 16     # width of the network (embedding dimension)
sl = 16 # maximum context length of the attention window (note: the longest name is 15 characters)
ah = 4      # number of attention heads
hd = ed // ah # derived dimension of each head
big_num = 1000000000000000000000000000000000000000000000000000000000000000

print("batch size", bs)
print("number of steps", steps)
print("iterations", iters)

# Tokenization and Padding
seqs = []
for i in range(len(docs)):
    doc = docs[i % len(docs)]
    doc = doc[:sl - 2]
    dl = len(doc) + 2
    doc = bos + doc + bos
    doc = doc + (bos * (sl - dl))
    docs[i] = doc
    assert len(docs[i]) == sl

# -------------------------------------
# DEFINE TORCH MODEL
torch_model = mt.GPT().double()
learning_rate = 0.01

optimizer = torch.optim.Adam(torch_model.parameters(), lr=learning_rate, betas=(0.85, 0.99), eps=1e-8)
scheduler = torch.optim.lr_scheduler.LinearLR(optimizer, start_factor=1.0, end_factor=0.0, total_iters=steps)

# -------------------------------------
# EXTRACT WEIGHTS

twdict = torch_model.state_dict().copy()
for k , t in twdict.items():
    twdict[k] = t.numpy().astype(np.float64)

fdimdic = {'wt' : (vocab_size, ed), 'wp' : (sl, ed),
          'wqry' : (ed, ed), 'wkey' : (ed, ed), 'wval' : (ed, ed),
          'wo' : (ed, ed), 'wu' : (4 * ed, ed), 'wd' :(ed, 4 * ed),
          'wc': (vocab_size, ed)}

pdimdic = {'wt' : (vocab_size, ed), 'wp' : (sl, ed),
          'wqry' : (ed, ed), 'wkey' : (ed, ed), 'wval' : (ed, ed),
          'wo' : (ed, ed), 'wu' : (4 * ed, ed), 'wd' :(ed, 4 * ed),
          'wc': (vocab_size, ed)}
fwdic = {}
fmdic = {}
fvdic = {}
pwdic = {}
pmdic = {}
pvdic = {}

for k , dim in fdimdic.items():
    fwdic[k] = np.zeros(dim)
    fmdic[k] = np.zeros(dim)
    fvdic[k] = np.zeros(dim)

for k , dim in pdimdic.items():
    pwdic[k] = np.zeros(dim)
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

pwdic['wt'] = twdict['token_embedding_table.weight']
pwdic['wp'] = twdict['position_embedding_table.weight']
pwdic['wo'] = twdict['blocks.0.sa_heads.proj.weight']
pwdic['wu'] = twdict['blocks.0.ffwd.net.0.weight']
pwdic['wd'] = twdict['blocks.0.ffwd.net.2.weight']
pwdic['wc'] = twdict['lm_head.weight']

for step in range(ah):
    pwdic['wqry'][step*hd : hd*(step + 1)] = \
        twdict[f"blocks.0.sa_heads.heads.{step}.query.weight"]
    pwdic['wkey'][step*hd : hd*(step + 1)] = \
        twdict[f"blocks.0.sa_heads.heads.{step}.key.weight"]
    pwdic['wval'][step*hd : hd*(step + 1)] = \
            twdict[f"blocks.0.sa_heads.heads.{step}.value.weight"]

pwdic = {k : np.vectorize(mp.to_val)(v) for k, v in pwdic.items()}

ones = np.ones((sl,sl))
cau_mask = (ones - np.tril(ones))

# # # -------------------------------------
# # # TRAINING TORCH

print("Training Torch")

nbatch = np.zeros((bs, sl -1)).astype(np.int64, copy=False)
ntarget = np.zeros((bs, sl -1)).astype(np.int64, copy=False)
torch_losses = np.zeros((steps)).astype(np.float64)

torch_model.train()
start = time.time()
index = 0
n = sl - 1
for step in range(steps):
    for i in range(bs):
        doc = docs[index % len(docs)]; index += 1
        tokens = [vocab.index(ch) for ch in doc]
        nbatch[i] = tokens[:n]
        ntarget[i] = tokens[1:n+1]

    batch = torch.tensor(nbatch, dtype=torch.long)
    target = torch.tensor(ntarget, dtype=torch.long)

    logits, loss = torch_model(batch, target)

    optimizer.zero_grad(set_to_none=True)
    loss.backward()
    optimizer.step()
    scheduler.step()

    print(f"step {step+1:4d} / {steps:4d} | loss {loss.item():.4f}", end='\r')

end = time.time()
print("torch training time", end - start)
# # -------------------------------------
# # TRAINING FUT
print("Training Futhark")

futhark_losses = np.zeros((steps)).astype(np.float64)
masks = np.zeros((steps, sl, sl)).astype(np.float64)
dls = np.zeros((steps)).astype(np.int64)
batches = np.zeros((steps, bs, sl)).astype(np.int64, copy=False)

#Preprocessing
for step in range(steps):
    masks[step] = -1*big_num*cau_mask
    dls[step] = sl

with futhark_server.Server(futhark) as server:
    for k , data in fwdic.items():
        server.put_value(k, data)
    server.cmd_call('to_params', 'p', *fwdic.keys())
    server.cmd_call('zero_params', 'mp')
    server.cmd_call('zero_params', 'vp')
    server.put_value('masks', masks)
    server.put_value('dls', dls)

    # start timer
    start = time.time()
    # Tokenization
    index = 0
    for step in range(steps):
        for i in range(bs):
            doc = docs[index % len(docs)]; index += 1
            tokens = [vocab.index(ch) for ch in doc]
            batches[step][i] = tokens
    server.put_value('batches', batches)
    server.cmd_call('train', 'p_mp_vp', 'p', 'mp', 'vp', 'masks',
                    'dls', 'batches')
    end = time.time()
    p_mp_vp = server.get_value('p_mp_vp')

print("futhark training time", end - start)

for i , k in enumerate(fdimdic.keys()):
    fwdic[k] = p_mp_vp[i]
    fmdic[k] = p_mp_vp[i + 9]
    fmdic[k] = p_mp_vp[i + 18]

try:
    np.save("fwdic.npy", fwdic, allow_pickle=True)
    file = open('fwdic.txt', 'wt')
    file.write(str(fwdic))
    file.close()
except :
    print("It refused")

#-------------------------------------
# PROBS

# input
doc = "marulanda"
doc = doc[:sl - 2]
dl = len(doc) + 2
doc = bos + doc + bos
doc = doc + (bos * (sl - dl))
dl = len(doc)
assert dl == sl
print("".join(doc))
# sequence ids
python_tokens = [vocab.index(ch) for ch in doc]
torch_tokens = np.array([python_tokens for _ in range(bs)])
# to numpy
futhark_tokens = np.zeros((bs, sl)).astype(np.int64)
futhark_tokens[:,:] = torch_tokens

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
    server.cmd_call('forward', 'flogits', 'fparams', 'tokens', 'mask')
    server.cmd_call('loss', 'floss', 'dl', 'fparams', 'tokens', 'mask')
    futhark_logits = server.get_value('flogits')
    futhark_loss = server.get_value('floss')
futhark_logits = futhark_logits[:,:-1]
futhark_probs =npsoftmax(futhark_logits, 1)

#### Torch
n = sl - 1
torch_target = torch_tokens[:,1:n+1]
torch_model.eval()
with torch.no_grad():
    x = torch.tensor(torch_tokens[:,:n], dtype=torch.long)
    y = torch.tensor(torch_target, dtype=torch.long)
    torch_logits, torch_loss = torch_model(x , y)
torch_logits = torch_logits.numpy()
torch_loss = torch_loss.numpy()
torch_probs =npsoftmax(torch_logits, 1)
#-------------------------------------
# TESTS

print("futhark loss", futhark_loss)
print("torch   loss", torch_loss)

# #-------------------------------------
# # PLOTS

# #### Probs
while True:
    bindex = int(input("batch <- "))
    if bindex == -1: break
    pindex = int(input("position <- "))

    barWidth = 0.25
    futhark_data = futhark_probs[bindex, pindex]
    torch_data = torch_probs[bindex, pindex]

    br1 = np.arange(len(torch_data))
    br2 = [x + barWidth for x in br1]
    br3 = [x + barWidth for x in br2]
    plt.bar(br1, futhark_data, width=barWidth, label="futhark")
    plt.bar(br2, torch_data, width=barWidth, label="torch")
    plt.xticks([r + barWidth for r in range(len(torch_data))], vocab)
    plt.xlabel('next token probability', fontsize = 12)
    plt.legend()
    # plt.savefig('figures/main_' + "".join(doc) + "_pindex_" + str(pindex) + "_seed_" + str(seed) + "_iter_" + str(steps) + "_matrix_" + str(matrix_type) +  '_.png')
    plt.show()
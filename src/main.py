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

futhark = "futhark/microgpt"
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
tdtype = torch.float64
fdtype = np.float64

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
stoi = {ch: i for i, ch in reversed(list(enumerate(vocab)))} # first occurrence wins, like vocab.index

# Initialize the parameters, to store the knowledge of the model
matrix_type = 'rand'
steps = 1000
bs = 50
aot_compile = True
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
for i in range(len(docs)):
    doc = docs[i % len(docs)]
    doc = doc[:sl - 2]
    dl = len(doc) + 2
    doc = bos + doc + bos
    doc = doc + (bos * (sl - dl))
    docs[i] = doc
    assert len(docs[i]) == sl
data = [[stoi[ch] for ch in doc] for doc in docs]
torch_data = torch.tensor(data, dtype=torch.long, device=device)
futhark_data = np.array(data)

# -------------------------------------
# DEFINE TORCH MODEL
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

torch_model = mt.GPT().to(device=device, dtype=tdtype)
learning_rate = 0.01

optimizer = torch.optim.Adam(
    torch_model.parameters(), lr=learning_rate, betas=(0.85, 0.99), eps=1e-8,
        fused=device.type == 'cuda')
scheduler = torch.optim.lr_scheduler.LinearLR(
    optimizer, start_factor=1.0, end_factor=0.0, total_iters=steps)

train_model = torch.compile(torch_model,mode='reduce-overhead', fullgraph=True)

# -------------------------------------
# EXTRACT WEIGHTS

twdict = torch_model.state_dict().copy()
for k , t in twdict.items():
    twdict[k] = t.numpy().astype(fdtype)

fdimdic = {'wt' : (vocab_size, ed), 'wp' : (sl, ed),
          'wqry' : (ed, ed), 'wkey' : (ed, ed), 'wval' : (ed, ed),
          'wo' : (ed, ed), 'wu' : (4 * ed, ed), 'wd' :(ed, 4 * ed),
          'wc': (vocab_size, ed)}

fwdic = {}
fmdic = {}
fvdic = {}

for k , dim in fdimdic.items():
    fwdic[k] = np.zeros(dim)
    fmdic[k] = np.zeros(dim)
    fvdic[k] = np.zeros(dim)

qkv = np.reshape(twdict['blocks.0.sa_heads.qkv.weight'], (3, ed, ed))
fwdic['wqry'][:,:] = qkv[0]
fwdic['wkey'][:,:] = qkv[1]
fwdic['wval'][:,:] = qkv[2]
fwdic['wt'][:,:]   = twdict['token_embedding_table.weight']
fwdic['wp'][:,:]   = twdict['position_embedding_table.weight']
fwdic['wo'][:,:]   = twdict['blocks.0.sa_heads.proj.weight']
fwdic['wu'][:,:]   = twdict['blocks.0.ffwd.net.0.weight']
fwdic['wd'][:,:]   = twdict['blocks.0.ffwd.net.2.weight']
fwdic['wc'][:,:]   = twdict['lm_head.weight']

ones = np.ones((sl,sl))
cau_mask = (ones - np.tril(ones))

# # # -------------------------------------
# # # TRAINING TORCH

print("Compiling Torch")

losses_dev = torch.zeros(steps, dtype=tdtype, device=device)
batch_offsets = torch.arange(bs, device=device)

if aot_compile:
    start = time.time()
    example_batch = torch.randint(
        0, vocab_size, (bs, sl -1), dtype=torch.long
    )

    example_target = torch.randint(
        0, vocab_size, (bs, sl -1), dtype=torch.long
    )

    compiled_fn = train_model.forward.aot_compile(
        ((example_batch, example_target), {})
    )
    end = time.time()
    print("torch compiling time", end - start)

print("Training Torch")

torch_model.train()
start = time.time()
n = sl - 1
for step in range(steps):
    # same docs, in the same order, as the original per-step loop
    seqs = torch_data[(batch_offsets + step * bs) % len(docs)]
    batch = seqs[:, :n].contiguous()
    target = seqs[:, 1:n+1].contiguous()

    torch.compiler.cudagraph_mark_step_begin()
    if aot_compile:
        _, loss = compiled_fn(torch_model, batch, target)
    else:
        _, loss = train_model(batch, target)

    optimizer.zero_grad(set_to_none=True)
    loss.backward()
    losses_dev[step] = loss.detach()
    optimizer.step()
    scheduler.step()

if device.type == 'cuda':
    torch.cuda.synchronize()
end = time.time()
torch_losses = losses_dev.double().cpu().numpy()
print("torch training time", end - start)

# # -------------------------------------
# # TRAINING FUT
print("Training Futhark")

futhark_losses = np.zeros((steps)).astype(fdtype)
masks = np.zeros((steps, sl, sl)).astype(fdtype)
dls = sl*np.ones((steps)).astype(np.int64)
batches = np.zeros((steps, bs, sl)).astype(np.int64, copy=False)

#Preprocessing
for step in range(steps):
    masks[step] = -1*big_num*cau_mask

batch_offsets = np.arange(bs)

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
    for step in range(steps):
        batches[step] = futhark_data[(batch_offsets + step * bs) % len(docs)]
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
mask = np.where(cau_mask + pad_mask >= 1, 1, 0).astype(fdtype)
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
    x = torch.tensor(torch_tokens[:,:n], dtype=torch.long, device= device)
    y = torch.tensor(torch_target, dtype=torch.long, device= device)
    torch_logits, torch_loss = torch_model(x , y)
torch_logits = torch_logits .cpu().numpy()
torch_loss = torch_loss .cpu().numpy()
torch_probs =npsoftmax(torch_logits, 1)
#-------------------------------------
# TESTS

print("futhark loss", futhark_loss)
print("torch   loss", torch_loss)

# #-------------------------------------
# # # PLOTS

# #### Probs
# while True:
#     bindex = int(input("batch <- "))
#     if bindex == -1: break
#     pindex = int(input("position <- "))

#     barWidth = 0.25
#     futhark_sample = futhark_probs[bindex, pindex]
#     torch_sample = torch_probs[bindex, pindex]

#     br1 = np.arange(len(torch_sample))
#     br2 = [x + barWidth for x in br1]
#     br3 = [x + barWidth for x in br2]
#     plt.bar(br1, futhark_sample, width=barWidth, label="futhark")
#     plt.bar(br2, torch_sample, width=barWidth, label="torch")
#     plt.xticks([r + barWidth for r in range(len(torch_sample))], vocab)
#     plt.xlabel('next token probability', fontsize = 12)
#     plt.legend()
#     # plt.savefig('figures/main_' + "".join(doc) + "_pindex_" + str(pindex) + "_seed_" + str(seed) + "_iter_" + str(steps) + "_matrix_" + str(matrix_type) +  '_.png')
#     plt.show()
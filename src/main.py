import numpy as np
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

# -------------------------------------
# DATA
file = open('input-mgpt/input.txt')
docs = [line.strip() for line in file if line.strip()]
random.shuffle(docs)

# -------------------------------------
# TOKENIZER
uchars = sorted(set(''.join(docs)))
bos = "_" # Padding
BOS = len(uchars) # Padding token
vocab = uchars + [bos] # vocabulary including the padding token
stoi = {ch: i for i, ch in reversed(list(enumerate(vocab)))} # tokenizer

# -------------------------------------
# TOGGLE HYPERPARAMETERS
# To play around with
aot_compile = True # If true, torch model is compiled ahead of time
batch_size = 50 # number of sequences per batch
n_batch = 1000 # number of batches
tdtype = torch.float64
fdtype = np.float64

# -------------------------------------
# FIXED HYPERPARAMETERS
# These are static in Futhark
n_embd = 16     # width of the network (embedding dimension)
seq_size = 16   # maximum context length of the attention window
n_head = 4      # number of attention heads
n_layer = 1     # number of layers
vocab_size = len(uchars) + 1 # vocabulary size including the padding token
head_dim = n_embd // n_head # derived dimension of each head
n_seq = batch_size * n_batch # derived total number of processed sequences
big_num = 1e+17 # for the attention mask
big_num = np.array(big_num, dtype=fdtype)
# Parameters for the adam optimizer
learning_rate = 0.01
betas = (0.85, 0.99)
eps = 1e-8

print("number of processed documents", n_seq)
print("batch size", batch_size)
print("number of batches", n_batch)

# -------------------------------------
# TOKENIZATION AND PADDING
# Each batch must contain names of the same length
# To deal with this, we add padding such that all names are of length seq_size
for i in range(len(docs)):
    doc = docs[i % len(docs)]
    doc = doc[:seq_size - 2]
    dl = len(doc) + 2
    doc = bos + doc + bos
    doc = doc + (bos * (seq_size - dl))
    docs[i] = doc
    assert len(docs[i]) == seq_size
data = [[stoi[ch] for ch in doc] for doc in docs]
torch_data = torch.tensor(data, dtype=torch.long, device=device)
futhark_data = np.array(data)

# -------------------------------------
# DEFINE TORCH MODEL
# If cuda is available, use it. Otherwise use cpu.
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Define the model
torch_model = mt.GPT(n_head, head_dim, seq_size, vocab_size, n_embd, n_layer).to(device=device, dtype=tdtype)

# Define optimizer and scheduler
optimizer = torch.optim.Adam(
    torch_model.parameters(), lr=learning_rate, betas=betas, eps=eps,
        fused=device.type == 'cuda')
scheduler = torch.optim.lr_scheduler.LinearLR(
    optimizer, start_factor=1.0, end_factor=0.0, total_iters=n_batch)

# Non-ahead of time compilation
train_model = torch.compile(torch_model,mode='reduce-overhead', fullgraph=True)

# -------------------------------------
# EXTRACT WEIGHTS
# When we define the torch model, random weights are instanciated.
# We extract them and use them for futhark as well

twdict = torch_model.state_dict().copy()
for k , t in twdict.items():
    twdict[k] = t.cpu().numpy().astype(fdtype)

fdimdic = {'wt' : (vocab_size, n_embd), 'wp' : (seq_size, n_embd),
          'wqry' : (n_embd, n_embd), 'wkey' : (n_embd, n_embd), 'wval' : (n_embd, n_embd),
          'wo' : (n_embd, n_embd), 'wu' : (4 * n_embd, n_embd), 'wd' :(n_embd, 4 * n_embd),
          'wc': (vocab_size, n_embd)}

fwdic = {}
fmdic = {}
fvdic = {}

for k , dim in fdimdic.items():
    fwdic[k] = np.zeros(dim, dtype=fdtype)
    fmdic[k] = np.zeros(dim, dtype=fdtype)
    fvdic[k] = np.zeros(dim, dtype=fdtype)

qkv = np.reshape(twdict['blocks.0.sa_heads.qkv.weight'], (3, n_embd, n_embd))
fwdic['wqry'][:,:] = qkv[0]
fwdic['wkey'][:,:] = qkv[1]
fwdic['wval'][:,:] = qkv[2]
fwdic['wt'][:,:]   = twdict['token_embedding_table.weight']
fwdic['wp'][:,:]   = twdict['position_embedding_table.weight']
fwdic['wo'][:,:]   = twdict['blocks.0.sa_heads.proj.weight']
fwdic['wu'][:,:]   = twdict['blocks.0.ffwd.net.0.weight']
fwdic['wd'][:,:]   = twdict['blocks.0.ffwd.net.2.weight']
fwdic['wc'][:,:]   = twdict['lm_head.weight']

ones = np.ones((seq_size,seq_size), dtype=fdtype)
cau_mask = (ones - np.tril(ones))
# -------------------------------------
# TRAINING TORCH

# We use batch_offsets to avoid adding an extra loop that extracts the batches
batch_offsets = torch.arange(batch_size, device=device)

# Compile ahead of time?
if aot_compile:
    print("Compiling Torch")
    start = time.time()
    # Torch asks for example inputs to compile ahead of time
    example_batch = torch.randint(
        0, vocab_size, (batch_size, seq_size -1), dtype=torch.long, device=device
    )
    example_target = torch.randint(
        0, vocab_size, (batch_size, seq_size -1), dtype=torch.long, device=device
    )
    # Compiled forward pass
    compiled_fn = train_model.forward.aot_compile(
        ((example_batch, example_target), {})
    )
    end = time.time()
    print("torch compiling time", end - start)

print("Training Torch")

torch_model.train()
# Start timer
start = time.time()
# Each sequence is of length seq_size - 1.
# This is so the target does not go out of index bounds
n = seq_size - 1
# For each batch...
for step in range(n_batch):
    # Get a batch and a target
    seqs = torch_data[(batch_offsets + step * batch_size) % len(docs)]
    batch = seqs[:, :n].contiguous()
    target = seqs[:, 1:n+1].contiguous()

    # Forward pass
    torch.compiler.cudagraph_mark_step_begin()
    if aot_compile:
        _, loss = compiled_fn(torch_model, batch, target)
    else:
        _, loss = train_model(batch, target)

    # Backpropagation
    optimizer.zero_grad(set_to_none=True)
    loss.backward()
    # Optimization
    optimizer.step()
    scheduler.step()

if device.type == 'cuda':
    torch.cuda.synchronize()
# End timer
end = time.time()
print("torch training time", end - start)

# # -------------------------------------
# # TRAINING FUT
print("Training Futhark")

#Preprocessing
# All batches
batches = np.zeros((n_batch, batch_size, seq_size)).astype(np.int64, copy=False)
# Attention mask
mask = -1*big_num*cau_mask

# We use batch_offsets to avoid adding an extra loop that extracts the batches
batch_offsets = np.arange(batch_size)

# Call server and put values
with futhark_server.Server(futhark) as server:
    for k , data in fwdic.items():
        server.put_value(k, data)
    server.cmd_call('to_params', 'p', *fwdic.keys())
    server.cmd_call('zero_params', 'mp')
    server.cmd_call('zero_params', 'vp')
    server.put_value('mask', mask)

    for step in range(n_batch):
        batches[step] = futhark_data[(batch_offsets + step * batch_size) % len(docs)]

    server.put_value('batches', batches)
    # Start timer
    start = time.time()
    server.cmd_call('train', 'p_mp_vp', 'p', 'mp', 'vp', 'mask', 'batches')
    # End timer
    end = time.time()
    p_mp_vp = server.get_value('p_mp_vp')

print("futhark training time", end - start)

for i , k in enumerate(fdimdic.keys()):
    fwdic[k] = p_mp_vp[i]
    fmdic[k] = p_mp_vp[i + 9]
    fmdic[k] = p_mp_vp[i + 18]

#-------------------------------------
# PROBS
# Do a forward pass to check the results match

# input
doc = "marulanda"
doc = doc[:seq_size - 2]
dl = len(doc) + 2
doc = bos + doc + bos
doc = doc + (bos * (seq_size - dl))
dl = len(doc)
assert dl == n_embd
print("".join(doc))
# sequence ids
python_tokens = [vocab.index(ch) for ch in doc]
torch_tokens = np.array([python_tokens for _ in range(batch_size)])
# to numpy
futhark_tokens = np.zeros((batch_size, n_embd)).astype(np.int64)
futhark_tokens[:,:] = torch_tokens

pad_mask = np.ones((n_embd,n_embd))
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
futhark_probatch_size =npsoftmax(futhark_logits, 1)

#### Torch
n = seq_size - 1
torch_target = torch_tokens[:,1:n+1]
torch_model.eval()
with torch.no_grad():
    x = torch.tensor(torch_tokens[:,:n], dtype=torch.long, device= device)
    y = torch.tensor(torch_target, dtype=torch.long, device= device)
    torch_logits, torch_loss = torch_model(x , y)
torch_logits = torch_logits .cpu().numpy()
torch_loss = torch_loss .cpu().numpy()
torch_probatch_size =npsoftmax(torch_logits, 1)
#-------------------------------------
# TESTS

print("futhark loss", futhark_loss)
print("torch   loss", torch_loss)
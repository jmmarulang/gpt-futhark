
"""
A PyTorch equivalent of microgpt.py: train and run inference for a character-level GPT.
"""
import numpy as np
import time
import random
import torch
import torch.nn as nn
from torch.nn import functional as F

# Hyperparameters
# const = 0.6
n_layer = 1
n_embd = 16
block_size = 16
n_head = 4
head_dim = n_embd // n_head
learning_rate = 0.01
vocab_size = 27
steps = 10000
bs = 5
# sl = 16
dtype = torch.float64  # GPUs run float64 at 1/2 to 1/64 of float32 speed; torch.float32 is much faster on consumer GPUs
use_compile = True     # torch.compile with CUDA graphs (GPU only); removes per-kernel launch overhead
log_every = 100        # printing the loss forces a GPU->CPU sync, so only do it every N steps

class MultiHeadAttention(nn.Module):
    def __init__(self):
        super().__init__()
        # all heads' q, k, v in one matmul instead of 3 * n_head small ones
        self.qkv = nn.Linear(n_embd, 3 * n_head * head_dim, bias=False)
        self.proj = nn.Linear(head_dim * n_head, n_embd, bias=False)

    def forward(self, x):
        B, T, C = x.shape
        q, k, v = self.qkv(x).split(n_head * head_dim, dim=-1)
        q = q.view(B, T, n_head, head_dim).transpose(1, 2) # (B, n_head, T, head_dim)
        k = k.view(B, T, n_head, head_dim).transpose(1, 2)
        v = v.view(B, T, n_head, head_dim).transpose(1, 2)
        # fused causal attention (scale = head_dim**-0.5, same as before)
        out = F.scaled_dot_product_attention(q, k, v, is_causal=True)
        out = out.transpose(1, 2).contiguous().view(B, T, n_head * head_dim)
        out = self.proj(out)
        return out

class FeedForward(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_embd, 4 * n_embd, bias=False),
            nn.ReLU(),
            nn.Linear(4 * n_embd, n_embd, bias=False),
        )

    def forward(self, x):
        return self.net(x)

class Block(nn.Module):
    def __init__(self):
        super().__init__()
        self.sa_heads = MultiHeadAttention()
        self.ffwd = FeedForward()

    def forward(self, x):
        x = x + self.sa_heads(F.rms_norm(x, (n_embd,), eps=1e-5))
        x = x + self.ffwd(F.rms_norm(x, (n_embd,), eps=1e-5))
        return x

class GPT(nn.Module):
    def __init__(self):
        super().__init__()
        self.token_embedding_table = nn.Embedding(vocab_size, n_embd)
        self.position_embedding_table = nn.Embedding(block_size, n_embd)
        self.blocks = nn.Sequential(*[Block() for _ in range(n_layer)])
        self.lm_head = nn.Linear(n_embd, vocab_size, bias=False)

        # Better init
        self.apply(self._init_weights)

    def _init_weights(self, module):
        if isinstance(module, nn.Linear):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.08)
            # torch.nn.init.constant_(module.weight, self.const)
        elif isinstance(module, nn.Embedding):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.08)
            # torch.nn.init.constant_(module.weight, self.const)

    def forward(self, idx, targets=None):
        B, T = idx.shape
        tok_emb = self.token_embedding_table(idx) # (B, T, n_embd)
        pos_emb = self.position_embedding_table(torch.arange(T, device=idx.device)) # (T, n_embd)
        x = tok_emb + pos_emb # (B, T, n_embd)
        x = F.rms_norm(x, (n_embd,), eps=1e-5)
        x = self.blocks(x) # (B, T, n_embd)
        logits = self.lm_head(x) # (B, T, vocab_size)

        if targets is None:
            loss = None
        else:
            B, T, C = logits.shape
            logits_flat = logits.view(B*T, C)
            targets = targets.reshape(B*T)
            losses = F.cross_entropy(logits_flat, targets, reduction='none')
            loss = torch.sum(losses)/(B * block_size)

        return logits, loss

## ------------------------------------
# Data
with open('input.txt') as file:
    docs = [line.strip() for line in file if line.strip()]
random.shuffle(docs)

# Tokenizer
uchars = sorted(set(''.join(docs)))
BOS = len(uchars)
bos = "_"
vocab_size = len(uchars) + 1
vocab = uchars + [bos]
stoi = {ch: i for i, ch in reversed(list(enumerate(vocab)))} # first occurrence wins, like vocab.index

print("batch size", bs)
print("number of steps", steps)

# Tokenization and Padding
for i in range(len(docs)):
    doc = docs[i][:block_size - 2]
    dl = len(doc) + 2
    doc = bos + doc + bos
    doc = doc + (bos * (block_size - dl))
    docs[i] = doc
    assert len(docs[i]) == block_size

# -------------------------------------
# DEFINE TORCH MODEL
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
torch_model = GPT().to(device=device, dtype=dtype)
learning_rate = 0.01

# Tokenize the whole dataset once and keep it on the device: no per-step Python tokenization or host->device copies
data = torch.tensor([[stoi[ch] for ch in doc] for doc in docs], dtype=torch.long, device=device) # (n_docs, block_size)
n_docs = data.shape[0]
batch_offsets = torch.arange(bs, device=device)

optimizer = torch.optim.Adam(torch_model.parameters(), lr=learning_rate, betas=(0.85, 0.99), eps=1e-8,
                             fused=device.type == 'cuda')
scheduler = torch.optim.lr_scheduler.LinearLR(optimizer, start_factor=1.0, end_factor=0.0, total_iters=steps)

compiled = use_compile and device.type == 'cuda'
train_model = torch.compile(torch_model, mode='reduce-overhead', fullgraph=True) if compiled else torch_model

# # # -------------------------------------
# # # TRAINING TORCH

print("Training Torch")

losses_dev = torch.zeros(steps, dtype=dtype, device=device)

torch_model.train()
start = time.time()
n = block_size - 1
for step in range(steps):
    # same docs, in the same order, as the original per-step loop
    seqs = data[(batch_offsets + step * bs) % n_docs]
    batch = seqs[:, :n]
    target = seqs[:, 1:n+1]

    if compiled:
        torch.compiler.cudagraph_mark_step_begin()
    _, loss = train_model(batch, target)

    optimizer.zero_grad(set_to_none=True)
    loss.backward()
    losses_dev[step] = loss.detach()
    optimizer.step()
    scheduler.step()

    if (step + 1) % log_every == 0 or step + 1 == steps:
        print(f"step {step+1:4d} / {steps:4d} | loss {losses_dev[step].item():.4f}", end='\r')

if device.type == 'cuda':
    torch.cuda.synchronize()
end = time.time()
torch_losses = losses_dev.double().cpu().numpy()
print()
print("torch training time", end - start)

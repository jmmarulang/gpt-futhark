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

    def forward(self, idx, targets):
        B, T = idx.shape
        tok_emb = self.token_embedding_table(idx) # (B, T, n_embd)
        pos_emb = self.position_embedding_table(torch.arange(T, device=idx.device)) # (T, n_embd)
        x = tok_emb + pos_emb # (B, T, n_embd)
        x = F.rms_norm(x, (n_embd,), eps=1e-5)
        x = self.blocks(x) # (B, T, n_embd)
        logits = self.lm_head(x) # (B, T, vocab_size)

        # if targets is None:
        #     loss = None
        # else:
        B, T, C = logits.shape
        logits_flat = logits.view(B*T, C)
        targets = targets.reshape(B*T)
        losses = F.cross_entropy(logits_flat, targets, reduction='none')
        loss = torch.sum(losses)/(B * block_size)

        return logits, loss
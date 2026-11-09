"""
A PyTorch equivalent of microgpt.py
"""
import numpy as np
import time
import random
import torch
import torch.nn as nn
from torch.nn import functional as F

class MultiHeadAttention(nn.Module):
    def __init__(self, n_head, head_dim, n_embd):
        super().__init__()
        self.n_head = n_head
        self.head_dim = head_dim
        self.n_emd = n_embd
        # all heads' q, k, v in one matmul instead of 3 * n_head small ones
        self.qkv = nn.Linear(n_embd, 3 * n_head * head_dim, bias=False)
        self.proj = nn.Linear(head_dim * n_head, n_embd, bias=False)

    def forward(self, x):
        B, T, C = x.shape
        q, k, v = self.qkv(x).split(self.n_head * self.head_dim, dim=-1)
        q = q.view(B, T, self.n_head, self.head_dim).transpose(1, 2) # (B, self.n_head, T, self.head_dim)
        k = k.view(B, T, self.n_head, self.head_dim).transpose(1, 2)
        v = v.view(B, T, self.n_head, self.head_dim).transpose(1, 2)
        # fused causal attention (scale = self.head_dim**-0.5, same as before)
        out = F.scaled_dot_product_attention(q, k, v, is_causal=True)
        out = out.transpose(1, 2).contiguous().view(B, T, self.n_head * self.head_dim)
        out = self.proj(out)
        return out

class FeedForward(nn.Module):
    def __init__(self, n_embd):
        super().__init__()
        self.n_emd = n_embd
        self.net = nn.Sequential(
            nn.Linear(n_embd, 4 * n_embd, bias=False),
            nn.ReLU(),
            nn.Linear(4 * n_embd, n_embd, bias=False),
        )

    def forward(self, x):
        return self.net(x)

class Block(nn.Module):
    def __init__(self, n_head, head_dim, n_embd):
        super().__init__()
        self.n_head = n_head
        self.head_dim = head_dim
        self.n_embd = n_embd
        self.sa_heads = MultiHeadAttention(n_head, head_dim, n_embd)
        self.ffwd = FeedForward(n_embd)

    def forward(self, x):
        x = x + self.sa_heads(F.rms_norm(x, (self.n_embd,), eps=1e-5))
        x = x + self.ffwd(F.rms_norm(x, (self.n_embd,), eps=1e-5))
        return x

class GPT(nn.Module):
    def __init__(self, n_head, head_dim, seq_size, vocab_size, n_embd, n_layer):
        super().__init__()
        self.n_head = n_head
        self.head_dim = head_dim
        self.seq_size = seq_size
        self.vocab_size = vocab_size
        self.n_embd = n_embd
        self.n_layer = n_layer
        self.token_embedding_table = nn.Embedding(vocab_size, n_embd)
        self.position_embedding_table = nn.Embedding(seq_size, n_embd)
        self.blocks = nn.Sequential(*[Block(n_head, head_dim, n_embd) for _ in range(n_layer)])
        self.lm_head = nn.Linear(n_embd, vocab_size, bias=False)

        # Better init
        self.apply(self._init_weights)

    def _init_weights(self, module):
        if isinstance(module, nn.Linear):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.08)
        elif isinstance(module, nn.Embedding):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.08)

    def forward(self, idx, targets):
        B, T = idx.shape
        tok_emb = self.token_embedding_table(idx) # (B, T, n_embd)
        pos_emb = self.position_embedding_table(torch.arange(T, device=idx.device)) # (T, n_embd)
        x = tok_emb + pos_emb # (B, T, n_embd)
        x = F.rms_norm(x, (self.n_embd,), eps=1e-5)
        x = self.blocks(x) # (B, T, n_embd)
        logits = self.lm_head(x) # (B, T, vocab_size)

        B, T, C = logits.shape
        logits_flat = logits.view(B*T, C)
        targets = targets.reshape(B*T)
        losses = F.cross_entropy(logits_flat, targets, reduction='none')
        loss = torch.sum(losses)/(B * self.seq_size)

        return logits, loss
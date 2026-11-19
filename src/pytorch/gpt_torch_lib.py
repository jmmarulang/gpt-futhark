"""
A PyTorch equivalent of microgpt.py
"""
import numpy as np
import time
import random
import torch
import torch.nn as nn
from torch.nn import functional as F
from dataclasses import dataclass

@dataclass
class GPTConfig :
    n_embd      : int
    seq_size    : int
    forward_dim : int
    n_head      : int
    n_layer     : int
    vocab_size  : int
    head_dim    : int
    bias        : bool

class MultiHeadAttention(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.n_head = config.n_head
        self.head_dim = config.head_dim
        self.n_embd = config.n_embd
        self.qkv = nn.Linear(self.n_embd, 3 * self.n_head * self.head_dim, bias=True)
        self.proj = nn.Linear(self.head_dim * self.n_head, self.n_embd, bias=True)

    def forward(self, x):
        B, T, C = x.shape
        q, k, v = self.qkv(x).split(self.n_head * self.head_dim, dim=-1)
        q = q.view(B, T, self.n_head, self.head_dim).transpose(1, 2) # (B, self.n_head, T, self.head_dim)
        k = k.view(B, T, self.n_head, self.head_dim).transpose(1, 2)
        v = v.view(B, T, self.n_head, self.head_dim).transpose(1, 2)
        out = F.scaled_dot_product_attention(q, k, v, is_causal=True)
        out = out.transpose(1, 2).contiguous().view(B, T, self.n_head * self.head_dim)
        out = self.proj(out)
        return out

class FeedForward(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.n_embd = config.n_embd
        self.net = nn.Sequential(
            nn.Linear(self.n_embd, 4 * self.n_embd, bias=True),
            nn.ReLU(),
            nn.Linear(4 * self.n_embd, self.n_embd, bias=True),
        )

    def forward(self, x):
        return self.net(x)

class LayerNorm(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.n_embd = config.n_embd
        self.layer_norm = nn.LayerNorm(config.n_embd, bias=config.bias)

    def forward(self, input):
        output = self.layer_norm(input)
        return output

class Block(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.ln_1 = LayerNorm(config)
        self.sa_heads = MultiHeadAttention(config)
        self.ln_2 = LayerNorm(config)
        self.ffwd = FeedForward(config)

    def forward(self, x):
        x = x + self.sa_heads(self.ln_1(x))
        x = x + self.ffwd(self.ln_2(x))
        return x

class GPT(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.n_head = config.n_head
        self.head_dim = config.head_dim
        self.seq_size = config.seq_size
        self.vocab_size = config.vocab_size
        self.n_embd = config.n_embd
        self.n_layer = config.n_layer

        self.token_embedding_table = nn.Embedding(self.vocab_size, self.n_embd)
        self.position_embedding_table = nn.Embedding(self.seq_size, self.n_embd)
        self.blocks = nn.Sequential(*[Block(config) for _ in range(self.n_layer)])
        self.ln_f = LayerNorm(config)
        self.lm_head = nn.Linear(self.n_embd, self.vocab_size, bias=True)

        # Better init
        self.apply(self._init_weights)

    def _init_weights(self, module):
        if isinstance(module, nn.Embedding):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.08)
        elif isinstance(module, nn.Linear):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.08)
        elif isinstance(module, nn.LayerNorm):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.08)

    def forward(self, idx, targets):
        B, T = idx.shape
        tok_emb = self.token_embedding_table(idx) # (B, T, n_embd)
        pos_emb = self.position_embedding_table(torch.arange(T, device=idx.device)) # (T, n_embd)
        x = tok_emb + pos_emb # (B, T, n_embd)
        x = self.blocks(x) # (B, T, n_embd)
        # x = F.layer_norm(x, (self.n_embd,), eps=1e-5)
        x = self.ln_f(x)
        logits = self.lm_head(x) # (B, T, vocab_size)

        B, T, C = logits.shape
        logits_flat = logits.view(B*T, C)
        targets = targets.reshape(B*T)
        losses = F.cross_entropy(logits_flat, targets, reduction='none')
        loss = torch.sum(losses)/(B * self.seq_size)

        return logits, loss
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
class GPTConfig               :
    n_embd                    : int
    seq_size                  : int
    forward_dim               : int
    n_head                    : int
    n_layer                   : int
    vocab_size                : int
    head_dim                  : int
    elementwise_affine        : bool

class MultiHeadAttention(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.n_head = config.n_head
        self.head_dim = config.head_dim
        self.n_emd = config.n_embd
        # all heads' q, k, v in one matmul instead of 3 * n_head small ones
        self.qkv = nn.Linear(config.n_embd, 3 * config.n_head * config.head_dim, bias=True)
        self.proj = nn.Linear(config.head_dim * config.n_head, config.n_embd, bias=True)

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
    def __init__(self, config):
        super().__init__()
        self.n_emd = config.n_embd
        self.net = nn.Sequential(
            nn.Linear(config.n_embd, 4 * config.n_embd, bias=True),
            nn.ReLU(),
            nn.Linear(4 * config.n_embd, config.n_embd, bias=True),
        )

    def forward(self, x):
        return self.net(x)

# class Norm(nn.Module):
#     def __init__(self, config):
#         super().__init__()
#         self.n_embd = config.n_embd
#         self.norm = nn.LayerNorm(config.n_embd, eps=1e-5, elementwise_affine= config.elementwise_affine)
#     def forward(self, x):
#             return self.norm(x)

class Block(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.n_head = config.n_head
        self.head_dim = config.head_dim
        self.n_embd = config.n_embd
        self.sa_norm = nn.LayerNorm(config.n_embd, eps=1e-5, elementwise_affine= config.elementwise_affine)
        self.sa_heads = MultiHeadAttention(config)
        self.ffwd_norm = nn.LayerNorm(config.n_embd, eps=1e-5, elementwise_affine= config.elementwise_affine)
        self.ffwd = FeedForward(config)

    def forward(self, x):
        x = x + self.sa_heads(self.sa_norm(x))
        x = x + self.ffwd(self.ffwd_norm(x))
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

        self.token_embedding_table = nn.Embedding(config.vocab_size, config.n_embd)
        self.position_embedding_table = nn.Embedding(config.seq_size, config.n_embd)
        self.blocks = nn.Sequential(*[Block(config) for _ in range(config.n_layer)])
        self.lm_norm = nn.LayerNorm(config.n_embd, eps=1e-5, elementwise_affine= config.elementwise_affine)
        self.lm_head = nn.Linear(config.n_embd, config.vocab_size, bias=True)

        # Tied weights
        # self.token_embedding_table.weight = self.lm_head.weight

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
        x = self.blocks(x) # (B, T, n_embd)
        x = self.lm_norm(x)
        logits = self.lm_head(x) # (B, T, vocab_size)

        B, T, C = logits.shape
        logits_flat = logits.view(B*T, C)
        targets = targets.reshape(B*T)
        losses = F.cross_entropy(logits_flat, targets, reduction='none')
        loss = torch.sum(losses)/(B * self.seq_size)

        return logits, loss
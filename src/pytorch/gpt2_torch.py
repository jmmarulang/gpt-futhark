# ===========================================================================================================

# From https://gist.github.com/ssnym/8b4a4715c02519bd23da427f3f197ed9

# GPT-2 Implementation
# Based on Andrej Karpathy's "Let's reproduce GPT-2" lecture
# https://www.youtube.com/watch?v=l8pRSuU81PU
#
# Modifications done:
# - Custom DataLoader with sequential batching and train/val split
# - Custom tiktokenizer wrapper
# - Checkpoint save/load
# - EOT stop token inference
# ===========================================================================================================

from dataclasses import dataclass
import torch
import torch.nn as nn
from torch.nn import functional as F
import math
import os

import tiktoken

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

EOT_TOKEN = 50256

# ===========================================================================================================

# @dataclass
# class GPTConfig:
#     block_size: int = 256
#     vocab_size: int = 65
#     n_layer: int = 6
#     n_head: int = 6
#     n_embd: int = 384


# GPT-2 124M parameter model configs
@dataclass
class GPTConfig:
    block_size: int = 1024
    vocab_size: int = 50257
    n_layer: int = 12
    n_head: int = 12
    n_embd: int = 768


class CausalSelfAttention(nn.Module):
    """
    Causal (masked) Multi-Head Self-Attention
    Input:
        x: (B, T, C)
            B = batch size
            T = sequence length
            C = embedding dimension (n_embd)
    Output:
        y: (B, T, C)

    x (B, T, C)
    |
    Linear → QKV (B, T, 3C)
    |
    split → q, k, v
    |
    reshape → (B, nh, T, hs)
    |
    attention → (B, nh, T, hs)
    |
    transpose → (B, T, nh, hs)
    |
    reshape → (B, T, C)
    |
    c_proj → (B, T, C)
    """

    def __init__(self, config):
        super().__init__()
        assert config.n_embd % config.n_head == 0
        # key, query, value projections for all heads,but in batch
        self.c_attn = nn.Linear(config.n_embd, 3 * config.n_embd) # [Wq | Wk | Wv] concatenated
        # output projection
        self.c_proj = nn.Linear(config.n_embd, config.n_embd) # after multi-head attention we merge heads → (B, T, C)
        # regularization
        self.n_head = config.n_head
        self.n_embd = config.n_embd
        # not really a 'bias' more of a mask, but following the OpenAI/HF naming though
        self.register_buffer("bias", torch.tril(torch.ones(config.block_size, config.block_size)).view(1, 1, config.block_size, config.block_size))

    def forward(self, x):
        B, T, C = x.size() # batch_size, sequence_lenght, n_embd
        # calculate query, key, values for all heads in batch and move head forward to be the bat.............
        # nh = 'number of heads', hs = 'head size'= C / n_head, C = (number of channels) == nh * ns
        # in GPT-2 (124M), n_head = 12, hs = 64, so nh*hs = 768 channels in the Transformer
        qkv = self.c_attn(x)    # (B, T, 3C)
        q, k, v = qkv.split(self.n_embd, dim=2)     # 3 * (B, T, C)
        k = k.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        q = q.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        v = v.view(B, T, self.n_head, C // self.n_head).transpose(1, 2) # (B, nh, T, hs)
        # attention (materializes the large (T,T) matrix for all the queries and keys)
        att = (q @ k.transpose(-2,-1))  # (B, nh, T, T)
        att = att * (1.0 / math.sqrt(k.size(-1))) # scaling
        att = att.masked_fill(self.bias[:, :, :T, :T] == 0, float('-inf')) # masking
        att = F.softmax(att, dim=-1) # tokens attend only past + current tokens
        y = att @ v # (B, nh, T, T) x (B, nh, T, hs) -> (B, nh, T, hs) - weighted sum of all tokens
        # now re-assembling all head outputs side by side
        y = y.transpose(1, 2) # (B, T, nh, hs)
        y = y.contiguous().view(B, T, C) # (B, T, C)
        # output projection - after concatenation, c_proj mixes information from all heads together
        y = self.c_proj(y)
        return y


class MLP(nn.Module):

    def __init__(self, config):
        super().__init__()
        self.c_fc = nn.Linear(config.n_embd, 4*config.n_embd)
        self.gelu = nn.GELU(approximate='tanh')                 # suggest to use approximate='none'
        self.c_proj = nn.Linear(4*config.n_embd, config.n_embd)

    def forward(self, x):
        x = self.c_fc(x)
        x = self.gelu(x)
        x = self.c_proj(x)
        return x

class Block(nn.Module):
    """
    Decoder Only Transformer Block (GPT-Style)
    |
    ├── LayerNorm → Self-Attention → Residual → LayerNorm → MLP → Residual
    |
    ├── Input:  (batch, seq, n_embd)
    └── Output: (batch, seq, n_embd)
    """

    def __init__(self, config):
        super().__init__()
        self.ln_1 = nn.LayerNorm(config.n_embd) # In GPT-2 layer-normalization blocks are before attention
        self.attn = CausalSelfAttention(config) # multi-head self-attention
        self.ln_2 = nn.LayerNorm(config.n_embd)
        self.mlp = MLP(config)

    def forward(self, x):
        # x = residual path + (layer_norm -> attention)
        x = x + self.attn(self.ln_1(x))
        x = x + self.mlp(self.ln_2(x))
        return x


class GPT(nn.Module):

    def __init__(self, config):
        super().__init__()
        self.config = config

        self.transformer = nn.ModuleDict(dict(
            wte = nn.Embedding(config.vocab_size, config.n_embd),
            wpe = nn.Embedding(config.block_size, config.n_embd),
            h = nn.ModuleList([Block(config) for _ in range(config.n_layer)]),
            ln_f = nn.LayerNorm(config.n_embd),
        ))
        self.lm_head = nn.Linear(config.n_embd, config.vocab_size, bias=False)
        # weight sharing between embedding layer and logits layer - better result + reduce parameters
        self.lm_head.weight = self.transformer.wte.weight

        # init parameters
        self.apply(self._init_weights)



    def _init_weights(self, module):
        """
        To initial weights just like GPT-2
        """
        if isinstance(module, nn.Linear):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)
            if module.bias is not None:
                torch.nn.init.zeros_(module.bias)
        elif isinstance(module, nn.Embedding):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)

    def forward(self, x):
        B, T = x.shape
        assert T<= self.config.block_size, f"Cannot forward sequence of length {T}, block_size is {self.config.block_size}"
        pos = torch.arange(0, T, dtype=torch.long, device = x.device) # shape(T)
        pos_emb = self.transformer.wpe(pos) # (T, n_embd)
        tok_emb = self.transformer.wte(x)   # (B, T, n_embd)
        x = pos_emb + tok_emb               # Broadcasting : (B, T, n_embd)
        # forward the blocks of transformer
        for block in self.transformer.h:
            x = block(x)
        # forward the final LayerNorm and classifier
        x = self.transformer.ln_f(x)  # (B, T, n_embd)
        logits = self.lm_head(x)    # (B, T, vocab_size)
        return logits



def save_checkpoint(model, optimizer, path):
    torch.save({
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
    }, path)
    print(f"Checkpoint Saved \n")


def load_checkpoint(model, optimizer, path):
    checkpoint = torch.load(path, map_location=device, weights_only=True)

    model.load_state_dict(checkpoint['model_state_dict'])

    if optimizer is not None:
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])

    print(f"Model Loaded \n")

    return model, optimizer



# ===========================================================================================================

class tiktokenizer:

    def __init__(self, model):
        self.enc = tiktoken.get_encoding(model)

    def encode_t(self, text, allowed_special=set()):
        tokens = self.enc.encode(text, allowed_special=allowed_special)
        tokens = torch.tensor(tokens, dtype=torch.long)
        return tokens # T

    def decode_t(self, tokens):
        out = self.enc.decode(tokens)
        return out


class DataLoader:
    """
    Sequential DataLoader : GPT style
    """

    def __init__(self, tokens, batch_size, block_size):

        self.tokens = tokens
        self.batch_size = batch_size
        self.block_size = block_size
        self.pos = 0

    def next_batch(self):
        B, T = self.batch_size, self.block_size
        # grab chunk from current position
        chunk = self.tokens[self.pos : self.pos + B*T + 1]
        x = chunk[:-1].view(B,T)
        y = chunk[1:].view(B,T)
        # advance position
        self.pos += B*T
        # reset if we'd go out of bounds next call
        if self.pos + B*T + 1 > len(self.tokens):
            self.pos = 0
        return x, y

# ===========================================================================================================

def predict(x, max_length, stop_token = None):
    """
    Predict next (max_length - T) tokens for B batches
    """
    torch.manual_seed(24)
    torch.cuda.manual_seed(42)
    while x.size(1) < max_length:
        with torch.no_grad():

            logits = model(x) # (5, T,  vocab_size) (B, T, vocab_size)
            logits = logits[:, -1, :] # (B, vocab_size) -- last token vocab_size only for each batch
            probs = F.softmax(logits, dim=-1)
            topk_probs, topk_indices = torch.topk(probs, 50, dim=-1) # (B, 50), (B, 50)
            ix = torch.multinomial(topk_probs, 1) # (B, 1)
            xcol = torch.gather(topk_indices, -1, ix) # (B, 1)
            if stop_token is not None and (xcol == stop_token).any():
                break
            x = torch.cat((x, xcol), dim=1)
    return x


def generate(num_return_sequences, x, max_length, enc):
    """
    Generate + decode + Display new _num_return_sequences_
    """
    x = predict(x, max_length, stop_token=EOT_TOKEN)

    for i in range(num_return_sequences):
        tokens = x[i].tolist()
        if  EOT_TOKEN in tokens:
            tokens = tokens[:tokens.index(EOT_TOKEN)]
        decode = enc.decode_t(tokens)
        print(">", decode, "\n")


def train(model:GPT, optimizer,  train_dataloader, val_dataloader,  epochs:int):

    B, T = train_dataloader.batch_size, train_dataloader.block_size
    steps_per_epoch = len(train_dataloader.tokens) // (B*T)
    val_steps = len(val_dataloader.tokens) // (B*T)

    if val_steps == 0:
        print("Warning: val set too small for even one batch, skipping val")
        val_steps = 1

    print(f"Total train steps per epoch : {steps_per_epoch}")
    print(f"Total val steps per epoch    : {val_steps}\n")

    for epoch in range(epochs):

        # ────────── Training ────────────────────
        model.train()
        train_dataloader.pos = 0
        epoch_loss = 0.0

        for step in range(steps_per_epoch):
            print(step)

            x, y = train_dataloader.next_batch()
            x, y  = x.to(device), y.to(device) # (B, T)

            logits = model(x)
            _, _, vocab_size = logits.shape

            loss = F.cross_entropy(logits.view(B*T, vocab_size), y.view(B*T))

            epoch_loss += loss.item()

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

        # ────────── Validation ────────────────────
        model.eval()
        val_dataloader.pos=0
        val_epoch_loss = 0.0

        with torch.no_grad():
            for step in range(val_steps):

                x_val, y_val = val_dataloader.next_batch()
                x_val, y_val = x_val.to(device), y_val.to(device)

                val_logits = model(x_val)
                _, _, val_vocab_size = val_logits.shape
                val_loss = F.cross_entropy(val_logits.view(B*T, val_vocab_size), y_val.view(B*T))

                val_epoch_loss += val_loss.item()

        epoch_loss = epoch_loss / steps_per_epoch
        val_epoch_loss = val_epoch_loss / val_steps
        print(f'{epoch}/{epochs} | train loss : {epoch_loss:.5f} | val loss : {val_epoch_loss:.5f}')


# ===========================================================================================================
block_size = 1

batch_size  = 1
epochs = 1
learning_rate = 3e-4

num_return_sequences = 1
max_length = 1

MODEL_PATH = 'mgpt2.pt'

config = GPTConfig()
model = GPT(config)
model.to(device)

# model.eval()

optimizer = torch.optim.AdamW(model.parameters(), lr=learning_rate, betas=(0.9, 0.95), eps=1e-8)

if os.path.exists(MODEL_PATH):
    model, optimizer = load_checkpoint(model, optimizer, MODEL_PATH)


enc = tiktokenizer('gpt2')


with open('data/shakespeare.txt', 'r', encoding='utf-8') as f:
    lines = f.read().splitlines()
text = '<|endoftext|>'.join(lines)

print(f"Total text : {len(text)}")

# testing with sample of data
text = text[:100]
print(f"Total text after truncating : {len(text)}")

tokens = enc.encode_t(text, allowed_special={'<|endoftext|>'}) # (T)

print(f"Total  Tokens : {tokens.shape}")

n = len(tokens)
train_tokens = tokens[:int(0.9*n)]
val_tokens = tokens[int(0.9*n):]

print(f"Train tokens : {len(train_tokens)}")
print(f"Val tokens : {len(val_tokens)}")

train_dataloader = DataLoader(train_tokens, batch_size, block_size)
val_dataloader = DataLoader(val_tokens, batch_size, block_size)

train(model, optimizer, train_dataloader, val_dataloader, epochs)

# save after training
save_checkpoint(model, optimizer, MODEL_PATH)


tokens = enc.encode_t("So the earth is ")
tokens = tokens.unsqueeze(0).repeat(num_return_sequences, 1) # (16, T) (B, T)
x = tokens.to(device)
model.eval()
generate(num_return_sequences, x, max_length, enc)
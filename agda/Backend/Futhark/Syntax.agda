-- A small DSL that mirrors the subset of Futhark we generate.
--
-- Unlike E, every construct here corresponds directly to a Futhark
-- construct: loops (imap, sum) and selections run over a single
-- dimension, scalar operations work on scalars only, and indices can
-- be combined arithmetically (needed for reshapes).  Arrays themselves
-- are still multi-dimensional, as they are in Futhark.
module Backend.Futhark.Syntax where

open import Data.Nat using (ℕ; _*_)
open import Data.List using (List; []; _∷_)
open import Relation.Binary.PropositionalEquality
open import Function

open import Ar using (S)
open import Lang using (Kop; Bop)

data FTy : Set where
  ix : ℕ → FTy
  ar : S → FTy

data FCtx : Set where
  ε   : FCtx
  _▹_ : FCtx → FTy → FCtx

infixl 15 _▹_

variable
  Γ Δ Ξ : FCtx
  τ σ : FTy
  m n k : ℕ
  s p q : S

data _∈_ : FTy → FCtx → Set where
  here  : τ ∈ (Γ ▹ τ)
  there : τ ∈ Γ → τ ∈ (Γ ▹ σ)

-- Extending a context with one 1-d index per dimension of a shape.
_▹▹_ : FCtx → S → FCtx
Γ ▹▹ [] = Γ
Γ ▹▹ (n ∷ s) = (Γ ▹ ix n) ▹▹ s

infixl 15 _▹▹_

-- Scalar unary operations (softmax is not scalar, so it is separate).
data Uop : Set where
  negₒ reluₒ sqrtₒ invₒ indpₒ lnₒ : Uop
  scₒ : ℕ → Uop

-- Index expressions.  `div n i` and `mod m i` are the components of
-- remQuot, `comb` is combine.
data I (Γ : FCtx) : ℕ → Set where
  var  : ix n ∈ Γ → I Γ n
  div  : ∀ n → I Γ (m * n) → I Γ m
  mod  : ∀ m → I Γ (m * n) → I Γ n
  comb : I Γ m → I Γ n → I Γ (m * n)

-- Array expressions of shape s.
data F (Γ : FCtx) : S → Set where
  var     : ar s ∈ Γ → F Γ s
  kop     : Kop → F Γ []
  uop     : Uop → F Γ [] → F Γ []
  bop     : Bop → F Γ [] → F Γ [] → F Γ []
  softmax : F (Γ ▹▹ s) [] → F Γ s              -- softmax over s of the elements
  imap    : F (Γ ▹ ix n) s → F Γ (n ∷ s)
  sum     : F (Γ ▹ ix n) [] → F Γ []
  sel     : F Γ (n ∷ s) → I Γ n → F Γ s
  ifeq    : I Γ n → I Γ n → F Γ [] → F Γ []    -- if i == j then e else 0
  let′    : F Γ p → F (Γ ▹ ar p) s → F Γ s
  ilet    : I Γ n → F (Γ ▹ ix n) s → F Γ s

-- Weakening
data _⊆_ : FCtx → FCtx → Set where
  ε    : ε ⊆ ε
  skip : Γ ⊆ Δ → Γ ⊆ (Δ ▹ τ)
  keep : Γ ⊆ Δ → (Γ ▹ τ) ⊆ (Δ ▹ τ)

⊆-eq : Γ ⊆ Γ
⊆-eq {ε} = ε
⊆-eq {Γ ▹ x} = keep ⊆-eq

wk▹▹ : Γ ⊆ Δ → Γ ⊆ (Δ ▹▹ s)
wk▹▹ {s = []} w = w
wk▹▹ {s = n ∷ s} w = wk▹▹ {s = s} (skip w)

keep▹▹ : Γ ⊆ Δ → (Γ ▹▹ s) ⊆ (Δ ▹▹ s)
keep▹▹ {s = []} w = w
keep▹▹ {s = n ∷ s} w = keep▹▹ {s = s} (keep w)

wkv : Γ ⊆ Δ → τ ∈ Γ → τ ∈ Δ
wkv (skip w) v = there (wkv w v)
wkv (keep w) here = here
wkv (keep w) (there v) = there (wkv w v)

wkI : Γ ⊆ Δ → I Γ n → I Δ n
wkI w (var x) = var (wkv w x)
wkI w (div n i) = div n (wkI w i)
wkI w (mod m i) = mod m (wkI w i)
wkI w (comb i j) = comb (wkI w i) (wkI w j)

wk : Γ ⊆ Δ → F Γ s → F Δ s
wk w (var x) = var (wkv w x)
wk w (kop o) = kop o
wk w (uop o e) = uop o (wk w e)
wk w (bop o e e₁) = bop o (wk w e) (wk w e₁)
wk w (softmax {s = s} e) = softmax (wk (keep▹▹ {s = s} w) e)
wk w (imap e) = imap (wk (keep w) e)
wk w (sum e) = sum (wk (keep w) e)
wk w (sel e i) = sel (wk w e) (wkI w i)
wk w (ifeq i j e) = ifeq (wkI w i) (wkI w j) (wk w e)
wk w (let′ e e₁) = let′ (wk w e) (wk (keep w) e₁)
wk w (ilet i e) = ilet (wkI w i) (wk (keep w) e)

↑ : Γ ⊆ (Γ ▹ τ)
↑ = skip ⊆-eq

-- Multi-dimensional indices are lists of 1-d index expressions.
data Idx (Γ : FCtx) : S → Set where
  []  : Idx Γ []
  _∷_ : I Γ n → Idx Γ s → Idx Γ (n ∷ s)

wkIdx : Γ ⊆ Δ → Idx Γ s → Idx Δ s
wkIdx w [] = []
wkIdx w (i ∷ is) = wkI w i ∷ wkIdx w is

-- The index variables bound by Γ ▹▹ s.
vars : ∀ s → Idx (Γ ▹▹ s) s
vars [] = []
vars (n ∷ s) = wkI (wk▹▹ {s = s} ⊆-eq) (var here) ∷ vars s

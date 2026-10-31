-- Printing F (Syntax.agda) as Futhark, using the helpers from
-- src/futhark/microgpt.fut (imap1, isum1, isoftmax1, ...).
--
-- This is the only unverified step of the verified backend: every F
-- construct maps directly to a Futhark construct.  Index lets are
-- inlined, as index expressions are cheap.
module Backend.Futhark.Print where

open import Data.Nat using (ℕ; suc; _+_)
open import Data.Nat.Show using () renaming (show to show-nat)
open import Data.List as L using (List; []; _∷_)
open import Data.String using (String; _++_; intersperse)
open import Text.Printf using (printf)
open import Function using (_$_)

open import Ar using (S)
open import Lang using (𝟘ₒ; 𝟙ₒ; ⊞ₒ; ⊠ₒ)
open import Backend.Futhark.Syntax

data Names : FCtx → Set where
  ε   : Names ε
  _▹_ : Names Γ → String → Names (Γ ▹ τ)

lookupN : τ ∈ Γ → Names Γ → String
lookupN here (ν ▹ x) = x
lookupN (there v) (ν ▹ _) = lookupN v ν

showI : I Γ n → Names Γ → String
showI (var x) ν = lookupN x ν
showI (div n i) ν = printf "(%s / %u)" (showI i ν) n
showI (mod {n = n} m i) ν = printf "(%s %% %u)" (showI i ν) n
showI (comb {n = n} i j) ν = printf "((%s * %u) + %s)" (showI i ν) n (showI j ν)

showUop : Uop → String → String
showUop negₒ = printf "(F.neg %s)"
showUop reluₒ = printf "(F.max %s zero)"
showUop sqrtₒ = printf "(F.sqrt %s)"
showUop invₒ = printf "(one F./ %s)"
showUop indpₒ = printf "(indicatorp %s)"
showUop lnₒ = printf "(F.log %s)"
showUop (scₒ n) x = printf "(%s F./ fromi64 %u)" x n

shape-args : S → String
shape-args s = intersperse " " (L.map show-nat s)

-- Names for the index variables of Γ ▹▹ s, starting at depth d.
extN : ∀ s → ℕ → Names Γ → Names (Γ ▹▹ s)
extN [] d ν = ν
extN (n ∷ s) d ν = extN s (suc d) (ν ▹ printf "i%u" d)

ix-names : ℕ → S → List String
ix-names d [] = []
ix-names d (n ∷ s) = printf "i%u" d ∷ ix-names (suc d) s

-- d is the binder depth, used to generate fresh names.
showF : ℕ → F Γ s → Names Γ → String
showF d (var x) ν = lookupN x ν
showF d (kop 𝟘ₒ) ν = "zero"
showF d (kop 𝟙ₒ) ν = "one"
showF d (uop o e) ν = showUop o (showF d e ν)
showF d (bop ⊞ₒ e e₁) ν = printf "(%s F.+ %s)" (showF d e ν) (showF d e₁ ν)
showF d (bop ⊠ₒ e e₁) ν = printf "(%s F.* %s)" (showF d e ν) (showF d e₁ ν)
showF d (softmax {s = []} e) ν =
  printf "(let x%u = F.exp %s in x%u F./ x%u)" d (showF d e ν) d d
showF d (softmax {s = s} e) ν =
  printf "(isoftmax%u %s (\\%s -> %s))" (L.length s) (shape-args s)
         (intersperse " " (ix-names d s)) (showF (d + L.length s) e (extN s d ν))
showF d (imap {n = n} e) ν =
  printf "(imap1 %u (\\i%u -> %s))" n d (showF (suc d) e (ν ▹ printf "i%u" d))
showF d (sum {n = n} e) ν =
  printf "(isum1 %u (\\i%u -> %s))" n d (showF (suc d) e (ν ▹ printf "i%u" d))
showF d (sel e i) ν = printf "%s[%s]" (showF d e ν) (showI i ν)
showF d (ifeq i j e) ν =
  printf "(if %s == %s then %s else zero)" (showI i ν) (showI j ν) (showF d e ν)
showF d (let′ e e₁) ν =
  printf "(let x%u = %s\nin %s)" d (showF d e ν) (showF (suc d) e₁ (ν ▹ printf "x%u" d))
showF d (ilet i e) ν = showF d e (ν ▹ showI i ν)

show : F Γ s → Names Γ → String
show e ν = showF 0 e ν

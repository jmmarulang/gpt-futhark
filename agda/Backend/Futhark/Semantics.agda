-- Semantics of the Futhark DSL (Syntax.agda), in the same style as Eval.agda.
-- Only the operations of Real are needed, none of its properties.
open import Data.Nat using (ℕ; zero; suc)
open import Data.Fin as Fin using (Fin; remQuot; combine)
open import Data.Product
open import Data.Unit
open import Data.List using ([]; _∷_)
open import Data.List.Relation.Unary.All using ([]; _∷_)
open import Relation.Binary.PropositionalEquality
open import Relation.Nullary
open import Function

open import Ar using (Ar; P; K; sum₁; sum₁-cong; sum-cong)
import Ar as A
open import Lang using (Kop; 𝟘ₒ; 𝟙ₒ; Bop; ⊞ₒ; ⊠ₒ)
open import Real
open import Backend.Futhark.Syntax

module Backend.Futhark.Semantics (r : Real) where
  open Real.Real r

  ⟦_⟧ᵗ : FTy → Set
  ⟦ ix n ⟧ᵗ = Fin n
  ⟦ ar s ⟧ᵗ = Ar s R

  ⟦_⟧ᶜ : FCtx → Set
  ⟦ ε ⟧ᶜ = ⊤
  ⟦ Γ ▹ τ ⟧ᶜ = ⟦ Γ ⟧ᶜ × ⟦ τ ⟧ᵗ

  lookup : τ ∈ Γ → ⟦ Γ ⟧ᶜ → ⟦ τ ⟧ᵗ
  lookup here (_ , x) = x
  lookup (there v) (ρ , _) = lookup v ρ

  evalI : I Γ n → ⟦ Γ ⟧ᶜ → Fin n
  evalI (var x) ρ = lookup x ρ
  evalI (div n i) ρ = proj₁ (remQuot n (evalI i ρ))
  evalI (mod {n = n} m i) ρ = proj₂ (remQuot {m} n (evalI i ρ))
  evalI (comb i j) ρ = combine (evalI i ρ) (evalI j ρ)

  evalIdx : Idx Γ s → ⟦ Γ ⟧ᶜ → P s
  evalIdx [] ρ = []
  evalIdx (i ∷ is) ρ = evalI i ρ ∷ evalIdx is ρ

  kopᵣ : Kop → R
  kopᵣ 𝟘ₒ = fromℕ 0
  kopᵣ 𝟙ₒ = fromℕ 1

  uopᵣ : Uop → R → R
  uopᵣ negₒ = -_
  uopᵣ reluₒ = _∨_ 0ᵣ
  uopᵣ sqrtₒ = √_
  uopᵣ invₒ = 1/_
  uopᵣ indpₒ = I+
  uopᵣ lnₒ = log
  uopᵣ (scₒ n) = _÷ fromℕ n

  bopᵣ : Bop → R → R → R
  bopᵣ ⊞ₒ = _+_
  bopᵣ ⊠ₒ = _*_

  ifeqᵣ : Fin n → Fin n → R → R
  ifeqᵣ i j x with i Fin.≟ j
  ... | yes _ = x
  ... | no _ = fromℕ 0

  -- Same definition as in Eval.
  Softmax : Ar s R → Ar s R
  Softmax a = A.map (λ x → x ÷ total) exps where
    exps = A.map (e^_) a
    total = A.sum _+_ (fromℕ 0) exps

  hd : P (n ∷ []) → Fin n
  hd (i ∷ []) = i

  -- Environments for Γ ▹▹ s
  ext : ⟦ Γ ⟧ᶜ → P s → ⟦ Γ ▹▹ s ⟧ᶜ
  ext {s = []} ρ [] = ρ
  ext {s = n ∷ s} ρ (i ∷ is) = ext (ρ , i) is

  eval : F Γ s → ⟦ Γ ⟧ᶜ → Ar s R
  eval (var x) ρ = lookup x ρ
  eval (kop o) ρ = K (kopᵣ o)
  eval (uop o e) ρ = A.map (uopᵣ o) (eval e ρ)
  eval (bop o e e₁) ρ = A.zipWith (bopᵣ o) (eval e ρ) (eval e₁ ρ)
  eval (softmax e) ρ = Softmax (λ i → eval e (ext ρ i) [])
  eval (imap e) ρ (i ∷ is) = eval e (ρ , i) is
  eval (sum e) ρ _ = sum₁ _+_ (fromℕ 0) (λ i → eval e (ρ , hd i) [])
  eval (sel e i) ρ is = eval e ρ (evalI i ρ ∷ is)
  eval (ifeq i j e) ρ is = ifeqᵣ (evalI i ρ) (evalI j ρ) (eval e ρ is)
  eval (let′ e e₁) ρ = eval e₁ (ρ , eval e ρ)
  eval (ilet i e) ρ = eval e (ρ , evalI i ρ)

  -- Pointwise equality of arrays and environments.
  _≈ᵃ_ : Ar s R → Ar s R → Set
  a ≈ᵃ b = ∀ i → a i ≡ b i

  _≈ᵗ_ : ⟦ τ ⟧ᵗ → ⟦ τ ⟧ᵗ → Set
  _≈ᵗ_ {ix n} a b = a ≡ b
  _≈ᵗ_ {ar s} a b = a ≈ᵃ b

  data _≈ᶜ_ : ⟦ Γ ⟧ᶜ → ⟦ Γ ⟧ᶜ → Set where
    ε : tt ≈ᶜ tt
    _▹_ : ∀ {ρ ν : ⟦ Γ ⟧ᶜ} → ρ ≈ᶜ ν → ∀ {a b : ⟦ τ ⟧ᵗ} → a ≈ᵗ b → (ρ , a) ≈ᶜ (ν , b)

  reflᵗ : {a : ⟦ τ ⟧ᵗ} → a ≈ᵗ a
  reflᵗ {ix n} = refl
  reflᵗ {ar s} _ = refl

  reflᶜ : {ρ : ⟦ Γ ⟧ᶜ} → ρ ≈ᶜ ρ
  reflᶜ {ε} = ε
  reflᶜ {Γ ▹ τ} = reflᶜ ▹ reflᵗ

  lookup-cong : {ρ ν : ⟦ Γ ⟧ᶜ} → ρ ≈ᶜ ν → (v : τ ∈ Γ) → lookup v ρ ≈ᵗ lookup v ν
  lookup-cong (eq ▹ x) here = x
  lookup-cong (eq ▹ x) (there v) = lookup-cong eq v

  evalI-cong : (i : I Γ n) {ρ ν : ⟦ Γ ⟧ᶜ} → ρ ≈ᶜ ν → evalI i ρ ≡ evalI i ν
  evalI-cong (var x) eq = lookup-cong eq x
  evalI-cong (div n i) eq = cong (λ t → proj₁ (remQuot n t)) (evalI-cong i eq)
  evalI-cong (mod {n = n} m i) eq = cong (λ t → proj₂ (remQuot {m} n t)) (evalI-cong i eq)
  evalI-cong (comb i j) eq = cong₂ combine (evalI-cong i eq) (evalI-cong j eq)

  Softmax-cong : {a b : Ar s R} → a ≈ᵃ b → Softmax a ≈ᵃ Softmax b
  Softmax-cong {a = a} eq i = cong₂ _÷_ (cong e^_ (eq i))
                                        (sum-cong _+_ _ {e^_ ∘ a} (cong e^_ ∘ eq))

  ext-cong : {ρ ν : ⟦ Γ ⟧ᶜ} → ρ ≈ᶜ ν → (is : P s) → ext ρ is ≈ᶜ ext ν is
  ext-cong eq [] = eq
  ext-cong eq (i ∷ is) = ext-cong (eq ▹ refl) is

  eval-cong : (e : F Γ s) {ρ ν : ⟦ Γ ⟧ᶜ} → ρ ≈ᶜ ν → eval e ρ ≈ᵃ eval e ν
  eval-cong (var x) eq = lookup-cong eq x
  eval-cong (kop o) eq _ = refl
  eval-cong (uop o e) eq i = cong (uopᵣ o) (eval-cong e eq i)
  eval-cong (bop o e e₁) eq i = cong₂ (bopᵣ o) (eval-cong e eq i) (eval-cong e₁ eq i)
  eval-cong (softmax e) eq = Softmax-cong (λ i → eval-cong e (ext-cong eq i) [])
  eval-cong (imap e) eq (i ∷ is) = eval-cong e (eq ▹ refl) is
  eval-cong (sum e) {ρ} {ν} eq _ = sum₁-cong _+_ _ {λ i → eval e (ρ , hd i) []}
                                                   {λ i → eval e (ν , hd i) []}
                                                   (λ i → eval-cong e (eq ▹ refl) [])
  eval-cong (sel e i) eq is = trans (eval-cong e eq _)
                                    (cong (λ t → eval e _ (t ∷ is)) (evalI-cong i eq))
  eval-cong (ifeq i j e) {ρ} {ν} eq is =
    trans (cong₂ (λ a b → ifeqᵣ a b (eval e ρ is)) (evalI-cong i eq) (evalI-cong j eq))
          (cong (ifeqᵣ (evalI i ν) (evalI j ν)) (eval-cong e eq is))
  eval-cong (let′ e e₁) eq = eval-cong e₁ (eq ▹ eval-cong e eq)
  eval-cong (ilet i e) eq = eval-cong e (eq ▹ evalI-cong i eq)

  -- Weakening
  wk-env : Γ ⊆ Δ → ⟦ Δ ⟧ᶜ → ⟦ Γ ⟧ᶜ
  wk-env ε ρ = ρ
  wk-env (skip w) (ρ , _) = wk-env w ρ
  wk-env (keep w) (ρ , x) = wk-env w ρ , x

  wk-env-id : (ρ : ⟦ Γ ⟧ᶜ) → wk-env ⊆-eq ρ ≡ ρ
  wk-env-id {ε} ρ = refl
  wk-env-id {Γ ▹ τ} (ρ , x) = cong (_, x) (wk-env-id ρ)

  wk-env-keep▹▹ : (w : Γ ⊆ Δ) (ρ : ⟦ Δ ⟧ᶜ) (is : P s)
                → wk-env (keep▹▹ {s = s} w) (ext ρ is) ≡ ext (wk-env w ρ) is
  wk-env-keep▹▹ {s = []} w ρ [] = refl
  wk-env-keep▹▹ {s = n ∷ s} w ρ (i ∷ is) = wk-env-keep▹▹ (keep w) (ρ , i) is

  lookup-wk : (w : Γ ⊆ Δ) (v : τ ∈ Γ) (ρ : ⟦ Δ ⟧ᶜ) → lookup (wkv w v) ρ ≡ lookup v (wk-env w ρ)
  lookup-wk (skip w) v (ρ , _) = lookup-wk w v ρ
  lookup-wk (keep w) here ρ = refl
  lookup-wk (keep w) (there v) (ρ , _) = lookup-wk w v ρ

  evalI-wk : (w : Γ ⊆ Δ) (i : I Γ n) (ρ : ⟦ Δ ⟧ᶜ) → evalI (wkI w i) ρ ≡ evalI i (wk-env w ρ)
  evalI-wk w (var x) ρ = lookup-wk w x ρ
  evalI-wk w (div n i) ρ = cong (λ t → proj₁ (remQuot n t)) (evalI-wk w i ρ)
  evalI-wk w (mod {n = n} m i) ρ = cong (λ t → proj₂ (remQuot {m} n t)) (evalI-wk w i ρ)
  evalI-wk w (comb i j) ρ = cong₂ combine (evalI-wk w i ρ) (evalI-wk w j ρ)

  evalIdx-wk : (w : Γ ⊆ Δ) (is : Idx Γ s) (ρ : ⟦ Δ ⟧ᶜ)
             → evalIdx (wkIdx w is) ρ ≡ evalIdx is (wk-env w ρ)
  evalIdx-wk w [] ρ = refl
  evalIdx-wk w (i ∷ is) ρ = cong₂ _∷_ (evalI-wk w i ρ) (evalIdx-wk w is ρ)

  eval-wk : (w : Γ ⊆ Δ) (e : F Γ s) (ρ : ⟦ Δ ⟧ᶜ) → eval (wk w e) ρ ≈ᵃ eval e (wk-env w ρ)
  eval-wk w (var x) ρ i = cong (λ a → a i) (lookup-wk w x ρ)
  eval-wk w (kop o) ρ _ = refl
  eval-wk w (uop o e) ρ i = cong (uopᵣ o) (eval-wk w e ρ i)
  eval-wk w (bop o e e₁) ρ i = cong₂ (bopᵣ o) (eval-wk w e ρ i) (eval-wk w e₁ ρ i)
  eval-wk w (softmax {s = s} e) ρ =
    Softmax-cong (λ i → trans (eval-wk (keep▹▹ {s = s} w) e (ext ρ i) [])
                              (cong (λ z → eval e z []) (wk-env-keep▹▹ w ρ i)))
  eval-wk w (imap e) ρ (i ∷ is) = eval-wk (keep w) e (ρ , i) is
  eval-wk w (sum e) ρ _ = sum₁-cong _+_ _ {λ i → eval (wk (keep w) e) (ρ , hd i) []}
                                          {λ i → eval e (wk-env w ρ , hd i) []}
                                          (λ i → eval-wk (keep w) e (ρ , hd i) [])
  eval-wk w (sel e i) ρ is = trans (cong (λ t → eval (wk w e) ρ (t ∷ is)) (evalI-wk w i ρ))
                                   (eval-wk w e ρ _)
  eval-wk w (ifeq i j e) ρ is =
    trans (cong₂ (λ a b → ifeqᵣ a b (eval (wk w e) ρ is)) (evalI-wk w i ρ) (evalI-wk w j ρ))
          (cong (ifeqᵣ (evalI i (wk-env w ρ)) (evalI j (wk-env w ρ))) (eval-wk w e ρ is))
  eval-wk w (let′ e e₁) ρ is = trans (eval-wk (keep w) e₁ _ is)
                                     (eval-cong e₁ (reflᶜ ▹ eval-wk w e ρ) is)
  eval-wk w (ilet i e) ρ is = trans (eval-wk (keep w) e _ is)
                                    (cong (λ t → eval e (wk-env w ρ , t) is) (evalI-wk w i ρ))

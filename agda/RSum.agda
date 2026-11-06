-- Sums of reals over shapes: linearity, Fubini, nested and blocked
-- shapes.  The generic facts about sums are in Ar; the delta rules for
-- one-hot arrays are in Eval.ZeroBut.
--
-- TODO: the proofs in Opt.agda chain sum-inv and sum-cong by hand;
-- they could use the lemmas here (together with the cleanup of
-- RealProp).
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Nat as ℕ using (ℕ; zero; suc)
open import Data.Fin as F using (Fin; zero; suc; _↑ˡ_; _↑ʳ_; combine)
open import Data.Fin.Properties using (remQuot-combine)
import Data.List as L
open import Data.List.Relation.Unary.All using ([]; _∷_)
open import Function
open import Relation.Binary.PropositionalEquality hiding ([_])
open import Ar
open import Real

module RSum (r : Real) (rp : RealProp r) where

open Real.Real r
open RealProp rp

sum₁-zero : sum₁ {n = n} _+_ (fromℕ 0) (K (fromℕ 0)) ≡ fromℕ 0
sum₁-zero {zero} = refl
sum₁-zero {suc n} = +-neutˡ ∙ sum₁-zero {n}

sum-zero : Ar.sum {s = s} _+_ (fromℕ 0) (λ _ → fromℕ 0) ≡ fromℕ 0
sum-zero {s = L.[]} = refl
sum-zero {s = x L.∷ s} = sum₁-cong {n = x} _+_ (fromℕ 0) (λ i → sum-zero {s}) ∙ sum₁-zero {x}

rsum : Ar s R → R
rsum = Ar.sum _+_ (fromℕ 0)

rsum₁ : Ar [ n ] R → R
rsum₁ = sum₁ _+_ (fromℕ 0)

rsum-cong : {a b : Ar s R} → a ≈ᵃ b → rsum a ≡ rsum b
rsum-cong = sum-cong _+_ (fromℕ 0)

rsum-cong′ : (a b : Ar s R) → a ≈ᵃ b → rsum a ≡ rsum b
rsum-cong′ a b = sum-cong _+_ (fromℕ 0)

rsum₁-cong : {a b : Ar [ n ] R} → a ≈ᵃ b → rsum₁ a ≡ rsum₁ b
rsum₁-cong = sum₁-cong _+_ (fromℕ 0)

rsum₁-cong′ : (a b : Ar [ n ] R) → a ≈ᵃ b → rsum₁ a ≡ rsum₁ b
rsum₁-cong′ a b = sum₁-cong _+_ (fromℕ 0)

rsum-0 : rsum {s} (λ _ → fromℕ 0) ≡ fromℕ 0
rsum-0 {s} = sum-zero {s = s}

-- A sum of arrays at an index is the sum at that index.
rsum-inv : (a : Ar p (Ar s R)) (i : P s)
      → Ar.sum (zipWith _+_) (K (fromℕ 0)) a i ≡ rsum (λ k → a k i)
rsum-inv a i = sum-inv _+_ (fromℕ 0) {a} i

rsum₁-+ : (a b : Ar [ n ] R) → rsum₁ (λ i → a i + b i) ≡ rsum₁ a + rsum₁ b
rsum₁-+ {zero} a b = sym +-neutˡ
rsum₁-+ {suc n} a b = cong (a _ + b _ +_) (rsum₁-+ (a ∘ ιsuc) (b ∘ ιsuc)) ∙ +-medial

rsum-+ : (a b : Ar s R) → rsum (λ i → a i + b i) ≡ rsum a + rsum b
rsum-+ {L.[]} a b = refl
rsum-+ {x L.∷ s} a b = rsum₁-cong (λ i → rsum-+ (λ j → a (i ++ j)) (λ j → b (i ++ j)))
                ∙ rsum₁-+ (λ i → rsum (λ j → a (i ++ j))) (λ i → rsum (λ j → b (i ++ j)))

rsum-*ˡ : (c : R) (a : Ar s R) → c * rsum a ≡ rsum (λ i → c * a i)
rsum-*ˡ c a = sym (sum-const-out {a = c} {b = a} {_⊕_ = _+_} {_⊙_ = _*_}
                              (fromℕ 0) +-neutˡ (sym *-nulʳ) dist)

-- - x = (- 1) * x
neg-* : ∀ {x} → - x ≡ (- fromℕ 1) * x
neg-* = sym (minus-*-pushˡ ∙ cong -_ *-neutˡ)

rsum-neg : (a : Ar s R) → rsum (λ i → - a i) ≡ - rsum a
rsum-neg a = rsum-cong′ (λ i → - a i) (λ i → (- fromℕ 1) * a i) (λ i → neg-*) ∙ sym (rsum-*ˡ _ a) ∙ sym neg-*

-- Fubini
rsum₁-swap : (h : P [ n ] → P s → R) → rsum₁ (λ i → rsum (h i)) ≡ rsum (λ j → rsum₁ (λ i → h i j))
rsum₁-swap {zero} {s} h = sym (rsum-0 {s = s})
rsum₁-swap {suc n} h = cong (rsum (h _) +_) (rsum₁-swap (h ∘ ιsuc))
                   ∙ sym (rsum-+ (h (zero ∷ [])) (λ j → rsum₁ (λ i → h (ιsuc i) j)))

rsum-swap : (f : P s → P p → R) → rsum (λ i → rsum (f i)) ≡ rsum (λ j → rsum (λ i → f i j))
rsum-swap {L.[]} f = refl
rsum-swap {x L.∷ s} f = rsum₁-cong (λ i → rsum-swap (λ k → f (i ++ k)))
                 ∙ rsum₁-swap (λ i j → rsum (λ k → f (i ++ k) j))

-- Sums over s ⊗ p are nested sums.
rsum-⊗ : (f : P (s ⊗ p) → R) → rsum f ≡ rsum {s} (λ i → rsum {p} (λ j → f (i ++ j)))
rsum-⊗ {s} {p} f = rsum-cong′ f (unnest {s = s} {p = p} (λ i j → f (i ++ j)))
                        (λ k → cong f (splitP-eq {s = s} {p = p} k))
              ∙ sym (sum-map {s = s} {p = p} _+_ (fromℕ 0) {λ i j → f (i ++ j)})

-- Sums over blocked shapes are nested sums.
inj-l : P [ m ] → P [ m ℕ.+ n ]
inj-l (i ∷ []) = (i ↑ˡ _) ∷ []

inj-r : P [ n ] → P [ m ℕ.+ n ]
inj-r {m = m} (i ∷ []) = (m ↑ʳ i) ∷ []

rsum₁-split : (f : Ar [ m ℕ.+ n ] R) → rsum₁ f ≡ rsum₁ (f ∘ inj-l {n = n}) + rsum₁ (f ∘ inj-r {m = m})
rsum₁-split {zero} f = rsum₁-cong′ f (f ∘ inj-r {m = 0}) (λ { (i ∷ []) → refl }) ∙ sym +-neutˡ
rsum₁-split {suc m} {n} f =
  cong (f _ +_) (rsum₁-split {m} {n} (f ∘ ιsuc))
  ∙ sym +-assoc
  ∙ cong₂ _+_ (cong (f _ +_) (rsum₁-cong′ (f ∘ ιsuc ∘ inj-l {n = n}) (f ∘ inj-l {n = n} ∘ ιsuc)
                                       λ { (i ∷ []) → refl }))
              (rsum₁-cong′ (f ∘ ιsuc ∘ inj-r {m = m}) (f ∘ inj-r {m = suc m}) λ { (i ∷ []) → refl })

comb₁ : P [ m ] → P [ n ] → P [ m ℕ.* n ]
comb₁ (x ∷ []) (y ∷ []) = combine x y ∷ []

rsum₁-combine : (f : Ar [ m ℕ.* n ] R) → rsum₁ f ≡ rsum₁ {m} (λ x → rsum₁ {n} (λ y → f (comb₁ x y)))
rsum₁-combine {zero} f = refl
rsum₁-combine {suc m} {n} f =
  rsum₁-split {n} {m ℕ.* n} f
  ∙ cong₂ _+_ (rsum₁-cong′ (f ∘ inj-l {n = m ℕ.* n}) (λ y → f (comb₁ {suc m} {n} (zero ∷ []) y))
                        λ { (y ∷ []) → refl })
              (rsum₁-combine {m} {n} (f ∘ inj-r {m = n})
               ∙ rsum₁-cong′ (λ x → rsum₁ (λ y → f (inj-r {m = n} (comb₁ {m} {n} x y))))
                          (λ x → rsum₁ (λ y → f (comb₁ {suc m} {n} (ιsuc x) y)))
                          λ { (x ∷ []) → rsum₁-cong′ (λ y → f (inj-r {m = n} (comb₁ {m} {n} (x ∷ []) y)))
                                                  (λ y → f (comb₁ {suc m} {n} (ιsuc (x ∷ [])) y))
                                                  λ { (y ∷ []) → refl } })

rsum-block : (m : s * p ≈ q) (f : Ar q R) → rsum f ≡ rsum (λ k → rsum (λ j → f (ix-combine k j m)))
rsum-block [] f = refl
rsum-block {s = n₁ L.∷ s′} {p = n₂ L.∷ p′} m@(cons ⦃ refl ⦄ ⦃ pf ⦄) f =
  rsum₁-cong (λ c → rsum-block pf (λ is → f (c ++ is)))
  ∙ rsum₁-combine {n₁} {n₂} G
  ∙ rsum₁-cong {a = λ x → rsum₁ (λ y → rsum (F x y))} {b = λ x → rsum (λ k → rsum₁ (λ y → F x y k))}
            (λ x → rsum₁-swap (F x))
  ∙ rsum₁-cong {a = λ x → rsum (λ k → rsum₁ (λ y → F x y k))}
            {b = λ x → rsum (λ k → rsum (λ j → f (ix-combine (x ++ k) j m)))}
            (λ { (x ∷ []) → rsum-cong λ k →
                   rsum₁-cong {a = λ y → F (x ∷ []) y k}
                           {b = λ y → rsum (λ j → f (ix-combine (x ∷ k) (y ++ j) m))}
                           λ { (y ∷ []) → refl } })
  where
    G : Ar [ n₁ ℕ.* n₂ ] R
    G c = rsum (λ k → rsum (λ j → f (c ++ ix-combine k j pf)))
    F : P [ n₁ ] → P [ n₂ ] → P s′ → R
    F x y k = rsum (λ j → f (comb₁ x y ++ ix-combine k j pf))

ix-div-combine : (k : P s) (j : P p) (m : s * p ≈ q) → ix-div (ix-combine k j m) m ≡ k
ix-div-combine [] [] [] = refl
ix-div-combine (x ∷ k) (y ∷ j) (cons ⦃ refl ⦄ ⦃ pf ⦄) =
  cong₂ _∷_ (cong proj₁ (remQuot-combine x y)) (ix-div-combine k j pf)

ix-mod-combine : (k : P s) (j : P p) (m : s * p ≈ q) → ix-mod (ix-combine k j m) m ≡ j
ix-mod-combine [] j [] = refl
ix-mod-combine (x ∷ k) (y ∷ j) (cons ⦃ refl ⦄ ⦃ pf ⦄) =
  cong₂ _∷_ (cong proj₂ (remQuot-combine x y)) (ix-mod-combine k j pf)

-- A shape q that splits into s and p: sums over q are nested sums.
-- Loops (imaps, imap, imapb) and selections (sels, sel, selb) only
-- differ in the split.
record Split (s p q : S) : Set where
  field
    comb     : P s → P p → P q
    fst      : P q → P s
    snd      : P q → P p
    fst-comb : ∀ k l → fst (comb k l) ≡ k
    snd-comb : ∀ k l → snd (comb k l) ≡ l
    rsum-split  : (f : P q → R) → rsum f ≡ rsum (λ k → rsum (λ l → f (comb k l)))

unit-split : Split s L.[] s
unit-split = record
  { comb = λ k _ → k ; fst = λ k → k ; snd = λ _ → []
  ; fst-comb = λ _ _ → refl ; snd-comb = λ { _ [] → refl } ; rsum-split = λ f → refl }

⊗-split : Split s p (s ⊗ p)
⊗-split {s} {p} = record
  { comb = _++_ ; fst = λ k → proj₁ (splitP k) ; snd = λ k → proj₂ (splitP k)
  ; fst-comb = λ _ _ → splitP-proj₁ {s = s} {p = p}
  ; snd-comb = λ _ _ → splitP-proj₂ {s = s} {p = p}
  ; rsum-split = rsum-⊗ {s = s} {p = p} }

block-split : s * p ≈ q → Split s p q
block-split m = record
  { comb = λ k l → ix-combine k l m ; fst = λ k → ix-div k m ; snd = λ k → ix-mod k m
  ; fst-comb = λ k l → ix-div-combine k l m ; snd-comb = λ k l → ix-mod-combine k l m
  ; rsum-split = rsum-block m }


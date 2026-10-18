{-# OPTIONS  --backtracking-instance-search #-}
-- {-# OPTIONS --warn=noUserWarning #-}

module _ where
module _ where
  open import Ar hiding (sum; slide; backslide; imapb; selb)
  open import Relation.Binary.PropositionalEquality
  open import Data.Product
  open import Data.Nat using (ℕ; zero; suc; _≟_)
  open import Data.List as L
  open import Data.List.Properties as L
  open import Relation.Nullary
  open import Data.Maybe
  open import Function
  open import Lang
  open import Ar
  open import LangEq

  open WkSub

  -- replace x with y in e, if x is any subexpression in e.
  replace : (e : E Γ is) (x y : E Γ ip) → E Γ is
  replace e x y with e-eq? e x
  ... | just (refl , refl) = y
  replace (var v) x y | nothing = var v
  replace 𝟘 x y | nothing = 𝟘
  replace 𝟙 x y | nothing = 𝟙
  replace (imaps e) x y | nothing = imaps (replace e (x ↑) (y ↑))
  replace (sels e e₁) x y | nothing = sels (replace e x y) (replace e₁ x y)
  replace (imap′ refl e) x y | nothing = imap (replace e (x ↑) (y ↑))
  replace (sel′ refl e e₁) x y | nothing = sel (replace e x y) (replace e₁ x y)
  replace (imapb x₁ e) x y | nothing = Lang.imapb x₁ (replace e (x ↑) (y ↑))
  replace (selb x₁ e e₁) x y | nothing = Lang.selb x₁ (replace e x y) (replace e₁ x y)
  replace (sum e) x y | nothing = Lang.sum (replace e (x ↑) (y ↑))
  replace (zero-but e e₁ e₂) x y | nothing = zero-but (replace e x y) (replace e₁ x y) (replace e₂ x y)
  -- replace (E.slide e x₁ e₁ x₂) x y | nothing = E.slide (replace e x y) x₁ (replace e₁ x y) x₂
  -- replace (E.backslide e e₁ x₁ x₂) x y | nothing = E.backslide (replace e x y) (replace e₁ x y) x₁ x₂
  -- replace (logistic e) x y | nothing = logistic (replace e x y)
  replace (bop x₁ e e₁) x y | nothing = bop x₁ (replace e x y) (replace e₁ x y)
  replace (scaledown x₁ e) x y | nothing = scaledown x₁ (replace e x y)
  -- replace (minus e) x y | nothing = minus (replace e x y)
  replace (let′ e e₁) x y | nothing = let′ (replace e x y) (replace e₁ (x ↑) (y ↑))
  -- Jairo made
  replace (uop x₁ e) x y | nothing = uop x₁ (replace e x y)
  -- replace (argmax sn e) x y | nothing = argmax sn (replace e x y)

  replace-let : (e : E Γ is) → E Γ is
  replace-let (let′ e e₁) = let e' = (replace-let e) in
    let′ e' (replace (replace-let e₁) (e' ↑) (var v₀)) -- is this correct?
  replace-let (var x) = var x
  replace-let 𝟘 = 𝟘
  replace-let 𝟙 = 𝟙
  replace-let (imaps e) = imaps (replace-let e)
  replace-let (sels e e₁) = sels (replace-let e) (replace-let e₁)
  replace-let (imap′ refl e) = imap (replace-let e)
  replace-let (sel′ refl e e₁) = sel (replace-let e) (replace-let e₁)
  replace-let (imapb x e) = Lang.imapb x (replace-let e)
  replace-let (selb x e e₁) = Lang.selb x (replace-let e) (replace-let e₁)
  replace-let (sum e) = Lang.sum (replace-let e)
  replace-let (zero-but e e₁ e₂) =
    zero-but (replace-let e) (replace-let e₁) (replace-let e₂)
  -- replace-let (E.slide e x e₁ x₁) =
  --   E.slide (replace-let e) x (replace-let e₁) x₁
  -- replace-let (E.backslide e e₁ x x₁) =
  --   E.backslide (replace-let e) (replace-let e₁) x x₁
  replace-let (bop x e e₁) = bop x (replace-let e) (replace-let e₁)
  replace-let (scaledown x e) = scaledown x (replace-let e)
  replace-let (uop x e) = uop x (replace-let e)
  -- replace-let (argmax sn e) = argmax sn (replace-let e)

module Test where
  open import Data.List

  open import Lang
  open Syntax

  ex₁ : E _ _
  ex₁ = Lcon (ar [] ∷ []) (ar []) ε
        λ a → Let x := (Let y := a ⊞ a In (y) ⊞ (y)) In x
  -- let′ (let′ (var v₀ ⊞ var v₀) (var v₀ ⊞ var v₀)) (var v₀)

  ex-repl = replace ex₁ (var v₀ ⊞ var v₀) 𝟙
  -- let′ (let′ 𝟙 (var v₀ ⊞ var v₀)) (var v₀)
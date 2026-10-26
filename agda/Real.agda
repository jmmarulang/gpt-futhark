open import Data.Nat using (ℕ)
open import Relation.Binary.PropositionalEquality
open import Data.Empty
open import Relation.Nullary

record Real : Set₁ where
  field
    R : Set
    fromℕ : ℕ → R
    ∞ᵣ : R
    _+_ _*_ _∨_ _÷_ : R → R → R
    -_ e^_ √_ I+ log : R → R

  infixl 10 _+_
  infixl 15 _*_
  infixl 15 _÷_
  infixl 15 _∨_

  0ᵣ : R
  0ᵣ = fromℕ 0

  -∞ᵣ : R
  -∞ᵣ = - ∞ᵣ

  logisticʳ : R → R
  logisticʳ x = fromℕ 1 ÷ (fromℕ 1 + e^ (- x))

  1/_ : R → R
  1/_ = fromℕ 1 ÷_

  -- syntax I-< a b = I[ a < b ]

record RealProp (r : Real) : Set where
  open Real r
  field
    +-neutˡ : ∀ {x} → fromℕ 0 + x ≡ x
    +-neutʳ : ∀ {x} → x + fromℕ 0 ≡ x
    *-neutˡ : ∀ {x} → fromℕ 1 * x ≡ x
    *-neutʳ : ∀ {x} → x * fromℕ 1 ≡ x
    *-nulˡ : ∀ {x} → fromℕ 0 * x ≡ fromℕ 0
    *-nulʳ : ∀ {x} → x * fromℕ 0 ≡ fromℕ 0
    minus-*-pushʳ : ∀ {x y} → (x * (- y)) ≡ - (x * y)
    minus-*-pushˡ : ∀ {x y} → ((- x) * y) ≡ - (x * y)
    minus-invʳ : ∀ {x} → (- (- x)) ≡ x
    minus-idʳ : - fromℕ 0 ≡ fromℕ 0
    ÷-nul : ∀ {x} → (x ≡ fromℕ 0 → ⊥) → fromℕ 0 ÷ x ≡ fromℕ 0
    *-÷-cut : ∀ {x y} → (x * (fromℕ 1 ÷ (x * y))) ≡ fromℕ 1 ÷ y -- wrong for x = 0
    fromℕ-inj : ∀ {x y} → (fromℕ x ≡ fromℕ y) → (x ≡ y)
    +-medial : ∀ {x y z w } → x + y + (z + w) ≡ x + z + (y + w)
    dist : ∀ {x y z} → x * (y + z) ≡ (x * y) + (x * z)
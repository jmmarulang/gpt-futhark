{-# OPTIONS  --backtracking-instance-search #-} -- only needed for tests
--{-# OPTIONS --warn=noUserWarning #-}

{-# OPTIONS --no-positivity-check #-}
module _ where

module _ where
  open import Data.Nat.Show using () renaming (show to show-nat)
  open import Data.List as L using (List; []; _∷_)
  open import Data.List.Relation.Unary.All as All using (All; []; _∷_)
  open import Relation.Binary.PropositionalEquality
  open import Data.String
  open import Text.Printf
  open import Data.Unit
  open import Data.Product as Prod hiding (_<*>_)
  open import Data.Nat using (ℕ; zero; suc)
  open import Ar hiding (_++_; Ix)
  open import Lang
  open import Function
  -- open import LangEq
  open import Relation.Nullary
  open import Data.List.Properties

  open import Effect.Monad.State
  open import Effect.Monad using (RawMonad)
  open RawMonadState {{...}} -- public
  open RawMonad {{...}} -- public

  instance
    _ = monad
    _ = applicative
    _ = monadState

  data SFin : ℕ → Set where
    val : String → SFin n

  data Ix : S → Set where
    []  : Ix []
    _∷_ : SFin n → Ix s → Ix (n ∷ s)

  getVal : SFin n → String
  getVal (val x) = x

  Futᵇ : BT → Set
  Futᵇ ℝ     = (String → String) × String
  Futᵇ (ℙ s) = Ix s

  data Fut : IS → Set where
    full  : (Ix s → State ℕ (Futᵇ B)) → Fut (ar′ s B)
    part′ : (s Ar.⊗ p) ≡ r → (Ix s → State ℕ (Fut $ ar′ p B)) → Fut (ar′ r B)

  part : (Ix s → State ℕ (Fut $ ar′ p B)) → Fut (ar′ (s Ar.⊗ p) B)
  part f = part′ refl f

  index : Ix s → Fut (ix s)
  index i = full λ _ → return i

  Futᶜ : Ctx → Set
  Futᶜ ε = ⊤
  Futᶜ (Γ ▹ is) = Futᶜ Γ × Fut is

  lookup : is ∈ Γ → Futᶜ Γ → Fut is
  lookup v₀ (ρ , e) = e
  lookup (there x) (ρ , e) = lookup x ρ

  {-# TERMINATING #-} -- What is wrong with you, Agda?
  sem-imap : Fut (ar′ s B) → State ℕ (Futᵇ B)
  sem-imap {[]} (full f) = do
    {!   !}
  sem-imap {s ∷ ss} (full x) = {!   !}
  sem-imap {s} (part′ x x₁) = {!   !}

  to-fut : E Γ is → Futᶜ Γ → State ℕ (Fut is)
  to-fut 𝟘 ρ = pure $ full λ _ → return (id , "zero")
  to-fut 𝟙 ρ = pure $ full λ _ → return (id , "one")
  to-fut (uop x e) ρ = {!   !}
  to-fut (bop x e e₁) ρ = {!   !}
  to-fut (zero-but e e₁ e₂) ρ = {!   !}
  to-fut (let′ e e₁) ρ = {!   !}
  to-fut (var x) ρ = return $ lookup x ρ
  to-fut (imaps e) ρ = do
    return $ full λ i → do
      b ← to-fut e (ρ , index i)
      r ← sem-imap b
      return $ {!   !}
  to-fut (mop x e) ρ = {!   !}
  to-fut (sop x e e₁) ρ = {!   !}
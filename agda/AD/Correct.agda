-- grad computes the transposed Jacobian applied to the seed.
open import Ar using (Ar; p)
open import Lang
open import Real

module AD.Correct (r : Real) (rp : RealProp r) where

open Real.Real r
open import Eval r
open import AD.VJP r rp
open import AD.Grad
open import AD.GradCorrect r rp
open import AD.Jacobian r rp

grad-correct : (e : E Γ (ar p)) (s : E Γ (ar p)) (δ : EE Γ Γ) (ν : ⟦ Γ ⟧ᶜ)
             → ⟦ grad′ e s δ ⟧ᴸ ν ≈ᵀ ⟦ δ ⟧ᴸ ν +ᵀ Jᵀ (J e ν) (eval s ν)
grad-correct e s δ ν = grad′-sound e s δ ν ∙ᵀ +ᵀ-cong reflᵀ (V-J e ν (eval s ν))

-- Verified reverse-mode AD.
--
-- This module is the interface to the AD in AD/:
--
--   Grad.agda         grad, a sharing-preserving vjp on E (no proofs)
--   VJP.agda          V, the vjp of E in the semantics, and tangents Tan
--   GradCorrect.agda  ⟦ grad ⟧ agrees with V
--   Jacobian.agda     J, the Jacobian of E in the semantics, and V = Jᵀ
--   Correct.agda      grad computes the transposed Jacobian
--   Dual.agda         dual numbers: J is the derivative, and the
--                     dot-product test for grad
--
-- Sums of reals over shapes are in RSum.agda, the delta rules for
-- one-hot arrays in Eval.ZeroBut.
--
-- Main theorems, for e s : E Γ (ar p), ν : ⟦ Γ ⟧ᶜ:
--
--   grad-correct : ⟦ grad′ e s δ ⟧ᴸ ν ≈ᵀ ⟦ δ ⟧ᴸ ν +ᵀ Jᵀ (J e ν) (eval s ν)
--
--   grad-dual    : ⟨ ⟦ grad′ e s zero-ee ⟧ᴸ (val-env ρ̂) , tan-env ρ̂ ⟩
--                ≡ rsum (λ i → eval s (val-env ρ̂) i * proj₂ (ED.eval e ρ̂ i))
--
-- where ED.eval is the semantics of E over dual numbers and ρ̂ is a dual
-- environment (a point val-env ρ̂ and a direction tan-env ρ̂).  The
-- statement of grad-dual mentions neither J nor V: pairing the gradient
-- with any direction gives the seed paired with the forward derivative
-- in that direction.  All modules pass --safe.
--
--
-- Trusted base
-- ============
--
-- * The derivatives of the scalar primitives in AD.Dual.dual: e^, √,
--   log, I+ (zero) and the subgradient convention for ∨ (which gives
--   relu the derivative I+, as grad assumes).  Everything else,
--   including softmax, is derived from them.
-- * The laws of R in RealProp.  The proofs use only the laws of a
--   commutative ring and ÷-* (division is multiplication by 1/_);
--   dual numbers are a commutative ring but not a field.
--
--
-- Design decisions
-- ================
--
-- 1. EE as a monad.  EE Γ Δ is a telescope of array lets followed by
--    the adjoints (Env Γ) of the variables of Γ.  As a functor of the
--    environment it is the free monad of the let operation on
--    context-indexed families; we use its strong bind ee-bind (the
--    continuation gets the weakening into the extended context) and
--    ee-map.  All operations on EE are instances, except ee-map-sum,
--    which turns index-dependent lets into imaps and carries its
--    substitution as an accumulator.
--
-- 2. Two contexts in grad.  grad e w s δ takes w : Γ ⊆ Δ from the
--    context of e to the context of the seed and the adjoints, which
--    contains the lets introduced so far.  The primal expression is
--    never weakened, so recursion (and induction in proofs) is
--    structural, and no zero adjoints for let-bound variables are
--    needed.  grad′ e = grad e ⊆-eq is the top-level interface.
--
-- 3. The proof goes through a semantic vjp.  V mirrors grad case by
--    case, without syntax or sharing.  GradCorrect is about
--    bookkeeping only (lets, environments, weakening, substitution);
--    Jacobian is about calculus only (sums, deltas, the algebra of the
--    primitives).  A change in the sharing strategy of grad touches
--    only GradCorrect.
--
-- 4. Tangents are functions from array variables, Tan Γ =
--    ∀ {s} → ar s ∈ Γ → Ar s R, so all operations are pointwise.  In
--    the equality _≈ᵀ_ the shape is explicit: with an implicit binder
--    Agda cannot solve the metas in congruences.  For the same reason
--    sums use rsum-cong′ with explicit summands (rsum is not injective).
--
-- 5. J e ρ i is row i of the Jacobian: the derivatives of element i
--    with respect to all array variables.  It is defined by the
--    forward rules (the let case is the chain rule) and checked
--    against dual numbers in Dual.fwd-tan.
--
-- 6. Eval depends only on Real (the lemmas that need RealProp are in
--    Eval.ZeroBut), so that the semantics can be instantiated with
--    dual numbers, for which RealProp does not hold.
--
--
-- TODO
-- ====
--
-- 1. Clean up RealProp into the laws of a commutative ring with 1/_,
--    together with the properties used by Opt.
-- 2. Sparse adjoints: represent one-hot seeds symbolically (an `at`
--    marker consumed by the delta rule when leaving the binder of the
--    index), so that grad never produces zero-but.
-- 3. Share seeds that are not variables (⊞, ⊠, sum, imap copy them).
module AD where

open import Real

open import AD.Grad public using (Env; EE; grad; grad′; zero-ee)

module Correctness (r : Real) (rp : RealProp r) where
  open import AD.GradCorrect r rp public using (⟦_⟧ᴸ; grad-sound; grad′-sound)
  open import AD.Jacobian r rp public using (J; Jᵀ; V-J)
  open import AD.Correct r rp public using (grad-correct)
  open import AD.Dual r rp public using (dual; val-env; tan-env; ⟨_,_⟩; fwd-val; fwd-tan; grad-dual)

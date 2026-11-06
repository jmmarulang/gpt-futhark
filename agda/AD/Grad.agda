-- Reverse-mode AD (vjp) that preserves sharing.
--
-- EE is a telescope of lets followed by the adjoints, and grad takes a weakening
-- from the context of the primal expression to the context of the seed
-- and the adjoints; see the design notes in AD.agda.
module AD.Grad where

open import Data.Product using (_,_)
open import Data.Maybe using (just; nothing)
open import Function
open import Relation.Binary.PropositionalEquality using (refl)
open import Ar hiding (sum; slide; backslide; imapb; selb; map)
open import Lang
open WkSub

-- Env Γ Δ holds an adjoint (in Δ) for every array variable of Γ.
data Env : Ctx → Ctx → Set where
  ε    : Env ε Δ
  skip : Env Γ Δ → Env (Γ ▹ ix s) Δ
  _▹_  : Env Γ Δ → E Δ (ar s) → Env (Γ ▹ ar s) Δ

-- A telescope of array lets followed by an environment in the
-- extended context.
data EE (Γ : Ctx) : Ctx → Set where
  env  : Env Γ Δ → EE Γ Δ
  let′ : E Δ (ar s) → EE Γ (Δ ▹ ar s) → EE Γ Δ

ee-map : {Γ′ : Ctx} → (∀ {Δ} → Env Γ Δ → Env Γ′ Δ) → EE Γ Δ → EE Γ′ Δ
ee-map f (env ρ) = env (f ρ)
ee-map f (let′ x m) = let′ x (ee-map f m)

-- Bind: the continuation is used in the extended context.
ee-bind : {Γ′ : Ctx} → EE Γ Δ → (∀ {Ψ} → Δ ⊆ Ψ → Env Γ Ψ → EE Γ′ Ψ) → EE Γ′ Δ
ee-bind (env ρ) k = k ⊆-eq ρ
ee-bind (let′ x m) k = let′ x (ee-bind m (λ w → k (w ∙ʷ skip ⊆-eq)))

env-wk : Δ ⊆ Ψ → Env Γ Δ → Env Γ Ψ
env-wk w ε = ε
env-wk w (skip ρ) = skip (env-wk w ρ)
env-wk w (ρ ▹ x) = env-wk w ρ ▹ wk w x

env-↑ : Env Γ Δ → Env Γ (Δ ▹ is)
env-↑ = env-wk (skip ⊆-eq)

env-sub : Env Γ Δ → Sub Ψ Δ → Env Γ Ψ
env-sub ε σ = ε
env-sub (skip ρ) σ = skip (env-sub ρ σ)
env-sub (ρ ▹ x) σ = env-sub ρ σ ▹ sub x σ

zero-env : Env Γ Δ
zero-env {ε} = ε
zero-env {Γ ▹ ix _} = skip zero-env
zero-env {Γ ▹ ar _} = zero-env ▹ 𝟘

env-tail : Env (Γ ▹ is) Δ → Env Γ Δ
env-tail (skip ρ) = ρ
env-tail (ρ ▹ _) = ρ

env-update+ : Env Γ Δ → ar s ∈ Γ → E Δ (ar s) → Env Γ Δ
env-update+ (ρ ▹ x) v₀ t = ρ ▹ (x ⊞ t)
env-update+ (skip ρ) (there v) t = skip (env-update+ ρ v t)
env-update+ (ρ ▹ x) (there v) t = env-update+ ρ v t ▹ x

env-plus : (ρ ν : Env Γ Δ) → Env Γ Δ
env-plus ε ν = ν
env-plus (skip ρ) (skip ν) = skip (env-plus ρ ν)
env-plus (ρ ▹ x) (ν ▹ y) = env-plus ρ ν ▹ (x ⊞ y)

env-map-sum : Env Γ (Δ ▹ ix s) → Env Γ Δ
env-map-sum ε = ε
env-map-sum (skip ρ) = skip (env-map-sum ρ)
env-map-sum (ρ ▹ x) = env-map-sum ρ ▹ Lang.sum x

-- Operations on EE
ee-wk : Δ ⊆ Ψ → EE Γ Δ → EE Γ Ψ
ee-wk w (env ρ) = env (env-wk w ρ)
ee-wk w (let′ x m) = let′ (wk w x) (ee-wk (keep w) m)

ee-↑ : EE Γ Δ → EE Γ (Δ ▹ is)
ee-↑ = ee-wk (skip ⊆-eq)

zero-ee : EE Γ Δ
zero-ee = env zero-env

ee-tail : EE (Γ ▹ is) Δ → EE Γ Δ
ee-tail = ee-map env-tail

ee-push-zero : EE Γ Δ → EE (Γ ▹ ar s) Δ
ee-push-zero = ee-map (_▹ 𝟘)

ee-update+ : ar s ∈ Γ → E Δ (ar s) → EE Γ Δ → EE Γ Δ
ee-update+ v t δ = ee-bind δ λ w ρ → env (env-update+ ρ v (wk w t))

ee-plus : (δ ν : EE Γ Δ) → EE Γ Δ
ee-plus δ ν = ee-bind δ λ w ρ → ee-bind (ee-wk w ν) λ w′ ν′ → env (env-plus (env-wk w′ ρ) ν′)

ee-sub : EE Γ Δ → Sub Ψ Δ → EE Γ Ψ
ee-sub (env ρ) σ = env (env-sub ρ σ)
ee-sub (let′ x m) σ = let′ (sub x σ) (ee-sub m (skeep σ))

-- Sum all the adjoints over the last (index) variable of the context.
-- Lets that do not depend on the index are lifted out, the others
-- become imaps.  The substitution σ accumulates the renaming of the
-- lets that are already processed.
ee-map-sum-sub : EE Γ Ψ → Sub (Δ ▹ ix s) Ψ → EE Γ Δ
ee-map-sum-sub (env ρ) σ = env (env-map-sum (env-sub ρ σ))
ee-map-sum-sub (let′ x ρ) σ with stren-∃ (sub x σ) v₀
... | just (x′ , _) =
      let′ x′ (ee-map-sum-sub ρ (wks σ (keep (skip ⊆-eq)) ▹ var v₁))
... | nothing =
      let′ (imap (sub x σ)) (ee-map-sum-sub ρ (wks σ (keep (skip ⊆-eq)) ▹ sel (var v₁) (var v₀)))

ee-map-sum : EE Γ (Δ ▹ ix s) → EE Γ Δ
ee-map-sum ρ = ee-map-sum-sub ρ sub-id

-- The body of an imap that is s at index i and zero elsewhere.
one-hot : E Δ (ix s) → E Δ (ar p) → E (Δ ▹ ix s) (ar p)
one-hot i s = zero-but (var v₀) (i ↑) (s ↑)

-- grad e w s δ adds the vjp of e at seed s to δ.
grad : (e : E Γ is) → Γ ⊆ Δ → (s : E Δ is) → EE Γ Δ → EE Γ Δ

grad-sum : (e : E (Γ ▹ ix s) (ar p)) → Γ ⊆ Δ → (seed : E (Δ ▹ ix s) (ar p)) → EE Γ Δ → EE Γ Δ
grad-sum e w s δ = ee-plus δ $ ee-tail $ ee-map-sum (grad e (keep w) s zero-ee)

-- Continuation for let: the last adjoint (of the bound variable) is
-- shared and becomes the seed of the bound expression.
grad-let : (e : E Γ (ar s)) → Γ ⊆ Δ → (Δ ▹ ar s) ⊆ Ψ → Env (Γ ▹ ar s) Ψ → EE Γ Ψ
grad-let e w w′ (ρ ▹ x) = let′ x (grad e w″ (var v₀) (env (env-↑ ρ)))
  where w″ = skip (w′ ∙ʷ (skip ⊆-eq ∙ʷ w))

grad {is = ix _} (var x) w s = id
grad {is = ar _} (var x) w s = ee-update+ x s
grad 𝟘                   w s = id
grad 𝟙                   w s = id

grad (imaps e)           w s = grad-sum e w (sels (s ↑) (var v₀))
grad (imap′ refl e)      w s = grad-sum e w (sel (s ↑) (var v₀))
grad (Lang.imapb m e)    w s = grad-sum e w (Lang.selb m (s ↑) (var v₀))
grad (Lang.sum e)        w s = grad-sum e w (s ↑)

grad (sels e i)          w s = grad e w (imaps (one-hot (wk w i) s))
grad (sel′ refl e i)     w s = grad e w (imap (one-hot (wk w i) s))
grad (Lang.selb m e i)   w s = grad e w (Lang.imapb m (one-hot (wk w i) s))
grad (zero-but i j e)    w s = grad e w (zero-but (wk w i) (wk w j) s)

grad (e ⊞ e₁)            w s = grad e w s ∘ grad e₁ w s
grad (e ⊠ e₁)            w s = grad e w (s ⊠ wk w e₁) ∘ grad e₁ w (wk w e ⊠ s)
grad (scaledown x e)     w s = grad e w (scaledown x s)
grad (⊟ e)               w s = grad e w (⊟ s)

grad (relu e)            w s = grad e w (𝕚+ (wk w e) ⊠ s)
grad (𝕚+ e)              w s = grad e w 𝟘
grad (√ e)               w s = grad e w (s // (𝟚 ⊠ √ (wk w e)))
grad (𝟙/ e)              w s = grad e w (⊟ (𝟙/ (wk w e) ⊠ (s // wk w e)))
grad (ln e)              w s = grad e w (s // wk w e)

grad (let′ e e₁)         w s δ = let′ (wk w e) (ee-bind δ₁ (grad-let e w))
  where δ₁ = grad e₁ (keep w) (s ↑) (ee-push-zero (ee-↑ δ))

-- Share softmax, the seed and their dot product.
grad (ℙ e)               w s δ =
  let′ (ℙ (wk w e))                                            -- v₂
  (let′ (s ↑)                                                  -- v₁
  (let′ (Lang.sum (sels (var v₁ ⊠ var v₂) (var v₀)))           -- v₀
  (grad e (w₃ ∙ʷ w) (var v₂ ⊠ (var v₁ ⊟ imaps (var v₁))) (ee-wk w₃ δ))))
  where w₃ = skip (skip (skip ⊆-eq))

-- The top-level entry point.
grad′ : (e s : E Γ is) → EE Γ Γ → EE Γ Γ
grad′ e = grad e ⊆-eq

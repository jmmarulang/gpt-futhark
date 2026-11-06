-- Soundness of AD.Grad with respect to the semantic vjp V:
--
--   ⟦ grad e w s δ ⟧ ν ≈ ⟦ δ ⟧ ν + V e (wk-env w ν) (eval s ν)
--
-- The proof follows the structure of grad; the reasoning about lets
-- is in the lemmas about ee-bind, ee-map and ee-map-sum-sub.
open import Data.Product using (_,_; proj₁; proj₂)
open import Data.Maybe using (just; nothing)
open import Function
open import Data.List.Relation.Unary.All using ([])
open import Relation.Binary.PropositionalEquality
open import Ar
open import Lang
open import Real

module AD.GradCorrect (r : Real) (rp : RealProp r) where

open Real.Real r
open RealProp rp
open import Eval r
open import AD.VJP r rp
open import AD.Grad
open WkSub hiding (_∙ˢ_)

-- Semantics of adjoint environments
⟦_⟧ᴱ : Env Γ Δ → ⟦ Δ ⟧ᶜ → Tan Γ
⟦ ρ ▹ x ⟧ᴱ ν v₀ = eval x ν
⟦ ρ ▹ x ⟧ᴱ ν (there v) = ⟦ ρ ⟧ᴱ ν v
⟦ skip ρ ⟧ᴱ ν (there v) = ⟦ ρ ⟧ᴱ ν v

⟦_⟧ᴸ : EE Γ Δ → ⟦ Δ ⟧ᶜ → Tan Γ
⟦ env ρ ⟧ᴸ ν = ⟦ ρ ⟧ᴱ ν
⟦ let′ x m ⟧ᴸ ν = ⟦ m ⟧ᴸ (ν , eval x ν)

-- Facts about environments
symᶜ : {ν ν′ : ⟦ Γ ⟧ᶜ} → ν ≈ᶜ ν′ → ν′ ≈ᶜ ν
symᶜ ε = ε
symᶜ (p ▹ q) = symᶜ p ▹ symˢ q

wk-env-cong : (w : Γ ⊆ Δ) {ν ν′ : ⟦ Δ ⟧ᶜ} → ν ≈ᶜ ν′ → wk-env w ν ≈ᶜ wk-env w ν′
wk-env-cong ε p = p
wk-env-cong (skip w) (p ▹ _) = wk-env-cong w p
wk-env-cong (keep w) (p ▹ q) = wk-env-cong w p ▹ q

wk-env-∙ : (w : Δ ⊆ Ψ) (w′ : Γ ⊆ Δ) (ν : ⟦ Ψ ⟧ᶜ)
         → wk-env (w ∙ʷ w′) ν ≈ᶜ wk-env w′ (wk-env w ν)
wk-env-∙ w ε ν = reflᶜ
wk-env-∙ (skip w) (skip w′) (ν , _) = wk-env-∙ w (skip w′) ν
wk-env-∙ (keep w) (skip w′) (ν , a) = wk-env-∙ (skip w) w′ (ν , a)
wk-env-∙ (skip w) (keep w′) (ν , _) = wk-env-∙ w (keep w′) ν
wk-env-∙ (keep w) (keep w′) (ν , a) = wk-env-∙ w w′ ν ▹ reflˢ

-- Facts about the semantics of environments
⟦⟧ᴱ-cong : (ρ : Env Γ Δ) {ν ν′ : ⟦ Δ ⟧ᶜ} → ν ≈ᶜ ν′ → ⟦ ρ ⟧ᴱ ν ≈ᵀ ⟦ ρ ⟧ᴱ ν′
⟦⟧ᴱ-cong (ρ ▹ x) p _ v₀ = eval-cong x p
⟦⟧ᴱ-cong (ρ ▹ x) p _ (there v) = ⟦⟧ᴱ-cong ρ p _ v
⟦⟧ᴱ-cong (skip ρ) p _ (there v) = ⟦⟧ᴱ-cong ρ p _ v

⟦⟧ᴸ-cong : (m : EE Γ Δ) {ν ν′ : ⟦ Δ ⟧ᶜ} → ν ≈ᶜ ν′ → ⟦ m ⟧ᴸ ν ≈ᵀ ⟦ m ⟧ᴸ ν′
⟦⟧ᴸ-cong (env ρ) p = ⟦⟧ᴱ-cong ρ p
⟦⟧ᴸ-cong (let′ x m) p = ⟦⟧ᴸ-cong m (p ▹ eval-cong x p)

env-wk-sem : (w : Δ ⊆ Ψ) (ρ : Env Γ Δ) (ν : ⟦ Ψ ⟧ᶜ) → ⟦ env-wk w ρ ⟧ᴱ ν ≈ᵀ ⟦ ρ ⟧ᴱ (wk-env w ν)
env-wk-sem w (ρ ▹ x) ν _ v₀ = eval-wk w x ν
env-wk-sem w (ρ ▹ x) ν _ (there v) = env-wk-sem w ρ ν _ v
env-wk-sem w (skip ρ) ν _ (there v) = env-wk-sem w ρ ν _ v

ee-wk-sem : (w : Δ ⊆ Ψ) (m : EE Γ Δ) (ν : ⟦ Ψ ⟧ᶜ) → ⟦ ee-wk w m ⟧ᴸ ν ≈ᵀ ⟦ m ⟧ᴸ (wk-env w ν)
ee-wk-sem w (env ρ) ν = env-wk-sem w ρ ν
ee-wk-sem w (let′ x m) ν = ee-wk-sem (keep w) m (ν , eval (wk w x) ν)
                        ∙ᵀ ⟦⟧ᴸ-cong m (reflᶜ ▹ eval-wk w x ν)

-- Weakening by one variable
env-↑-sem : (ρ : Env Γ Δ) (ν : ⟦ Δ ⟧ᶜ) {a : ⟦ is ⟧ˢ} → ⟦ env-↑ ρ ⟧ᴱ (ν , a) ≈ᵀ ⟦ ρ ⟧ᴱ ν
env-↑-sem ρ ν = env-wk-sem (skip ⊆-eq) ρ _ ∙ᵀ ⟦⟧ᴱ-cong ρ wk-env-id

ee-↑-sem : (m : EE Γ Δ) (ν : ⟦ Δ ⟧ᶜ) {a : ⟦ is ⟧ˢ} → ⟦ ee-↑ m ⟧ᴸ (ν , a) ≈ᵀ ⟦ m ⟧ᴸ ν
ee-↑-sem m ν = ee-wk-sem (skip ⊆-eq) m _ ∙ᵀ ⟦⟧ᴸ-cong m wk-env-id

env-sub-sem : (ρ : Env Γ Δ) (σ : Sub Ψ Δ) (ν : ⟦ Ψ ⟧ᶜ) → ⟦ env-sub ρ σ ⟧ᴱ ν ≈ᵀ ⟦ ρ ⟧ᴱ (sub-env σ ν)
env-sub-sem (ρ ▹ x) σ ν _ v₀ = eval-sub x ν σ
env-sub-sem (ρ ▹ x) σ ν _ (there v) = env-sub-sem ρ σ ν _ v
env-sub-sem (skip ρ) σ ν _ (there v) = env-sub-sem ρ σ ν _ v

zero-env-sem : (ν : ⟦ Δ ⟧ᶜ) → ⟦ zero-env {Γ} ⟧ᴱ ν ≈ᵀ 0ᵀ
zero-env-sem {Γ = Γ ▹ ar _} ν _ v₀ = reflᵃ
zero-env-sem {Γ = Γ ▹ ar _} ν _ (there v) = zero-env-sem ν _ v
zero-env-sem {Γ = Γ ▹ ix _} ν _ (there v) = zero-env-sem ν _ v

env-tail-sem : (ρ : Env (Γ ▹ is) Δ) (ν : ⟦ Δ ⟧ᶜ) → ⟦ env-tail ρ ⟧ᴱ ν ≈ᵀ tailᵀ (⟦ ρ ⟧ᴱ ν)
env-tail-sem (skip ρ) ν _ v = reflᵃ
env-tail-sem (ρ ▹ x) ν _ v = reflᵃ

env-plus-sem : (ρ μ : Env Γ Δ) (ν : ⟦ Δ ⟧ᶜ) → ⟦ env-plus ρ μ ⟧ᴱ ν ≈ᵀ ⟦ ρ ⟧ᴱ ν +ᵀ ⟦ μ ⟧ᴱ ν
env-plus-sem (ρ ▹ x) (μ ▹ y) ν _ v₀ = reflᵃ
env-plus-sem (ρ ▹ x) (μ ▹ y) ν _ (there v) = env-plus-sem ρ μ ν _ v
env-plus-sem (skip ρ) (skip μ) ν _ (there v) = env-plus-sem ρ μ ν _ v

env-map-sum-sem : (ρ : Env Γ (Δ ▹ ix s)) (ν : ⟦ Δ ⟧ᶜ)
                → ⟦ env-map-sum ρ ⟧ᴱ ν ≈ᵀ Σᵀ (λ k → ⟦ ρ ⟧ᴱ (ν , k))
env-map-sum-sem (ρ ▹ x) ν _ v₀ = reflᵃ
env-map-sum-sem (ρ ▹ x) ν _ (there v) = env-map-sum-sem ρ ν _ v
env-map-sum-sem (skip ρ) ν _ (there v) = env-map-sum-sem ρ ν _ v

env-update-sem : (ρ : Env Γ Δ) (x : ar s ∈ Γ) (t : E Δ (ar s)) (ν : ⟦ Δ ⟧ᶜ)
               → ⟦ env-update+ ρ x t ⟧ᴱ ν ≈ᵀ ⟦ ρ ⟧ᴱ ν +ᵀ 𝕖 x (eval t ν)
env-update-sem (ρ ▹ a) v₀ t ν _ v₀ = reflᵃ
env-update-sem (ρ ▹ a) v₀ t ν _ (there y) i = sym +-neutʳ
env-update-sem (ρ ▹ a) (there x) t ν _ v₀ i = sym +-neutʳ
env-update-sem (ρ ▹ a) (there x) t ν _ (there y) i =
  env-update-sem ρ x t ν _ y i ∙ cong₂ _+_ refl (sym (𝕖-there x (eval t ν) y i))
env-update-sem (skip ρ) (there x) t ν _ (there y) i =
  env-update-sem ρ x t ν _ y i ∙ cong₂ _+_ refl (sym (𝕖-there x (eval t ν) y i))

-- Semantics of the monad operations
ee-map-sem : {Γ′ : Ctx} (f : ∀ {Δ} → Env Γ Δ → Env Γ′ Δ) (g : Tan Γ → Tan Γ′)
             → (∀ {Δ} (ρ : Env Γ Δ) ν → ⟦ f ρ ⟧ᴱ ν ≈ᵀ g (⟦ ρ ⟧ᴱ ν))
             → (m : EE Γ Δ) (ν : ⟦ Δ ⟧ᶜ) → ⟦ ee-map f m ⟧ᴸ ν ≈ᵀ g (⟦ m ⟧ᴸ ν)
ee-map-sem f g H (env ρ) ν = H ρ ν
ee-map-sem f g H (let′ x m) ν = ee-map-sem f g H m (ν , eval x ν)

ee-bind-sem : {Γ′ : Ctx} (m : EE Γ Δ) (k : ∀ {Ψ} → Δ ⊆ Ψ → Env Γ Ψ → EE Γ′ Ψ)
           (g : Tan Γ → Tan Γ′) (ν : ⟦ Δ ⟧ᶜ)
         → (∀ {Ψ} (w : Δ ⊆ Ψ) (ρ : Env Γ Ψ) (ν′ : ⟦ Ψ ⟧ᶜ)
              → wk-env w ν′ ≈ᶜ ν → ⟦ k w ρ ⟧ᴸ ν′ ≈ᵀ g (⟦ ρ ⟧ᴱ ν′))
         → ⟦ ee-bind m k ⟧ᴸ ν ≈ᵀ g (⟦ m ⟧ᴸ ν)
ee-bind-sem (env ρ) k g ν H = H ⊆-eq ρ ν wk-env-id
ee-bind-sem (let′ x m) k g ν H =
  ee-bind-sem m (λ w → k (w ∙ʷ skip ⊆-eq)) g (ν , eval x ν)
    λ w ρ ν′ p → H (w ∙ʷ skip ⊆-eq) ρ ν′
                   (wk-env-∙ w (skip ⊆-eq) ν′ ∙ᶜ wk-env-cong (skip ⊆-eq) p ∙ᶜ wk-env-id)

-- Semantics of the operations on EE
ee-tail-sem : (m : EE (Γ ▹ is) Δ) (ν : ⟦ Δ ⟧ᶜ) → ⟦ ee-tail m ⟧ᴸ ν ≈ᵀ tailᵀ (⟦ m ⟧ᴸ ν)
ee-tail-sem = ee-map-sem env-tail tailᵀ env-tail-sem

ee-push-zero-sem : (m : EE Γ Δ) (ν : ⟦ Δ ⟧ᶜ)
                 → ⟦ ee-push-zero {s = s} m ⟧ᴸ ν ≈ᵀ ⟦ m ⟧ᴸ ν ▹ᵀ K (fromℕ 0)
ee-push-zero-sem = ee-map-sem (_▹ 𝟘) (_▹ᵀ K (fromℕ 0)) go
  where go : ∀ {Δ} (ρ : Env _ Δ) ν → ⟦ ρ ▹ 𝟘 ⟧ᴱ ν ≈ᵀ ⟦ ρ ⟧ᴱ ν ▹ᵀ K (fromℕ 0)
        go ρ ν _ v₀ = reflᵃ
        go ρ ν _ (there v) = reflᵃ

ee-update-sem : (x : ar s ∈ Γ) (t : E Δ (ar s)) (δ : EE Γ Δ) (ν : ⟦ Δ ⟧ᶜ)
              → ⟦ ee-update+ x t δ ⟧ᴸ ν ≈ᵀ ⟦ δ ⟧ᴸ ν +ᵀ 𝕖 x (eval t ν)
ee-update-sem x t δ ν = ee-bind-sem δ κ (_+ᵀ 𝕖 x (eval t ν)) ν
  λ w ρ ν′ p → env-update-sem ρ x (wk w t) ν′
               ∙ᵀ +ᵀ-congʳ (𝕖-cong x (eval-wk w t ν′ ∙ᵃ eval-cong t p))
  where κ = λ {Ψ} (w : _ ⊆ Ψ) ρ → env (env-update+ ρ x (wk w t))

ee-plus-sem : (δ μ : EE Γ Δ) (ν : ⟦ Δ ⟧ᶜ) → ⟦ ee-plus δ μ ⟧ᴸ ν ≈ᵀ ⟦ δ ⟧ᴸ ν +ᵀ ⟦ μ ⟧ᴸ ν
ee-plus-sem δ μ ν = ee-bind-sem δ κ (_+ᵀ ⟦ μ ⟧ᴸ ν) ν
  λ w ρ ν′ p →
    ee-bind-sem (ee-wk w μ) (κ′ ρ) (⟦ ρ ⟧ᴱ ν′ +ᵀ_) ν′
      (λ w′ μ′ ν″ p′ → env-plus-sem (env-wk w′ ρ) μ′ ν″
                       ∙ᵀ +ᵀ-congˡ (env-wk-sem w′ ρ ν″ ∙ᵀ ⟦⟧ᴱ-cong ρ p′))
    ∙ᵀ +ᵀ-congʳ (ee-wk-sem w μ ν′ ∙ᵀ ⟦⟧ᴸ-cong μ p)
  where
    κ′ : ∀ {Ψ} → Env _ Ψ → ∀ {Ψ′} → Ψ ⊆ Ψ′ → Env _ Ψ′ → EE _ Ψ′
    κ′ ρ w′ ν′ = env (env-plus (env-wk w′ ρ) ν′)
    κ : ∀ {Ψ} → _ ⊆ Ψ → Env _ Ψ → EE _ Ψ
    κ w ρ = ee-bind (ee-wk w μ) (κ′ ρ)

≡→≈ᵃ : {a b : Ar s R} → a ≡ b → a ≈ᵃ b
≡→≈ᵃ refl = reflᵃ

ee-map-sum-sub-sem : (m : EE Γ Ψ) (σ : Sub (Δ ▹ ix s) Ψ) (ν : ⟦ Δ ⟧ᶜ)
                   → ⟦ ee-map-sum-sub m σ ⟧ᴸ ν ≈ᵀ Σᵀ (λ k → ⟦ m ⟧ᴸ (sub-env σ (ν , k)))
ee-map-sum-sub-sem (env ρ) σ ν =
  env-map-sum-sem (env-sub ρ σ) ν ∙ᵀ Σᵀ-cong λ k → env-sub-sem ρ σ (ν , k)
ee-map-sum-sub-sem (let′ x m) σ ν with stren-∃ (sub x σ) v₀
... | just (x′ , eq) =
  ee-map-sum-sub-sem m (σ′ ▹ var v₁) (ν , eval x′ ν) ∙ᵀ Σᵀ-cong λ k → ⟦⟧ᴸ-cong m (env≈ k)
  where
    σ′ = wks σ (keep (skip ⊆-eq))
    env≈ : ∀ k → sub-env (σ′ ▹ var v₁) ((ν , eval x′ ν) , k)
               ≈ᶜ (sub-env σ (ν , k) , eval x (sub-env σ (ν , k)))
    env≈ k = (sub-env-wks σ (keep (skip ⊆-eq)) _ ∙ᶜ sub-env-cong σ (wk-env-id ▹ refl))
           ▹ (symˢ (eval-cong x′ wk-env-id)
              ∙ᵃ (symˢ (eval-wk (skip ⊆-eq) x′ (ν , k))
              ∙ᵃ (≡→≈ᵃ (cong (λ e → eval e (ν , k)) (sym eq))
              ∙ᵃ eval-sub x (ν , k) σ)))
... | nothing =
  ee-map-sum-sub-sem m (σ′ ▹ sel (var v₁) (var v₀)) (ν , eval (imap (sub x σ)) ν)
  ∙ᵀ Σᵀ-cong λ k → ⟦⟧ᴸ-cong m (env≈ k)
  where
    σ′ = wks σ (keep (skip ⊆-eq))
    env≈ : ∀ k → sub-env (σ′ ▹ sel (var v₁) (var v₀)) ((ν , eval (imap (sub x σ)) ν) , k)
               ≈ᶜ (sub-env σ (ν , k) , eval x (sub-env σ (ν , k)))
    env≈ k = (sub-env-wks σ (keep (skip ⊆-eq)) _ ∙ᶜ sub-env-cong σ (wk-env-id ▹ refl))
           ▹ λ j → cong₂ (λ a b → eval (sub x σ) (ν , a) b)
                         (splitP-proj₁ {i = k} {j = j}) (splitP-proj₂ {i = k} {j = j})
                   ∙ eval-sub x (ν , k) σ j

ee-map-sum-sem : (m : EE Γ (Δ ▹ ix s)) (ν : ⟦ Δ ⟧ᶜ)
               → ⟦ ee-map-sum m ⟧ᴸ ν ≈ᵀ Σᵀ (λ k → ⟦ m ⟧ᴸ (ν , k))
ee-map-sum-sem m ν = ee-map-sum-sub-sem m sub-id ν ∙ᵀ Σᵀ-cong λ k → ⟦⟧ᴸ-cong m (sub-env-id {ρ = ν , k})

-- Evaluation of weakened expressions and seeds
↑-eval : (s : E Δ (ar p)) {ν : ⟦ Δ ⟧ᶜ} {a : ⟦ is ⟧ˢ} → eval (s ↑) (ν , a) ≈ᵃ eval s ν
↑-eval s = eval-wk (skip ⊆-eq) s _ ∙ᵃ eval-cong s wk-env-id

-- The seed of a loop body or a let body.
↑-seed : (s : E Δ (ar p)) {ν : ⟦ Δ ⟧ᶜ} {s′ : Ar p R} → eval s ν ≈ᵃ s′
       → {a : ⟦ is ⟧ˢ} → eval (s ↑) (ν , a) ≈ᵃ s′
↑-seed s sp = ↑-eval s ∙ᵃ sp

module _ {w : Γ ⊆ Δ} {ν : ⟦ Δ ⟧ᶜ} {ρ : ⟦ Γ ⟧ᶜ} (p : wk-env w ν ≈ᶜ ρ) where
  wk-eval : (e : E Γ is) → eval (wk w e) ν ≈ˢ eval e ρ
  wk-eval e = eval-wk w e ν ∙ˢ eval-cong e p

  wk↑-ix : (i : E Γ (ix s)) {a : ⟦ is ⟧ˢ} → eval (wk w i ↑) (ν , a) ≡ eval i ρ
  wk↑-ix i = eval-wk (skip ⊆-eq) (wk w i) _ ∙ eval-cong (wk w i) wk-env-id ∙ wk-eval i

  one-hot-sound : (i : E Γ (ix q)) (s : E Δ (ar u)) {s′ : Ar u R} → eval s ν ≈ᵃ s′
                → (k : P q) → eval (one-hot (wk w i) s) (ν , k) ≈ᵃ one-hotᵃ (eval i ρ) s′ k
  one-hot-sound i s sp k = zb-cong {i = k} refl (wk↑-ix i) (↑-seed s sp)

-- The main theorem
grad-sound : (e : E Γ (ar p)) (w : Γ ⊆ Δ) (s : E Δ (ar p)) (δ : EE Γ Δ) (ν : ⟦ Δ ⟧ᶜ)
             {ρ : ⟦ Γ ⟧ᶜ} → wk-env w ν ≈ᶜ ρ
           → {s′ : Ar p R} → eval s ν ≈ᵃ s′
           → ⟦ grad e w s δ ⟧ᴸ ν ≈ᵀ ⟦ δ ⟧ᴸ ν +ᵀ V e ρ s′

grad-sum-sound : (e : E (Γ ▹ ix q) (ar p)) (w : Γ ⊆ Δ) (s : E (Δ ▹ ix q) (ar p))
                 (δ : EE Γ Δ) (ν : ⟦ Δ ⟧ᶜ)
                 {ρ : ⟦ Γ ⟧ᶜ} → wk-env w ν ≈ᶜ ρ
               → {s′ : P q → Ar p R} → (∀ k → eval s (ν , k) ≈ᵃ s′ k)
               → ⟦ grad-sum e w s δ ⟧ᴸ ν ≈ᵀ ⟦ δ ⟧ᴸ ν +ᵀ V-sum e ρ s′
grad-sum-sound e w s δ ν {ρ} p {s′} sp =
  ee-plus-sem δ (ee-tail (ee-map-sum M)) ν
  ∙ᵀ +ᵀ-congʳ (ee-tail-sem (ee-map-sum M) ν
               ∙ᵀ tailᵀ-cong (ee-map-sum-sem M ν ∙ᵀ Σᵀ-cong body))
  where
    M = grad e (keep w) s zero-ee
    body = λ k → grad-sound e (keep w) s zero-ee (ν , k) (p ▹ refl) (sp k)
                 ∙ᵀ +ᵀ-congˡ (zero-env-sem (ν , k)) ∙ᵀ +ᵀ-neutˡ

grad-sound (var x)          w s δ ν p sp = ee-update-sem x s δ ν ∙ᵀ +ᵀ-congʳ (𝕖-cong x sp)
grad-sound 𝟘                w s δ ν p sp = symᵀ +ᵀ-neutʳ
grad-sound 𝟙                w s δ ν p sp = symᵀ +ᵀ-neutʳ

grad-sound (imaps e)        w s δ ν p {s′} sp =
  grad-sum-sound e w (sels (s ↑) (var v₀)) δ ν p {λ k → K (s′ k)} λ k _ → ↑-seed s sp k
grad-sound (imap′ refl e)   w s δ ν p {s′} sp =
  grad-sum-sound e w (sel (s ↑) (var v₀)) δ ν p {nest s′} λ k j → ↑-seed s sp (k ++ j)
grad-sound (imapb m e)      w s δ ν p {s′} sp =
  grad-sum-sound e w (Lang.selb m (s ↑) (var v₀)) δ ν p {Ar.selb s′ m}
    λ k j → ↑-seed s sp (ix-combine k j m)
grad-sound (sum e)          w s δ ν p {s′} sp =
  grad-sum-sound e w (s ↑) δ ν p {λ _ → s′} λ k → ↑-seed s sp

grad-sound (sels e i)       w s δ ν {ρ} p {s′} sp =
  grad-sound e w (imaps (one-hot (wk w i) s)) δ ν p {λ k → one-hotᵃ (eval i ρ) s′ k []}
    λ k → one-hot-sound p i s sp k []
grad-sound (sel′ refl e i)  w s δ ν {ρ} p {s′} sp =
  grad-sound e w (imap (one-hot (wk w i) s)) δ ν p {unnest (one-hotᵃ (eval i ρ) s′)}
    λ k → one-hot-sound p i s sp (proj₁ (splitP k)) (proj₂ (splitP k))
grad-sound (selb m e i)     w s δ ν {ρ} p {s′} sp =
  grad-sound e w (Lang.imapb m (one-hot (wk w i) s)) δ ν p {Ar.imapb (one-hotᵃ (eval i ρ) s′) m}
    λ k → one-hot-sound p i s sp (ix-div k m) (ix-mod k m)
grad-sound (zero-but i j e) w s δ ν {ρ} p {s′} sp =
  grad-sound e w (zero-but (wk w i) (wk w j) s) δ ν p {zb (eval i ρ) (eval j ρ) s′}
    (zb-cong (wk-eval p i) (wk-eval p j) sp)

grad-sound (e ⊞ e₁)         w s δ ν p sp =
  grad-sound e w s (grad e₁ w s δ) ν p sp
  ∙ᵀ +ᵀ-congˡ (grad-sound e₁ w s δ ν p sp)
  ∙ᵀ +ᵀ-assoc
grad-sound (e ⊠ e₁)         w s δ ν {ρ} p {s′} sp =
  grad-sound e w (s ⊠ wk w e₁) (grad e₁ w (wk w e ⊠ s) δ) ν p
    {s′ *ᵃ eval e₁ ρ} (λ i → cong₂ _*_ (sp i) (wk-eval p e₁ i))
  ∙ᵀ +ᵀ-congˡ (grad-sound e₁ w (wk w e ⊠ s) δ ν p
                 {eval e ρ *ᵃ s′} (λ i → cong₂ _*_ (wk-eval p e i) (sp i)))
  ∙ᵀ +ᵀ-assoc
grad-sound (scaledown n e)  w s δ ν p {s′} sp =
  grad-sound e w (scaledown n s) δ ν p {Ar.map (_÷ fromℕ n) s′} λ i → cong (_÷ fromℕ n) (sp i)
grad-sound (⊟ e)            w s δ ν p {s′} sp =
  grad-sound e w (⊟ s) δ ν p { -ᵃ s′} λ i → cong -_ (sp i)

grad-sound (relu e)         w s δ ν {ρ} p {s′} sp =
  grad-sound e w (𝕚+ (wk w e) ⊠ s) δ ν p {Ar.map I+ (eval e ρ) *ᵃ s′}
    λ i → cong₂ _*_ (cong I+ (wk-eval p e i)) (sp i)
grad-sound (𝕚+ e)           w s δ ν p sp = grad-sound e w 𝟘 δ ν p reflᵃ
grad-sound (√ e)            w s δ ν {ρ} p {s′} sp =
  grad-sound e w (s // (𝟚 ⊠ uop √ₒ (wk w e))) δ ν p
    {s′ *ᵃ 1/ᵃ ((K (fromℕ 1) +ᵃ K (fromℕ 1)) *ᵃ Ar.map √_ (eval e ρ))}
    λ i → cong₂ _*_ (sp i) (cong (λ z → 1/ ((fromℕ 1 + fromℕ 1) * (√_ z))) (wk-eval p e i))
grad-sound (𝟙/ e)           w s δ ν {ρ} p {s′} sp =
  grad-sound e w (⊟ (𝟙/ (wk w e) ⊠ (s // wk w e))) δ ν p
    { -ᵃ (1/ᵃ eval e ρ *ᵃ (s′ *ᵃ 1/ᵃ eval e ρ))}
    λ i → cong -_ (cong₂ _*_ (cong 1/_ (wk-eval p e i)) (cong₂ _*_ (sp i) (cong 1/_ (wk-eval p e i))))
grad-sound (ln e)           w s δ ν {ρ} p {s′} sp =
  grad-sound e w (s // wk w e) δ ν p {s′ *ᵃ 1/ᵃ eval e ρ}
    λ i → cong₂ _*_ (sp i) (cong 1/_ (wk-eval p e i))

grad-sound (let′ e e₁)      w s δ ν {ρ} p {s′} sp =
  ee-bind-sem δ₁ (grad-let e w) g (ν , a) H
  ∙ᵀ +ᵀ-cong (tailᵀ-cong δ₁≈) (V-cong e ρ λ i → δ₁≈ _ v₀ i ∙ +-neutˡ)
  ∙ᵀ +ᵀ-congˡ (+ᵀ-congˡ (ee-↑-sem δ ν))
  ∙ᵀ +ᵀ-assoc
  where
    a = eval (wk w e) ν
    δ₁ = grad e₁ (keep w) (s ↑) (ee-push-zero (ee-↑ δ))
    t = V e₁ (ρ , eval e ρ) s′
    g : Tan (_ ▹ ar _) → Tan _
    g u = tailᵀ u +ᵀ V e ρ (u v₀)

    δ₁≈ : ⟦ δ₁ ⟧ᴸ (ν , a) ≈ᵀ (⟦ ee-↑ δ ⟧ᴸ (ν , a) ▹ᵀ K (fromℕ 0)) +ᵀ t
    δ₁≈ = grad-sound e₁ (keep w) (s ↑) (ee-push-zero (ee-↑ δ)) (ν , a) (p ▹ wk-eval p e) (↑-seed s sp)
          ∙ᵀ +ᵀ-congˡ (ee-push-zero-sem (ee-↑ δ) (ν , a))

    H : ∀ {Ψ} (w′ : (_ ▹ ar _) ⊆ Ψ) (ρ′ : Env (_ ▹ ar _) Ψ) (ν′ : ⟦ Ψ ⟧ᶜ)
      → wk-env w′ ν′ ≈ᶜ (ν , a) → ⟦ grad-let e w w′ ρ′ ⟧ᴸ ν′ ≈ᵀ g (⟦ ρ′ ⟧ᴱ ν′)
    H w′ (ρ₀ ▹ x) ν′ q =
      grad-sound e w″ (var v₀) (env (env-↑ ρ₀)) (ν′ , eval x ν′) p″ reflᵃ
      ∙ᵀ +ᵀ-congˡ (env-↑-sem ρ₀ ν′)
      where
        w″ = skip (w′ ∙ʷ (skip ⊆-eq ∙ʷ w))
        p″ = wk-env-∙ w′ (skip ⊆-eq ∙ʷ w) ν′
             ∙ᶜ wk-env-cong (skip ⊆-eq ∙ʷ w) q
             ∙ᶜ wk-env-∙ (skip ⊆-eq) w (ν , a)
             ∙ᶜ wk-env-cong w wk-env-id
             ∙ᶜ p
grad-sound (ℙ e)            w s δ ν {ρ} p {s′} sp =
  grad-sound e (w₃ ∙ʷ w) (var v₂ ⊠ (var v₁ ⊟ imaps (var v₁))) (ee-wk w₃ δ) ν₃ p₃
    {ℙ-seed (Softmax (eval e ρ)) s′}
    (ℙ-seed-cong (wk-eval p (ℙ e)) (↑-seed s sp))
  ∙ᵀ +ᵀ-congˡ (ee-wk-sem w₃ δ ν₃ ∙ᵀ ⟦⟧ᴸ-cong δ wk-env-id)
  where
    w₃ = skip (skip (skip ⊆-eq))
    ν₁ = ν , eval (ℙ (wk w e)) ν
    ν₂ = ν₁ , eval (s ↑) ν₁
    ν₃ = ν₂ , eval (Lang.sum (sels (var v₁ ⊠ var v₂) (var v₀))) ν₂
    p₃ = wk-env-∙ w₃ w ν₃ ∙ᶜ wk-env-cong w wk-env-id ∙ᶜ p

-- For the top-level call.
grad′-sound : (e : E Γ (ar p)) (s : E Γ (ar p)) (δ : EE Γ Γ) (ν : ⟦ Γ ⟧ᶜ)
            → ⟦ grad′ e s δ ⟧ᴸ ν ≈ᵀ ⟦ δ ⟧ᴸ ν +ᵀ V e ν (eval s ν)
grad′-sound e s δ ν = grad-sound e ⊆-eq s δ ν wk-env-id reflᵃ

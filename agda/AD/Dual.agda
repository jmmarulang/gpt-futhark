-- Derivatives via dual numbers.
--
-- Instantiating the semantics with dual numbers gives forward-mode
-- derivatives of every expression; the only trusted part is the
-- derivatives of the scalar primitives in `dual`.  We show that the
-- tangent computed this way is J·ρ̇, so the Jacobian J is the derivative,
-- and conclude that grad satisfies the dot-product (adjoint) test
-- against dual numbers, a specification that mentions neither J nor V.
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Unit using (tt)
open import Data.Nat using (zero; suc)
open import Data.List.Relation.Unary.All using ([]; _∷_)
import Data.List as L
open import Relation.Nullary using (yes; no)
open import Function
open import Relation.Binary.PropositionalEquality hiding ([_]; J)
open import Ar
open import Lang
open import Real

module AD.Dual (r : Real) (rp : RealProp r) where

open Real.Real r
open RealProp rp
import Eval as EvalM
open EvalM r
open ZeroBut rp using (hot; rsum-hot′)
open import AD.VJP r rp
open import RSum r rp
open import AD.Jacobian r rp
open import AD.Grad using (grad′; zero-ee)
open import AD.GradCorrect r rp using (⟦_⟧ᴸ; zero-env-sem)
open import AD.Correct r rp using (grad-correct)

-- Dual numbers: a value and a tangent.
𝔻 : Set
𝔻 = R × R

infixl 10 _+ᴰ_
infixl 15 _*ᴰ_ _÷ᴰ_ _∨ᴰ_

_+ᴰ_ _*ᴰ_ _÷ᴰ_ _∨ᴰ_ : 𝔻 → 𝔻 → 𝔻
(a , a′) +ᴰ (b , b′) = a + b , a′ + b′
(a , a′) *ᴰ (b , b′) = a * b , a′ * b + a * b′
-- x ÷ y = x * (1/ y), with (1/ y)′ = - y′ / y²
(a , a′) ÷ᴰ (b , b′) = a ÷ b , a′ * 1/ b + a * - (b′ * 1/ b * 1/ b)
-- A subgradient convention for max, written with the step function I+.
(a , a′) ∨ᴰ (b , b′) = a ∨ b , (fromℕ 1 + - I+ (b + - a)) * a′ + I+ (b + - a) * b′

-ᴰ_ e^ᴰ √ᴰ I+ᴰ logᴰ : 𝔻 → 𝔻
-ᴰ (a , a′)  = - a , - a′
e^ᴰ (a , a′) = e^ a , e^ a * a′
√ᴰ (a , a′)  = √_ a , a′ * 1/ ((fromℕ 1 + fromℕ 1) * √_ a)
I+ᴰ (a , a′) = I+ a , fromℕ 0
logᴰ (a , a′) = log a , a′ * 1/ a

dual : Real
dual = record
  { R = 𝔻 ; fromℕ = λ n → fromℕ n , fromℕ 0 ; ∞ᵣ = ∞ᵣ , fromℕ 0
  ; _+_ = _+ᴰ_ ; _*_ = _*ᴰ_ ; _∨_ = _∨ᴰ_ ; _÷_ = _÷ᴰ_
  ; -_ = -ᴰ_ ; e^_ = e^ᴰ ; √_ = √ᴰ ; I+ = I+ᴰ ; log = logᴰ }

-- The semantics over dual numbers.
module ED = EvalM dual

-- Values and tangents of a dual environment.
val-env : ED.⟦ Γ ⟧ᶜ → ⟦ Γ ⟧ᶜ
val-env {ε} _ = tt
val-env {Γ ▹ ix _} (ρ , i) = val-env ρ , i
val-env {Γ ▹ ar _} (ρ , a) = val-env ρ , Ar.map proj₁ a

tan-env : ED.⟦ Γ ⟧ᶜ → Tan Γ
tan-env ρ v = Ar.map proj₂ (ED.lookup v ρ)

lookup-val : (v : ar s ∈ Γ) (ρ̂ : ED.⟦ Γ ⟧ᶜ) → Ar.map proj₁ (ED.lookup v ρ̂) ≈ᵃ lookup v (val-env ρ̂)
lookup-val v₀ (ρ̂ , a) i = refl
lookup-val {Γ = Γ ▹ ix _} (there v) (ρ̂ , _) = lookup-val v ρ̂
lookup-val {Γ = Γ ▹ ar _} (there v) (ρ̂ , _) = lookup-val v ρ̂

lookup-ix : (v : ix s ∈ Γ) (ρ̂ : ED.⟦ Γ ⟧ᶜ) → ED.lookup v ρ̂ ≡ lookup v (val-env ρ̂)
lookup-ix v₀ (ρ̂ , i) = refl
lookup-ix {Γ = Γ ▹ ix _} (there v) (ρ̂ , _) = lookup-ix v ρ̂
lookup-ix {Γ = Γ ▹ ar _} (there v) (ρ̂ , _) = lookup-ix v ρ̂

-- Index expressions are variables.
fwd-idx : (i : E Γ (ix s)) (ρ̂ : ED.⟦ Γ ⟧ᶜ) {ρ : ⟦ Γ ⟧ᶜ} → val-env ρ̂ ≈ᶜ ρ → ED.eval i ρ̂ ≡ eval i ρ
fwd-idx (var x) ρ̂ p = lookup-ix x ρ̂ ∙ lookup-≈ᶜ p x

-- Projections commute with sums and zero-but.
-- The value and tangent parts of a sum of dual arrays.
rsumᴰ-proj : (h : 𝔻 → R) → (∀ x y → h (x +ᴰ y) ≡ h x + h y) → h (fromℕ 0 , fromℕ 0) ≡ fromℕ 0
        → (a : Ar q (Ar s 𝔻)) (i : P s)
        → h (Ar.sum (zipWith _+ᴰ_) (K (fromℕ 0 , fromℕ 0)) a i) ≡ rsum (λ k → h (a k i))
rsumᴰ-proj h hf h0 a i = cong h (sum-inv _+ᴰ_ (fromℕ 0 , fromℕ 0) {a} i)
                    ∙ sum-hom h _+ᴰ_ _+_ _ _ hf h0 (λ k → a k i)

rsumᴰ-val : (a : Ar q (Ar s 𝔻)) (i : P s)
       → proj₁ (Ar.sum (zipWith _+ᴰ_) (K (fromℕ 0 , fromℕ 0)) a i) ≡ rsum (λ k → proj₁ (a k i))
rsumᴰ-val = rsumᴰ-proj proj₁ (λ _ _ → refl) refl

rsumᴰ-tan : (a : Ar q (Ar s 𝔻)) (i : P s)
       → proj₂ (Ar.sum (zipWith _+ᴰ_) (K (fromℕ 0 , fromℕ 0)) a i) ≡ rsum (λ k → proj₂ (a k i))
rsumᴰ-tan = rsumᴰ-proj proj₂ (λ _ _ → refl) refl

zb-proj : (h : 𝔻 → R) → h (fromℕ 0 , fromℕ 0) ≡ fromℕ 0
        → (a b : P s) (x : Ar p 𝔻) (k : P p) → h (ED.zb a b x k) ≡ zb a b (h ∘ x) k
zb-proj h h0 a b x k with a ≟ₚ b
... | yes _ = refl
... | no _ = h0

-- Pairing of a (co)tangent with a tangent.
⟨_,_⟩ : Tan Γ → Tan Γ → R
⟨_,_⟩ {ε} t u = fromℕ 0
⟨_,_⟩ {Γ ▹ ix _} t u = ⟨ tailᵀ t , tailᵀ u ⟩
⟨_,_⟩ {Γ ▹ ar _} t u = ⟨ tailᵀ t , tailᵀ u ⟩ + rsum (λ j → t v₀ j * u v₀ j)

pair-cong : {t t′ : Tan Γ} (u : Tan Γ) → t ≈ᵀ t′ → ⟨ t , u ⟩ ≡ ⟨ t′ , u ⟩
pair-cong {ε} u p = refl
pair-cong {Γ ▹ ix _} u p = pair-cong (tailᵀ u) (tailᵀ-cong p)
pair-cong {Γ ▹ ar s} {t} {t′} u p =
  cong₂ _+_ (pair-cong (tailᵀ u) (tailᵀ-cong p))
            (rsum-cong′ (λ j → t v₀ j * u v₀ j) (λ j → t′ v₀ j * u v₀ j) (λ j → cong₂ _*_ (p _ v₀ j) refl))

pair-0 : (u : Tan Γ) → ⟨ 0ᵀ , u ⟩ ≡ fromℕ 0
pair-0 {ε} u = refl
pair-0 {Γ ▹ ix _} u = pair-0 (tailᵀ u)
pair-0 {Γ ▹ ar s} u =
  cong₂ _+_ (pair-0 (tailᵀ u))
            (rsum-cong′ (λ j → fromℕ 0 * u v₀ j) (λ _ → fromℕ 0) (λ j → *-nulˡ) ∙ rsum-0 {s = s})
  ∙ +-neutˡ

pair-+ : (t t′ u : Tan Γ) → ⟨ t +ᵀ t′ , u ⟩ ≡ ⟨ t , u ⟩ + ⟨ t′ , u ⟩
pair-+ {ε} t t′ u = sym +-neutˡ
pair-+ {Γ ▹ ix _} t t′ u = pair-+ (tailᵀ t) (tailᵀ t′) (tailᵀ u)
pair-+ {Γ ▹ ar s} t t′ u =
  cong₂ _+_ (pair-+ (tailᵀ t) (tailᵀ t′) (tailᵀ u))
            (rsum-cong′ (λ j → (t v₀ j + t′ v₀ j) * u v₀ j) (λ j → t v₀ j * u v₀ j + t′ v₀ j * u v₀ j)
                     (λ j → *-distʳ)
             ∙ rsum-+ (λ j → t v₀ j * u v₀ j) (λ j → t′ v₀ j * u v₀ j))
  ∙ +-medial

pair-Jᵀ : (A : P s → Tan Γ) (c : Ar s R) (u : Tan Γ) → ⟨ Jᵀ A c , u ⟩ ≡ rsum (λ i → c i * ⟨ A i , u ⟩)
pair-Jᵀ {s} {ε} A c u = sym (rsum-cong′ (λ i → c i * fromℕ 0) (λ _ → fromℕ 0) (λ i → *-nulʳ) ∙ rsum-0 {s = s})
pair-Jᵀ {Γ = Γ ▹ ix _} A c u = pair-Jᵀ (λ i → tailᵀ (A i)) c (tailᵀ u)
pair-Jᵀ {Γ = Γ ▹ ar _} A c u =
  cong₂ _+_ (pair-Jᵀ (λ i → tailᵀ (A i)) c (tailᵀ u))
            (rsum-cong′ (λ j → rsum (λ i → c i * A i v₀ j) * u v₀ j) (λ j → rsum (λ i → c i * A i v₀ j * u v₀ j))
                     (λ j → rsum-*ʳ (λ i → c i * A i v₀ j) (u v₀ j))
             ∙ rsum-swap (λ j i → c i * A i v₀ j * u v₀ j)
             ∙ rsum-cong′ (λ i → rsum (λ j → c i * A i v₀ j * u v₀ j)) (λ i → c i * rsum (λ j → A i v₀ j * u v₀ j))
                       (λ i → rsum-cong′ (λ j → c i * A i v₀ j * u v₀ j) (λ j → c i * (A i v₀ j * u v₀ j))
                                      (λ j → *-assoc)
                              ∙ sym (rsum-*ˡ (c i) (λ j → A i v₀ j * u v₀ j))))
  ∙ sym (rsum-+ (λ i → c i * ⟨ tailᵀ (A i) , tailᵀ u ⟩) (λ i → c i * rsum (λ j → A i v₀ j * u v₀ j)))
  ∙ rsum-cong′ (λ i → c i * ⟨ tailᵀ (A i) , tailᵀ u ⟩ + c i * rsum (λ j → A i v₀ j * u v₀ j))
            (λ i → c i * ⟨ A i , u ⟩) (λ i → sym dist)

pair-· : (c : R) (t u : Tan Γ) → ⟨ c ·ᵀ t , u ⟩ ≡ c * ⟨ t , u ⟩
pair-· c t u = pair-Jᵀ {s = L.[]} (λ _ → t) (K c) u

pair-neg : (t u : Tan Γ) → ⟨ negᵀ t , u ⟩ ≡ - ⟨ t , u ⟩
pair-neg t u = pair-cong u (λ _ v j → neg-*) ∙ pair-· (- fromℕ 1) t u ∙ sym neg-*

pair-Σᵀ : (f : P s → Tan Γ) (u : Tan Γ) → ⟨ Σᵀ f , u ⟩ ≡ rsum (λ k → ⟨ f k , u ⟩)
pair-Σᵀ f u =
  pair-cong u (λ _ v j → rsum-inv (λ k → f k v) j
                         ∙ rsum-cong′ (λ k → f k v j) (λ k → fromℕ 1 * f k v j) (λ k → sym *-neutˡ))
  ∙ pair-Jᵀ f (K (fromℕ 1)) u
  ∙ rsum-cong′ (λ k → fromℕ 1 * ⟨ f k , u ⟩) (λ k → ⟨ f k , u ⟩) (λ k → *-neutˡ)

pair-𝕖 : (x : ar s ∈ Γ) (a : Ar s R) (u : Tan Γ) → ⟨ 𝕖 x a , u ⟩ ≡ rsum (λ j → a j * u x j)
pair-𝕖 v₀ a u = cong₂ _+_ (pair-0 (tailᵀ u)) refl ∙ +-neutˡ
pair-𝕖 {Γ = Γ ▹ ix _} (there x) a u = pair-cong (tailᵀ u) (λ _ y → 𝕖-there x a y) ∙ pair-𝕖 x a (tailᵀ u)
pair-𝕖 {s = s} {Γ = Γ ▹ ar p} (there x) a u =
  cong₂ _+_ (pair-cong (tailᵀ u) (λ _ y → 𝕖-there x a y) ∙ pair-𝕖 x a (tailᵀ u))
            (rsum-cong′ (λ j → fromℕ 0 * u v₀ j) (λ _ → fromℕ 0) (λ j → *-nulˡ) ∙ rsum-0 {s = p})
  ∙ +-neutʳ

-- The value part of the dual semantics is the semantics.
fwd-val : (e : E Γ (ar s)) (ρ̂ : ED.⟦ Γ ⟧ᶜ) {ρ : ⟦ Γ ⟧ᶜ} → val-env ρ̂ ≈ᶜ ρ
        → (i : P s) → proj₁ (ED.eval e ρ̂ i) ≡ eval e ρ i
fwd-val (var x)          ρ̂ p i = lookup-val x ρ̂ i ∙ lookup-≈ᶜ p x i
fwd-val 𝟘                ρ̂ p i = refl
fwd-val 𝟙                ρ̂ p i = refl

fwd-val (imaps e)        ρ̂ p i = fwd-val e (ρ̂ , i) (p ▹ refl) []
fwd-val (imap′ refl e)   ρ̂ p k = fwd-val e (ρ̂ , proj₁ (splitP k)) (p ▹ refl) (proj₂ (splitP k))
fwd-val (imapb m e)      ρ̂ p k = fwd-val e (ρ̂ , ix-div k m) (p ▹ refl) (ix-mod k m)
fwd-val (Lang.sum e)     ρ̂ {ρ} p i =
  rsumᴰ-val (λ k → ED.eval e (ρ̂ , k)) i
  ∙ rsum-cong′ (λ k → proj₁ (ED.eval e (ρ̂ , k) i)) (λ k → eval e (ρ , k) i)
            (λ k → fwd-val e (ρ̂ , k) (p ▹ refl) i)
  ∙ sym (rsum-inv (λ k → eval e (ρ , k)) i)

fwd-val (sels e i)       ρ̂ {ρ} p _ =
  fwd-val e ρ̂ p (ED.eval i ρ̂) ∙ cong (eval e ρ) (fwd-idx i ρ̂ p)
fwd-val (sel′ refl e i)  ρ̂ {ρ} p j =
  fwd-val e ρ̂ p (ED.eval i ρ̂ ++ j) ∙ cong (λ k → eval e ρ (k ++ j)) (fwd-idx i ρ̂ p)
fwd-val (selb m e i)     ρ̂ {ρ} p j =
  fwd-val e ρ̂ p (ix-combine (ED.eval i ρ̂) j m)
  ∙ cong (λ k → eval e ρ (ix-combine k j m)) (fwd-idx i ρ̂ p)
fwd-val (zero-but i j e) ρ̂ {ρ} p k =
  zb-proj proj₁ refl (ED.eval i ρ̂) (ED.eval j ρ̂) (ED.eval e ρ̂) k
  ∙ zb-cong (fwd-idx i ρ̂ p) (fwd-idx j ρ̂ p) (fwd-val e ρ̂ p) k

fwd-val (e ⊞ e₁)         ρ̂ p i = cong₂ _+_ (fwd-val e ρ̂ p i) (fwd-val e₁ ρ̂ p i)
fwd-val (e ⊠ e₁)         ρ̂ p i = cong₂ _*_ (fwd-val e ρ̂ p i) (fwd-val e₁ ρ̂ p i)
fwd-val (scaledown n e)  ρ̂ p i = cong (_÷ fromℕ n) (fwd-val e ρ̂ p i)
fwd-val (⊟ e)            ρ̂ p i = cong -_ (fwd-val e ρ̂ p i)

fwd-val (relu e)         ρ̂ p i = cong (fromℕ 0 ∨_) (fwd-val e ρ̂ p i)
fwd-val (𝕚+ e)           ρ̂ p i = cong I+ (fwd-val e ρ̂ p i)
fwd-val (√ e)            ρ̂ p i = cong √_ (fwd-val e ρ̂ p i)
fwd-val (𝟙/ e)           ρ̂ p i = cong 1/_ (fwd-val e ρ̂ p i)
fwd-val (ln e)           ρ̂ p i = cong log (fwd-val e ρ̂ p i)

fwd-val (let′ e e₁)      ρ̂ p i = fwd-val e₁ (ρ̂ , ED.eval e ρ̂) (p ▹ fwd-val e ρ̂ p) i
fwd-val (ℙ e)            ρ̂ {ρ} p i =
  cong₂ _÷_ (cong e^_ (fwd-val e ρ̂ p i))
            (sum-hom proj₁ _+ᴰ_ _+_ _ _ (λ _ _ → refl) refl (λ k → e^ᴰ (ED.eval e ρ̂ k))
             ∙ rsum-cong′ (λ k → e^ proj₁ (ED.eval e ρ̂ k)) (λ k → e^ eval e ρ k)
                       (λ k → cong e^_ (fwd-val e ρ̂ p k)))

-- The tangent part of the dual semantics is the Jacobian applied to
-- the tangent of the environment.
fwd-tan : (e : E Γ (ar s)) (ρ̂ : ED.⟦ Γ ⟧ᶜ) {ρ : ⟦ Γ ⟧ᶜ} → val-env ρ̂ ≈ᶜ ρ
        → (i : P s) → proj₂ (ED.eval e ρ̂ i) ≡ ⟨ J e ρ i , tan-env ρ̂ ⟩
fwd-tan (var x)          ρ̂ p i = sym (pair-𝕖 x (hot i) (tan-env ρ̂) ∙ rsum-hot′ i (tan-env ρ̂ x))
fwd-tan 𝟘                ρ̂ p i = sym (pair-0 (tan-env ρ̂))
fwd-tan 𝟙                ρ̂ p i = sym (pair-0 (tan-env ρ̂))

fwd-tan (imaps e)        ρ̂ p i = fwd-tan e (ρ̂ , i) (p ▹ refl) []
fwd-tan (imap′ refl e)   ρ̂ p k = fwd-tan e (ρ̂ , proj₁ (splitP k)) (p ▹ refl) (proj₂ (splitP k))
fwd-tan (imapb m e)      ρ̂ p k = fwd-tan e (ρ̂ , ix-div k m) (p ▹ refl) (ix-mod k m)
fwd-tan (Lang.sum e)     ρ̂ {ρ} p i =
  rsumᴰ-tan (λ k → ED.eval e (ρ̂ , k)) i
  ∙ rsum-cong′ (λ k → proj₂ (ED.eval e (ρ̂ , k) i)) (λ k → ⟨ tailᵀ (J e (ρ , k) i) , tan-env ρ̂ ⟩)
            (λ k → fwd-tan e (ρ̂ , k) (p ▹ refl) i)
  ∙ sym (pair-Σᵀ (λ k → tailᵀ (J e (ρ , k) i)) (tan-env ρ̂))

fwd-tan (sels e i)       ρ̂ {ρ} p _ =
  fwd-tan e ρ̂ p (ED.eval i ρ̂) ∙ cong (λ k → ⟨ J e ρ k , tan-env ρ̂ ⟩) (fwd-idx i ρ̂ p)
fwd-tan (sel′ refl e i)  ρ̂ {ρ} p j =
  fwd-tan e ρ̂ p (ED.eval i ρ̂ ++ j) ∙ cong (λ k → ⟨ J e ρ (k ++ j) , tan-env ρ̂ ⟩) (fwd-idx i ρ̂ p)
fwd-tan (selb m e i)     ρ̂ {ρ} p j =
  fwd-tan e ρ̂ p (ix-combine (ED.eval i ρ̂) j m)
  ∙ cong (λ k → ⟨ J e ρ (ix-combine k j m) , tan-env ρ̂ ⟩) (fwd-idx i ρ̂ p)
fwd-tan (zero-but i j e) ρ̂ {ρ} p k =
  zb-proj proj₂ refl (ED.eval i ρ̂) (ED.eval j ρ̂) (ED.eval e ρ̂) k
  ∙ cong₂ (λ a b → zb a b (proj₂ ∘ ED.eval e ρ̂) k) (fwd-idx i ρ̂ p) (fwd-idx j ρ̂ p)
  ∙ go
  where
    go : zb (eval i ρ) (eval j ρ) (proj₂ ∘ ED.eval e ρ̂) k
       ≡ ⟨ zbᵀ (eval i ρ) (eval j ρ) (J e ρ k) , tan-env ρ̂ ⟩
    go with eval i ρ ≟ₚ eval j ρ
    ... | yes _ = fwd-tan e ρ̂ p k
    ... | no _ = sym (pair-0 (tan-env ρ̂))

fwd-tan (e ⊞ e₁)         ρ̂ {ρ} p i =
  cong₂ _+_ (fwd-tan e ρ̂ p i) (fwd-tan e₁ ρ̂ p i)
  ∙ sym (pair-+ (J e ρ i) (J e₁ ρ i) (tan-env ρ̂))
fwd-tan (e ⊠ e₁)         ρ̂ {ρ} p i =
  cong₂ _+_ (cong₂ _*_ (fwd-tan e ρ̂ p i) (fwd-val e₁ ρ̂ p i))
            (cong₂ _*_ (fwd-val e ρ̂ p i) (fwd-tan e₁ ρ̂ p i))
  ∙ cong₂ _+_ *-comm refl
  ∙ sym (pair-+ (eval e₁ ρ i ·ᵀ J e ρ i) (eval e ρ i ·ᵀ J e₁ ρ i) τ
         ∙ cong₂ _+_ (pair-· (eval e₁ ρ i) (J e ρ i) τ) (pair-· (eval e ρ i) (J e₁ ρ i) τ))
  where τ = tan-env ρ̂
fwd-tan (scaledown n e)  ρ̂ {ρ} p i =
  cong₂ _+_ (cong (_* 1/ fromℕ n) (fwd-tan e ρ̂ p i))
            (cong₂ _*_ refl (cong -_ (cong (_* 1/ fromℕ n) *-nulˡ ∙ *-nulˡ) ∙ minus-idʳ) ∙ *-nulʳ)
  ∙ +-neutʳ ∙ *-comm
  ∙ sym (pair-· (fromℕ 1 ÷ fromℕ n) (J e ρ i) (tan-env ρ̂))
fwd-tan (⊟ e)            ρ̂ {ρ} p i = cong -_ (fwd-tan e ρ̂ p i) ∙ sym (pair-neg (J e ρ i) (tan-env ρ̂))

fwd-tan (relu e)         ρ̂ {ρ} p i =
  cong₂ _+_ *-nulʳ refl ∙ +-neutˡ
  ∙ cong₂ _*_ (cong I+ (cong₂ _+_ refl minus-idʳ ∙ +-neutʳ ∙ fwd-val e ρ̂ p i)) (fwd-tan e ρ̂ p i)
  ∙ sym (pair-· (I+ (eval e ρ i)) (J e ρ i) (tan-env ρ̂))
fwd-tan (𝕚+ e)           ρ̂ p i = sym (pair-0 (tan-env ρ̂))
fwd-tan (√ e)            ρ̂ {ρ} p i =
  cong₂ _*_ (fwd-tan e ρ̂ p i) (cong (λ z → 1/ ((fromℕ 1 + fromℕ 1) * √_ z)) (fwd-val e ρ̂ p i))
  ∙ *-comm
  ∙ sym (pair-· (1/ ((fromℕ 1 + fromℕ 1) * √_ (eval e ρ i))) (J e ρ i) (tan-env ρ̂))
fwd-tan (𝟙/ e)           ρ̂ {ρ} p i =
  cong₂ _+_ *-nulˡ (*-neutˡ ∙ cong -_ (cong₂ _*_ (cong₂ _*_ (fwd-tan e ρ̂ p i) w′) w′))
  ∙ +-neutˡ
  ∙ cong -_ (*-assoc ∙ *-comm)
  ∙ sym minus-*-pushˡ
  ∙ sym (pair-· (- (1/ (eval e ρ i) * 1/ (eval e ρ i))) (J e ρ i) (tan-env ρ̂))
  where w′ = cong 1/_ (fwd-val e ρ̂ p i)
fwd-tan (ln e)           ρ̂ {ρ} p i =
  cong₂ _*_ (fwd-tan e ρ̂ p i) (cong 1/_ (fwd-val e ρ̂ p i))
  ∙ *-comm
  ∙ sym (pair-· (1/ (eval e ρ i)) (J e ρ i) (tan-env ρ̂))

fwd-tan (let′ e e₁)      ρ̂ {ρ} p i =
  fwd-tan e₁ (ρ̂ , d) (p ▹ fwd-val e ρ̂ p) i
  ∙ cong₂ _+_ refl (rsum-cong′ (λ k → J e₁ ρ′ i v₀ k * proj₂ (d k)) (λ k → J e₁ ρ′ i v₀ k * ⟨ J e ρ k , τ ⟩)
                            (λ k → cong₂ _*_ refl (fwd-tan e ρ̂ p k))
                    ∙ sym (pair-Jᵀ (J e ρ) (J e₁ ρ′ i v₀) τ))
  ∙ sym (pair-+ (tailᵀ (J e₁ ρ′ i)) (Jᵀ (J e ρ) (J e₁ ρ′ i v₀)) τ)
  where
    d = ED.eval e ρ̂
    ρ′ = ρ , eval e ρ
    τ = tan-env ρ̂
fwd-tan (ℙ e)            ρ̂ {ρ} p i =
  cong₂ _+_ (cong₂ _*_ (cong₂ _*_ (cong e^_ (fwd-val e ρ̂ p i)) (fwd-tan e ρ̂ p i)) (cong 1/_ T≡))
            (cong₂ _*_ (cong e^_ (fwd-val e ρ̂ p i))
                       (cong -_ (cong₂ _*_ (cong₂ _*_ T′≡ (cong 1/_ T≡)) (cong 1/_ T≡))))
  ∙ cong₂ _+_ (*-assoc ∙ cong (wᵢ *_) *-comm ∙ sym *-assoc)
              (minus-*-pushʳ ∙ cong -_ (cong (wᵢ *_) (*-comm ∙ cong (y *_) *-comm) ∙ sym *-assoc))
  ∙ cong₂ _+_ (cong₂ _*_ (sym ÷-*) refl)
              (cong -_ (cong₂ _*_ (sym ÷-*) (rsum-*ˡ y (λ k → wₖ k * 𝕏 k)
                                             ∙ rsum-cong′ (λ k → y * (wₖ k * 𝕏 k)) (λ k → sm k * 𝕏 k)
                                                       (λ k → sym *-assoc ∙ cong₂ _*_ (*-comm ∙ sym ÷-*) refl))))
  ∙ sym (rhs-alg)
  where
    τ = tan-env ρ̂
    sm = Softmax (eval e ρ)
    wₖ : P _ → R
    wₖ k = e^ eval e ρ k
    wᵢ = wₖ i
    𝕏 : P _ → R
    𝕏 k = ⟨ J e ρ k , τ ⟩
    T = rsum wₖ
    y = 1/ T
    T≡ : proj₁ (Ar.sum _+ᴰ_ (fromℕ 0 , fromℕ 0) (Ar.map e^ᴰ (ED.eval e ρ̂))) ≡ T
    T≡ = sum-hom proj₁ _+ᴰ_ _+_ _ _ (λ _ _ → refl) refl (Ar.map e^ᴰ (ED.eval e ρ̂))
       ∙ rsum-cong′ (λ k → e^ proj₁ (ED.eval e ρ̂ k)) wₖ (λ k → cong e^_ (fwd-val e ρ̂ p k))
    T′≡ : proj₂ (Ar.sum _+ᴰ_ (fromℕ 0 , fromℕ 0) (Ar.map e^ᴰ (ED.eval e ρ̂))) ≡ rsum (λ k → wₖ k * 𝕏 k)
    T′≡ = sum-hom proj₂ _+ᴰ_ _+_ _ _ (λ _ _ → refl) refl (Ar.map e^ᴰ (ED.eval e ρ̂))
        ∙ rsum-cong′ (λ k → e^ proj₁ (ED.eval e ρ̂ k) * proj₂ (ED.eval e ρ̂ k)) (λ k → wₖ k * 𝕏 k)
                  (λ k → cong₂ _*_ (cong e^_ (fwd-val e ρ̂ p k)) (fwd-tan e ρ̂ p k))
    rhs-alg : ⟨ J (ℙ e) ρ i , τ ⟩ ≡ sm i * 𝕏 i + - (sm i * rsum (λ k → sm k * 𝕏 k))
    rhs-alg = pair-· (sm i) (J e ρ i +ᵀ negᵀ (Jᵀ (J e ρ) sm)) τ
            ∙ cong (sm i *_) (pair-+ (J e ρ i) (negᵀ (Jᵀ (J e ρ) sm)) τ
                              ∙ cong₂ _+_ refl (pair-neg (Jᵀ (J e ρ) sm) τ
                                                ∙ cong -_ (pair-Jᵀ (J e ρ) sm τ)))
            ∙ dist ∙ cong₂ _+_ refl minus-*-pushʳ

-- grad passes the dot-product test against dual numbers: for every
-- dual environment ρ̂ (a point val-env ρ̂ and a direction tan-env ρ̂),
-- pairing the gradient with the direction gives the seed paired with
-- the tangent computed by the dual semantics.
grad-dual : (e s : E Γ (ar p)) (ρ̂ : ED.⟦ Γ ⟧ᶜ)
          → ⟨ ⟦ grad′ e s zero-ee ⟧ᴸ (val-env ρ̂) , tan-env ρ̂ ⟩
          ≡ rsum (λ i → eval s (val-env ρ̂) i * proj₂ (ED.eval e ρ̂ i))
grad-dual e s ρ̂ =
  pair-cong τ (grad-correct e s zero-ee ν)
  ∙ pair-+ (⟦ zero-ee ⟧ᴸ ν) (Jᵀ (J e ν) (eval s ν)) τ
  ∙ cong₂ _+_ (pair-cong τ (zero-env-sem ν) ∙ pair-0 τ) (pair-Jᵀ (J e ν) (eval s ν) τ)
  ∙ +-neutˡ
  ∙ rsum-cong′ (λ i → eval s ν i * ⟨ J e ν i , τ ⟩) (λ i → eval s ν i * proj₂ (ED.eval e ρ̂ i))
            (λ i → cong₂ _*_ refl (sym (fwd-tan e ρ̂ reflᶜ i)))
  where
    ν = val-env ρ̂
    τ = tan-env ρ̂

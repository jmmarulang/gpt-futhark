-- Semantic reverse mode: the vjp of an expression as a function on
-- arrays.  It follows AD.Grad case by case, but without syntax,
-- sharing or let-telescopes.
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Function
open import Relation.Nullary using (yes; no)
open import Data.List.Relation.Unary.All using ([])
open import Relation.Binary.PropositionalEquality
open import Ar
open import Lang
open import Real

module AD.VJP (r : Real) (rp : RealProp r) where

open Real.Real r
open RealProp rp
open import Eval r

-- Tangents (and cotangents): an array for every array variable.
Tan : Ctx → Set
Tan Γ = ∀ {s} → ar s ∈ Γ → Ar s R

infix 4 _≈ᵀ_
_≈ᵀ_ : Tan Γ → Tan Γ → Set
-- The shape is explicit: an implicit one here blocks unification.
_≈ᵀ_ {Γ} t u = ∀ s (v : ar s ∈ Γ) → t v ≈ᵃ u v

0ᵀ : Tan Γ
0ᵀ _ = K (fromℕ 0)

infixl 10 _+ᵀ_
_+ᵀ_ : Tan Γ → Tan Γ → Tan Γ
(t +ᵀ u) v = zipWith _+_ (t v) (u v)

Σᵀ : (P s → Tan Γ) → Tan Γ
Σᵀ f v = Ar.sum (zipWith _+_) (K (fromℕ 0)) (λ k → f k v)

tailᵀ : Tan (Γ ▹ is) → Tan Γ
tailᵀ t v = t (there v)

infixl 15 _▹ᵀ_
_▹ᵀ_ : Tan Γ → Ar s R → Tan (Γ ▹ ar s)
(t ▹ᵀ a) v₀ = a
(t ▹ᵀ a) (there v) = t v

-- The tangent that is a at x and zero elsewhere.
𝕖 : ar s ∈ Γ → Ar s R → Tan Γ
𝕖 x a y with eq? x y
... | veq = a
... | neq _ _ = K (fromℕ 0)

-- Laws
reflᵀ : {t : Tan Γ} → t ≈ᵀ t
reflᵀ _ v i = refl

symᵀ : {t u : Tan Γ} → t ≈ᵀ u → u ≈ᵀ t
symᵀ p s v i = sym (p s v i)

infixr 4 _∙ᵀ_
_∙ᵀ_ : {t u w : Tan Γ} → t ≈ᵀ u → u ≈ᵀ w → t ≈ᵀ w
(p ∙ᵀ q) s v i = p s v i ∙ q s v i

+ᵀ-cong : {t t′ u u′ : Tan Γ} → t ≈ᵀ t′ → u ≈ᵀ u′ → t +ᵀ u ≈ᵀ t′ +ᵀ u′
+ᵀ-cong p q s v i = cong₂ _+_ (p s v i) (q s v i)

+ᵀ-congˡ : {t t′ u : Tan Γ} → t ≈ᵀ t′ → t +ᵀ u ≈ᵀ t′ +ᵀ u
+ᵀ-congˡ {u = u} p = +ᵀ-cong p (reflᵀ {t = u})

+ᵀ-congʳ : {t u u′ : Tan Γ} → u ≈ᵀ u′ → t +ᵀ u ≈ᵀ t +ᵀ u′
+ᵀ-congʳ {t = t} p = +ᵀ-cong (reflᵀ {t = t}) p

+ᵀ-assoc : {t u w : Tan Γ} → t +ᵀ u +ᵀ w ≈ᵀ t +ᵀ (u +ᵀ w)
+ᵀ-assoc _ v i = +-assoc

+ᵀ-neutˡ : {t : Tan Γ} → 0ᵀ +ᵀ t ≈ᵀ t
+ᵀ-neutˡ _ v i = +-neutˡ

+ᵀ-neutʳ : {t : Tan Γ} → t +ᵀ 0ᵀ ≈ᵀ t
+ᵀ-neutʳ _ v i = +-neutʳ

tailᵀ-cong : {t u : Tan (Γ ▹ is)} → t ≈ᵀ u → tailᵀ t ≈ᵀ tailᵀ u
tailᵀ-cong p s v = p s (there v)

Σᵀ-cong : {f g : P s → Tan Γ} → (∀ k → f k ≈ᵀ g k) → Σᵀ f ≈ᵀ Σᵀ g
Σᵀ-cong {f = f} {g} p s v i =
  sum-inv _+_ (fromℕ 0) {λ k → f k v} i
  ∙ sum-cong _+_ (fromℕ 0) (λ k → p k s v i)
  ∙ sym (sum-inv _+_ (fromℕ 0) {λ k → g k v} i)

𝕖-cong : (x : ar s ∈ Γ) {a b : Ar s R} → a ≈ᵃ b → 𝕖 x a ≈ᵀ 𝕖 x b
𝕖-cong x p _ y with eq? x y
... | veq = p
... | neq _ _ = reflᵃ

𝕖-there : (x : ar s ∈ Γ) (a : Ar s R) (y : ar p ∈ Γ)
        → 𝕖 (there {ip = is} x) a (there y) ≈ᵃ 𝕖 x a y
𝕖-there x a y with eq? x y
... | veq = reflᵃ
... | neq _ _ = reflᵃ

zb-cong : {i i′ j j′ : P s} {a b : Ar p R} → i ≡ i′ → j ≡ j′ → a ≈ᵃ b
        → zb i j a ≈ᵃ zb i′ j′ b
zb-cong {i = i} {j = j} refl refl p with i ≟ₚ j
... | yes _ = p
... | no _ = reflᵃ

-- Pointwise operations on arrays (as eval computes ⊞, ⊠, ⊟ and 𝟙/).
infixl 10 _+ᵃ_
infixl 15 _*ᵃ_
_+ᵃ_ _*ᵃ_ : Ar s R → Ar s R → Ar s R
_+ᵃ_ = zipWith _+_
_*ᵃ_ = zipWith _*_

-ᵃ_ 1/ᵃ_ : Ar s R → Ar s R
-ᵃ_ = Ar.map -_
1/ᵃ_ = Ar.map 1/_

-- The array that is a at index i and zero elsewhere (as a function
-- of the index, like the body of one-hot in AD.Grad).
one-hotᵃ : P s → Ar p R → P s → Ar p R
one-hotᵃ i a k = zb k i a

-- The seed of the bound expression in the vjp of softmax:
-- p ⊠ (s ⊟ ⟨s,p⟩), written as AD.Grad computes it.
ℙ-seed : Ar s R → Ar s R → Ar s R
ℙ-seed p s = p *ᵃ (s +ᵃ -ᵃ (λ _ → d []))
  where d : Ar unit R
        d = Ar.sum (zipWith _+_) (K (fromℕ 0)) (λ i → K ((s *ᵃ p) i))

ℙ-seed-cong : {p p′ s s′ : Ar q R} → p ≈ᵃ p′ → s ≈ᵃ s′ → ℙ-seed p s ≈ᵃ ℙ-seed p′ s′
ℙ-seed-cong {p = p} {p′} {s} {s′} pp ps i =
  cong₂ _*_ (pp i) (cong₂ _+_ (ps i) (cong -_ d-eq))
  where d-eq = sum-inv _+_ (fromℕ 0) {λ j → K ((s *ᵃ p) j)} []
             ∙ sum-cong _+_ (fromℕ 0) (λ j → cong₂ _*_ (ps j) (pp j))
             ∙ sym (sum-inv _+_ (fromℕ 0) {λ j → K ((s′ *ᵃ p′) j)} [])

-- V e ρ s is the vjp of e at ρ applied to the cotangent s.
V : E Γ (ar s) → ⟦ Γ ⟧ᶜ → Ar s R → Tan Γ

-- e is the body of a loop over k, s k its cotangent.
V-sum : E (Γ ▹ ix s) (ar p) → ⟦ Γ ⟧ᶜ → (P s → Ar p R) → Tan Γ
V-sum e ρ s = tailᵀ (Σᵀ λ k → V e (ρ , k) (s k))

V (var x)          ρ s = 𝕖 x s
V 𝟘                ρ s = 0ᵀ
V 𝟙                ρ s = 0ᵀ

V (imaps e)        ρ s = V-sum e ρ (λ k → K (s k))
V (imap′ refl e)   ρ s = V-sum e ρ (nest s)
V (imapb m e)      ρ s = V-sum e ρ (Ar.selb s m)
V (sum e)          ρ s = V-sum e ρ (λ _ → s)

V (sels e i)       ρ s = V e ρ (λ k → one-hotᵃ (eval i ρ) s k [])
V (sel′ refl e i)  ρ s = V e ρ (unnest (one-hotᵃ (eval i ρ) s))
V (selb m e i)     ρ s = V e ρ (Ar.imapb (one-hotᵃ (eval i ρ) s) m)
V (zero-but i j e) ρ s = V e ρ (zb (eval i ρ) (eval j ρ) s)

V (e ⊞ e₁)         ρ s = V e₁ ρ s +ᵀ V e ρ s
V (e ⊠ e₁)         ρ s = V e₁ ρ (eval e ρ *ᵃ s) +ᵀ V e ρ (s *ᵃ eval e₁ ρ)
V (scaledown n e)  ρ s = V e ρ (Ar.map (_÷ fromℕ n) s)
V (⊟ e)            ρ s = V e ρ (-ᵃ s)

V (relu e)         ρ s = V e ρ (Ar.map I+ (eval e ρ) *ᵃ s)
V (𝕚+ e)           ρ s = V e ρ (K (fromℕ 0))
V (√ e)            ρ s = V e ρ (s *ᵃ 1/ᵃ ((K (fromℕ 1) +ᵃ K (fromℕ 1)) *ᵃ Ar.map √_ (eval e ρ)))
V (𝟙/ e)           ρ s = V e ρ (-ᵃ (1/ᵃ eval e ρ *ᵃ (s *ᵃ 1/ᵃ eval e ρ)))
V (ln e)           ρ s = V e ρ (s *ᵃ 1/ᵃ eval e ρ)

V (let′ e e₁)      ρ s = tailᵀ t +ᵀ V e ρ (t v₀)
  where t = V e₁ (ρ , eval e ρ) s
V (ℙ e)            ρ s = V e ρ (ℙ-seed (Softmax (eval e ρ)) s)

V-cong : (e : E Γ (ar s)) (ρ : ⟦ Γ ⟧ᶜ) {a b : Ar s R} → a ≈ᵃ b → V e ρ a ≈ᵀ V e ρ b

V-sum-cong : (e : E (Γ ▹ ix s) (ar p)) (ρ : ⟦ Γ ⟧ᶜ) {a b : P s → Ar p R}
           → (∀ k → a k ≈ᵃ b k) → V-sum e ρ a ≈ᵀ V-sum e ρ b
V-sum-cong e ρ p = tailᵀ-cong (Σᵀ-cong λ k → V-cong e (ρ , k) (p k))

-- One-hot arrays at index i.
one-hot-cong : (i k : P s) {a b : Ar p R} → a ≈ᵃ b → one-hotᵃ i a k ≈ᵃ one-hotᵃ i b k
one-hot-cong i k = zb-cong {i = k} {j = i} refl refl

V-cong (var x)          ρ p = 𝕖-cong x p
V-cong 𝟘                ρ p = reflᵀ
V-cong 𝟙                ρ p = reflᵀ

V-cong (imaps e)        ρ p = V-sum-cong e ρ λ k _ → p k
V-cong (imap′ refl e)   ρ p = V-sum-cong e ρ λ k j → p (k ++ j)
V-cong (imapb m e)      ρ p = V-sum-cong e ρ λ k j → p _
V-cong (sum e)          ρ p = V-sum-cong e ρ λ _ → p

V-cong (sels e i)       ρ p = V-cong e ρ λ k → one-hot-cong (eval i ρ) k p []
V-cong (sel′ refl e i)  ρ p = V-cong e ρ λ k → one-hot-cong (eval i ρ) (proj₁ (splitP k)) p _
V-cong (selb m e i)     ρ p = V-cong e ρ λ k → one-hot-cong (eval i ρ) (ix-div k m) p _
V-cong (zero-but i j e) ρ p = V-cong e ρ (zb-cong {i = eval i ρ} {j = eval j ρ} refl refl p)

V-cong (e ⊞ e₁)         ρ p = +ᵀ-cong (V-cong e₁ ρ p) (V-cong e ρ p)
V-cong (e ⊠ e₁)         ρ p = +ᵀ-cong (V-cong e₁ ρ λ i → cong (_ *_) (p i))
                                      (V-cong e ρ λ i → cong (_* _) (p i))
V-cong (scaledown n e)  ρ p = V-cong e ρ λ i → cong (_÷ fromℕ n) (p i)
V-cong (⊟ e)            ρ p = V-cong e ρ λ i → cong -_ (p i)

V-cong (relu e)         ρ p = V-cong e ρ λ i → cong (_ *_) (p i)
V-cong (𝕚+ e)           ρ p = reflᵀ
V-cong (√ e)            ρ p = V-cong e ρ λ i → cong (_* _) (p i)
V-cong (𝟙/ e)           ρ p = V-cong e ρ λ i → cong (λ z → - (_ * (z * _))) (p i)
V-cong (ln e)           ρ p = V-cong e ρ λ i → cong (_* _) (p i)

V-cong (let′ e e₁)      ρ p = +ᵀ-cong (tailᵀ-cong t≈) (V-cong e ρ (t≈ _ v₀))
  where t≈ = V-cong e₁ (ρ , eval e ρ) p
V-cong (ℙ e)            ρ p = V-cong e ρ (ℙ-seed-cong {p = Softmax (eval e ρ)} reflᵃ p)

-- The Jacobian of E in the semantics, and the theorem that the
-- semantic vjp V is the transposed Jacobian applied to the cotangent:
--
--   V e ρ c ≈ Jᵀ (J e ρ) c
--
-- J e ρ i is row i of the Jacobian of e at ρ: the derivatives of
-- element i with respect to all array variables.  It is defined by the
-- usual forward rules; AD.Dual checks it against dual numbers.
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.List.Relation.Unary.All using ([]; _∷_)
open import Relation.Nullary using (yes; no)
open import Function
open import Relation.Binary.PropositionalEquality hiding ([_]; J)
open import Ar
open import Lang
open import Real

module AD.Jacobian (r : Real) (rp : RealProp r) where

open Real.Real r
open RealProp rp
open import Eval r
open import AD.VJP r rp
open import RSum r rp
open ZeroBut rp using (rsum-zb; hot; rsum-hot)

infixl 15 _·ᵀ_
_·ᵀ_ : R → Tan Γ → Tan Γ
(c ·ᵀ t) v = Ar.map (c *_) (t v)

negᵀ : Tan Γ → Tan Γ
negᵀ t v = Ar.map -_ (t v)

zbᵀ : P s → P s → Tan Γ → Tan Γ
zbᵀ a b t v = zb a b (t v)

-- The transposed Jacobian with rows A applied to the cotangent c.
Jᵀ : (P s → Tan Γ) → Ar s R → Tan Γ
Jᵀ A c v j = rsum (λ i → c i * A i v j)

J : E Γ (ar s) → ⟦ Γ ⟧ᶜ → P s → Tan Γ
J (var x)          ρ i = 𝕖 x (hot i)
J 𝟘                ρ i = 0ᵀ
J 𝟙                ρ i = 0ᵀ

J (imaps e)        ρ i = tailᵀ (J e (ρ , i) [])
J (imap′ refl e)   ρ k = tailᵀ (J e (ρ , proj₁ (splitP k)) (proj₂ (splitP k)))
J (imapb m e)      ρ k = tailᵀ (J e (ρ , ix-div k m) (ix-mod k m))
J (sum e)          ρ i = tailᵀ (Σᵀ λ k → J e (ρ , k) i)

J (sels e i)       ρ _ = J e ρ (eval i ρ)
J (sel′ refl e i)  ρ j = J e ρ (eval i ρ ++ j)
J (selb m e i)     ρ j = J e ρ (ix-combine (eval i ρ) j m)
J (zero-but i j e) ρ k = zbᵀ (eval i ρ) (eval j ρ) (J e ρ k)

J (e ⊞ e₁)         ρ i = J e ρ i +ᵀ J e₁ ρ i
J (e ⊠ e₁)         ρ i = eval e₁ ρ i ·ᵀ J e ρ i +ᵀ eval e ρ i ·ᵀ J e₁ ρ i
J (scaledown n e)  ρ i = (fromℕ 1 ÷ fromℕ n) ·ᵀ J e ρ i
J (⊟ e)            ρ i = negᵀ (J e ρ i)

J (relu e)         ρ i = I+ (eval e ρ i) ·ᵀ J e ρ i
J (𝕚+ e)           ρ i = 0ᵀ
J (√ e)            ρ i = 1/ ((fromℕ 1 + fromℕ 1) * (√_ (eval e ρ i))) ·ᵀ J e ρ i
J (𝟙/ e)           ρ i = (- (1/ (eval e ρ i) * 1/ (eval e ρ i))) ·ᵀ J e ρ i
J (ln e)           ρ i = 1/ (eval e ρ i) ·ᵀ J e ρ i

-- Chain rule: the derivative through the bound variable.
J (let′ e e₁)      ρ i = tailᵀ (J e₁ ρ′ i) +ᵀ Jᵀ (J e ρ) (J e₁ ρ′ i v₀)
  where ρ′ = ρ , eval e ρ
-- d (softmax e)ᵢ = smᵢ (d eᵢ - Σₖ smₖ d eₖ)
J (ℙ e)            ρ i = sm i ·ᵀ (J e ρ i +ᵀ negᵀ (Jᵀ (J e ρ) sm))
  where sm = Softmax (eval e ρ)

-- Algebra
*-distʳ : ∀ {x y z} → (x + y) * z ≡ x * z + y * z
*-distʳ = *-comm ∙ dist ∙ cong₂ _+_ *-comm *-comm

rsum-*ʳ : (a : Ar s R) (x : R) → rsum a * x ≡ rsum (λ i → a i * x)
rsum-*ʳ a x = *-comm ∙ rsum-*ˡ x a ∙ rsum-cong′ (λ i → x * a i) (λ i → a i * x) (λ i → *-comm)

-- Properties of Jᵀ
Jᵀ-0 : (c : Ar s R) → Jᵀ {Γ = Γ} (λ _ → 0ᵀ) c ≈ᵀ 0ᵀ
Jᵀ-0 {s = s} c _ v j =
  rsum-cong′ (λ i → c i * fromℕ 0) (λ _ → fromℕ 0) (λ i → *-nulʳ) ∙ rsum-0 {s = s}

Jᵀ-c0 : (A : P s → Tan Γ) → Jᵀ A (K (fromℕ 0)) ≈ᵀ 0ᵀ
Jᵀ-c0 {s = s} A _ v j =
  rsum-cong′ (λ i → fromℕ 0 * A i v j) (λ _ → fromℕ 0) (λ i → *-nulˡ) ∙ rsum-0 {s = s}

Jᵀ-+ : (A B : P s → Tan Γ) (c : Ar s R) → Jᵀ (λ i → A i +ᵀ B i) c ≈ᵀ Jᵀ A c +ᵀ Jᵀ B c
Jᵀ-+ A B c _ v j =
  rsum-cong′ (λ i → c i * (A i v j + B i v j)) (λ i → c i * A i v j + c i * B i v j) (λ i → dist)
  ∙ rsum-+ (λ i → c i * A i v j) (λ i → c i * B i v j)

Jᵀ-comp : (B : P q → Tan Γ) (C : P s → Ar q R) (c : Ar s R)
        → Jᵀ (λ i → Jᵀ B (C i)) c ≈ᵀ Jᵀ B (λ k → rsum (λ i → c i * C i k))
Jᵀ-comp B C c _ v j =
  rsum-cong′ (λ i → c i * rsum (λ k → C i k * B k v j)) (λ i → rsum (λ k → c i * (C i k * B k v j)))
          (λ i → rsum-*ˡ (c i) (λ k → C i k * B k v j))
  ∙ rsum-swap (λ i k → c i * (C i k * B k v j))
  ∙ rsum-cong′ (λ k → rsum (λ i → c i * (C i k * B k v j))) (λ k → rsum (λ i → c i * C i k) * B k v j)
            (λ k → rsum-cong′ (λ i → c i * (C i k * B k v j)) (λ i → c i * C i k * B k v j)
                           (λ i → sym *-assoc)
                   ∙ sym (rsum-*ʳ (λ i → c i * C i k) (B k v j)))

-- Loops: the rows of a loop are the rows of its body, reindexed.
Jᵀ-loop : (sp : Split s p q) (A : P s → P p → Tan (Γ ▹ ix s)) (c : Ar q R)
        → tailᵀ (Σᵀ λ k → Jᵀ (A k) (λ l → c (Split.comb sp k l)))
          ≈ᵀ Jᵀ (λ i → tailᵀ (A (Split.fst sp i) (Split.snd sp i))) c
Jᵀ-loop sp A c _ v j =
  rsum-inv (λ k → Jᵀ (A k) (λ l → c (comb k l)) (there v)) j
  ∙ sym (rsum-split (λ i → c i * A (fst i) (snd i) (there v) j)
         ∙ rsum-cong′ (λ k → rsum (λ l → c (comb k l) * A (fst (comb k l)) (snd (comb k l)) (there v) j))
                   (λ k → rsum (λ l → c (comb k l) * A k l (there v) j))
                   (λ k → rsum-cong′ (λ l → c (comb k l) * A (fst (comb k l)) (snd (comb k l)) (there v) j)
                                  (λ l → c (comb k l) * A k l (there v) j)
                                  (λ l → cong₂ (λ a b → c (comb k l) * A a b (there v) j)
                                               (fst-comb k l) (snd-comb k l))))
  where open Split sp

-- Selections: a one-hot cotangent selects rows.
Jᵀ-select : (sp : Split s p q) (A : P q → Tan Γ) (a : P s) (c : Ar p R)
          → Jᵀ A (λ i → zb (Split.fst sp i) a c (Split.snd sp i)) ≈ᵀ Jᵀ (λ j → A (Split.comb sp a j)) c
Jᵀ-select sp A a c _ v j =
  rsum-split (λ i → zb (fst i) a c (snd i) * A i v j)
  ∙ rsum-cong′ (λ k → rsum (λ l → zb (fst (comb k l)) a c (snd (comb k l)) * A (comb k l) v j))
            (λ k → rsum (λ l → zb k a c l * A (comb k l) v j))
            (λ k → rsum-cong′ (λ l → zb (fst (comb k l)) a c (snd (comb k l)) * A (comb k l) v j)
                           (λ l → zb k a c l * A (comb k l) v j)
                           (λ l → cong₂ (λ a′ b′ → zb a′ a c b′ * A (comb k l) v j)
                                        (fst-comb k l) (snd-comb k l)))
  ∙ rsum-swap (λ k l → zb k a c l * A (comb k l) v j)
  ∙ rsum-cong′ (λ l → rsum (λ k → zb k a c l * A (comb k l) v j)) (λ l → c l * A (comb a l) v j)
            (λ l → rsum-zb a c l (λ k → A (comb k l) v j))
  where open Split sp

-- Sums: the rows of a sum are the sums of the rows.
Jᵀ-Σᵀ : (A : P q → P s → Tan Γ) (c : Ar s R) → Jᵀ (λ i → Σᵀ (λ k → A k i)) c ≈ᵀ Σᵀ (λ k → Jᵀ (A k) c)
Jᵀ-Σᵀ A c _ v j =
  rsum-cong′ (λ i → c i * Σᵀ (λ k → A k i) v j) (λ i → rsum (λ k → c i * A k i v j))
          (λ i → cong₂ _*_ refl (rsum-inv (λ k → A k i v) j) ∙ rsum-*ˡ (c i) (λ k → A k i v j))
  ∙ rsum-swap (λ i k → c i * A k i v j)
  ∙ sym (rsum-inv (λ k → Jᵀ (A k) c v) j)

-- The proof that V is the transposed Jacobian.
V-J : (e : E Γ (ar s)) (ρ : ⟦ Γ ⟧ᶜ) (c : Ar s R) → V e ρ c ≈ᵀ Jᵀ (J e ρ) c

V-sum-J : (e : E (Γ ▹ ix s) (ar p)) (ρ : ⟦ Γ ⟧ᶜ) (c : P s → Ar p R)
        → V-sum e ρ c ≈ᵀ tailᵀ (Σᵀ λ k → Jᵀ (J e (ρ , k)) (c k))
V-sum-J e ρ c = tailᵀ-cong (Σᵀ-cong λ k → V-J e (ρ , k) (c k))

-- Cases where the seed is scaled pointwise.
scale : (e : E Γ (ar s)) (ρ : ⟦ Γ ⟧ᶜ) (c c′ k : Ar s R) → (∀ i → c′ i ≡ c i * k i)
      → V e ρ c′ ≈ᵀ Jᵀ (λ i → k i ·ᵀ J e ρ i) c
scale e ρ c c′ k eq _ v j =
  V-J e ρ c′ _ v j
  ∙ rsum-cong′ (λ i → c′ i * J e ρ i v j) (λ i → c i * (k i * J e ρ i v j))
            (λ i → cong₂ _*_ (eq i) refl ∙ *-assoc)

V-J {s = s} (var x) ρ c _ v j with eq? x v
... | veq     = sym (rsum-hot c j)
... | neq _ _ = sym (rsum-cong′ (λ i → c i * fromℕ 0) (λ _ → fromℕ 0) (λ i → *-nulʳ) ∙ rsum-0 {s = s})
V-J 𝟘                ρ c = symᵀ (Jᵀ-0 c)
V-J 𝟙                ρ c = symᵀ (Jᵀ-0 c)

V-J (imaps e)        ρ c = V-sum-J e ρ (λ k → K (c k)) ∙ᵀ Jᵀ-loop unit-split (λ k → J e (ρ , k)) c
V-J (imap′ refl e)   ρ c = V-sum-J e ρ (nest c) ∙ᵀ Jᵀ-loop ⊗-split (λ k → J e (ρ , k)) c
V-J (imapb m e)      ρ c = V-sum-J e ρ (Ar.selb c m) ∙ᵀ Jᵀ-loop (block-split m) (λ k → J e (ρ , k)) c
V-J (sum e)          ρ c = V-sum-J e ρ (λ _ → c) ∙ᵀ tailᵀ-cong (symᵀ (Jᵀ-Σᵀ (λ k → J e (ρ , k)) c))

V-J (sels e i)       ρ c = V-J e ρ (λ k → one-hotᵃ (eval i ρ) c k [])
                           ∙ᵀ Jᵀ-select unit-split (J e ρ) (eval i ρ) c
V-J (sel′ refl e i)  ρ c = V-J e ρ (unnest (one-hotᵃ (eval i ρ) c))
                           ∙ᵀ Jᵀ-select ⊗-split (J e ρ) (eval i ρ) c
V-J (selb m e i)     ρ c = V-J e ρ (Ar.imapb (one-hotᵃ (eval i ρ) c) m)
                           ∙ᵀ Jᵀ-select (block-split m) (J e ρ) (eval i ρ) c
V-J (zero-but i j e) ρ c _ v l = V-J e ρ (zb (eval i ρ) (eval j ρ) c) _ v l ∙ go
  where
    go : rsum (λ k → zb (eval i ρ) (eval j ρ) c k * J e ρ k v l)
       ≡ rsum (λ k → c k * zb (eval i ρ) (eval j ρ) (J e ρ k v) l)
    go with eval i ρ ≟ₚ eval j ρ
    ... | yes _ = refl
    ... | no _  = rsum-cong′ (λ k → fromℕ 0 * J e ρ k v l) (λ k → c k * fromℕ 0)
                          (λ k → *-nulˡ ∙ sym *-nulʳ)

V-J (e ⊞ e₁)         ρ c _ v j =
  cong₂ _+_ (V-J e₁ ρ c _ v j) (V-J e ρ c _ v j)
  ∙ +-comm
  ∙ sym (Jᵀ-+ (J e ρ) (J e₁ ρ) c _ v j)
V-J (e ⊠ e₁)         ρ c _ v j =
  cong₂ _+_ (V-J e₁ ρ (eval e ρ *ᵃ c) _ v j) (V-J e ρ (c *ᵃ eval e₁ ρ) _ v j)
  ∙ +-comm
  ∙ cong₂ _+_ (rsum-cong′ (λ i → c i * eval e₁ ρ i * J e ρ i v j)
                       (λ i → c i * (eval e₁ ρ i * J e ρ i v j)) λ i → *-assoc)
              (rsum-cong′ (λ i → eval e ρ i * c i * J e₁ ρ i v j)
                       (λ i → c i * (eval e ρ i * J e₁ ρ i v j))
                       λ i → cong₂ _*_ *-comm refl ∙ *-assoc)
  ∙ sym (Jᵀ-+ (λ i → eval e₁ ρ i ·ᵀ J e ρ i) (λ i → eval e ρ i ·ᵀ J e₁ ρ i) c _ v j)
V-J (scaledown n e)  ρ c =
  scale e ρ c (Ar.map (_÷ fromℕ n) c) (λ _ → fromℕ 1 ÷ fromℕ n) λ i → ÷-*
V-J (⊟ e)            ρ c _ v j =
  V-J e ρ (-ᵃ c) _ v j
  ∙ rsum-cong′ (λ i → (- c i) * J e ρ i v j) (λ i → c i * (- J e ρ i v j))
            (λ i → minus-*-pushˡ ∙ sym minus-*-pushʳ)

V-J (relu e)         ρ c =
  scale e ρ c (Ar.map I+ (eval e ρ) *ᵃ c) (λ i → I+ (eval e ρ i)) λ i → *-comm
V-J (𝕚+ e)           ρ c = V-J e ρ (K (fromℕ 0)) ∙ᵀ Jᵀ-c0 (J e ρ) ∙ᵀ symᵀ (Jᵀ-0 c)
V-J (√ e)            ρ c =
  scale e ρ c (c *ᵃ 1/ᵃ ((K (fromℕ 1) +ᵃ K (fromℕ 1)) *ᵃ Ar.map √_ (eval e ρ)))
              (λ i → 1/ ((fromℕ 1 + fromℕ 1) * (√_ (eval e ρ i)))) λ i → refl
V-J (𝟙/ e)           ρ c =
  scale e ρ c (-ᵃ (1/ᵃ eval e ρ *ᵃ (c *ᵃ 1/ᵃ eval e ρ)))
              (λ i → - (1/ (eval e ρ i) * 1/ (eval e ρ i))) λ i →
  cong -_ (sym *-assoc ∙ cong₂ _*_ *-comm refl ∙ *-assoc) ∙ sym minus-*-pushʳ
V-J (ln e)           ρ c =
  scale e ρ c (c *ᵃ 1/ᵃ eval e ρ) (λ i → 1/ (eval e ρ i)) λ i → refl

V-J (let′ e e₁)      ρ c _ v j =
  cong₂ _+_ (V-J e₁ ρ′ c _ (there v) j)
            (V-cong e ρ (V-J e₁ ρ′ c _ v₀) _ v j ∙ V-J e ρ (Jᵀ (J e₁ ρ′) c v₀) _ v j)
  ∙ cong₂ _+_ refl (sym (Jᵀ-comp (J e ρ) (λ i → J e₁ ρ′ i v₀) c _ v j))
  ∙ sym (Jᵀ-+ (λ i → tailᵀ (J e₁ ρ′ i)) (λ i → Jᵀ (J e ρ) (J e₁ ρ′ i v₀)) c _ v j)
  where ρ′ = ρ , eval e ρ

V-J (ℙ e)            ρ c _ v j =
  V-J e ρ (ℙ-seed sm c) _ v j
  ∙ rsum-cong′ (λ k → sm k * (c k + - D) * 𝕏 k) (λ k → c k * sm k * 𝕏 k + - (D * (sm k * 𝕏 k))) lhs
  ∙ rsum-+ (λ k → c k * sm k * 𝕏 k) (λ k → - (D * (sm k * 𝕏 k)))
  ∙ cong₂ _+_ refl (rsum-neg (λ k → D * (sm k * 𝕏 k)) ∙ cong -_ (sym (rsum-*ˡ D (λ k → sm k * 𝕏 k))))
  ∙ cong₂ _+_ refl (cong (λ z → - (z * Q)) D≡)
  ∙ sym (rsum-cong′ (λ i → c i * (sm i * (𝕏 i + - Q))) (λ i → c i * sm i * 𝕏 i + - (c i * sm i * Q)) rhs
         ∙ rsum-+ (λ i → c i * sm i * 𝕏 i) (λ i → - (c i * sm i * Q))
         ∙ cong₂ _+_ refl (rsum-neg (λ i → c i * sm i * Q) ∙ cong -_ (sym (rsum-*ʳ (λ i → c i * sm i) Q))))
  where
    sm = Softmax (eval e ρ)
    𝕏 : P _ → R
    𝕏 k = J e ρ k v j
    Q = rsum (λ k → sm k * 𝕏 k)
    D = Ar.sum (zipWith _+_) (K (fromℕ 0)) (λ i → K (zipWith _*_ c sm i)) []
    D≡ : D ≡ rsum (λ i → c i * sm i)
    D≡ = rsum-inv (λ i → K (zipWith _*_ c sm i)) []

    lhs : ∀ k → sm k * (c k + - D) * 𝕏 k ≡ c k * sm k * 𝕏 k + - (D * (sm k * 𝕏 k))
    lhs k = cong (_* 𝕏 k) (dist ∙ cong₂ _+_ refl minus-*-pushʳ)
          ∙ *-distʳ
          ∙ cong₂ _+_ (cong (_* 𝕏 k) *-comm)
                      (minus-*-pushˡ ∙ cong -_ (cong (_* 𝕏 k) *-comm ∙ *-assoc))

    rhs : ∀ i → c i * (sm i * (𝕏 i + - Q)) ≡ c i * sm i * 𝕏 i + - (c i * sm i * Q)
    rhs i = cong₂ _*_ refl (dist ∙ cong₂ _+_ refl minus-*-pushʳ)
          ∙ dist
          ∙ cong₂ _+_ (sym *-assoc) (minus-*-pushʳ ∙ cong -_ (sym *-assoc))

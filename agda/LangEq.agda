-- {-# OPTIONS --warn=noUserWarning #-}
module _ where
  open import Ar hiding (sum; slide; backslide; imapb; selb)
  open import Relation.Binary.PropositionalEquality
  open import Data.Product
  open import Data.Nat using (ℕ; zero; suc; _≟_)
  open import Data.List as L
  open import Data.List.Properties as L
  open import Relation.Nullary
  open import Function
  open import Lang
  open import Ar

  -- Equality of types
  _≟ⁱ_ : (a b : IS) → Dec (a ≡ b)
  ix x ≟ⁱ ix y with x ≟ˢ y
  ... | no ¬p = no λ { refl → ¬p refl }
  ... | yes refl = yes refl
  ix x ≟ⁱ ar y = no λ ()
  ar x ≟ⁱ ix y = no λ ()
  ar x ≟ⁱ ar y with x ≟ˢ y
  ... | no ¬p = no λ { refl → ¬p refl }
  ... | yes refl = yes refl

  _≟ᵏ_ : (a b : Kop) → Dec (a ≡ b)
  zero-op ≟ᵏ zero-op = yes refl
  zero-op ≟ᵏ one-op = no λ ()
  one-op ≟ᵏ zero-op = no λ ()
  one-op ≟ᵏ one-op = yes refl

  _≟ᵒ_ : (a b : Bop) → Dec (a ≡ b)
  plus-op ≟ᵒ plus-op = yes refl
  plus-op ≟ᵒ mul-op = no λ ()
  mul-op ≟ᵒ plus-op = no λ ()
  mul-op ≟ᵒ mul-op = yes refl

  _≟ᵘ_ : (a b : Uop) → Dec (a ≡ b)
  -- logistic ≟ᵘ logistic = yes refl
  -- logistic ≟ᵘ neg-op = no λ ()
  -- logistic ≟ᵘ relu-op = no λ ()
  -- logistic ≟ᵘ sqrt-op = no λ ()
  -- logistic ≟ᵘ inv-op = no λ ()
  -- logistic ≟ᵘ indp-op = no λ ()
  -- logistic ≟ᵘ ln-op = no λ ()
  -- neg-op ≟ᵘ logistic = no λ ()
  neg-op ≟ᵘ neg-op = yes refl
  neg-op ≟ᵘ relu-op = no λ ()
  neg-op ≟ᵘ sqrt-op = no λ ()
  neg-op ≟ᵘ inv-op = no λ ()
  neg-op ≟ᵘ indp-op = no λ ()
  neg-op ≟ᵘ ln-op = no λ ()
  -- relu-op ≟ᵘ logistic = no λ ()
  relu-op ≟ᵘ neg-op = no λ ()
  relu-op ≟ᵘ relu-op = yes refl
  relu-op ≟ᵘ sqrt-op = no λ ()
  relu-op ≟ᵘ inv-op = no λ ()
  relu-op ≟ᵘ indp-op = no λ ()
  relu-op ≟ᵘ ln-op = no λ ()
  -- sqrt-op ≟ᵘ logistic = no λ ()
  sqrt-op ≟ᵘ neg-op = no λ ()
  sqrt-op ≟ᵘ relu-op = no λ ()
  sqrt-op ≟ᵘ sqrt-op = yes refl
  sqrt-op ≟ᵘ inv-op = no λ ()
  sqrt-op ≟ᵘ indp-op = no λ ()
  sqrt-op ≟ᵘ ln-op = no λ ()
  -- inv-op ≟ᵘ logistic = no λ ()
  inv-op ≟ᵘ neg-op = no λ ()
  inv-op ≟ᵘ relu-op = no λ ()
  inv-op ≟ᵘ sqrt-op = no λ ()
  inv-op ≟ᵘ inv-op = yes refl
  inv-op ≟ᵘ indp-op = no λ ()
  inv-op ≟ᵘ ln-op = no λ ()
  -- indp-op ≟ᵘ logistic = no λ ()
  indp-op ≟ᵘ neg-op = no λ ()
  indp-op ≟ᵘ relu-op = no λ ()
  indp-op ≟ᵘ sqrt-op = no λ ()
  indp-op ≟ᵘ inv-op = no λ ()
  indp-op ≟ᵘ indp-op = yes refl
  indp-op ≟ᵘ ln-op = no λ ()
  -- ln-op ≟ᵘ logistic = no λ ()
  ln-op ≟ᵘ neg-op = no λ ()
  ln-op ≟ᵘ relu-op = no λ ()
  ln-op ≟ᵘ sqrt-op = no λ ()
  ln-op ≟ᵘ inv-op = no λ ()
  ln-op ≟ᵘ indp-op = no λ ()
  ln-op ≟ᵘ ln-op = yes refl
  -- softmax-op ≟ᵘ logistic = no λ ()
  softmax-op ≟ᵘ neg-op = no λ ()
  softmax-op ≟ᵘ relu-op = no λ ()
  softmax-op ≟ᵘ sqrt-op = no λ ()
  softmax-op ≟ᵘ inv-op = no λ ()
  softmax-op ≟ᵘ indp-op = no λ ()
  softmax-op ≟ᵘ ln-op = no λ ()
  -- logistic ≟ᵘ softmax-op = no λ ()
  neg-op ≟ᵘ softmax-op = no λ ()
  relu-op ≟ᵘ softmax-op = no λ ()
  sqrt-op ≟ᵘ softmax-op = no λ ()
  inv-op ≟ᵘ softmax-op = no λ ()
  indp-op ≟ᵘ softmax-op = no λ ()
  ln-op ≟ᵘ softmax-op = no λ ()
  softmax-op ≟ᵘ softmax-op = yes refl
  neg-op ≟ᵘ scaledown-op x = no λ ()
  relu-op ≟ᵘ scaledown-op x = no λ ()
  sqrt-op ≟ᵘ scaledown-op x = no λ ()
  inv-op ≟ᵘ scaledown-op x = no λ ()
  indp-op ≟ᵘ scaledown-op x = no λ ()
  ln-op ≟ᵘ scaledown-op x = no λ ()
  softmax-op ≟ᵘ scaledown-op x = no λ ()
  scaledown-op x ≟ᵘ neg-op = no λ ()
  scaledown-op x ≟ᵘ relu-op = no λ ()
  scaledown-op x ≟ᵘ sqrt-op = no λ ()
  scaledown-op x ≟ᵘ inv-op = no λ ()
  scaledown-op x ≟ᵘ indp-op = no λ ()
  scaledown-op x ≟ᵘ ln-op = no λ ()
  scaledown-op x ≟ᵘ softmax-op = no λ ()
  scaledown-op x ≟ᵘ scaledown-op y with x ≟ y
  ... | no a = no λ b → a (scaledown-inj b)
  ... | yes refl = yes refl

  -- Hail UIP
  *≈-uopiq : (a b : s * p ≈ q) → a ≡ b
  *≈-uopiq {[]} {[]} {[]} [] [] = refl
  *≈-uopiq {x ∷ s} {x₁ ∷ p} {x₂ ∷ q} (cons ⦃ refl ⦄ ⦃ a ⦄) (cons ⦃ refl ⦄ ⦃ b ⦄)
    = cong₂ (λ t u → cons ⦃ t ⦄ ⦃ u ⦄) refl (*≈-uopiq a b)

  +≈-uopiq : (a b : s + p ≈ q) → a ≡ b
  +≈-uopiq {[]} {[]} {[]} [] [] = refl
  +≈-uopiq {x ∷ s} {x₁ ∷ p} {x₂ ∷ q} (cons ⦃ refl ⦄ ⦃ a ⦄) (cons ⦃ refl ⦄ ⦃ b ⦄)
    = cong₂ (λ t u → cons ⦃ t ⦄ ⦃ u ⦄) refl (+≈-uopiq a b)

  suc≈-uopiq : (a b : suc s ≈ p) → a ≡ b
  suc≈-uopiq [] [] = refl
  suc≈-uopiq (cons ⦃ refl ⦄ ⦃ a ⦄) (cons ⦃ refl ⦄ ⦃ b ⦄) = cong₂ (λ t u → cons ⦃ t ⦄ ⦃ u ⦄) refl (suc≈-uopiq a b)

  uopiq : {a b : s ≡ p} → a ≡ b
  uopiq {a = refl} {b = refl} = refl

  _≟ᵐ_ : ∀ {s p q} (a : Mop s p q) → (b : Mop s p q) → Dec (a ≡ b)
  imaps-op ≟ᵐ imaps-op = yes refl
  imaps-op ≟ᵐ imap-op x = no λ ()
  imaps-op ≟ᵐ imapb-op x = no λ ()
  imaps-op ≟ᵐ sum-op = no λ ()
  imap-op x ≟ᵐ imaps-op = no λ ()
  imap-op x ≟ᵐ imap-op x₁ = yes (cong imap-op uopiq)
  imap-op x ≟ᵐ imapb-op x₁ = no λ ()
  imap-op x ≟ᵐ sum-op = no λ ()
  imapb-op x ≟ᵐ imaps-op = no λ ()
  imapb-op x ≟ᵐ imap-op x₁ = no λ ()
  imapb-op x ≟ᵐ imapb-op x₁ = yes (cong imapb-op (*≈-uopiq _ _))
  imapb-op x ≟ᵐ sum-op = no λ ()
  sum-op ≟ᵐ imaps-op = no λ ()
  sum-op ≟ᵐ imap-op x = no λ ()
  sum-op ≟ᵐ imapb-op x = no λ ()
  sum-op ≟ᵐ sum-op = yes refl

  _≟ᶜ_ : ∀ {s p q} (a : Sop s p q) → (b : Sop s p q) → Dec (a ≡ b)
  sels-op ≟ᶜ sels-op = yes refl
  sels-op ≟ᶜ sel-op x = no λ ()
  sels-op ≟ᶜ selb-op x = no λ ()
  sel-op x ≟ᶜ sels-op = no λ ()
  sel-op x ≟ᶜ sel-op x₁ = yes (cong sel-op uopiq)
  sel-op x ≟ᶜ selb-op x₁ = no λ ()
  selb-op x ≟ᶜ sels-op = no λ ()
  selb-op x ≟ᶜ sel-op x₁ = no λ ()
  selb-op x ≟ᶜ selb-op x₁ = yes (cong selb-op (*≈-uopiq _ _))

  isVar : (e : E Γ is) → Dec (∃ λ v → e ≡ var v)
  isVar (var x) = yes (x , refl)
  isVar 𝟘 = no λ ()
  isVar 𝟙 = no λ ()
  isVar (imaps e) = no λ ()
  isVar (sels e e₁) = no λ ()
  isVar (imap′ refl e) = no λ ()
  isVar (sel′ refl e e₁) = no λ ()
  isVar (imapb x e) = no λ ()
  isVar (selb x e e₁) = no λ ()
  isVar (Lang.sum e) = no λ ()
  isVar (zero-but e e₁ e₂) = no λ ()
  -- isVar (slide e x e₁ x₁) = no λ ()
  -- isVar (backslide e e₁ x x₁) = no λ ()
  isVar (bop x e e₁) = no λ ()
  isVar (scaledown x e) = no λ ()
  isVar (let′ e e₁) = no λ ()
  -- Jairo made
  isVar (uop x e) = no λ ()

  isKop : (e : E Γ (ar s)) → Dec (∃ λ t → e ≡ kop t)
  isKop (var x) = no λ ()
  isKop (kop x) = yes (x , refl)
  isKop (uop x e) = no λ ()
  isKop (bop x e e₁) = no λ ()
  isKop (mop x e) = no λ ()
  isKop (sop x e e₁) = no λ ()
  isKop (zero-but e e₁ e₂) = no λ ()
  isKop (let′ e e₁) = no λ ()

  isUop : (e : E Γ (ar s)) → Dec (∃₂ λ a b → e ≡ uop a b)
  isUop (var x) = no λ ()
  isUop (kop x) = no λ ()
  isUop (uop x e) = yes (x , e , refl)
  isUop (bop x e e₁) = no λ ()
  isUop (mop x e) = no λ ()
  isUop (sop x e e₁) = no λ ()
  isUop (zero-but e e₁ e₂) = no λ ()
  isUop (let′ e e₁) = no λ ()

  isBop : (e : E Γ (ar s)) → Dec (∃₂ λ o t → ∃ λ t₁ → e ≡ bop o t t₁)
  isBop (var x) = no λ ()
  isBop (kop x) = no λ ()
  isBop (uop x e) = no λ ()
  isBop (bop x e e₁) = yes (x , e , e₁ , refl)
  isBop (mop x e) = no λ ()
  isBop (sop x e e₁) = no λ ()
  isBop (zero-but e e₁ e₂) = no λ ()
  isBop (let′ e e₁) = no λ ()

  isMop : (e : E Γ (ar s))
    → Dec (∃₂ (λ p q → ∃₂ (λ x t → e ≡ mop {p} {q} x t)))
  isMop (var x) = no λ ()
  isMop (kop x) = no λ ()
  isMop (uop x e) = no λ ()
  isMop (bop x e e₁) = no λ ()
  isMop (mop {p} {q} x e) = yes (p , q , x , e , refl)
  isMop (sop x e e₁) = no λ ()
  isMop (zero-but e e₁ e₂) = no λ ()
  isMop (let′ e e₁) = no λ ()

  isSop : (e : E Γ (ar s))
    → Dec (∃₂ (λ p q → ∃ (λ x → ∃₂ (λ a b → e ≡ sop {p} {q} x a b))))
  isSop (var x) = no λ ()
  isSop (kop x) = no λ ()
  isSop (uop x e) = no λ ()
  isSop (bop x e e₁) = no λ ()
  isSop (mop x e) = no λ ()
  isSop (sop {p} {q} x e e₁) = yes (p , q , x , e , e₁ , refl)
  isSop (zero-but e e₁ e₂) = no λ ()
  isSop (let′ e e₁) = no λ ()

  isZero : (e : E Γ (ar s)) → Dec (e ≡ 𝟘)
  isZero 𝟘 = yes refl
  isZero (var x) = no  λ ()
  isZero 𝟙 = no λ ()
  isZero (imaps e) = no λ ()
  isZero (sels e e₁) = no λ ()
  isZero (imap′ refl e) = no λ ()
  isZero (sel′ refl e e₁) = no λ ()
  isZero (Lang.imapb x e) = no λ ()
  isZero (Lang.selb x e e₁) = no λ ()
  isZero (Lang.sum e) = no λ ()
  isZero (zero-but e e₁ e₂) = no λ ()
  -- isZero (E.slide e x e₁ x₁) = no λ ()
  -- isZero (E.backslide e e₁ x x₁) = no λ ()
  isZero (bop x e e₁) = no λ ()
  isZero (scaledown x e) = no λ ()
  isZero (let′ e e₁) = no λ ()
  -- Jairo made
  isZero (uop x e) = no λ ()
  -- isZero (argmax pf e) = no λ ()

  isOne : (e : E Γ (ar s)) → Dec (e ≡ 𝟙)
  isOne 𝟘 = no λ ()
  isOne (var x) = no λ ()
  isOne 𝟙 = yes refl
  isOne (imaps e) = no λ ()
  isOne (sels e e₁) = no λ ()
  isOne (imap′ refl e) = no λ ()
  isOne (sel′ refl e e₁) = no λ ()
  isOne (Lang.imapb x e) = no λ ()
  isOne (Lang.selb x e e₁) = no λ ()
  isOne (Lang.sum e) = no λ ()
  isOne (zero-but e e₁ e₂) = no λ ()
  -- isOne (E.slide e x e₁ x₁) = no λ ()
  -- isOne (E.backslide e e₁ x x₁) = no λ ()
  isOne (bop x e e₁) = no λ ()
  isOne (scaledown x e) = no λ ()
  isOne (let′ e e₁) = no λ ()
  -- Jairo made
  isOne (uop x e) = no λ ()
  -- isOne (argmax pf e) = no λ ()

  isImap : (e : E Γ (ar q))
         → Dec (∃₂ λ s p
                → Σ (s L.++ p ≡ q) λ eq → ∃ λ u → subst (E Γ ∘ ar) (sym eq) e ≡ imap {s = s} u)
  isImap (var x) = no λ { (_ , _ , refl , _ , ()) }
  isImap 𝟘 = no λ { (_ , _ , refl , _ , ()) }
  isImap 𝟙 = no λ { (_ , _ , refl , _ , ()) }
  isImap (imaps e) = no λ { (_ , _ , refl , _ , ()) }
  isImap (sels e e₁) = no λ { ([] , [] , refl , _ , ())  }
  isImap (imap′ refl e) = yes (_ , _ , refl , e , refl)
  isImap (sel′ refl e e₁) = no λ { (_ , _ , refl , _ , ()) }
  isImap (Lang.imapb x e) = no λ { (_ , _ , refl , _ , ()) }
  isImap (Lang.selb x e e₁) = no λ { (_ , _ , refl , _ , ()) }
  isImap (Lang.sum e) = no λ { (_ , _ , refl , _ , ()) }
  isImap (zero-but e e₁ e₂) = no λ { (_ , _ , refl , _ , ()) }
  -- isImap (E.slide e x e₁ x₁) = no λ { (_ , _ , refl , _ , ()) }
  -- isImap (E.backslide e e₁ x x₁) = no λ { (_ , _ , refl , _ , ()) }
  isImap (bop x e e₁) = no λ { (_ , _ , refl , _ , ()) }
  isImap (scaledown x e) = no λ { (_ , _ , refl , _ , ()) }
  isImap (let′ e e₁) = no λ { (_ , _ , refl , _ , ()) }
  isImap (uop x e) = no λ { (_ , _ , refl , _ , ()) }
  -- isImap (argmax pf e) = no λ { (_ , _ , refl , _ , ()) }


  isImaps : (e : E Γ (ar s)) → Dec (∃ λ u → e ≡ imaps u)
  isImaps (var x) = no λ ()
  isImaps 𝟘 = no λ ()
  isImaps 𝟙 = no λ ()
  isImaps (imaps e) = yes (e , refl)
  isImaps (sels e e₁) = no λ ()
  isImaps (imap′ refl e) = no λ ()
  isImaps (sel′ refl e e₁) = no λ ()
  isImaps (Lang.imapb x e) = no λ ()
  isImaps (Lang.selb x e e₁) = no λ ()
  isImaps (Lang.sum e) = no λ ()
  isImaps (zero-but e e₁ e₂) = no λ ()
  -- isImaps (E.slide e x e₁ x₁) = no λ ()
  -- isImaps (E.backslide e e₁ x x₁) = no λ ()
  isImaps (bop x e e₁) = no λ ()
  isImaps (scaledown x e) = no λ ()
  isImaps (let′ e e₁) = no λ ()
  isImaps (uop x e) = no λ ()
  -- isImaps (argmax pf e) = no λ ()

  isZeroBut : (e : E Γ (ar p)) → Dec (∃₂ λ s i → ∃₂ λ j u → e ≡ zero-but {s = s} i j u)
  isZeroBut (var x) = no λ ()
  isZeroBut 𝟘 = no λ ()
  isZeroBut 𝟙 = no λ ()
  isZeroBut (imaps e) = no λ ()
  isZeroBut (sels e e₁) = no λ ()
  isZeroBut (imap′ refl e) = no λ ()
  isZeroBut (sel′ refl e e₁) = no λ ()
  isZeroBut (Lang.imapb x e) = no λ ()
  isZeroBut (Lang.selb x e e₁) = no λ ()
  isZeroBut (Lang.sum e) = no λ ()
  isZeroBut (zero-but e e₁ e₂) = yes (_ , e , e₁ , e₂ , refl)
  -- isZeroBut (E.slide e x e₁ x₁) = no λ ()
  -- isZeroBut (E.backslide e e₁ x x₁) = no λ ()
  isZeroBut (bop x e e₁) = no λ ()
  isZeroBut (scaledown x e) = no λ ()
  isZeroBut (let′ e e₁) = no λ ()
  isZeroBut (uop x e) = no λ ()
  -- isZeroBut (argmax pf e) = no λ ()

  isSels : (e : E Γ (ar p)) (s : S) → Dec (Σ (p ≡ []) λ eq → ∃₂ λ t u → subst (E Γ ∘ ar) eq e ≡ sels {s = s} t u)
  isSels (var x) s = no λ { (refl , _ , _ , ()) }
  isSels 𝟘 s = no λ { (refl , _ , _ , ()) }
  isSels 𝟙 s = no λ { (refl , _ , _ , ()) }
  isSels (imaps e) s = no λ { (refl , _ , _ , ()) }
  isSels (sels {s = s′} e e₁) s with s′ ≟ˢ s
  ... | no ¬p = no λ { (refl , t , u , refl) → ¬p refl }
  ... | yes refl = yes (refl , e , e₁ , refl)
  isSels (imap′ {s = s} refl e) s′ = no foo
    where foo : _
          foo (eq , t , u , x) with ++-[]₁ {s = s} eq
          foo (eq , t , u , x) | rr rewrite rr | eq with x
          ... | ()
  isSels (sel′ refl e e₁) s = no λ { (refl , _ , _ , ()) }
  isSels (Lang.imapb x e) s = no λ { (refl , _ , _ , ()) }
  isSels (Lang.selb x e e₁) s = no λ { (refl , _ , _ , ()) }
  isSels (Lang.sum e) s = no λ { (refl , _ , _ , ()) }
  isSels (zero-but e e₁ e₂) s = no λ { (refl , _ , _ , ()) }
  -- isSels (E.slide e x e₁ x₁) s = no λ { (refl , _ , _ , ()) }
  -- isSels (E.backslide e e₁ x x₁) s = no λ { (refl , _ , _ , ()) }
  isSels (bop x e e₁) s = no λ { (refl , _ , _ , ()) }
  isSels (scaledown x e) s = no λ { (refl , _ , _ , ()) }
  isSels (let′ e e₁) s = no λ { (refl , _ , _ , ()) }
  isSels (uop x e) s = no λ { (refl , _ , _ , ()) }
  -- isSels (argmax pf e) s = no λ { (refl , _ , _ , ()) }

  isSel :  (e : E Γ (ar p)) → Dec (∃ λ s → ∃₂ λ t u → e ≡ sel {s = s}{p} t u)
  isSel (var x) = no λ { (_ , _ , _ , ()) }
  isSel 𝟘 = no λ { (_ , _ , _ , ()) }
  isSel 𝟙 = no λ { (_ , _ , _ , ()) }
  isSel (imaps e) = no λ { (_ , _ , _ , ()) }
  isSel (sels e e₁) = no λ { (_ , _ , _ , ()) }
  isSel (imap′ refl e) = no λ { (_ , _ , _ , ()) }
  isSel (sel′ refl e e₁) = yes (_ , e , e₁ , refl)
  isSel (Lang.imapb x e) = no λ { (_ , _ , _ , ()) }
  isSel (Lang.selb x e e₁) = no λ { (_ , _ , _ , ()) }
  isSel (Lang.sum e) = no λ { (_ , _ , _ , ()) }
  isSel (zero-but e e₁ e₂) = no λ { (_ , _ , _ , ()) }
  -- isSel (E.slide e x e₁ x₁) = no λ { (_ , _ , _ , ()) }
  -- isSel (E.backslide e e₁ x x₁) = no λ { (_ , _ , _ , ()) }
  isSel (bop x e e₁) = no λ { (_ , _ , _ , ()) }
  isSel (scaledown x e) = no λ { (_ , _ , _ , ()) }
  isSel (let′ e e₁) = no λ { (_ , _ , _ , ()) }
  isSel (uop x e) = no λ { (_ , _ , _ , ()) }
  -- isSel (argmax pf e) = no λ { (_ , _ , _ , ()) }

  isImapb : (e : E Γ (ar q)) → Dec (∃₂ λ s p → Σ (s * p ≈ q) λ pf → ∃ λ t → e ≡ Lang.imapb pf t)
  isImapb (var x) = no λ { (_ , _ , _ , _ , ()) }
  isImapb 𝟘 = no λ { (_ , _ , _ , _ , ()) }
  isImapb 𝟙 = no λ { (_ , _ , _ , _ , ()) }
  isImapb (imaps e) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (sels e e₁) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (imap′ refl e) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (sel′ refl e e₁) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (Lang.imapb x e) = yes (_ , _ , x , e , refl)
  isImapb (Lang.selb x e e₁) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (Lang.sum e) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (zero-but e e₁ e₂) = no λ { (_ , _ , _ , _ , ()) }
  -- isImapb (E.slide e x e₁ x₁) = no λ { (_ , _ , _ , _ , ()) }
  -- isImapb (E.backslide e e₁ x x₁) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (bop x e e₁) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (scaledown x e) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (let′ e e₁) = no λ { (_ , _ , _ , _ , ()) }
  isImapb (uop x e) = no λ { (_ , _ , _ , _ , ()) }
  -- isImapb (argmax pf e) = no λ { (_ , _ , _ , _ , ()) }

  isSelb : (e : E Γ (ar p)) → Dec (∃₂ λ s q → Σ (s * p ≈ q) λ pf → ∃₂ λ t u → e ≡ Lang.selb pf t u)
  isSelb (var x) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb 𝟘 = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb 𝟙 = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (imaps e) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (sels e e₁) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (imap′ refl e) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (sel′ refl e e₁) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (Lang.imapb x e) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (Lang.selb x e e₁) = yes (_ , _ , x , e , e₁ , refl)
  isSelb (Lang.sum e) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (zero-but e e₁ e₂) = no λ { (_ , _ , _ , _ , _ , ()) }
  -- isSelb (E.slide e x e₁ x₁) = no λ { (_ , _ , _ , _ , _ , ()) }
  -- isSelb (E.backslide e e₁ x x₁) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (bop x e e₁) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (scaledown x e) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (let′ e e₁) = no λ { (_ , _ , _ , _ , _ , ()) }
  isSelb (uop x e) = no λ { (_ , _ , _ , _ , _ , ()) }
  -- isSelb (argmax pf e) = no λ { (_ , _ , _ , _ , _ , ()) }

  isSum : (e : E Γ (ar p)) → Dec (∃₂ λ s t → e ≡ Lang.sum {s = s} t)
  isSum (var x) = no λ ()
  isSum 𝟘 = no λ ()
  isSum 𝟙 = no λ ()
  isSum (imaps e) = no λ ()
  isSum (sels e e₁) = no λ ()
  isSum (imap′ refl e) = no λ ()
  isSum (sel′ refl e e₁) = no λ ()
  isSum (Lang.imapb x e) = no λ ()
  isSum (Lang.selb x e e₁) = no λ ()
  isSum (Lang.sum e) = yes (_ , e , refl)
  isSum (zero-but e e₁ e₂) = no λ ()
  -- isSum (E.slide e x e₁ x₁) = no λ ()
  -- isSum (E.backslide e e₁ x x₁) = no λ ()
  isSum (bop x e e₁) = no λ ()
  -- isSum (scaledown x e) = no λ ()
  isSum (let′ e e₁) = no λ ()
  isSum (uop x e) = no λ ()
  -- isSum (argmax pf e) = no λ ()

  -- isSlide : (e : E Γ (ar u)) → Dec (∃₂ λ s′ p′ → ∃₂ λ r′ t → ∃₂ λ x′ t₁ → ∃ λ x₁ → e ≡ E.slide {s = s′}{p′}{r′} t x′ t₁ x₁)
  -- isSlide (var x) = no λ ()
  -- isSlide 𝟘 = no λ ()
  -- isSlide 𝟙 = no λ ()
  -- isSlide (imaps e) = no λ ()
  -- isSlide (sels e e₁) = no λ ()
  -- isSlide (imap′ refl e) = no λ ()
  -- isSlide (sel′ refl e e₁) = no λ ()
  -- isSlide (Lang.imapb x e) = no λ ()
  -- isSlide (Lang.selb x e e₁) = no λ ()
  -- isSlide (Lang.sum e) = no λ ()
  -- isSlide (zero-but e e₁ e₂) = no λ ()
  -- -- isSlide (E.slide e x e₁ x₁) =  yes (_ , _ , _ , e , x , e₁ , x₁ , refl)
  -- -- isSlide (E.backslide e e₁ x x₁) = no λ ()
  -- isSlide (logi e) = no λ ()
  -- isSlide (bop x e e₁) = no λ ()
  -- isSlide (scaledown x e) = no λ ()
  -- isSlide (⊟ e) = no λ ()
  -- isSlide (let′ e e₁) = no λ ()
  -- isSlide (uop x e) = no λ ()
  -- -- isSlide (argmax pf e) = no λ ()

  -- isBackslide : (e : E Γ (ar r))
  --             → Dec (∃₂ λ s′ u′ → ∃₂ λ p′ t → ∃₂ λ t₁ x → ∃ λ x₁
  --                    → e ≡ E.backslide {s = s′}{u = u′}{p = p′} t t₁ x x₁)
  -- isBackslide (var x) = no λ ()
  -- isBackslide 𝟘 = no λ ()
  -- isBackslide 𝟙 = no λ ()
  -- isBackslide (imaps e) = no λ ()
  -- isBackslide (sels e e₁) = no λ ()
  -- isBackslide (imap′ refl e) = no λ ()
  -- isBackslide (sel′ refl e e₁) = no λ ()
  -- isBackslide (Lang.imapb x e) = no λ ()
  -- isBackslide (Lang.selb x e e₁) = no λ ()
  -- isBackslide (Lang.sum e) = no λ ()
  -- isBackslide (zero-but e e₁ e₂) = no λ ()
  -- -- isBackslide (E.slide e x e₁ x₁) = no λ ()
  -- -- isBackslide (E.backslide e e₁ x x₁) = yes (_ , _ , _ , e , e₁ , x , x₁ , refl)
  -- isBackslide (logi e) = no λ ()
  -- isBackslide (bop x e e₁) = no λ ()
  -- isBackslide (scaledown x e) = no λ ()
  -- isBackslide (⊟ e) = no λ ()
  -- isBackslide (let′ e e₁) = no λ ()
  -- isBackslide (uop x e) = no λ ()
  -- -- isBackslide (argmax pf e) = no λ ()

  isUn : (e : E Γ (ar s)) → Dec (∃ λ t → ∃ λ t₁ → e ≡ uop t t₁)
  isUn (var x) = no λ ()
  isUn 𝟘 = no λ ()
  isUn 𝟙 = no λ ()
  isUn (imaps e) = no λ ()
  isUn (sels e e₁) = no λ ()
  isUn (imap′ refl e) = no λ ()
  isUn (sel′ refl e e₁) = no λ ()
  isUn (Lang.imapb x e) = no λ ()
  isUn (Lang.selb x e e₁) = no λ ()
  isUn (Lang.sum e) = no λ ()
  isUn (zero-but e e₁ e₂) = no λ ()
  -- isUn (E.slide e x e₁ x₁) = no λ ()
  -- isUn (E.backslide e e₁ x x₁) = no λ ()
  isUn (bop x e e₁) = no λ ()
  -- isUn (scaledown x e) = no λ ()
  isUn (let′ e e₁) = no λ ()
  isUn (uop x e) = yes (x , e , refl)
  -- isUn (argmax pf e) = no λ ()

  un-inj : {a b : E Γ (ar s)} → {x y : Uop} → (uop x a ≡ uop y b) → (x ≡ y)
  un-inj {a = a} {b = b} {x = x} {y = y} refl = refl

  isInv : (e : E Γ (ar s)) → Dec (∃ λ t → e ≡ 𝟙/ t)
  isInv e with (isUn e)
  ... | no a = no (λ (b , c) → a (inv-op , b , c))
  ... | yes (x , e , refl) with x ≟ᵘ (inv-op)
  ... | yes refl = yes (e , refl)
  ... | no a = no λ (b , c) → a (un-inj c)

  isBin : (e : E Γ (ar s)) → Dec (∃₂ λ o t → ∃ λ t₁ → e ≡ bop o t t₁)
  isBin (var x) = no λ ()
  isBin 𝟘 = no λ ()
  isBin 𝟙 = no λ ()
  isBin (imaps e) = no λ ()
  isBin (sels e e₁) = no λ ()
  isBin (imap′ refl e) = no λ ()
  isBin (sel′ refl e e₁) = no λ ()
  isBin (Lang.imapb x e) = no λ ()
  isBin (Lang.selb x e e₁) = no λ ()
  isBin (Lang.sum e) = no λ ()
  isBin (zero-but e e₁ e₂) = no λ ()
  -- isBin (E.slide e x e₁ x₁) = no λ ()
  -- isBin (E.backslide e e₁ x x₁) = no λ ()
  -- isBin (logi e) = no λ ()
  isBin (bop x e e₁) = yes (x , e , e₁ , refl)
  isBin (scaledown x e) = no λ ()
  isBin (⊟ e) = no λ ()
  isBin (let′ e e₁) = no λ ()
  isBin (uop x e) = no λ ()
  -- isBin (argmax pf e) = no λ ()

  isScaledown : (e : E Γ (ar s)) → Dec (∃₂ λ x t  → e ≡ scaledown x t)
  isScaledown (var x) = no λ ()
  isScaledown 𝟘 = no λ ()
  isScaledown 𝟙 = no λ ()
  isScaledown (imaps e) = no λ ()
  isScaledown (sels e e₁) = no λ ()
  isScaledown (imap′ refl e) = no λ ()
  isScaledown (sel′ refl e e₁) = no λ ()
  isScaledown (Lang.imapb x e) = no λ ()
  isScaledown (Lang.selb x e e₁) = no λ ()
  isScaledown (Lang.sum e) = no λ ()
  isScaledown (zero-but e e₁ e₂) = no λ ()
  -- isScaledown (E.slide e x e₁ x₁) = no λ ()
  -- isScaledown (E.backslide e e₁ x x₁) = no λ ()
  -- isScaledown (logi e) = no λ ()
  isScaledown (bop x e e₁) = no λ ()
  isScaledown (scaledown x e) = yes (x , e , refl)
  isScaledown (⊟ e) = no λ ()
  isScaledown (let′ e e₁) = no λ ()
  isScaledown (relu e) = no λ ()
  isScaledown (√ e) = no λ ()
  isScaledown (𝟙/ e) = no λ ()
  isScaledown (𝕚+ e) = no λ ()
  isScaledown (ln e) = no λ ()
  isScaledown (ℙ e) = no λ ()
  -- isScaledown (argmax pf e) = no λ ()

  isLet : (e : E Γ (ar p)) → Dec (∃₂ λ s′ t → ∃ λ t₁ → e ≡ let′ {s = s′} t t₁)
  isLet (var x) = no λ ()
  isLet 𝟘 = no λ ()
  isLet 𝟙 = no λ ()
  isLet (imaps e) = no λ ()
  isLet (sels e e₁) = no λ ()
  isLet (imap′ refl e) = no λ ()
  isLet (sel′ refl e e₁) = no λ ()
  isLet (Lang.imapb x e) = no λ ()
  isLet (Lang.selb x e e₁) = no λ ()
  isLet (Lang.sum e) = no λ ()
  isLet (zero-but e e₁ e₂) = no λ ()
  -- isLet (E.slide e x e₁ x₁) = no λ ()
  -- isLet (E.backslide e e₁ x x₁) = no λ ()
  -- isLet (logi e) = no λ ()
  isLet (bop x e e₁) = no λ ()
  isLet (scaledown x e) = no λ ()
  isLet (⊟ e) = no λ ()
  isLet (let′ e e₁) = yes (_ , e , e₁ , refl)
  isLet (uop x e) = no λ ()
  -- isLet (argmax pf e) = no λ ()

  unvar : {x y : is ∈ Γ} → var x ≡ var y → x ≡ y
  unvar refl = refl

  -- Hail UIP
  *≈-uniq : (a b : s * p ≈ q) → a ≡ b
  *≈-uniq {[]} {[]} {[]} [] [] = refl
  *≈-uniq {x ∷ s} {x₁ ∷ p} {x₂ ∷ q} (cons ⦃ refl ⦄ ⦃ a ⦄) (cons ⦃ refl ⦄ ⦃ b ⦄)
    = cong₂ (λ t u → cons ⦃ t ⦄ ⦃ u ⦄) refl (*≈-uniq a b)

  +≈-uniq : (a b : s + p ≈ q) → a ≡ b
  +≈-uniq {[]} {[]} {[]} [] [] = refl
  +≈-uniq {x ∷ s} {x₁ ∷ p} {x₂ ∷ q} (cons ⦃ refl ⦄ ⦃ a ⦄) (cons ⦃ refl ⦄ ⦃ b ⦄)
    = cong₂ (λ t u → cons ⦃ t ⦄ ⦃ u ⦄) refl (+≈-uniq a b)

  suc≈-uniq : (a b : suc s ≈ p) → a ≡ b
  suc≈-uniq [] [] = refl
  suc≈-uniq (cons ⦃ refl ⦄ ⦃ a ⦄) (cons ⦃ refl ⦄ ⦃ b ⦄) = cong₂ (λ t u → cons ⦃ t ⦄ ⦃ u ⦄) refl (suc≈-uniq a b)

  open import Data.Maybe

  _≟ᵉ_ : (a b : E Γ is) → Maybe (a ≡ b)
  var x ≟ᵉ u with isVar u
  ... | no ¬p = nothing
  ... | yes (v , refl) with eq? x v
  ... | neq _ _ = nothing
  ... | veq = just refl
  kop x ≟ᵉ b with isKop b
  ... | no _ = nothing
  ... | yes (y , refl) with x ≟ᵏ y
  ... | no _ = nothing
  ... | yes refl = just refl
  uop x a ≟ᵉ b with isUop b
  ... | no _ = nothing
  ... | yes (y , c , refl) with x ≟ᵘ y
  ... | no _ = nothing
  ... | yes refl = (a ≟ᵉ c) >>= just ∘ (cong (uop y))
  bop x a b ≟ᵉ c with isBop c
  ... | no _ = nothing
  ... | yes (y , d , e , refl) with x ≟ᵒ y
  ... | no _ = nothing
  ... | yes refl = do
    eq1 ← a ≟ᵉ d
    eq2 ← b ≟ᵉ e
    just (cong₂ (bop _) eq1 eq2)
  mop {s} {p} {q} x a ≟ᵉ b with isMop b
  ... | no _ = nothing
  ... | yes (s′ , p′ , y , a′ , refl) with s ≟ˢ s′ | p ≟ˢ p′
  ... | no _ | _ = nothing
  ... | _ | no _ = nothing
  ... | yes refl | yes refl with x ≟ᵐ y
  ... | no _ = nothing
  ... | yes refl = (a ≟ᵉ a′) >>= just ∘ (cong (mop _))
  sop {s} {p} {q} x a i ≟ᵉ b with isSop b
  ... | no _ = nothing
  ... | yes (s′ , p′ , y , a′ , i′ , refl) with s ≟ˢ s′ | p ≟ˢ p′
  ... | no _ | _ = nothing
  ... | _ | no _ = nothing
  ... | yes refl | yes refl with x ≟ᶜ y
  ... | no _ = nothing
  ... | yes refl = do
    c ← a ≟ᵉ a′
    d ← i ≟ᵉ i′
    just (cong₂ (sop _) c d)
  zero-but {s = s} e e₁ e₂ ≟ᵉ u with isZeroBut u
  ... | no ¬p = nothing
  ... | yes (s′ , i , j , u , refl) with s ≟ˢ s′
  ... | no ¬p = nothing
  ... | yes refl = do
    ei ← e ≟ᵉ i
    e₁j ← e₁ ≟ᵉ j
    e₂u ← e₂ ≟ᵉ u
    just (cong₃ zero-but ei e₁j e₂u)
  let′ {s = s} e e₁ ≟ᵉ u with isLet u
  ... | no ¬p = nothing
  ... | yes (s′ , t , t₁ , refl) with s ≟ˢ s′
  ... | no ¬p = nothing
  ... | yes refl = do
    et ← e ≟ᵉ t
    e₁t₁ ← e₁ ≟ᵉ t₁
    just (cong₂ let′ et e₁t₁)

  e-eq? : (a : E Γ is) (b : E Γ ip) → Maybe (Σ (is ≡ ip) λ pp → subst (E Γ) pp a ≡ b)
  e-eq? {is = is}{ip} a b with is ≟ⁱ ip
  ... | no ¬p = nothing
  ... | yes refl = a ≟ᵉ b >>= just ∘ (refl ,_)

  open import Data.Unit
  open import Data.Empty
  open import Data.Maybe renaming (map to mmap)
  open import Data.Maybe.Properties
  open import Data.Nat using (ℕ; zero; suc; _+_)
  open WkSub hiding (_∙ˢ_)

  count-sels : E Γ is → ip ∈ Γ → ℕ
  count-sels (sels (var w) e₁) v with eq? w v
  ... | veq = 1
  ... | neq .w y = 0
  count-sels (sop x e e₁) v = count-sels e v + count-sels e₁ v
  count-sels (var x) v = 0
  count-sels (kop x) v = 0
  count-sels (uop x e) v = count-sels e v
  count-sels (bop x e e₁) v = count-sels e v + count-sels e₁ v
  count-sels (mop x e) v = count-sels e (there v)
  count-sels (zero-but e e₁ e₂) v = count-sels e₂ v
  count-sels (let′ e e₁) v = count-sels e v + count-sels e₁ (there v)

  inline : E Γ is → E Γ is
  inline e = norm-lets (inline' e) where
    inline' : E Γ is → E Γ is
    inline' (var x) = var x
    inline' (kop x) = kop x
    inline' (uop x e) = uop x (inline' e)
    inline' (bop x e e₁) = bop x (inline' e) (inline' e₁)
    inline' (mop x e) = mop x (inline' e)
    inline' (sop x e e₁) = sop x (inline' e) (inline' e₁)
    inline' (zero-but e e₁ e₂) = zero-but (inline' e) (inline' e₁) (inline' e₂)
    inline' (let′ e e₁) with a ← (inline' e₁) | count-uses a v₀ | count-sels a v₀ | e
    ... | 0 | _ | _ = sub a (sub-id ▹ (inline' e))
    ... | _ | _ | var v = sub a (sub-id ▹ (var v))
    ... | _ | _ | 𝟘 = sub a (sub-id ▹ 𝟘)
    ... | _ | _ | 𝟙 = sub a (sub-id ▹ 𝟙)
    -- ... | 1 | 0 | _ = sub a (sub-id ▹ inline' e)
    ... | 1 | 1 | _ = sub a (sub-id ▹ inline' e)
    ... | _ | _ | _ = let′ (inline' e) a
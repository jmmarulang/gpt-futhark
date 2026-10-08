{-# OPTIONS  --backtracking-instance-search #-}

-- {-# OPTIONS --warn=noUserWarning #-}
module _ where
module _ where
  open import Data.Nat using (ℕ; zero; suc)
  open import Data.List as L using (List; []; _∷_)
  open import Ar hiding (sum; slide; backslide; imapb; selb)
  open import Relation.Binary.PropositionalEquality hiding ([_])
  open import Relation.Nullary
  open import Function
  infixl 15 _▹_

  cong₃ : {X Y Z W : Set} (f : X → Y → Z → W) → ∀ {x x₁ y y₁ z z₁}
        → x ≡ x₁ → y ≡ y₁ → z ≡ z₁ → f x y z ≡ f x₁ y₁ z₁
  cong₃ _ refl refl refl = refl

  data IS : Set where
    ix  : S → IS
    ar  : S → IS

  data Ctx : Set where
    ε    : Ctx
    _▹_  : Ctx → IS → Ctx

  variable
    Γ Δ Ξ Ψ : Ctx
    is ip iq ir : IS

  data _∈_ : IS → Ctx → Set where
    here  : is ∈ (Γ ▹ is)
    there : is ∈ Γ → is ∈ (Γ ▹ ip)

  pattern v₀ = here
  pattern v₁ = there v₀
  pattern v₂ = there v₁
  pattern v₃ = there v₂
  pattern v₄ = there v₃
  pattern v₅ = there v₄
  pattern v₆ = there v₅
  pattern v₇ = there v₆
  pattern v₈ = there v₇
  pattern v₉ = there v₈
  pattern v₁₀ = there v₉
  pattern v₁₁ = there v₁₀
  pattern v₁₂ = there v₁₁
  pattern v₁₃ = there v₁₂

  v-inj : ∀ {ip} {x y : is ∈ Γ} → (there {ip = ip} x ≡ there y) → (x ≡ y)
  v-inj refl = refl

  -- We only use this for variable comparison.
  _/_ : (Γ : Ctx) → is ∈ Γ → Ctx
  (Γ ▹ x) / here = Γ
  (Γ ▹ x) / there v = (Γ / v) ▹ x

  wkv-/ : (v : is ∈ Γ) → ip ∈ (Γ / v) → ip ∈ Γ
  wkv-/ here w = there w
  wkv-/ (there v) here = here
  wkv-/ (there v) (there w) = there (wkv-/ v w)

  data Eq : is ∈ Γ → ip ∈ Γ → Set where
    veq : {x : is ∈ Γ} → Eq x x
    neq : (x : is ∈ Γ) → (y : ip ∈ (Γ / x)) → Eq x (wkv-/ x y)

  eq? : (x : is ∈ Γ) → (y : ip ∈ Γ) → Eq x y
  eq? v₀ v₀ = veq
  eq? v₀ (there y) = neq v₀ y
  eq? (there x) v₀ = neq (there x) v₀
  eq? (there x) (there y) with eq? x y
  ... | veq = veq
  ... | neq .x y = neq (there x) (there y)


  unthere : {x y : is ∈ Γ} → there {ip = ip} x ≡ there y → x ≡ y
  unthere refl = refl

  neq-wkv : (x : is ∈ Γ) (y : is ∈ (Γ / x)) → x ≢ wkv-/ x y
  neq-wkv v₀ y = λ ()
  neq-wkv (there x) v₀ = λ ()
  neq-wkv (there x) (there y) p = (neq-wkv x y) (unthere p)

  infixl 10 _⊞_
  infixl 10 _⊟_
  infixl 15 _⊠_
  -- infixl 15 _⊔_

  unit : S
  unit = []

  data Kop : Set where
    zero-op one-op : Kop

  -- Jairo made
  data Uop : Set where
    -- logistic
    neg-op
    -- Jairo made
      -- exp
      relu-op
      sqrt-op
      inv-op
      indp-op
      ln-op
      softmax-op
      : Uop
    scaledown-op : ℕ → Uop
  data Bop : Set where
    plus-op mul-op : Bop

  data Mop   : S → S → S → Set where
    imaps-op : Mop s unit s
    imap-op  : q ≡ s ⊗ p → Mop s p q
    imapb-op : s * p ≈ q → Mop s p q
    sum-op   : Mop s p p

  data Sop  : S → S → S → Set where
    sels-op : Sop s s unit
    sel-op  : s ≡ p ⊗ q → Sop s p q
    selb-op : p * q ≈ s → Sop s p q

  data E : Ctx → IS → Set where
    var        : is ∈ Γ → E Γ is

    kop        : Kop → E Γ (ar s)
    uop        : Uop → E Γ (ar s) → E Γ (ar s)
    bop        : Bop → E Γ (ar s) → E Γ (ar s) → E Γ (ar s)

    mop        : Mop s p q → E (Γ ▹ ix s) (ar p) → E Γ (ar q)
    sop        : Sop s p q → E Γ (ar s) → E Γ (ix p) → E Γ (ar q)

    zero-but   : E Γ (ix s) → E Γ (ix s) → E Γ (ar p) → E Γ (ar p)

    let′       : E Γ (ar s) → E (Γ ▹ ar s) (ar p) → E Γ (ar p)

  pattern 𝟙 {s = s} = kop {s = s} one-op
  pattern 𝟘 {s = s} = kop {s = s} zero-op

  pattern ⊟_ a = uop neg-op a
  pattern √ a = uop sqrt-op a
  pattern 𝟙/   a = uop inv-op a
  pattern relu a = uop relu-op a
  pattern ln   a = uop ln-op a
  pattern 𝕚+   a = uop indp-op a
  pattern ℙ    a = uop softmax-op a
  pattern scaledown n a = uop (scaledown-op n) a

  pattern _⊞_ a b = bop plus-op a b
  pattern _⊠_ a b = bop mul-op a b

  pattern imaps {s = s} {p = p} {q = q} a =
    mop {s = s} {p = p} {q = q} imaps-op a
  pattern imap′ {s = s} {p = p} {q = q} a b =
    mop {s = s} {p = p} {q = q} (imap-op a) b
  pattern imapb {s = s} {p = p} {q = q} a b =
    mop {s = s} {p = p} {q = q} (imapb-op a) b
  pattern sum {s = s} {p = p} {q = q} a =
    mop {s = s} {p = p} {q = q} sum-op a

  pattern sels {Γ = Γ} {s = s} {p = p} {q = q} a b =
    sop {s = s} {p = p} {q = q} {Γ = Γ} sels-op a b
  pattern sel′ {Γ = Γ} {s = s} {p = p} {q = q} a b c =
    sop {s = s} {p = p} {q = q} {Γ = Γ} (sel-op a) b c
  pattern selb {s = s} {p = p} {q = q} a b c =
    sop {s = s} {p = p} {q = q} (selb-op a) b c

  imap : E (Γ ▹ ix s) (ar p) → E Γ (ar (s ⊗ p))
  imap e = imap′ refl e

  sel : E Γ (ar (s ⊗ p)) → E Γ (ix s) → E Γ (ar p)
  sel e i = sel′ refl e i

  _⊟_ : ( a b : E Γ (ar s)) → E Γ (ar s)
  _⊟_ a b = a ⊞ ⊟ b

  _//_ : ( a b : E Γ (ar s)) → E Γ (ar s)
  _//_ a b = a ⊠ (𝟙/ b)

  𝕚0- : (E Γ (ar s)) → E Γ (ar s)
  𝕚0- a = 𝟙 ⊟ 𝕚+ a

  𝕚0+ : (E Γ (ar s)) → E Γ (ar s)
  𝕚0+ a = 𝕚0- (⊟ a)

  𝕚≤ : (E Γ (ar s)) → (E Γ (ar s)) → E Γ (ar s)
  𝕚≤ a b = 𝕚0+ (a ⊟ b)

  𝟚 : E Γ (ar s)
  𝟚 = 𝟙 ⊞ 𝟙

  var-inj : ∀ {x y : is ∈ Γ} → (var x ≡ var y) → (x ≡ y)
  var-inj refl = refl

  scaledown-inj : ∀ {x y} → scaledown-op x ≡ scaledown-op y → (x ≡ y)
  scaledown-inj refl = refl

module WkSub where
  open import Data.Nat using (ℕ; zero; suc; _+_)
  open import Relation.Binary.PropositionalEquality hiding ([_])
  open import Function
  open import Ar hiding (sum; slide; backslide; map ; imapb; selb)

  data _⊆_ : Ctx → Ctx → Set where
    ε    : ε ⊆ ε
    skip : Γ ⊆ Δ → Γ ⊆ (Δ ▹ is)
    keep : Γ ⊆ Δ → (Γ ▹ is) ⊆ (Δ ▹ is)

  wkv : Γ ⊆ Δ → is ∈ Γ → is ∈ Δ
  wkv (skip s) v = there (wkv s v)
  wkv (keep s) v₀ = v₀
  wkv (keep s) (there v) = there (wkv s v)

  wk : Γ ⊆ Δ → E Γ is → E Δ is
  wk s (var x) = var (wkv s x)
  wk s (kop x) = (kop x)
  wk s (uop x e) = uop x (wk s e)
  wk s (bop x e e₁) = bop x (wk s e) (wk s e₁)
  wk s (mop x e) = mop x (wk (keep s) e)
  wk s (sop x e e₁) = sop x (wk s e) (wk s e₁)
  wk s (zero-but e e₁ e₂) = zero-but (wk s e) (wk s e₁) (wk s e₂)
  wk s (let′ e e₁) = let′(wk s e) (wk (keep s) e₁)

  _∙ʷ_ : Δ ⊆ Ψ → Γ ⊆ Δ → Γ ⊆ Ψ
  s ∙ʷ ε = s
  skip s ∙ʷ skip p = skip (s ∙ʷ skip p)
  keep s ∙ʷ skip p = skip s ∙ʷ p
  skip s ∙ʷ keep p = skip (s ∙ʷ keep p)
  keep s ∙ʷ keep p = keep (s ∙ʷ p)

  ⊆-eq : Γ ⊆ Γ
  ⊆-eq {ε} = ε
  ⊆-eq {Γ ▹ x} = keep ⊆-eq

  ⊆-ε : ε ⊆ Γ
  ⊆-ε {ε} = ε
  ⊆-ε {Γ ▹ x} = skip ⊆-ε

  ⊆-inj : (Γ ▹ is) ⊆ (Δ ▹ ip) → Γ ⊆ Δ
  ⊆-inj (skip s) = s ∙ʷ skip ⊆-eq
  ⊆-inj (keep s) = s ∙ʷ ⊆-eq

  open import Data.Empty

  _↑ : E Γ is → E (Γ ▹ ip) is
  _↑ = wk (skip ⊆-eq)

  wk-/ : (v : is ∈ Γ) → (Γ / v) ⊆ Γ
  wk-/ v₀ = skip ⊆-eq
  wk-/ (there v) = keep (wk-/ v)

  data Sub (Γ : Ctx) : Ctx → Set where
    ε   : Sub Γ ε
    _▹_ : Sub Γ Δ → E Γ is → Sub Γ (Δ ▹ is)

  wks : Sub Γ Δ → Γ ⊆ Ψ → Sub Ψ Δ
  wks ε p = ε
  wks (s ▹ x) p = (wks s p) ▹ wk p x

  sdrop : Sub Γ Δ → Sub (Γ ▹ is) Δ
  sdrop s = wks s (skip ⊆-eq)

  skeep : Sub Γ Δ → Sub (Γ ▹ is) (Δ ▹ is)
  skeep s = sdrop s ▹ var v₀

  subv : Sub Γ Δ → is ∈ Δ → E Γ is
  subv (s ▹ x) v₀ = x
  subv (s ▹ x) (there v) = subv s v

  sub-id : Sub Γ Γ
  sub-id {ε} = ε
  sub-id {Γ ▹ x} = skeep sub-id

  sub : E Δ is → Sub Γ Δ → E Γ is
  sub (var x) s = subv s x
  sub (kop x) s = kop x
  sub (uop x e) s = uop x (sub e s)
  sub (bop x e e₁) s = bop x (sub e s) (sub e₁ s)
  sub (mop x e) s = mop x (sub e (skeep s))
  sub (sop x e e₁) s = sop x (sub e s) (sub e₁ s)
  sub (zero-but e e₁ e₂) s = zero-but (sub e s) (sub e₁ s) (sub e₂ s)
  sub (let′ e e₁) s = let′ (sub e s) (sub e₁ (skeep s))

  _∙ˢ_ : Sub Δ Ψ → Sub Γ Δ → Sub Γ Ψ
  ε ∙ˢ t = ε
  (s ▹ x) ∙ˢ t = (s ∙ˢ t) ▹ sub x t

  -- All kinds of theorems
  wkv-at-eq : (v : is ∈ Γ) → wkv ⊆-eq v ≡ v
  wkv-at-eq v₀ = refl
  wkv-at-eq (there v) = cong there (wkv-at-eq v)

  subv-wks : (v : is ∈ Γ) (s : Sub Δ Γ) (w : Δ ⊆ Ψ) → subv (wks s w) v ≡ wk w (subv s v)
  subv-wks v₀ (s ▹ x) w = refl
  subv-wks (there v) (s ▹ x) w = subv-wks v s w

  subv-sdrop : (v : is ∈ Γ) (s : Sub Δ Γ) → subv (sdrop {is = ip} s) v ≡ (subv s v) ↑
  subv-sdrop v₀ (s ▹ x) = refl
  subv-sdrop (there v) (s ▹ x) = subv-wks v s _

  subv-at-id : (v : is ∈ Γ) → subv sub-id v ≡ var v
  subv-at-id v₀ = refl
  subv-at-id {is} {.(Γ ▹ ip)} (there {is = .is} {Γ = Γ} {ip = ip} v)
    rewrite subv-sdrop {ip = ip} v sub-id | subv-at-id v = cong (var ∘′ there) (wkv-at-eq v)

  sub-at-id : (e : E Γ is) → sub e sub-id ≡ e
  sub-at-id (var x) = subv-at-id x
  sub-at-id (kop x) = refl
  sub-at-id (uop x e) = cong (uop x) (sub-at-id e)
  sub-at-id (bop x e e₁) = cong₂ (bop x) (sub-at-id e) (sub-at-id e₁)
  sub-at-id (mop x e) = cong (mop x) (sub-at-id e)
  sub-at-id (sop x e e₁) = cong₂ (sop x) (sub-at-id e) (sub-at-id e₁)
  sub-at-id (zero-but e e₁ e₂) = cong₃ zero-but (sub-at-id e) (sub-at-id e₁) (sub-at-id e₂)
  sub-at-id (let′ e e₁) = cong₂ let′ (sub-at-id e) (sub-at-id e₁)

  sub-ε : (e : E ε is) → sub e ε ≡ e
  sub-ε e = sub-at-id e

  sub-swap : Sub (Γ ▹ is ▹ ip) (Γ ▹ ip ▹ is)
  sub-swap = (sdrop (sdrop sub-id) ▹ var v₀) ▹ var (there v₀)

  -- We are not really using this, but this is a useful function to have.
  open import Data.Maybe
  open import Data.Maybe.Properties
  open import Data.Product hiding (map)

  strenv-∃ : (x : is ∈ Γ) (y : ip ∈ Γ)
    → Maybe (∃ (λ (z : ip ∈ (Γ / x)) → y ≡ wkv (wk-/ x) z))
  strenv-∃ v₀ v₀ = nothing
  strenv-∃ v₀ (there y) = just (y , (cong there (sym (wkv-at-eq y))))
  strenv-∃ (there x) v₀ = just (v₀ , refl)
  strenv-∃ (there x) (there y) =
    map (λ (a , eq) → there a , (cong there eq)) (strenv-∃ x y)

  stren-∃ : (e : E Γ is) (v : ip ∈ Γ)
    → Maybe (∃ λ (z : E (Γ / v) is) → e ≡ wk (wk-/ v) z)
  stren-∃ (var x) v = map (λ (a , b) → _ , (cong var b)) (strenv-∃ v x)
  stren-∃ (kop x) v = just (kop x , refl)
  stren-∃ (uop x e) v = map (λ (a , b) → _ , (cong (uop x) b)) (stren-∃ e v)
  stren-∃ (bop x e e₁) v = do
    (a , b) ← stren-∃ e v
    (c , d) ← stren-∃ e₁ v
    just (_ , (cong₂ (bop x) b d))
  stren-∃ (mop x e) v =
    map (λ (a , b) → _ , (cong (mop x) b)) (stren-∃ e (there v))
  stren-∃ (sop x e e₁) v = do
    (a , b) ← stren-∃ e v
    (c , d) ← stren-∃ e₁ v
    just (_ , (cong₂ (sop x) b d))
  stren-∃ (zero-but e e₁ e₂) v = do
    (a , b) ← stren-∃ e v
    (c , d) ← stren-∃ e₁ v
    (e , f) ← stren-∃ e₂ v
    just (_ , cong₃ zero-but b d f)
  stren-∃ (let′ e e₁) v = do
    (a , b) ← stren-∃ e v
    (c , d) ← stren-∃ e₁ (there v)
    just (_ , (cong₂ let′ b d))

  stren : (e : E Γ is) (v : ip ∈ Γ)
    → Maybe (E (Γ / v) is)
  stren e v = do
    (a , _) ← (stren-∃ e v)
    just a

  norm-lets : E Γ is → E Γ is
  norm-lets (var x) = var x
  norm-lets (kop x) = kop x
  norm-lets (uop x e) = uop x (norm-lets e)
  norm-lets (bop x e e₁) = bop x (norm-lets e) (norm-lets e₁)
  norm-lets (mop x e) = mop x (norm-lets e)
  norm-lets (sop x e e₁) = sop x (norm-lets e) (norm-lets e₁)
  norm-lets (zero-but e e₁ e₂) =
    zero-but (norm-lets e) (norm-lets e₁) (norm-lets e₂)
  norm-lets (let′ e e₁) =
    maybe id (let′ (norm-lets e) (norm-lets e₁)) (stren (norm-lets e₁) v₀)

  count-uses : E Γ is → ip ∈ Γ → ℕ
  count-uses (var x) v with eq? x v
  ... | veq = 1
  ... | _ = 0
  count-uses (kop x) v = 0
  count-uses (uop x e) v = count-uses e v
  count-uses (bop x e e₁) v = (count-uses e v) + (count-uses e₁ v)
  count-uses (mop x e) v = count-uses e (there v)
  count-uses (sop x e e₁) v = count-uses e v + count-uses e₁ v
  count-uses (zero-but e e₁ e₂) v =
    count-uses e v + count-uses e₁ v + count-uses e₂ v
  count-uses (let′ e e₁) v = count-uses e v + count-uses e₁ (there v)

module Syntax where
  open import Data.List as L using (List; []; _∷_)
  open import Ar hiding (sum; imapb)

  -- Convenience functions when writing expressions in the DSL
  -- In some sense we are faking HOAS using instance resolution.
  data Prefix : (Γ Δ : Ctx) → Set where
    instance
      zero : Prefix Γ Γ
      suc  : ⦃ Prefix Γ Δ ⦄ → Prefix Γ (Δ ▹ is)

  -- A term that can be lifted into larger contexts
  GE : Ctx → IS → Set
  GE Γ is = ∀ {Δ} → ⦃ Prefix Γ Δ ⦄ → E Δ is

  -- A variable that can be lifted into larger contexts
  GVar : Ctx → IS → Set
  GVar Γ is = ∀ {Δ} → ⦃ p : Prefix Γ Δ ⦄ → is ∈ Δ

  -- Lift var
  V : is ∈ Γ → GVar Γ is
  V v ⦃ p = zero ⦄ = v
  V v ⦃ p = suc  ⦄ = there (V v)

  -- Use GE GVar and V to define HOAS-style imap, imaps, and impab
  Imap : ∀ {Γ}
       → (GE (Γ ▹ ix s) (ix s) → E (Γ ▹ ix s) (ar p))
       → E Γ (ar (s ⊗ p))
  --Imap f = imap (f λ {Δ} ⦃ p ⦄ → var (V v₀))
  Imap f = imap (f (var (V v₀)))

  Sum : ∀ {Γ}
       → (GE (Γ ▹ ix s) (ix s) → E (Γ ▹ ix s) (ar p))
       → E Γ (ar p)
  Sum f = sum (f λ {Δ} ⦃ p ⦄ → var (V v₀))

  -- Max : ∀ {Γ}
  --      → (GE (Γ ▹ ix s) (ix s) → E (Γ ▹ ix s) (ar p))
  --      → E Γ (ar p)
  -- Max f = maximum (f λ {Δ} ⦃ p ⦄ → var (V v₀))

  Imaps : ∀ {Γ}
        → (GE (Γ ▹ ix s) (ix s) → E (Γ ▹ ix s) (ar unit))
        → E Γ (ar s)
  Imaps f = imaps (f λ {Δ} ⦃ p ⦄ → var (V v₀))

  Imapb : ∀ {Γ}
        → s * p ≈ q
        → (GE (Γ ▹ ix s) (ix s) → E (Γ ▹ ix s) (ar p))
        → E Γ (ar q)
  Imapb p f = imapb p (f λ {Δ} ⦃ p ⦄ → var (V v₀))

  Let-syntax : ∀ {Γ}
      → (E Γ (ar s))
      → (GE (Γ ▹ (ar s)) (ar s) → E (Γ ▹ (ar s)) (ar p))
      → E Γ (ar p)
  Let-syntax x f = let′ x (f λ {Δ} ⦃ p ⦄ → var (V v₀))

  infixl 3 Let-syntax
  syntax Let-syntax e (λ x → e') = Let x := e In e'

  -- Extend context with a list of types
  -- (List is a context that grows to the left)
  ext : Ctx → List IS → Ctx
  ext Γ [] = Γ
  ext Γ (x ∷ l) = ext (Γ ▹ x) l

  -- Turn the list of IS into the following function:
  --   l = [a, b, c]
  --   X = X
  --   Γ = Γ
  --   ----------------------------
  --   GE Γ a → GE Γ b → GE Γ c → X
  lfunh : (l : List IS) (X : Set) (Γ : Ctx) → Set
  lfunh [] X Γ = X
  lfunh (a ∷ l) X Γ = GE Γ a → lfunh l X Γ

  -- Diagonalise lfunh:
  --   l = [a, b]
  --   Γ = Γ
  --   is = is
  --   ---------------------------------------------
  --   GE (ext Γ l) a → GE (ext Γ l) → E (ext Γ l) is
  lfun : (l : List IS)  (Γ : Ctx) (is : IS) → Set
  lfun l Γ τ = lfunh l (E (ext Γ l) τ) (ext Γ l)

  -- Compute GE from the variable in the non-extended context
  lvar : ∀ l → is ∈ Γ → GE (ext Γ l) is
  lvar [] v = var (V v)
  lvar (x ∷ l) v = lvar l (there v)

  -- Apply function to the corresponding variables of the context
  Lcon : ∀ l is Γ → (f : lfun l Γ is) → E (ext Γ l) is
  Lcon []      is Γ f = f
  Lcon (x ∷ l) is Γ f = Lcon l is (Γ ▹ x) (f (lvar l v₀))

module Primitives where

  open import Data.List as L using (List; []; _∷_)
  open import Data.Nat as ℕ using (ℕ; zero; suc)
  open import Function using (_$_; it; _∋_)
  open import Relation.Binary.PropositionalEquality hiding ([_])
  open import Ar hiding (map; K; slide; selb; swap; sum)
  open Syntax
  open WkSub

  fromPrefix : Prefix Γ Δ → Γ ⊆ Δ
  fromPrefix zero = ⊆-eq
  fromPrefix (suc ⦃ p ⦄) = skip (fromPrefix p)

  wkp : Prefix Γ Δ → E Γ is → E Δ is
  wkp p = wk (fromPrefix p)

  ⟨_⟩ : E Γ is → GE Γ is
  ⟨_⟩ t {Δ} ⦃ p ⦄ = wkp p t

  module Microgpt where

    open import Data.Product as Prod hiding (map; _<*>_)
    open import Data.List.Properties

    variable
      ed : S
      ah hd sl vo pr fd bs : S

    Ks : ∀ {Γ} → E Γ $ ar [] → E Γ $ ar s
    Ks x = Imaps (λ _ → ⟨ x ⟩)

    K : ∀ {Γ s} → E Γ $ ar s → E Γ $ ar $ p ⊗ s
    K x = Imap (λ _ → ⟨ x ⟩)

    map : ∀ {Γ} → (E (Γ ▹ ix p) $ ar s → E (Γ ▹ ix p) $ ar q)
      → E Γ $ ar $ p ⊗ s → E Γ $ ar $ p ⊗ q
    map {p} f e = Imap {p} λ i → f (sel ⟨ e ⟩ i)

    zipwith : ∀ {Γ}
      → (E (Γ ▹ ix p) $ ar s → E (Γ ▹ ix p) $ ar q → E (Γ ▹ ix p) $ ar r)
      → E Γ $ ar $ p ⊗ s → E Γ $ ar $ p ⊗ q → E Γ $ ar $ p ⊗ r
    zipwith {p} f a b = Imap {p} λ i → f (sel ⟨ a ⟩ i) (sel ⟨ b ⟩ i)

    zipwith₃ : ∀ {Γ}
      → (E (Γ ▹ ix p) $ ar s → E (Γ ▹ ix p) $ ar q
        → E (Γ ▹ ix p) $ ar r → E (Γ ▹ ix p) $ ar w)
      → E Γ $ ar $ p ⊗ s → E Γ $ ar $ p ⊗ q → E Γ $ ar $ p ⊗ r
      → E Γ $ ar $ p ⊗ w
    zipwith₃ {p} f a b c = Imap {p} λ i → f (sel ⟨ a ⟩ i) (sel ⟨ b ⟩ i) (sel ⟨ c ⟩ i)

    assᵣ : ∀ {Γ} → E Γ $ ar $ s ⊗ (p ⊗ q) → E Γ $ ar $ (s ⊗ p) ⊗ q
    assᵣ {s} {p} {q} e = Imap {s ⊗ p} λ i → Imaps λ j →
      sels (Imap {s} λ k → Imaps λ w → sels (sel (sel ⟨ e ⟩ k) w) j) i

    tr : ∀ {Γ} → E Γ $ ar $ (s ⊗ p) → E Γ $ ar $ (p ⊗ s)
    tr {s} {p} e = Imap {p} λ i → Imaps λ j → sels (sel ⟨ e ⟩ j) i

    assₗ : ∀ {Γ} → E Γ $ ar $ (s ⊗ p) ⊗ q → E Γ $ ar $ s ⊗ (p ⊗ q)
    assₗ {s} {p} {q} e = Imap {s} λ i → Imap {p} λ j → Imaps λ k →
      sels (sel (sel (tr {s ⊗ p} ⟨ e ⟩) k) i) j

    trₗ : ∀ {Γ} → E Γ (ar (p ⊗ (s ⊗ u))) → E Γ (ar (s ⊗ (p ⊗ u)))
    trₗ {p} {s} {u} x = Imap {s} λ i → Imap {p} λ j → sel (sel ⟨ x ⟩ j) i

    trᵢ : ∀ {Γ} → E Γ $ ar $ (s ⊗ p) ⊗ (q ⊗ r)
      → E Γ $ ar $ (s ⊗ q) ⊗ (p ⊗ r)
    trᵢ {s} {p} {q} {r} e = assᵣ {s} {q} $ Imap {s} λ i →
      trₗ {p} {q} (sel (assₗ {s} ⟨ e ⟩) i)

    linear : ∀ {Γ} → E Γ $ ar $ p ⊗ s → E Γ $ ar p → E Γ $ ar s → E Γ $ ar p
    linear {s = s} w b x =
      (Imaps λ i → Sum {s} λ j → sels (sel ⟨ w ⟩ i) j ⊠ (sels ⟨ x ⟩ j)) ⊞ b

    matmul : ∀ {Γ} → E Γ (ar (u ⊗ s)) → E Γ (ar (s ⊗ r)) → E Γ (ar (u ⊗ r))
    matmul {u} {s} {r} w1 w2 =
      Imap {u} λ i → Imaps {r} λ j → Sum {s} λ k →
      sels (sel ⟨ w1 ⟩ i) k ⊠ sels (sel ⟨ w2 ⟩ k) j

    matmult : ∀ {Γ} → E Γ (ar (u ⊗ s)) → E Γ (ar (r ⊗ s)) → E Γ (ar (u ⊗ r))
    matmult {u} {s} {r} w1 w2 =
      Imap {u} λ i → Imaps {r} λ j → Sum {s} λ k →
      sels ((sel ⟨ w1 ⟩ i) ⊠ (sel ⟨ w2 ⟩ j)) k

    m-rmsnorm : ∀ {Γ} → E Γ $ ar $ p ⊗ s → E Γ $ ar $ p ⊗ s
    m-rmsnorm {p = p} {s = s} e =
      Let xx := e ⊠ e In
      Let ms :=
        map {p} (λ x → scaledown (len s) (Sum (λ i → sels ⟨ x ⟩ i))) xx In
      Let scale := √ (ms ⊞ (scaledown 100000 𝟙)) In
      zipwith {p} (λ a b → a // Ks b) ⟨ e ⟩ scale

    split : s * p ≈ r → E Γ $ ar $ r → E Γ $ ar $ s ⊗ p
    split {s} eq x = Imap {s} λ i → selb eq ⟨ x ⟩ i

    cat : s * p ≈ r → E Γ $ ar $ s ⊗ p → E Γ $ ar $ r
    cat eq x = Imapb eq λ i → sel ⟨ x ⟩ i

    cross-entropy : ∀ {Γ} (target logits : E Γ (ar s)) → (E Γ (ar []))
    cross-entropy {s} target probs =
      -- Let lnsf := ln (ℙ logits) In
      (⊟ (Sum λ i → sels (ln ⟨ probs ⟩) i ⊠ sels ⟨ target ⟩ i))

    avg : ∀ {Γ} → E Γ (ar s) → E Γ (ar [])
    avg {s} x = scaledown (len s) (Sum λ i → sels ⟨ x ⟩ i)

    AH = [ 4 ] ; HD = [ 4 ] ; SL = [ 16 ] ; FD = [ 64 ] ; SC = 2
    VO = [ 27 ] ; BS = [ 1 ] ; ED = [ 16 ]

    PR : AH * HD ≈ ED
    PR = cons

    record GPTW (Γ : Ctx) (sl ed ah hd fd vo : S) : Set₁ where
      constructor gptw
      field
        -- position embedding
        wp : E Γ $ ar $ sl ⊗ ed
        -- the embedding dimension matches the number of heads
        att-eq : ah * hd ≈ ed
        -- weights for queries, keys, values and output projection
        wkey wqry wval : E Γ $ ar $ ed ⊗ ed
        wo : E Γ $ ar $ ed ⊗ ed
        -- attn and padding mask
        mask : E Γ $ ar $ sl ⊗ sl
        -- up projection
        wu : E Γ $ ar $ fd ⊗ ed
        -- down projection
        wd : E Γ $ ar $ ed ⊗ fd
        -- output projection into vocabulary size
        wc : E Γ $ ar $ vo ⊗ ed
    open GPTW

    wk-gptp : Prefix Γ Δ → GPTW Γ sl ed ah hd fd vo → GPTW Δ sl ed ah hd fd vo
    wk-gptp pr p = record
      { wp = wk (fromPrefix pr) (p .wp)
      ; att-eq = p .att-eq
      ; wqry = wk (fromPrefix pr) (p .wqry)
      ; wkey = wk (fromPrefix pr) (p .wkey)
      ; wval = wk (fromPrefix pr) (p .wval)
      ; wo = wk (fromPrefix pr) (p .wo)
      ; mask = wk (fromPrefix pr) (p .mask)
      ; wu = wk (fromPrefix pr) (p .wu)
      ; wd = wk (fromPrefix pr) (p .wd)
      ; wc = wk (fromPrefix pr) (p .wc)
      }

    G-GPTW : Ctx → S → S → S → S → S → S → Set₁
    G-GPTW Γ sl ed ah hd fd vo =
      ∀ {Δ} → ⦃ Prefix Γ Δ ⦄ → GPTW Δ sl ed ah hd fd vo

    ⟨_⟩ʷ : GPTW Γ sl ed ah hd fd vo → G-GPTW Γ sl ed ah hd fd vo
    ⟨_⟩ʷ p {Δ} ⦃ pf ⦄  = wk-gptp pf p

    block : ∀ {Γ} → ah * hd ≈ ed → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
      → E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd)
    block {ah = ah} {bs = bs} {sl = sl} eq x =
      trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (split $ eq) x

    merge : ∀ {Γ} → ah * hd ≈ ed → E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd)
      → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
    merge {ah} {bs = bs} eq x = map {bs ⊗ _} (cat eq) (trᵢ {bs} {ah} x)

    attn-proj : ∀ {Γ} → ah * hd ≈ ed → E Γ $ ar $ ed ⊗ ed
      → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
      → E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd)
    attn-proj {bs = bs} {sl = sl} eq w x =
      block {bs = bs} eq $ map {bs ⊗ sl} (linear ⟨ w ⟩ 𝟘) x

    query : ∀ {Γ} → GPTW Γ sl ed ah hd fd vo
      → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
      → E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd)
    query {sl = sl} {bs = bs} θ x =
      attn-proj {bs = bs} (θ .att-eq) (θ .wqry) x

    key : ∀ {Γ} → GPTW Γ sl ed ah hd fd vo
      → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
      → E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd)
    key {sl = sl} {bs = bs} θ x =
      attn-proj {bs = bs} (θ .att-eq) (θ .wkey) x

    value : ∀ {Γ} → GPTW Γ sl ed ah hd fd vo
      → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
      → E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd)
    value {sl = sl} {bs = bs} θ x =
      attn-proj {bs = bs} (θ .att-eq) (θ .wval) x

    attn : ∀ {Γ} → (sc : ℕ) →
                   (mask : E Γ (ar (sl ⊗ sl)))
                   (qs ks vs : E Γ (ar (sl ⊗ hd)))
                  → E Γ (ar (sl ⊗ hd))
    attn {sl} {hd} {Γ} sc mask hq hk hv =
      matmul {sl}
        (map {sl} ℙ ((scaledown sc (matmult {sl} hq hk)) ⊞ ⟨ mask ⟩)) ⟨ hv ⟩

    mh-attn : ∀ {Γ} → (sc : ℕ)
                (mask : E Γ $ ar $ sl ⊗ sl)
                (q k v : E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd))
                → E Γ $ ar $ (bs ⊗ ah) ⊗ (sl ⊗ hd)
    mh-attn {sl = sl} {bs = bs} {ah = ah} sc mask q k v =
      zipwith₃ {bs ⊗ ah} (attn {sl} sc ⟨ mask ⟩) q k v

    bgpt-forward : ∀ {Γ} (sc : ℕ)
                → GPTW Γ sl ed ah hd fd vo
                → E Γ (ar (bs ⊗ (sl ⊗ ed)))
                → E Γ (ar ((bs ⊗ sl) ⊗ vo))
    bgpt-forward {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws =
      -- embedding
      Let x₀ := m-rmsnorm {bs ⊗ sl} (assᵣ {bs} {sl} $ K {bs} (θ .wp) ⊞ ws) In
      Let x₁ := m-rmsnorm {bs ⊗ sl} x₀ In
      -- attention
      Let att := merge {bs = bs} (θ .att-eq) $
        mh-attn {sl = sl} {bs = bs} sc ⟨ θ .mask ⟩
        (query ⟨ θ ⟩ʷ x₁) (key ⟨ θ ⟩ʷ x₁) (value ⟨ θ ⟩ʷ x₁) In
      Let x₂ := x₀ ⊞ (map {bs ⊗ sl} (linear ⟨ θ .wo ⟩ 𝟘) att) In
      -- feed forward and logits
      Let x₃ := m-rmsnorm {bs ⊗ sl} x₂ In
        (map {bs ⊗ sl} (linear ⟨ θ .wc ⟩ 𝟘) $
        x₂ ⊞_ $ map {bs ⊗ sl} (linear ⟨ θ .wd ⟩ 𝟘) $
        relu $ map {bs ⊗ sl} (linear ⟨ θ .wu ⟩ 𝟘) x₃)

    bgpt-loss : ∀ {Γ} (sc : ℕ)
                → GPTW Γ sl ed ah hd fd vo
                → E Γ (ar (bs ⊗ (sl ⊗ ed)))
                → E Γ (ar ((bs ⊗ sl) ⊗ vo))
                → E Γ (ar [])
    bgpt-loss {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws target =
      -- embedding
      Let x₀ := m-rmsnorm {bs ⊗ sl} (assᵣ {bs} {sl} $ K {bs} (θ .wp) ⊞ ws) In
      Let x₁ := m-rmsnorm {bs ⊗ sl} x₀ In
      -- attention
      Let att := merge {bs = bs} (θ .att-eq) $
        mh-attn {sl = sl} {bs = bs} sc ⟨ θ .mask ⟩
        (query ⟨ θ ⟩ʷ x₁) (key ⟨ θ ⟩ʷ x₁) (value ⟨ θ ⟩ʷ x₁) In
      Let x₂ := x₀ ⊞ (map {bs ⊗ sl} (linear ⟨ θ .wo ⟩ 𝟘) att) In
      -- feed forward and logits
      Let x₃ := m-rmsnorm {bs ⊗ sl} x₂ In
      Let logits := (map {bs ⊗ sl} (linear ⟨ θ .wc ⟩ 𝟘) $
        x₂ ⊞_ $ map {bs ⊗ sl} (linear ⟨ θ .wd ⟩ 𝟘) $
        relu $ map {bs ⊗ sl} (linear ⟨ θ .wu ⟩ 𝟘) x₃) In
      -- loss
      Let probs := map {bs ⊗ sl} ℙ logits In
      avg (zipwith {bs ⊗ sl} (λ a b → cross-entropy a b) ⟨ target ⟩ probs)

    bgpt-forward-e : E _ _
    bgpt-forward-e = Lcon (
                    ar (SL ⊗ ED) --wp
                  ∷ ar (ED ⊗ ED) --wkey
                  ∷ ar (ED ⊗ ED) --wqry
                  ∷ ar (ED ⊗ ED) --wval
                  ∷ ar (ED ⊗ ED) --wo
                  ∷ ar (SL ⊗ SL) --mask
                  ∷ ar (FD ⊗ ED) --wu
                  ∷ ar (ED ⊗ FD) --wd
                  ∷ ar (VO ⊗ ED) --wc
                  ∷ ar (BS ⊗ (SL ⊗ ED)) --ws
                  ∷ []) (ar $ BS ⊗ (SL ⊗ VO)) ε
                  λ wp wkey wqry wval wo mask wu wd wc ws
                  → let θ = gptw wp PR wkey wqry wval wo mask wu wd wc in
                    bgpt-forward {sl = SL} {vo = VO} {bs = BS} SC θ ws

    bgpt-loss-e : E _ _
    bgpt-loss-e = Lcon (
                    ar (SL ⊗ ED) --wp
                  ∷ ar (ED ⊗ ED) --wkey
                  ∷ ar (ED ⊗ ED) --wqry
                  ∷ ar (ED ⊗ ED) --wval
                  ∷ ar (ED ⊗ ED) --wo
                  ∷ ar (SL ⊗ SL) --mask
                  ∷ ar (FD ⊗ ED) --wu
                  ∷ ar (ED ⊗ FD) --wd
                  ∷ ar (VO ⊗ ED) --wc
                  ∷ ar (BS ⊗ (SL ⊗ ED)) --ws
                  ∷ ar ((BS ⊗ SL) ⊗ VO) --target
                  ∷ []) (ar []) ε
                  λ wp wkey wqry wval wo mask wu wd wc ws target
                  → let θ = gptw wp PR wkey wqry wval wo mask wu wd wc in
                    bgpt-loss {sl = SL} {vo = VO} {bs = BS} SC θ ws target

      -- avg (zipwith {bs} (λ x y → mgpt-loss sc ⟨ θ ⟩ʷ x y) ws (assₗ {bs} target))

    -- mgpt-forward : ∀ {Γ} (sc : ℕ)
    --                → GPTW Γ sl ed ah hd fd vo
    --                → E Γ (ar (sl ⊗ ed))
    --                → E Γ (ar (sl ⊗ vo))
    -- mgpt-forward {sl} {ed} {ah} {hd} {fd} {vo} sc θ ws =
    --   -- Embedding
    --   Let wj := (θ .wp) ⊞ ws In
    --   Let x₀ := map {sl} rmsnorm wj In --residual
    --   Let x₁ := map {sl} rmsnorm x₀ In
    --   -- Attn
    --   Let k      := map {sl} (linear ⟨ θ .wkey ⟩ 𝟘) x₁ In
    --   Let q      := map {sl} (linear ⟨ θ .wqry ⟩ 𝟘) x₁ In
    --   Let v      := map {sl} (linear ⟨ θ .wval ⟩ 𝟘) x₁ In
    --   Let bk     := trₗ {sl} {ah} $ map {sl} (split (θ .att-eq)) k In
    --   Let bq     := trₗ {sl} {ah} $ map {sl} (split (θ .att-eq)) q In
    --   Let bv     := trₗ {sl} {ah} $ map {sl} (split (θ .att-eq)) v In
    --   -- Let scores := zipwith {ah} (λ hq hk → matmult {sl} hq hk) bq bk In
    --   -- Let masked := map {ah} (λ x → x ⊞ ⟨ θ .mask ⟩) scores In
    --   -- Let sf     := map {ah} (map {sl} ℙ) masked In
    --   -- Let batt   := zipwith {ah} (λ hsf hv → matmul {sl} hsf hv) sf bv In
    --   Let batt := mh-attn' {sl} {ah} sc ⟨ θ .mask ⟩ bq bk bv In
    --   Let att    := map {sl} (cat (θ .att-eq)) (trₗ {ah} {sl} batt) In
    --   Let out    := map {sl} (linear ⟨ θ .wo ⟩ 𝟘) att In
    --   Let x₂     := out ⊞ x₀ In --residual
    --   -- Feed Forward
    --   Let x₃   := map {sl} rmsnorm x₂ In
    --   Let up   := map {sl} (linear ⟨ θ .wu ⟩ 𝟘) x₃ In
    --   Let af   := relu up In
    --   Let down := map {sl} (linear ⟨ θ .wd ⟩ 𝟘) af In
    --   Let x₄   := down ⊞ x₂ In
    --   -- logits
    --   map {sl} (linear ⟨ θ .wc ⟩ 𝟘) x₄

    -- mgpt-loss : ∀ {Γ} (sc : ℕ)
    --                → GPTW Γ sl ed ah hd fd vo
    --                → E Γ (ar (sl ⊗ ed))
    --                → E Γ (ar (sl ⊗ vo))
    --                → E Γ (ar [])
    -- mgpt-loss {sl} {ed} {ah} {hd} {fd} {vo} sc θ ws target =
    --   Let logits := mgpt-forward sc θ ws In
    --   avg (zipwith {sl} (λ a b → cross-entropy a b) ⟨ target ⟩ logits)

    -- bgpt-forward : ∀ {Γ} (sc : ℕ)
    --             → GPTW Γ sl ed ah hd fd vo
    --             → E Γ (ar (bs ⊗ (sl ⊗ ed)))
    --             → E Γ (ar (bs ⊗ (sl ⊗ vo)))
    -- bgpt-forward {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws =
    --   -- Embedding
    --   Let wj := (assᵣ {bs} {sl} $ K {bs} (θ .wp) ⊞ ws) In
    --   Let x₀ := map {bs ⊗ sl} rmsnorm wj In
    --   Let x₁ := map {bs ⊗ sl} rmsnorm x₀ In
    --   -- Attn
    --   Let k      := map {bs ⊗ sl} (linear ⟨ θ .wkey ⟩ 𝟘) x₁ In
    --   Let q      := map {bs ⊗ sl} (linear ⟨ θ .wqry ⟩ 𝟘) x₁ In
    --   Let v      := map {bs ⊗ sl} (linear ⟨ θ .wval ⟩ 𝟘) x₁ In
    --   Let bk     :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (split (θ .att-eq)) k In
    --   Let bq     :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (split (θ .att-eq)) q In
    --   Let bv     :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (split (θ .att-eq)) v In
    --   Let scores := zipwith {bs ⊗ ah} (λ hq hk → matmult {sl} hq hk) bq bk In
    --   Let masked := map {bs ⊗ ah} (λ x → x ⊞ ⟨ θ .mask ⟩) scores In
    --   Let sf     := map {bs ⊗ ah} (map {sl} ℙ) masked In
    --   Let batt   := zipwith {bs ⊗ ah} (λ hsf hv → matmul {sl} hsf hv) sf bv In
    --   Let att    := map {bs ⊗ sl} (cat (θ .att-eq)) (trᵢ {bs} batt) In
    --   Let out    := map {bs ⊗ sl} (linear ⟨ θ .wo ⟩ 𝟘) att In
    --   Let x₂     := out ⊞ x₀ In
    --   -- Feed Forward
    --   Let x₃   := map {bs ⊗ sl} rmsnorm x₂ In
    --   Let up   := map {bs ⊗ sl} (linear ⟨ θ .wu ⟩ 𝟘) x₃ In
    --   Let af   := relu up In
    --   Let down := map {bs ⊗ sl} (linear ⟨ θ .wd ⟩ 𝟘) af In
    --   Let x₄   := down ⊞ x₂ In
    --   -- logits
    --   assₗ {bs} {sl} (map {bs ⊗ sl} (linear ⟨ θ .wc ⟩ 𝟘) x₄)

    -- bgpt-loss : ∀ {Γ} (sc : ℕ)
    --             → GPTW Γ sl ed ah hd fd vo
    --             → E Γ (ar (bs ⊗ (sl ⊗ ed)))
    --             → E Γ (ar ((bs ⊗ sl) ⊗ vo))
    --             → E Γ (ar [])
    -- bgpt-loss {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws target =
    --   -- Embedding
    --   Let wj := (assᵣ {bs} {sl} $ K {bs} (θ .wp) ⊞ ws) In
    --   Let x₀ := map {bs ⊗ sl} rmsnorm wj In
    --   Let x₁ := map {bs ⊗ sl} rmsnorm x₀ In
    --   -- Attn
    --   Let k      := map {bs ⊗ sl} (linear ⟨ θ .wkey ⟩ 𝟘) x₁ In
    --   Let q      := map {bs ⊗ sl} (linear ⟨ θ .wqry ⟩ 𝟘) x₁ In
    --   Let v      := map {bs ⊗ sl} (linear ⟨ θ .wval ⟩ 𝟘) x₁ In
    --   Let bk     :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (split (θ .att-eq)) k In
    --   Let bq     :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (split (θ .att-eq)) q In
    --   Let bv     :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (split (θ .att-eq)) v In
    --   Let scores := zipwith {bs ⊗ ah} (λ hq hk → matmult {sl} hq hk) bq bk In
    --   Let masked := map {bs ⊗ ah} (λ x → x ⊞ ⟨ θ .mask ⟩) scores In
    --   Let sf     := map {bs ⊗ ah} (map {sl} ℙ) masked In
    --   Let batt   := zipwith {bs ⊗ ah} (λ hsf hv → matmul {sl} hsf hv) sf bv In
    --   Let att    := map {bs ⊗ sl} (cat (θ .att-eq)) (trᵢ {bs} batt) In
    --   Let out    := map {bs ⊗ sl} (linear ⟨ θ .wo ⟩ 𝟘) att In
    --   Let x₂     := out ⊞ x₀ In
    --   -- Feed Forward
    --   Let x₃   := map {bs ⊗ sl} rmsnorm x₂ In
    --   Let up   := map {bs ⊗ sl} (linear ⟨ θ .wu ⟩ 𝟘) x₃ In
    --   Let af   := relu up In
    --   Let down := map {bs ⊗ sl} (linear ⟨ θ .wd ⟩ 𝟘) af In
    --   Let x₄   := down ⊞ x₂ In
    --   -- logits
    --   Let logits := map {bs ⊗ sl} (linear ⟨ θ .wc ⟩ 𝟘) x₄ In
    --   -- loss
    --   avg (zipwith {bs ⊗ sl} (λ a b → cross-entropy a b) ⟨ target ⟩ logits)

    -- record GPTW (Γ : Ctx) (sl ed ah hd fd vo : S) : Set₁ where
    --   constructor gptw
    --   field
    --     -- position embedding
    --     wp : E Γ $ ar $ sl ⊗ ed
    --     -- the embedding dimension matches the number of heads
    --     att-eq : ah * hd ≈ ed
    --     -- weights for queries, keys, values and output projection
    --     wkey wqry wval : E Γ $ ar $ (ah ⊗ hd) ⊗ ed
    --     wo : E Γ $ ar $ ed ⊗ ed
    --     -- attn and padding mask
    --     mask : E Γ $ ar $ sl ⊗ sl
    --     -- up projection
    --     wu : E Γ $ ar $ fd ⊗ ed
    --     -- down projection
    --     wd : E Γ $ ar $ ed ⊗ fd
    --     -- output projection into vocabulary size
    --     wc : E Γ $ ar $ vo ⊗ ed
    -- open GPTW

    -- wk-gptp : Prefix Γ Δ → GPTW Γ sl ed ah hd fd vo → GPTW Δ sl ed ah hd fd vo
    -- wk-gptp pr p = record
    --   { wp = wk (fromPrefix pr) (p .wp)
    --   ; att-eq = p .att-eq
    --   ; wqry = wk (fromPrefix pr) (p .wqry)
    --   ; wkey = wk (fromPrefix pr) (p .wkey)
    --   ; wval = wk (fromPrefix pr) (p .wval)
    --   ; wo = wk (fromPrefix pr) (p .wo)
    --   ; mask = wk (fromPrefix pr) (p .mask)
    --   ; wu = wk (fromPrefix pr) (p .wu)
    --   ; wd = wk (fromPrefix pr) (p .wd)
    --   ; wc = wk (fromPrefix pr) (p .wc)
    --   }

    -- G-GPTW : Ctx → S → S → S → S → S → S → Set₁
    -- G-GPTW Γ sl ed ah hd fd vo =
    --   ∀ {Δ} → ⦃ Prefix Γ Δ ⦄ → GPTW Δ sl ed ah hd fd vo

    -- ⟨_⟩ʷ : GPTW Γ sl ed ah hd fd vo → G-GPTW Γ sl ed ah hd fd vo
    -- ⟨_⟩ʷ p {Δ} ⦃ pf ⦄  = wk-gptp pf p

    -- bgpt-forward : ∀ {Γ} (sc : ℕ)
    --             → GPTW Γ sl ed ah hd fd vo
    --             → E Γ (ar (bs ⊗ (sl ⊗ ed)))
    --             → E Γ (ar (bs ⊗ (sl ⊗ vo)))
    -- bgpt-forward {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws =
    --   -- Embedding
    --   Let wj := (assᵣ {bs} {sl} $ K {bs} (θ .wp) ⊞ ws) In
    --   Let x₀ := map {bs ⊗ sl} rmsnorm wj In
    --   Let x₁ := map {bs ⊗ sl} rmsnorm x₀ In
    --   -- Attn
    --   Let k      :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (linear ⟨ θ .wkey ⟩ 𝟘) x₁ In
    --   Let q      :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (linear ⟨ θ .wqry ⟩ 𝟘) x₁ In
    --   Let v      :=
    --     trᵢ {bs} {sl} {ah} $ map {bs ⊗ sl} (linear ⟨ θ .wval ⟩ 𝟘) x₁ In
    --   Let scores := zipwith {bs ⊗ ah} (λ hq hk → matmult {sl} hq hk) q k In
    --   Let masked := map {bs ⊗ ah} (λ x → x ⊞ ⟨ θ .mask ⟩) scores In
    --   Let sf     := map {bs ⊗ ah} (map {sl} ℙ) masked In
    --   Let batt   := zipwith {bs ⊗ ah} (λ hsf hv → matmul {sl} hsf hv) sf v In
    --   Let att    := map {bs ⊗ sl} (cat (θ .att-eq)) (trᵢ {bs} batt) In
    --   Let out    := map {bs ⊗ sl} (linear ⟨ θ .wo ⟩ 𝟘) att In
    --   Let x₂     := out ⊞ x₀ In
    --   -- Feed Forward
    --   Let x₃   := map {bs ⊗ sl} rmsnorm x₂ In
    --   Let up   := map {bs ⊗ sl} (linear ⟨ θ .wu ⟩ 𝟘) x₃ In
    --   Let af   := relu up In
    --   Let down := map {bs ⊗ sl} (linear ⟨ θ .wd ⟩ 𝟘) af In
    --   Let x₄   := down ⊞ x₂ In
    --   -- logits
    --   assₗ {bs} {sl} (map {bs ⊗ sl} (linear ⟨ θ .wc ⟩ 𝟘) x₄)

    -- bgpt-forward-e : E _ _
    -- bgpt-forward-e = Lcon (
    --                 ar (SL ⊗ ED) --wp
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wkey
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wqry
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wval
    --               ∷ ar (ED ⊗ ED) --wo
    --               ∷ ar (SL ⊗ SL) --mask
    --               ∷ ar (FD ⊗ ED) --wu
    --               ∷ ar (ED ⊗ FD) --wd
    --               ∷ ar (VO ⊗ ED) --wc
    --               ∷ ar (BS ⊗ (SL ⊗ ED)) --ws
    --               ∷ []) (ar $ BS ⊗ (SL ⊗ VO)) ε
    --               λ wp wkey wqry wval wo mask wu wd wc ws
    --               → let θ = gptw wp PR wkey wqry wval wo mask wu wd wc in
    --                 bgpt-forward {sl = SL} {vo = VO} {bs = BS} SC θ ws


    -- mgpt-forward : ∀ {Γ} (sc : ℕ)
    --                → GPTW Γ sl ed ah hd fd vo
    --                → E Γ (ar (sl ⊗ ed))
    --                → E Γ (ar (sl ⊗ vo))
    -- mgpt-forward {sl} {ed} {ah} {hd} {fd} {vo} sc θ ws =
    --   -- Embedding
    --   Let wj := (θ .wp) ⊞ ws In
    --   Let x₀ := map {sl} rmsnorm wj In --residual
    --   Let x₁ := map {sl} rmsnorm x₀ In
    --   -- Attn
    --   Let k      := map {sl} (linear ⟨ θ .wkey ⟩ 𝟘) x₁ In
    --   Let q      := map {sl} (linear ⟨ θ .wqry ⟩ 𝟘) x₁ In
    --   Let v      := map {sl} (linear ⟨ θ .wval ⟩ 𝟘) x₁ In
    --   Let bk     := trₗ {sl} {ah} $ map {sl} (split (θ .att-eq)) k In
    --   Let bq     := trₗ {sl} {ah} $ map {sl} (split (θ .att-eq)) q In
    --   Let bv     := trₗ {sl} {ah} $ map {sl} (split (θ .att-eq)) v In
    --   Let scores := zipwith {ah} (λ hq hk → matmult {sl} hq hk) bq bk In
    --   Let masked := map {ah} (λ x → x ⊞ ⟨ θ .mask ⟩) scores In
    --   Let sf     := map {ah} (map {sl} ℙ) masked In
    --   Let batt   := zipwith {ah} (λ hsf hv → matmul {sl} hsf hv) sf bv In
    --   Let att    := map {sl} (cat (θ .att-eq)) (trₗ {ah} {sl} batt) In
    --   Let out    := map {sl} (linear ⟨ θ .wo ⟩ 𝟘) att In
    --   Let x₂     := out ⊞ x₀ In --residual
    --   -- Feed Forward
    --   Let x₃   := map {sl} rmsnorm x₂ In
    --   Let up   := map {sl} (linear ⟨ θ .wu ⟩ 𝟘) x₃ In
    --   Let af   := relu up In
    --   Let down := map {sl} (linear ⟨ θ .wd ⟩ 𝟘) af In
    --   Let x₄   := down ⊞ x₂ In
    --   -- logits
    --   map {sl} (linear ⟨ θ .wc ⟩ 𝟘) x₄

    -- bgpt-forward : ∀ {Γ} (sc : ℕ)
    --                → GPTW Γ sl ed ah hd fd vo
    --                → E Γ (ar (bs ⊗ (sl ⊗ ed)))
    --                → E Γ (ar (bs ⊗ (sl ⊗ vo)))
    -- bgpt-forward {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws =
    --   map {bs} (λ x → mgpt-forward sc ⟨ θ ⟩ʷ x) ws

    -- mgpt-forward-e : E _ _
    -- mgpt-forward-e = Lcon (
    --                 ar (SL ⊗ ED) --wp
    --               ∷ ar (ED ⊗ ED) --wkey
    --               ∷ ar (ED ⊗ ED) --wqry
    --               ∷ ar (ED ⊗ ED) --wval
    --               ∷ ar (ED ⊗ ED) --wo
    --               ∷ ar (SL ⊗ SL) --mask
    --               ∷ ar (FD ⊗ ED) --wu
    --               ∷ ar (ED ⊗ FD) --wd
    --               ∷ ar (VO ⊗ ED) --wc
    --               ∷ ar (SL ⊗ ED) --ws
    --               ∷ []) (ar $ SL ⊗ VO) ε
    --               λ wp wkey wqry wval wo mask wu wd wc ws
    --               → let θ = gptw wp PR wkey wqry wval wo mask wu wd wc in
    --                 mgpt-forward {sl = SL} {vo = VO} SC θ ws

    -- gpt-forward : ∀ {Γ} → ℕ → GPTW Γ sl ed ah hd fd vo
    --               → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
    --               → E Γ $ ar $ (bs ⊗ sl) ⊗ vo
    -- gpt-forward {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws =
    --   Let wj := ws ⊞ assᵣ {bs} (K {bs} $ θ .wp) In
    --   Let x₀ := map {bs ⊗ sl} rmsnorm wj In --residual
    --   -- block
    --   Let x₁ := map {bs ⊗ sl} rmsnorm x₀ In
    --   ---- attn
    --   ------ calculate key/query/val and swap dimensions
    --   Let k := trᵢ {bs} {sl} {ah} $
    --     map {bs ⊗ sl} {q = ah ⊗ hd} (linear ⟨ θ .wkey ⟩ 𝟘) x₁ In
    --   Let q := trᵢ {bs} {sl} {ah} $
    --     map {bs ⊗ sl} {q = ah ⊗ hd} (linear ⟨ θ .wqry ⟩ 𝟘) x₁ In
    --   Let v := trᵢ {bs} {sl} {ah} $
    --     map {bs ⊗ sl} {q = ah ⊗ hd} (linear ⟨ θ .wval ⟩ 𝟘) x₁ In
    --   ------ calculate scores
    --   Let scores := zipwith {bs ⊗ ah}
    --     (λ a b → (scaledown sc $ matmult {sl} a b) ⊠ ⟨ θ .mask ⟩) q k In
    --   ------ apply softmax to each row
    --   Let sf  := map {bs ⊗ ah} ℙ scores In
    --   ------ multiply by val, swap dimensions, and cat
    --   Let att := map (cat $ θ .att-eq) $ trᵢ {bs} {ah} {sl} $
    --               zipwith {bs ⊗ ah} (matmul {sl}) sf v In
    --   Let out := map {bs ⊗ sl} {q = ed} (linear ⟨ θ .wo ⟩ 𝟘) att In
    --   Let x₂  := x₀ ⊞ out In --residual
    --   ---- feed forward
    --   Let x₃ := map {bs ⊗ sl} rmsnorm x₂ In
    --   Let up := map {bs ⊗ sl} {q = fd} (linear ⟨ θ .wu ⟩ 𝟘) x₃ In
    --   Let rl := relu up In
    --   Let down := map {bs ⊗ sl} {q = ed} (linear ⟨ θ .wd ⟩ 𝟘) rl In
    --   Let x₄ := x₂ ⊞ down In
    --   -- logits
    --   map {bs ⊗ sl} {q = vo} (linear ⟨ θ .wc ⟩ 𝟘) x₄

    -- gpt-loss : ∀ {Γ} → ℕ → GPTW Γ sl ed ah hd fd vo
    --               → E Γ $ ar $ (bs ⊗ sl) ⊗ ed
    --               → E Γ $ ar $ (bs ⊗ sl) ⊗ vo
    --               → E Γ $ ar []
    -- gpt-loss {sl} {ed} {ah} {hd} {fd} {vo} {bs} sc θ ws target =
    --   Let wj := ws ⊞ assᵣ {bs} (K {bs} $ θ .wp) In
    --   Let x₀ := map {bs ⊗ sl} rmsnorm wj In --residual
    --   -- block
    --   Let x₁ := map {bs ⊗ sl} rmsnorm x₀ In
    --   ---- attn
    --   ------ calculate key/query/val and swap dimensions
    --   Let k := trᵢ {bs} {sl} {ah} $
    --     map {bs ⊗ sl} {q = ah ⊗ hd} (linear ⟨ θ .wkey ⟩ 𝟘) x₁ In
    --   Let q := trᵢ {bs} {sl} {ah} $
    --     map {bs ⊗ sl} {q = ah ⊗ hd} (linear ⟨ θ .wqry ⟩ 𝟘) x₁ In
    --   Let v := trᵢ {bs} {sl} {ah} $
    --     map {bs ⊗ sl} {q = ah ⊗ hd} (linear ⟨ θ .wval ⟩ 𝟘) x₁ In
    --   ------ calculate scores
    --   Let scores := zipwith {bs ⊗ ah}
    --     (λ a b → (scaledown sc $ matmult {sl} a b) ⊠ ⟨ θ .mask ⟩) q k In
    --   ------ apply softmax to each row
    --   Let sf  := map {bs ⊗ ah} ℙ scores In
    --   ------ multiply by val, swap dimensions, and cat
    --   Let att := map (cat $ θ .att-eq) $ trᵢ {bs} {ah} {sl} $
    --               zipwith {bs ⊗ ah} (matmul {sl}) sf v In
    --   Let out := map {bs ⊗ sl} {q = ed} (linear ⟨ θ .wo ⟩ 𝟘) att In
    --   Let x₂  := x₀ ⊞ out In --residual
    --   ---- feed forward
    --   Let x₃ := map {bs ⊗ sl} rmsnorm x₂ In
    --   Let up := map {bs ⊗ sl} {q = fd} (linear ⟨ θ .wu ⟩ 𝟘) x₃ In
    --   Let rl := relu up In
    --   Let down := map {bs ⊗ sl} {q = ed} (linear ⟨ θ .wd ⟩ 𝟘) rl In
    --   Let x₄ := x₂ ⊞ down In
    --   -- logits
    --   Let logits := map {bs ⊗ sl} {q = vo} (linear ⟨ θ .wc ⟩ 𝟘) x₄ In
    --   -- loss
    --   avg (zipwith {bs ⊗ sl} (λ a b → cross-entropy a b) ⟨ target ⟩ logits)

    -- gpt-forward-e : E _ _
    -- gpt-forward-e = Lcon (
    --                 ar (SL ⊗ ED) --wp
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wkey
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wqry
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wval
    --               ∷ ar (ED ⊗ ED) --wo
    --               ∷ ar (SL ⊗ SL) --mask
    --               ∷ ar (FD ⊗ ED) --wu
    --               ∷ ar (ED ⊗ FD) --wd
    --               ∷ ar (VO ⊗ ED) --wc
    --               ∷ ar ((BS ⊗ SL) ⊗ ED) --ws
    --               ∷ []) (ar $ (BS ⊗ SL) ⊗ VO) ε
    --               λ wp wkey wqry wval wo mask wu wd wc ws
    --               → let θ = gptw wp PR wkey wqry wval wo mask wu wd wc in
    --                 gpt-forward {sl = SL} {vo = VO} {bs = BS} SC θ ws

    -- gpt-loss-e : E _ _
    -- gpt-loss-e = Lcon (
    --                 ar (SL ⊗ ED) --wp
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wkey
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wqry
    --               ∷ ar ((AH ⊗ HD) ⊗ ED) --wval
    --               ∷ ar (ED ⊗ ED) --wo
    --               ∷ ar (SL ⊗ SL) --mask
    --               ∷ ar (FD ⊗ ED) --wu
    --               ∷ ar (ED ⊗ FD) --wd
    --               ∷ ar (VO ⊗ ED) --wc
    --               ∷ ar ((BS ⊗ SL) ⊗ ED) --ws
    --               ∷ ar ((BS ⊗ SL) ⊗ VO) --target
    --               ∷ []) (ar []) ε
    --               λ wp wkey wqry wval wo mask wu wd wc ws target
    --               → let θ = gptw wp PR wkey wqry wval wo mask wu wd wc in
    --                 gpt-loss {sl = SL} {vo = VO} {bs = BS} SC θ ws target
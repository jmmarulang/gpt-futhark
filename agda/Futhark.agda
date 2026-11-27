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

  Mem : Set → Set
  Mem = (String → String) ×_

  Futᵇ : BT → Set
  Futᵇ ℝ     = Mem String
  Futᵇ (ℙ s) = Ix s

  F : Set → Set
  F X = State ℕ X

  data Fut : IS → Set where
    full  : (Ix s → F $ Futᵇ B) → Fut (ar′ s B)
    part′ : (Ix s → F $ Mem $ (Fut $ ar p)) → (s Ar.⊗ p) ≡ r → Fut (ar r)

  part : (Ix s → F $ Mem $ (Fut $ ar p)) → Fut (ar (s Ar.⊗ p))
  part f = part′ f refl

  index : Ix s → Fut (ix s)
  index i = full λ _ → return i

  Futᶜ : Ctx → Set
  Futᶜ ε = ⊤
  Futᶜ (Γ ▹ is) = Futᶜ Γ × Fut is

  lookup : is ∈ Γ → Futᶜ Γ → Fut is
  lookup v₀ (ρ , e) = e
  lookup (there x) (ρ , e) = lookup x ρ

  fresh-i : ∀ n → State ℕ (SFin n)
  fresh-i n = do
    c ← get
    modify suc
    let i = printf "i%u" c
    return (val i)

  fresh-var : State ℕ String
  fresh-var = do
    c ← get
    modify suc
    let x = printf "x%u" c
    return x

  fresh-ix : ∀ s → State ℕ (Ix s)
  fresh-ix [] = pure []
  fresh-ix (x ∷ s) = _∷_ <$> fresh-i x <*> fresh-ix s

  named-i : ∀ {n} → String → SFin n
  named-i str = val str

  named-ix′ : ∀ s → String → Ix s
  named-ix′ [] str = []
  named-ix′ (n ∷ s) str = named-i str ∷ named-ix′ s str

  -- CHECK
  named-ix : String → Fut (ari s p)
  named-ix {s} {p} str = full (λ i → return (named-ix′ p str))

  shape-args : S → String
  shape-args s = intersperse " " $ L.map show-nat s

  dim : S → ℕ
  dim s = L.length s

  ix-join : Ix s → String → String
  ix-join [] d = ""
  ix-join (x ∷ []) d = getVal x
  ix-join {s = _ ∷ s} (x ∷ y ∷ xs) d = getVal x ++ d ++ ix-join {s} (y ∷ xs) d

  to-imap : (s : S) → (i : Ix s) → (e : String) → String
  to-imap s i e = printf "(imap%u %s (\\%s -> %s))" (dim s) (shape-args s) (ix-join i " ") e

  _⊗ⁱ_ : Ix s → Ix p → Ix (s Ar.⊗ p)
  [] ⊗ⁱ js = js
  (i ∷ is) ⊗ⁱ js = i ∷ (is ⊗ⁱ js)

  splitⁱ : (ij : Ix (s Ar.⊗ p)) → Σ (Ix s) λ i → Σ (Ix p) λ j → i ⊗ⁱ j ≡ ij
  splitⁱ {[]} ij = [] , ij , refl
  splitⁱ {_ ∷ s} (x ∷ ij) with splitⁱ {s} ij
  ... | i , j , refl = (x ∷ i) , j , refl

  ix-map : (String → String) → Ix s → Ix s
  ix-map f [] = []
  ix-map f (x ∷ i) = val (f (getVal x)) ∷ ix-map f i

  to-sel : Ix s → String → String
  to-sel i a = a ++ ix-join (ix-map (printf "[%s]") i) ""

  range-i′ : ℕ → Ix s
  range-i′ {[]} n = []
  range-i′ {m ∷ s} n = (val $ printf "%u" n) ∷ range-i′ (suc n)

  range-i : Ix s
  range-i = range-i′ 0

  ix-zipwith : ((a b : String) → String) → Ix s → Ix s → Ix s
  ix-zipwith f [] [] = []
  ix-zipwith f (x ∷ i) (y ∷ j) = val (f (getVal x) (getVal y)) ∷ ix-zipwith f i j

  {-# TERMINATING #-} -- What is wrong with you, Agda?
  sem-sel-fut : Fut (ar′ s B) → Ix s → State ℕ (Futᵇ B)
  sem-sel-fut {B = ℝ} (full x) i = do
    f , b ← x i
    return (f , b)
  sem-sel-fut {B = ℝ} (part′ {r} x refl) ij = do
    let i , j , pr = splitⁱ {r} ij
    f , r ← x i
    h , b ← sem-sel-fut r j
    return ((h ∘ f) , b)
  sem-sel-fut {B = ℙ p} (full {s = s} f) i = do
    x ← f i
    let y = ix-map (λ st → (to-sel i st)) x
    let r = ix-map {p} (printf "[%s]") range-i
    return $ ix-zipwith _++_ y r

  {-# TERMINATING #-} -- What is wrong with you, Agda?
  sem-imap′ : Fut (ar s) → State ℕ String
  sem-imap′ {s} (full f) with s
  ... | [] = do
    f , a ← f []
    return (f a)
  ... | s′ = do
    iv ← fresh-ix s′
    f , a ← f iv
    return (f $ to-imap s′ iv a)

  sem-imap′ {s} (part′ {p}{r} f refl) = do
    iv ← fresh-ix p
    h , a ← f iv
    b ← sem-imap′ a
    return (h $ to-imap p iv b)

  {-# TERMINATING #-} -- What is wrong with you, Agda?
  sem-imap : Fut (ar′ s B) → State ℕ (Futᵇ B)
  sem-imap {s} {ℝ} (full f) with s
  ... | [] = do
    f , a ← f []
    return (f , a)
  ... | s′ = do
    iv ← fresh-ix s′
    f , a ← f iv
    return $ f ∘ to-imap s′ iv , a
  sem-imap {s} {ℝ} (part′ {p}{r} f refl) = do
    iv ← fresh-ix p
    h , a ← f iv
    g , b ← sem-imap a
    -- CHECK
    return $ h ∘ to-imap p iv , g b
  sem-imap {s} {ℙ P} (full f) with s
  ... | [] = do
    a ← f []
    -- CHECK
    return a
  ... | s′ = do
    iv ← fresh-ix s′
    a ← f iv
    -- CHECK
    return $ ix-map (to-imap s′ iv) a

  to-softmax : (s : S) → (i : Ix s) → (e : String) → String
  to-softmax [] i e = e
  to-softmax s  i e = printf "(isoftmax%u %s (\\%s -> %s))" (dim s) (shape-args s)
                         (ix-join i " ") e

  ix-eq : (i j : Ix s) → String
  ix-eq i j = ix-join (ix-zipwith (printf "(%s == %s)") i j) " && "

  mkar : String → Ix s → State ℕ ((String → String) × String)
  mkar a i = return (id , to-sel i a)

  to-div-mod : s * p ≈ q → Ix q
             → Ix s × Ix p
  to-div-mod [] [] = [] , []
  to-div-mod (cons {m = m} {n = n} ⦃ _ ⦄ ⦃ eq ⦄) ((val x) ∷ i) =
    Prod.map (val (printf "(%s / %s)" x (show-nat n)) ∷_)
             (val (printf "(%s %% %s)" x (show-nat n)) ∷_)
             (to-div-mod eq i)

  from-div-mod : s * p ≈ q
               → Ix s → Ix p
               → Ix q
  from-div-mod [] [] [] = []
  from-div-mod (cons {n = n} ⦃ _ ⦄ ⦃ eq ⦄) (val i ∷ is) (val j ∷ js) =
    val (printf "((%s * %s) + %s)" i (show-nat n) j)
    ∷ (from-div-mod eq is js)

  to-sum : (s : S) → (i : Ix s) → (e : String) → String
  to-sum [] i e = e
  to-sum s  i e = printf "(isum%u %s (\\%s -> %s))" (dim s) (shape-args s)
                         (ix-join i " ") e

  sem-sum : Fut (ar p) → Ix s → Ix p → State ℕ String
  sem-sum {s = s} a i j = do
    f , b ← sem-sel-fut a j
    --CHECK
    return (to-sum s i (f b))

  ix-curry : (Ix (s Ar.⊗ p) → X) → Ix s → Ix p → X
  ix-curry f i j = f (i ⊗ⁱ j)

  ix-uncurry : (Ix s → Ix p → X) → Ix (s Ar.⊗ p) → X
  ix-uncurry {s = s} f ij with splitⁱ {s} ij
  ... | i , j , refl = f i j

  to-fut : E Γ (ar′ s B) → Futᶜ Γ → State ℕ (Fut $ ar′ s B)
  to-str : E Γ (ar s) → Futᶜ Γ → State ℕ String

  -- TODO: Define using sem-imap
  to-str e ρ = to-fut e ρ >>= sem-imap′

  to-fut 𝟘 ρ = pure $ full λ _ → return (id , "zero")
  to-fut 𝟙 ρ = pure $ full λ _ → return (id , "one")

  to-fut (scaledown x e) ρ = do
    a ← to-fut e ρ
    return $ full λ i → do
      f , b ← sem-sel-fut a i
      -- CHECK
      return (f , printf "(%s F./ fromi64 %s)" b (show-nat x))
  to-fut (⊟ e) ρ = do
    a ← to-fut e ρ
    return $ full λ i → do
      f , b ← sem-sel-fut a i
      -- CHECK
      return (id , printf "(F.neg %s)" (f b))
  to-fut (relu e) ρ = do
    a ← to-fut e ρ
    return $ full λ i → do
      f , b ← sem-sel-fut a i
      -- CHECK
      return (id , printf "(F.max %s zero)" (f b))
  to-fut (√ e) ρ = do
    a ← to-fut e ρ
    return $ full λ i → do
      f , b ← sem-sel-fut a i
      -- CHECK
      return (id , printf "(F.sqrt %s)" (f b))
  to-fut (𝟙/ e) ρ = do
    a ← to-fut e ρ
    return $ full λ i → do
      f , b ← sem-sel-fut a i
      -- CHECK
      return (id , printf "(one F./ %s)" (f b))
  to-fut (𝕚+ e) ρ = do
    a ← to-fut e ρ
    return $ full λ i → do
      f , b ← sem-sel-fut a i
      -- CHECK
      return (id , printf "(indicatorp %s)" (f b))
  to-fut (ln e) ρ = do
    a ← to-fut e ρ
    return $ full λ i → do
      f , b ← sem-sel-fut a i
      -- CHECK
      return (id , printf "(F.log %s)" (f b))
  to-fut (softmax {s = s} e) ρ = do
    i ← fresh-ix s
    sf ← fresh-var
    a ← to-fut e ρ
    return $ full λ j → do
      f , b ← sem-sel-fut a i
      return (printf "(let %s = %s\nin %s)" sf (to-softmax s i (f b)) , to-sel j sf)
  to-fut (e ⊞ e₁) ρ = do
    l ← to-fut e ρ
    r ← to-fut e₁ ρ
    return $ full λ i → do
      f , b ← sem-sel-fut l i
      g , c ← sem-sel-fut r i
      -- CHECK
      return (id , printf "(%s F.+ %s)" (f b) (g c))
  to-fut (e ⊠ e₁) ρ = do
    l ← to-fut e ρ
    r ← to-fut e₁ ρ
    return $ full λ i → do
      f , b ← sem-sel-fut l i
      g , c ← sem-sel-fut r i
      -- CHECK
      return (id , printf "(%s F.* %s)" (f b) (g c))

  to-fut (zero-but e e₁ e₂) ρ = do
    full i ← to-fut e ρ
    i ← i []
    full j ← to-fut e₁ ρ
    j ← j []
    a ← to-fut e₂ ρ
    return $ full λ k → do
      f , b ← sem-sel-fut a k
      return (id , printf "(if (%s) then %s else zero)" (ix-eq i j) (f b))
  to-fut (let′ {s = s}{p} e e₁) ρ = do
    n ← fresh-var
    to-fut e₁ (ρ , full (mkar n)) >>= λ where
      (full a) → return $ full λ i → do
        x ← to-str e ρ
        f , v ← a i
        return (printf "(let %s = %s\nin %s)" n x ∘ f , v)
      (part′ {r}{q} a refl) → return $ part {r}{q} λ i → do
        x ← to-str e ρ
        f , v ← a i
        return (printf "(let %s = %s\nin %s)" n x ∘ f , v)
  to-fut (var x) ρ = return $ lookup x ρ

  to-fut (sum′ {s = s} refl e) ρ = do
    i ← fresh-ix s
    b ← to-fut e (ρ , index i)
    return $ full λ j → do
      c ← sem-sum b i j
      return (id , c)
  to-fut (imaps {s = s} e) ρ = do
    return $ full λ i → do
      b ← to-fut e (ρ , index i)
      r ← sem-imap b
      -- CHECK
      return r
  to-fut {B = ℝ} (imap′ {B} {s} {p} {_} refl e) ρ = do
    return $ part {s}{p} λ i → do
      b ← to-fut e (ρ , index i)
      return (id , b)
  to-fut {B = ℙ r} (imap′ {B} {s} {p} {_} refl e) ρ = do
    return $ full $ ix-uncurry {s} λ i j → do
      full b ← to-fut e (ρ , index i)
      b′ ← b j
      -- Check
      return b′
  to-fut (imapb {s = s} {p = p} {q = q} pf e) ρ = do
    return $ full λ i → do -- is plain correct?
      let (j , k) = to-div-mod pf i
      b ← to-fut e (ρ , index j)
      r ← sem-sel-fut b k
      --CHECK
      return r

  to-fut {s = s} {B} (sels e e₁) ρ = do
    a ← to-fut e ρ
    full x ← to-fut e₁ ρ
    x ← x []
    b ← sem-sel-fut a x
    return $ full λ _ → return b
  to-fut (sel′ refl e e₁) ρ = do
    a ← to-fut e ρ
    full x ← to-fut e₁ ρ
    i ← x []
    return $ full λ j → do
      b ← sem-sel-fut a (ix-curry id i j)
      --CHECK
      return b
  to-fut (selb {s}{p}{q} pf e e₁) ρ = do
    a ← to-fut e ρ
    full x ← to-fut e₁ ρ
    i ← x []
    return $ full λ j → do
      let k = from-div-mod pf i j
      b ← sem-sel-fut a k
      return b

module _ where
open import Relation.Binary.PropositionalEquality
open import Data.List
open import Data.Product
open import Data.Nat
open import Data.String
open import Function
open import Lang
open import Ar
open Syntax

open import Effect.Monad.State
open import Effect.Monad using (RawMonad)
open RawMonadState {{...}} -- public
open RawMonad {{...}} -- public

instance
  _ = monad
  _ = applicative
  _ = monadState

infixl 5 _,,_
_,,_ = _,′_

test₁-e : E _ _
test₁-e = Lcon (ar (5 ∷ 5 ∷ []) ∷ ari (3 ∷ []) (5 ∷ 5 ∷ []) ∷ []) (ar _) ε
          λ w is → Imap λ i → sel w (sel (Imaps λ j → sels is j) i)

test₁-s : String
test₁-s = proj₂ (runState (to-str test₁-e ((_ , full (mkar "a")) , named-ix "id")) 0)
-- Exp : imap[]
-- Got : "(imap1 3 (\\i0 -> a[id[i0][0][i0][0]][id[i0][1][i0][1]]))"

test₂-e : E _ _
test₂-e = Lcon (ar (5 ∷ 5 ∷ []) ∷ ari (3 ∷ 3 ∷ []) (5 ∷ 5 ∷ []) ∷ []) (ar _) ε
          λ w is → Imap {3 ∷ 3 ∷ []} λ i → sel w (sel is i)

test₂-s : String
test₂-s = proj₂ (runState (to-str test₂-e ((_ , full (mkar "a")) , named-ix "id")) 0)
-- "(imap2 3 3 (\\i0 i1 -> a[id[i0][i1][0]][id[i0][i1][1]]))"

test₃-e : E _ _
test₃-e = Lcon (ar (5 ∷ []) ∷ ari (3 ∷ []) (5 ∷ []) ∷ []) (ar (3 ∷ [])) ε
          λ w is → Imaps λ i → sels w (sels is i)

test₃-s : String
test₃-s = proj₂ (runState (to-str test₃-e ((_ , full (mkar "a")) , named-ix "id")) 0)
-- Exp: (imap1 3 (\\i0 -> a[id[i0][0]]))
-- Got: (imap1 3 (\\i0 -> a[id[i0][0]]))

-- Lets inside the summand must stay under the isum binder.
test₄-e : E _ _
test₄-e = Lcon (ar (5 ∷ []) ∷ []) (ar []) ε
          λ a → Sum {5 ∷ []} λ i → Let x := sels a i In (x ⊞ x)

test₄-s : String
test₄-s = proj₂ (runState (to-str test₄-e (_ , full (mkar "a"))) 0)
-- Expected: "(isum1 5 (\\i0 -> (let x1 = a[i0] in (x1 F.+ x1))))"

-- Summing an imap (combined) must produce a single isum.
test₅-e : E _ _
test₅-e = Lcon (ar (5 ∷ []) ∷ []) (ar (3 ∷ [])) ε
          λ a → Sum {5 ∷ []} λ i → Imap {3 ∷ []} {[]} λ j → sels a i

test₅-s : String
test₅-s = proj₂ (runState (to-str test₅-e (_ , full (mkar "a"))) 0)
-- Expected: "(imap1 3 (\\i1 -> (isum1 5 (\\i0 -> a[i0]))))"

-- Lets of the softmax argument must be bound before isoftmax uses them.
test₆-e : E _ _
test₆-e = Lcon (ar (5 ∷ []) ∷ []) (ar (5 ∷ [])) ε
          λ a → softmax (Let y := a ⊞ a In y)

test₆-s : String
test₆-s = proj₂ (runState (to-str test₆-e (_ , full (mkar "a"))) 0)
-- Expected:
-- "(let x1 = (isoftmax1 5 (\\i0 -> (let x2 = (imap1 5 (\\i4 -> (a[i4] F.+ a[i4])))
-- in x2[i0])))
-- in (imap1 5 (\\i3 -> x1[i3])))"

-- "(let x1 = (isoftmax1 5 (\\i0 -> (let x2 = (imap1 5 (\\i4 -> (a[i4] F.+ a[i4])))
-- in x2[i0])))
-- in (imap1 5 (\\i3 -> x1[i3])))"
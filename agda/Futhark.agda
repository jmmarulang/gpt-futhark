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

  F : S → Set → Set
  F s X = Ix s → State ℕ ((String → String) × X)

  data Sem : IS → Set where
    plain : F s String → Sem (ar s)
    combined : F s (Sem (ar p)) →  Sem (ar (s Ar.⊗ p))
    index : Ix s → Sem (ix s)

  subst-plain : ∀ {x} → {d : s L.++ p ≡ q}
    → subst (Sem ∘ ar) (sym d) (plain x) ≡
      plain (subst (λ y → F y _) (sym d) x)
  subst-plain {d = refl} = refl

  isCombined : (a : Sem (ar q))
    → Dec (∃₂ λ s p → Σ (s L.++ p ≡ q) λ eq
      → ∃ (λ t → subst (Sem ∘ ar) (sym eq) a ≡ combined {s}{p} t))
  isCombined (plain _) = no foo where
    foo : _
    foo (s , _ , _ , _ , eq) with (sym (subst-plain {s = s}) ∙ eq)
    ... | ()
  isCombined (combined {s}{p} a) = yes (s , p , refl , a , refl)

  -- Here is a detailed explanation why the type for semantic
  -- arrays look so complicated.
  --
  -- A first approximation is to use semantic type for arrays
  -- as `Sem (ar s) = Ix s → State ℕ String`.  That is, we have
  -- something indexable but after indexing it might need to
  -- generate some fresh variables.  The problem is that this
  -- prevents us from compiling lets in the right way.
  -- Consider an example:
  --    Let z := zero in Imaps λ i → z
  --
  -- The output of this function is an array, so the body
  -- of the let will have a type `Ix s → State ℕ String`,
  -- and it will look something like:
  --    f i = "let z = 0 in " ++ (λ j → "z") i.
  --
  -- If we are selecting into such an array, it is fine, as
  -- `f j` evaluates into "let z := 0 in z".  However, how
  -- do we turn this into an imap expression now?  Given that
  -- we cannot look inside `f`, the only function is to generate
  -- somethihg like:
  --    "imap λ i → " ++ f "i"
  --
  -- which results in:
  --    "imap λ i → let z = 0 in z"
  --
  -- while this is correct semantically, this inlines let
  -- computations which results in very inefficient codLang.
  -- Just imagine that instead of zero we are precomputing
  -- an expensive array:
  --    Let z := (Imap expensive) in Imaps λ i → f (sels z i)
  --
  -- by inlining this computation inside the Imaps we are going
  -- to repeat it for each iteration just to select one element.
  --
  -- We avoid this, by giving the body of `f` a little more
  -- structurLang.  In particular, we introduce a function that
  -- remembers where the selectable expression goes, and the
  -- expression itself.  In the above case, the function
  -- will look like `λ s → "let z = 0 in " ++ s`, and the
  -- selectable expression is the same `(λ j → "z") i`.
  -- Which make it possible to produce:
  --    "let z := 0 in imap λ i → z"
  --
  -- Note, that for general selections into lets, such as
  --   sel (let x = e in e₁) i
  -- it is safe to translate this into (let x = e in sel e₁ i).
  -- While it is tempting to pre-select only those parts of e
  -- that are needed to compute (sel e₁ i), there is no easy
  -- way to do this for all cases.

  FEnv : Ctx → Set
  FEnv ε = ⊤
  FEnv (Γ ▹ is) = FEnv Γ × Sem is

  lookup : is ∈ Γ → FEnv Γ → Sem is
  lookup v₀ (ρ , e) = e
  lookup (there x) (ρ , e) = lookup x ρ

  --show-shape : S → String
  --show-shape s = printf "[%s]" $ intersperse ", " $ L.map show-nat s

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

  fresh-i-named : ∀ n → String → State ℕ (SFin n)
  fresh-i-named n st = do
    c ← get
    modify suc
    let i = printf "%s%u" st c
    return (val i)

  fresh-ix-named' : ∀ s → String → State ℕ (Ix s)
  fresh-ix-named' [] st = pure []
  fresh-ix-named' (x ∷ s) st = _∷_ <$> fresh-i-named x st <*> fresh-ix-named' s st

  fresh-ix-named : ∀ s → String → Ix s
  fresh-ix-named s st = proj₂ (runState (fresh-ix-named' s st) 0)

  shape-args : S → String
  shape-args s = intersperse " " $ L.map show-nat s

  dim : S → ℕ
  dim s = L.length s

  -- bop : Bop -> String
  -- bop plus = "F.+"
  -- bop mul = "F.*"

  show-array-type : S → String
  show-array-type [] = "f32"
  show-array-type s = printf "%sf32" $ intersperse "" $ L.map (printf "[%s]" ∘ show-nat) s

  _⊗ⁱ_ : Ix s → Ix p → Ix (s Ar.⊗ p)
  [] ⊗ⁱ js = js
  (i ∷ is) ⊗ⁱ js = i ∷ (is ⊗ⁱ js)

  splitⁱ : (ij : Ix (s Ar.⊗ p)) → Σ (Ix s) λ i → Σ (Ix p) λ j → i ⊗ⁱ j ≡ ij
  splitⁱ {[]} ij = [] , ij , refl
  splitⁱ {_ ∷ s} (x ∷ ij) with splitⁱ {s} ij
  ... | i , j , refl = (x ∷ i) , j , refl

  ix-curry : (Ix (s Ar.⊗ p) → X) → Ix s → Ix p → X
  ix-curry f i j = f (i ⊗ⁱ j)

  ix-uncurry : (Ix s → Ix p → X) → Ix (s Ar.⊗ p) → X
  ix-uncurry {s = s} f ij with splitⁱ {s} ij
  ... | i , j , refl = f i j

  ix-map : (String → String) → Ix s → Ix s
  ix-map f [] = []
  ix-map f (x ∷ i) = val (f (getVal x)) ∷ ix-map f i

  ix-zipwith : ((a b : String) → String) → Ix s → Ix s → Ix s
  ix-zipwith f [] [] = []
  ix-zipwith f (x ∷ i) (y ∷ j) = val (f (getVal x) (getVal y)) ∷ ix-zipwith f i j

  ix-join : Ix s → String → String
  ix-join [] d = ""
  ix-join (x ∷ []) d = getVal x
  ix-join {s = _ ∷ s} (x ∷ y ∷ xs) d = getVal x ++ d ++ ix-join {s} (y ∷ xs) d

  ix-to-list : Ix s → List String
  ix-to-list [] = []
  ix-to-list (x ∷ xs) = getVal x ∷ ix-to-list xs

  -- first argument is an index i, second is a variable x. Gives you x[i]
  to-sel : Ix s → String → String
  to-sel i a = a ++ ix-join (ix-map (printf "[%s]") i) ""

  to-imap : (s : S) → (i : Ix s) → (e : String) → String
  to-imap s i e = printf "(imap%u %s (\\%s -> %s))"
                   (dim s) (shape-args s) (ix-join i " ")
                   e
  to-sum : (s : S) → (i : Ix s) → (e : String) → String
  to-sum [] i e = e
  to-sum s  i e = printf "(isum%u %s (\\%s -> %s))" (dim s) (shape-args s)
                         (ix-join i " ") e

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

  ix-eq : (i j : Ix s) → String
  ix-eq i j = ix-join (ix-zipwith (printf "(%s == %s)") i j) " && "

  ix-plus : s + p ≈ r → (suc_≈_ p u)
          → (i : Ix s)
          → (j : Ix u)
          → Ix r
  ix-plus []  [] [] [] = []
  ix-plus (cons ⦃ _ ⦄ ⦃ s+p ⦄) (cons ⦃ _ ⦄ ⦃ sp ⦄) (val i ∷ is) (val j ∷ js) =
    val (printf "(%s + %s)" i j) ∷ (ix-plus s+p sp is js)

  ix-minus : s + p ≈ r → (suc_≈_ p u)
           → (i : Ix r)
           → (j : Ix s)
           → Ix u
  ix-minus []  [] [] [] = []
  ix-minus (cons ⦃ _ ⦄ ⦃ s+p ⦄) (cons ⦃ _ ⦄ ⦃ sp ⦄) (val i ∷ is) (val j ∷ js) =
    val (printf "(%s - %s)" i j) ∷ ix-minus s+p sp is js

  to-softmax : (s : S) → (i : Ix s) → (e : String) → String
  to-softmax [] i e = e
  to-softmax s  i e = printf "(isoftmax%u %s (\\%s -> %s))" (dim s) (shape-args s)
                         (ix-join i " ") e

  {-# TERMINATING #-}
  sem-sel-fut : Sem (ar s) → Ix s → State ℕ (String)
  sem-sel-fut (plain x) i = do
    f , b ← x i
    return (f b)
  sem-sel-fut (combined {r} x) ij = do
    let i , j , pr = splitⁱ {r} ij
    f , r ← x i
    b ← sem-sel-fut r j
    return (f b)

  {-# TERMINATING #-}
  sem-sel-fut' : Sem (ar s) → Ix s → State ℕ ((String → String) × String)
  sem-sel-fut' (plain x) i = do
    f , b ← x i
    return (f , b)
  sem-sel-fut' (combined {r} x) ij = do
    let i , j , pr = splitⁱ {r} ij
    f , r ← x i
    h , b ← sem-sel-fut' r j
    return (h ∘ f , b)

  -- {-# TERMINATING #-}
  -- sem-sel : Sem (ar (s Ar.⊗ p)) → Ix s → State ℕ (Sem (ar p))
  -- sem-sel {s} {p} a i with isCombined a
  -- ... | no _ = return $ plain λ j → do -- 1
  --   b ← ix-curry (sem-sel-fut a) i j
  --   return (id , b)
  -- ... | yes (q , r , qr-eq , t , _) with (q ≟ˢ s) -- 1
  -- ... | yes refl = foo where -- 2
  --   foo : _
  --   foo with (sym $ ++-cancelˡ s _ _ qr-eq)
  --   ... | refl = t i >>= λ where
  --       (f , plain b) → return $ plain λ k → do
  --         h , b′ ← b k
  --         return (f ∘ h , b′)
  --       (f , combined {s₁}{p₁} b) → return $ combined {s₁}{p₁} λ k → do
  --         h , b′ ← b k
  --         return (f ∘ h , b′)
  -- ... | no b = {!   !} -- 2

  {-# TERMINATING #-}
  sem-sum : Sem (ar p) → Ix s → Ix p → State ℕ String
  sem-sum {p}{s} (plain a) i j = do
    f , a′ ← a j
    return (f $ to-sum s i a′)

  sem-sum {_}{s} (combined {q}{r} a) i kw = do
    let k , w , pr = splitⁱ {q} kw
    f , a′ ← a k
    b ← sem-sum a′ i w
    return (f $ to-sum s i b)

  {-# TERMINATING #-} -- What is wrong with you, Agda?
  sem-imap : Sem (ar s) → State ℕ String
  sem-imap {s} (plain f) with s
  ... | [] = do
    f , a ← f []
    return (f a)
  ... | s′ = do
    iv ← fresh-ix s′
    f , a ← f iv
    return (f $ to-imap s′ iv a)

  sem-imap {s} (combined {p}{r} f) = do
    iv ← fresh-ix p
    h , a ← f iv
    b ← sem-imap a
    return (h $ to-imap p iv b)

  to-fut : E Γ is → FEnv Γ → State ℕ (Sem is)

  to-str : E Γ (ar s) → FEnv Γ → State ℕ String
  to-str e ρ = to-fut e ρ >>= sem-imap

  to-fut (var x) ρ = return $ lookup x ρ
  to-fut 𝟘 ρ = pure $ plain $ λ i → pure (id , "zero")
  to-fut 𝟙 ρ = pure $ plain $ (λ _ → pure (id , "one"))

  to-fut {Γ} (imaps {s = s} e) ρ = do
    return $ plain λ i → do
      b ← to-fut e (ρ , index i)
      r ← sem-imap b
      return (id , r)

  to-fut (sels e e₁) ρ = do
    a ← to-fut e ρ
    index x ← to-fut e₁ ρ
    b ← sem-sel-fut a x
    return $ plain λ _ → return (id , b)

  to-fut (imap′ {s = s}{p} refl e) ρ =
    return $ combined {s}{p} λ i → do
      b ← to-fut e (ρ , index i)
      return (id , b)

  to-fut (sel′ {s = s}{p = p} refl e e₁) ρ =
    -- do
    -- index i ← to-fut e₁ ρ
    -- a ← to-fut e ρ
    -- b ← sem-sel a i
    -- return b
    do
    a ← to-fut e ρ
    index i ← to-fut e₁ ρ
    return $ plain λ j → do
      b ← sem-sel-fut a (ix-curry id i j)
      return (id , b)

  -- TODO : Make it preserve combined
  -- Not used in mgpt
  to-fut (Lang.imapb {s = s}{p = p}{q = q} pf e) ρ =
    do
    return $ plain λ i → do -- is plain correct?
      let (j , k) = to-div-mod pf i
      b ← to-fut e (ρ , index j)
      r ← sem-sel-fut b k
      return (id , r)

  to-fut (Lang.selb {s}{p}{q} pf e e₁) ρ =
    do
    a ← to-fut e ρ
    index i ← to-fut e₁ ρ
    return $ plain λ j → do -- is plain correct?
      let k = from-div-mod pf i j
      b ← sem-sel-fut a k
      return (id , b)

  to-fut (Lang.sum {s = s} e) ρ = do
    i ← fresh-ix s
    b ← to-fut e (ρ , index i)
    return $ plain λ j → do
      c ← sem-sum b i j
      return (id , c)

  to-fut (zero-but e e₁ e₂) ρ = do
    index i ← to-fut e ρ
    index j ← to-fut e₁ ρ
    a ← to-fut e₂ ρ
    return $ plain λ k → do
      b ← sem-sel-fut a k
      return (id , printf "(if (%s) then %s else zero)" (ix-eq i j) b)

  -- to-fut (Lang.slide e x e₁ x₁) ρ = do
  --   index i ← to-fut e ρ
  --   a ← to-fut e₁ ρ
  --   return $ plain λ j → do
  --     b ← sem-sel-fut a (ix-plus x x₁ i j)
  --     return (id , b)

  -- to-fut (Lang.backslide {u = u} e e₁ x x₁) ρ = do
  --   index i ← to-fut e ρ
  --   a ← to-fut e₁ ρ
  --   return $ plain λ j → do
  --     let j-i = ix-minus x₁ x j i
  --     let j≥i = intersperse " && " (L.zipWith (printf "%s >= %s") (ix-to-list j) (ix-to-list i))
  --     let j-i<u = intersperse " && " (L.zipWith (printf "%s < %u") (ix-to-list j-i) u)
  --     b ← sem-sel-fut a j-i
  --     let c = printf "if (%s && %s) then %s else zero"
  --                    j≥i j-i<u b
  --     return (id , c)

  to-fut (scaledown x e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id ,  printf "(%s F./ fromi64 %s)" b (show-nat x))

  to-fut (e ⊞ e₁) ρ = do
    l ← to-fut e ρ
    r ← to-fut e₁ ρ
    return $ plain λ i → do
      b ← sem-sel-fut l i
      c ← sem-sel-fut r i
      return (id , printf "(%s F.+ %s)" b c)

  to-fut (e ⊠ e₁) ρ = do
    l ← to-fut e ρ
    r ← to-fut e₁ ρ
    return $ plain λ i → do
      b ← sem-sel-fut l i
      c ← sem-sel-fut r i
      return (id , printf "(%s F.* %s)" b c)

  to-fut (⊟ e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(F.neg %s)" b)

  to-fut (𝟙/ e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(one F./ %s)" b)

  to-fut (relu e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(F.max %s zero)" b)

  to-fut (√ e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(F.sqrt %s)" b)

  to-fut (𝕚+ e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(indicatorp %s)" b)

  to-fut (ln e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(F.log %s)" b)

  to-fut (uop {s = s} softmax e) ρ = do
    c ← get
    i ← fresh-ix s
    sf ← fresh-var
    a ← to-fut e ρ
    return $ plain λ j → do
      _ , b ← sem-sel-fut' a i
      f , _ ← sem-sel-fut' a i
      return (printf "(let %s = %s\nin %s)" sf (to-softmax s i b) ∘ f , to-sel j sf)

  -- to-fut (logi e) ρ = do
  --   a ← to-fut e ρ
  --   return $ plain λ i → do
  --     b ← sem-sel-fut a i
  --     return (id , printf "(logistics %s)" b)

  to-fut (let′ {s = s}{p} e e₁) ρ = do
    n ← fresh-var
    to-fut e₁ (ρ , plain (mkar n)) >>= λ where
      (plain a) → return (plain λ i → do
         x ← to-str e ρ
         f , v ← a i
         return (printf "(let %s = %s\nin %s)" n x ∘ f , v))
      (combined {r}{q} a) → return (combined {r}{q} λ i → do
         x ← to-str e ρ
         f , v ← a i
         return (printf "(let %s = %s\nin %s)" n x ∘ f , v))


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
instance
  _ = monad
  _ = applicative
  _ = monadState

infixl 5 _,,_
_,,_ = _,′_

test-e : E _ _
test-e = Lcon (ar (5 ∷ []) ∷ []) (ar (5 ∷ 5 ∷ [])) ε
         λ e → Imap {5 ∷ []}{5 ∷ []} λ i → Let x := 𝟘 {s = unit} In Imaps λ j → x

test-s : String
test-s = proj₂ (runState (to-str test-e (_ , plain (mkar "f"))) 0)
-- "(imap1 5 (\\i0 -> (let x1 = zero
-- in (imap1 5 (\\i2 -> x1)))))"

test₂-e : E _ _
test₂-e = Lcon (ar (5 ∷ []) ∷ ix (5 ∷ []) ∷ []) (ar (5 ∷ [])) ε
         λ e i → sel (Let y := 𝟘 {s = unit} In Imap {5 ∷ []}{5 ∷ []} λ i → Let x := 𝟘 {s = unit} In Imaps λ j → x) i
        --  λ e i → sel (Imap {5 ∷ []}{5 ∷ []} λ i → Let x := zero {s = unit} In Imaps λ j → x) i
        --  λ e j → Imaps {5 ∷ 5 ∷ []} λ i → (sel (Let x := sels one i In sel e i) j)

test₂-s : String
test₂-s = proj₂ (runState (to-str test₂-e ((_ , (plain (mkar "f"))) , index (val "j1" ∷ []))) 0)
-- "(imap1 5 (\\i1 -> (let x0 = zero
-- in (let x2 = zero
-- in x2))))"

test₃-e : E _ _ -- Is this what we want?
test₃-e = Lcon (ar (5 ∷ []) ∷ []) (ar (_)) ε
         λ e → Imap {5 ∷ []} (λ i →
          zero-but i i (
            Imap {5 ∷ []}{5 ∷ []} λ j → Let x := 𝟘 {s = unit} In Imaps λ k → x))

test₃-s : String
test₃-s = proj₂ (runState (to-str test₃-e (_ , plain (mkar "f"))) 0)
-- "(imap1 5 (\\i0 -> (imap2 5 5 (\\i1 i2 -> (if ((i0 == i0)) then (let x3 = zero
-- in x3) else zero)))))"
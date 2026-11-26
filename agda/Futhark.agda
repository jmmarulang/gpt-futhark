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
    combined : F s (Sem (ar p)) → Sem (ar (s Ar.⊗ p))
    index : Ix s → Sem (ix s)

  FEnv : Ctx → Set
  FEnv ε = ⊤
  FEnv (Γ ▹ is) = FEnv Γ × Sem is

  shape-args : S → String
  shape-args s = intersperse " " $ L.map show-nat s

  dim : S → ℕ
  dim s = L.length s

  fresh-i : ∀ n → State ℕ (SFin n)
  fresh-i n = do
    c ← get
    modify suc
    let i = printf "i%u" c
    return (val i)

  fresh-ix : ∀ s → State ℕ (Ix s)
  fresh-ix [] = pure []
  fresh-ix (x ∷ s) = _∷_ <$> fresh-i x <*> fresh-ix s

  ix-join : Ix s → String → String
  ix-join [] d = ""
  ix-join (x ∷ []) d = getVal x
  ix-join {s = _ ∷ s} (x ∷ y ∷ xs) d = getVal x ++ d ++ ix-join {s} (y ∷ xs) d

  to-imap : (s : S) → (i : Ix s) → (e : String) → String
  to-imap s i e = printf "(imap%u %s (\\%s -> %s))" (dim s) (shape-args s) (ix-join i " ") e

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

  lookup : is ∈ Γ → FEnv Γ → Sem is
  lookup v₀ (ρ , e) = e
  lookup (there x) (ρ , e) = lookup x ρ

  _⊗ⁱ_ : Ix s → Ix p → Ix (s Ar.⊗ p)
  [] ⊗ⁱ js = js
  (i ∷ is) ⊗ⁱ js = i ∷ (is ⊗ⁱ js)

  splitⁱ : (ij : Ix (s Ar.⊗ p)) → Σ (Ix s) λ i → Σ (Ix p) λ j → i ⊗ⁱ j ≡ ij
  splitⁱ {[]} ij = [] , ij , refl
  splitⁱ {_ ∷ s} (x ∷ ij) with splitⁱ {s} ij
  ... | i , j , refl = (x ∷ i) , j , refl

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

  to-softmax : (s : S) → (i : Ix s) → (e : String) → String
  to-softmax [] i e = e
  to-softmax s  i e =
      printf "(isoftmax%u %s (\\%s -> %s))" (dim s) (shape-args s)
        (ix-join i " ") e

  fresh-var : State ℕ String
  fresh-var = do
    c ← get
    modify suc
    let x = printf "x%u" c
    return x

  ix-map : (String → String) → Ix s → Ix s
  ix-map f [] = []
  ix-map f (x ∷ i) = val (f (getVal x)) ∷ ix-map f i

  to-sel : Ix s → String → String
  to-sel i a = a ++ ix-join (ix-map (printf "[%s]") i) ""

  mkar : String → Ix s → State ℕ ((String → String) × String)
  mkar a i = return (id , to-sel i a)

  ix-zipwith : ((a b : String) → String) → Ix s → Ix s → Ix s
  ix-zipwith f [] [] = []
  ix-zipwith f (x ∷ i) (y ∷ j) = val (f (getVal x) (getVal y)) ∷ ix-zipwith f i j

  ix-eq : (i j : Ix s) → String
  ix-eq i j = ix-join (ix-zipwith (printf "(%s == %s)") i j) " && "

  to-fut : E Γ is → FEnv Γ → State ℕ (Sem is)

  to-str : E Γ (ar s) → FEnv Γ → State ℕ String
  to-str e ρ = to-fut e ρ >>= sem-imap

  to-fut (var x) ρ = return $ lookup x ρ
  to-fut 𝟘 ρ = pure $ plain $ λ i → pure (id , "zero")
  to-fut 𝟙 ρ = pure $ plain $ λ i → pure (id , "one")

  to-fut (⊟ e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(F.neg %s)" b)
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
  to-fut (𝟙/ e) ρ = do
    a ← to-fut e ρ
    return $ plain λ i → do
      b ← sem-sel-fut a i
      return (id , printf "(one F./ %s)" b)
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
  to-fut (softmax {s} e) ρ = do
    i ← fresh-ix s
    sf ← fresh-var
    a ← to-fut e ρ
    return $ plain λ j → do
      b ← sem-sel-fut a i
      return (printf "(let %s = %s\nin %s)" sf (to-softmax s i b) , to-sel j sf)
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

  to-fut (imaps {ℝ} e) ρ = {!   !}
    -- do
    -- return $ plain λ i → do
    --   b ← to-fut e (ρ , index i)
    --   r ← sem-imap b
    --   return (id , r)

  to-fut (imaps {ℙ r} {s = s} {p = .[]} e) ρ =
    {!   !}
    -- do
    -- return $ plain λ i → do
    --   b ← to-fut e (ρ , index i)
    --   return (id , {!   !})

  to-fut (imap′ refl e) ρ = {!   !}
  to-fut (imapb x e) ρ = {!   !}
  to-fut (sum′ refl e) ρ = {!   !}

  to-fut (sop x e e₁) ρ = {!   !}

  to-fut (zero-but e e₁ e₂) ρ = {!   !}
    -- do
  --   index i ← to-fut e ρ
  --   index j ← to-fut e₁ ρ
  --   a ← to-fut e₂ ρ
  --   return $ plain λ k → do
  --     b ← sem-sel-fut a k
  --     return (id , printf "(if (%s) then %s else zero)" (ix-eq i j) b)

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

test : E _ _
test = Lcon (ar (5 ∷ []) ∷ ari (3 ∷ []) (5 ∷ []) ∷ []) (ar (3 ∷ [])) ε
          λ w is → Imaps λ i → sels w (sels is i)

-- Lets inside the summand must stay under the isum binder.
test₄-e : E _ _
test₄-e = Lcon (ar (5 ∷ []) ∷ []) (ar []) ε
          λ a → Sum {5 ∷ []} λ i → Let x := sels a i In (x ⊞ x)

test₄-s : String
test₄-s = proj₂ (runState (to-str test₄-e (_ , plain (mkar "a"))) 0)
-- Expected: "(isum1 5 (\\i0 -> (let x1 = a[i0]
-- in (x1 F.+ x1))))"

-- Summing an imap (combined) must produce a single isum.
test₅-e : E _ _
test₅-e = Lcon (ar (5 ∷ []) ∷ []) (ar (3 ∷ [])) ε
          λ a → Sum {5 ∷ []} λ i → Imap {3 ∷ []} {[]} λ j → sels a i

test₅-s : String
test₅-s = proj₂ (runState (to-str test₅-e (_ , plain (mkar "a"))) 0)
-- Expected: "(imap1 3 (\\i1 -> (isum1 5 (\\i0 -> a[i0]))))"

-- Lets of the softmax argument must be bound before isoftmax uses them.
test₆-e : E _ _
test₆-e = Lcon (ar (5 ∷ []) ∷ []) (ar (5 ∷ [])) ε
          λ a → softmax (Let y := a ⊞ a In y)

test₆-s : String
test₆-s = proj₂ (runState (to-str test₆-e (_ , plain (mkar "a"))) 0)
-- Expected: "(let x1 = (isoftmax1 5 (\\i0 -> (let x2 = (imap1 5 (\\i4 -> (a[i4] F.+ a[i4])))
-- in x2[i0])))
-- in (imap1 5 (\\i3 -> x1[i3])))"
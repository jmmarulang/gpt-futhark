-- Pretty printer for the DSL defined in Lang


module _ where
  open import Data.Bool
  open import Data.Nat.Show using () renaming (show to show-nat)
  --open import Data.List as L using (List; []; _∷_)
  --open import Data.List.Relation.Unary.All as All using (All; []; _∷_)
  open import Relation.Binary.PropositionalEquality
  open import Relation.Nullary
  open import Data.String
  open import Text.Printf
  open import Data.Unit
  open import Data.Product as Prod hiding (_<*>_)
  open import Data.Nat -- using (ℕ; zero; suc)
  open import Ar hiding (_++_; Ix)
  open import Lang
  open import Function

  open import Effect.Monad.State
  open import Effect.Monad using (RawMonad)
  open RawMonadState {{...}} -- public
  open RawMonad {{...}} -- public

  instance
    _ = monad
    _ = applicative
    _ = monadState

  Sem : IS → Set
  Sem t = String
  --Sem (ar s) = (Ix s → State ℕ ((String → String) × String))
  --Sem (ix s) = Ix s

  FEnv : Ctx → Set
  FEnv ε = ⊤
  FEnv (Γ ▹ is) = FEnv Γ × Sem is

  lookup : is ∈ Γ → FEnv Γ → Sem is
  lookup v₀ (ρ , e) = e
  lookup (there x) (ρ , e) = lookup x ρ

  fresh-name : ℕ → String
  fresh-name n = "x" ++ show-nat n

  fresh-var : State ℕ String
  fresh-var = do
    c ← get
    modify suc
    return (fresh-name c)


  -- bop : Bop -> String
  -- bop plus = "+"
  -- bop mul = "*"

  uopf : Uop → String
  uopf neg-op = "-"
  uopf relu-op = "relu"
  uopf sqrt-op = "sqrt"
  uopf inv-op = "inv"
  uopf indp-op = "ind-positive"
  uopf ln-op = "ln"
  uopf softmax-op = "softmax"
  uopf (scaledown-op x) = printf "scaledown %u" x

  pars : Bool → String → String
  pars true = printf "(%s)"
  pars false = id

  precImap = 1
  precLet = 2
  precAdd = 3
  precMul = 4
  --precUnary = 5
  precApp = 6

  ppx : (prec : ℕ) → E Γ is → FEnv Γ → State ℕ (Sem is)
  ppx p (var x) ρ = return (lookup x ρ)
  ppx p 𝟘 ρ = return "0"
  ppx p 𝟙 ρ = return "1"
  ppx p (imaps e) ρ = do
    iv ← fresh-var
    a ← ppx 0 e (ρ , iv)
    return (pars (does (p >? precImap)) (printf "imaps λ %s → %s" iv a))
  ppx p (sels e e₁) ρ = do
    a ← ppx (1 + precApp) e ρ
    i ← ppx (1 + precApp) e₁ ρ
    return (pars (does (p >? precApp)) $ printf "sels %s %s" a i)
  ppx p (imap′ refl e) ρ = do
    iv ← fresh-var
    a ← ppx 0 e (ρ , iv)
    return (pars (does (p >? precImap)) (printf "imap λ %s → %s" iv a))
  ppx p (sel′ refl e e₁) ρ = do
    a ← ppx (1 + precApp) e ρ
    i ← ppx (1 + precApp) e₁ ρ
    return (pars (does (p >? precApp)) $ printf "sel %s %s" a i)

  ppx p (Lang.imapb x e) ρ = do
    iv ← fresh-var
    a ← ppx 0 e (ρ , iv)
    return (pars (does (p >? precImap)) (printf "imapb λ %s → %s" iv a))

  ppx p (Lang.selb x e e₁) ρ = do
    a ← ppx (1 + precApp) e ρ
    i ← ppx (1 + precApp) e₁ ρ
    return (pars (does (p >? precApp)) $ printf "selb %s %s" a i)

  ppx p (Lang.sum e) ρ = do
    iv ← fresh-var
    a ← ppx 0 e (ρ , iv)
    return (pars (does (p >? precImap)) (printf "sum λ %s → %s" iv a))

  ppx p (zero-but e e₁ e₂) ρ = do
    a ← ppx (1 + precApp) e ρ
    b ← ppx (1 + precApp) e₁ ρ
    c ← ppx (1 + precApp) e₂ ρ
    return (pars (does (p >? precApp)) $ printf "(zero-but %s %s %s)" a b c)

  -- ppx p (Lang.slide e x e₁ x₁) ρ = do
  --   a ← ppx (1 + precApp) e ρ
  --   b ← ppx (1 + precApp) e₁ ρ
  --   return (pars (does (p >? precApp)) $ printf "slide %s %s" a b)

  -- ppx p (Lang.backslide e e₁ x x₁) ρ = do
  --   a ← ppx (1 + precApp) e ρ
  --   b ← ppx (1 + precApp) e₁ ρ
  --   return (pars (does (p >? precApp)) $ printf "backslide %s %s" a b)

  ppx p (e ⊞ e₁) ρ = do
    a ← ppx (precAdd) e ρ
    b ← ppx (precAdd) e₁ ρ
    return (pars (does (p >? precAdd)) $ printf "%s + %s" a b)

  ppx p (e ⊠ e₁) ρ = do
    a ← ppx (precMul) e ρ
    b ← ppx (precMul) e₁ ρ
    return (pars (does (p >? precMul)) $ printf "(%s * %s)" a b)

  ppx p (scaledown x e) ρ = do
    a ← ppx (1 + precApp) e ρ
    return (pars (does (p >? precApp)) $ printf "scaledown %u %s" x a)

  ppx p (let′ e e₁) ρ = do
    x ← fresh-var
    a ← ppx (1 + precLet) e ρ
    b ← ppx precLet e₁ (ρ , x)
    return (pars (does (p >? precLet)) $ printf "let %s = %s in\n%s" x a b)

  ppx p (uop x e) ρ = do
    a ← ppx (1 + precApp) e ρ
    return (pars (does (p >? precApp)) $ printf "(%s %s)" (uopf x) a)

  pp : E Γ is → FEnv Γ → State ℕ (Sem is)
  pp = ppx 0

  -- test : Sem (ar s) → State ℕ String
  -- test a = {! a  !}

  -- to-str-pp : E Γ (ar s) → FEnv Γ → State ℕ String
  -- to-str-pp e ρ = pp e ρ >>= return
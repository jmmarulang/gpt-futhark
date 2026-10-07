{-# OPTIONS --backtracking-instance-search #-} -- only needed for tests
-- {-# OPTIONS --warn=noUserWarning #-}
module _ where

open import Grad

module Optimise where
  open import Lang
  open import Data.Product
  open import Data.Nat
  -- We are not interested in the proof,
  -- but we are interested in the optimisation, so we ignore
  -- the R module, and make it up with a postulate

  open import Real
  postulate
    r : Real.Real
    rp : RealProp r

  open import Opt r rp public

  doopt : E Γ is → E Γ is
  doopt e = danger-opt e

    -- (opt e .proj₁)

  multiopt : E Γ is → ℕ → E Γ is
  multiopt e 0 = e
  multiopt e (suc n) = doopt (multiopt e n)

module Extract where
  open import Data.String
  open import Text.Printf
  open import Data.Product as Prod
  open import Data.Nat using (ℕ; zero; suc; _+_)
  open import Data.List as L
  open import Relation.Binary.PropositionalEquality

  open import Lang
  open import Ar hiding (r ; Ix)
  open import Function
  open import Futhark
  open import Replace

  open import Effect.Monad.State
  open import Effect.Monad using (RawMonad)
  open RawMonadState {{...}} --public
  open RawMonad {{...}} --public

  open import Data.Maybe hiding (_>>=_)

  open import LangEq

  import PP

  instance
    _ = monad
    _ = applicative
    _ = monadState

  open Optimise
  open Syntax
  open Primitives
  open WkSub

  OPT = 20

  -- Show Env (e.g. after running grad) where optimisations are applied
  -- to every expression in the list.
  env-opt : Env Γ Δ → Env Γ Δ
  env-opt ε = ε
  env-opt (skip ρ) = skip (env-opt ρ)
  env-opt (ρ ▹ x) = env-opt ρ ▹ multiopt x OPT

  ee-opt : EE Γ Δ → EE Γ Δ
  ee-opt (env ρ) = env (env-opt ρ)
  ee-opt (let′ x ρ) = let′ (multiopt x OPT) (ee-opt ρ)

  env-count-uses : Env Γ Δ → is ∈ Δ → ℕ
  env-count-uses ε v = 0
  env-count-uses (skip ρ) v = env-count-uses ρ v
  env-count-uses (ρ ▹ x) v = env-count-uses ρ v + count-uses x v

  ee-count-uses : EE Γ Δ → is ∈ Δ → ℕ
  ee-count-uses (env ρ) = env-count-uses ρ
  ee-count-uses (let′ x ρ) v = count-uses x v + ee-count-uses ρ (there v)

  env-count-sels : Env Γ Δ → is ∈ Δ → ℕ
  env-count-sels ε v = 0
  env-count-sels (skip ρ) v = env-count-sels ρ v
  env-count-sels (ρ ▹ x) v = env-count-sels ρ v + count-sels x v

  ee-count-sels : EE Γ Δ → is ∈ Δ → ℕ
  ee-count-sels (env ρ) = env-count-sels ρ
  ee-count-sels (let′ x ρ) v = count-sels x v + ee-count-sels ρ (there v)

  env-norm-lets : Env Γ Δ → Env Γ Δ
  env-norm-lets ε = ε
  env-norm-lets (skip x) = skip (env-norm-lets x)
  env-norm-lets (xs ▹ x) = env-norm-lets xs ▹ norm-lets x

  ee-inline : EE Γ Δ → EE Γ Δ
  ee-inline (env x) = env (env-norm-lets x)
  ee-inline (let′ e ρ) with δ ← ee-inline ρ | ee-count-uses δ v₀ | ee-count-sels δ v₀ | e
  ... | 0 | _ | _ = ee-sub δ (sub-id ▹ inline e) -- does nothing?
  ... | _ | _ | var b = ee-sub δ (sub-id ▹ var b)
  ... | _ | _ | 𝟘 = ee-sub δ (sub-id ▹ 𝟘)
  ... | _ | _ | 𝟙 = ee-sub δ (sub-id ▹ 𝟙)
  ... | 1 | 1 | _ = ee-sub δ (sub-id ▹ inline e)
  -- ... | 1 | 0 | _ = ee-sub δ (sub-id ▹ inline e)
  ... | _ | _ | _ = let′ (inline e) δ

  env-replace : Env Γ Δ → (a b : E Δ is) → Env Γ Δ
  env-replace ε a b = ε
  env-replace (skip ρ) a b = skip (env-replace ρ a b)
  env-replace (ρ ▹ x) a b = env-replace ρ a b ▹ replace x a b

  ee-replace : EE Γ Δ → (a b : E Δ is) → EE Γ Δ
  ee-replace (env ρ) x y = env (env-replace ρ x y)
  ee-replace (let′ e e₁) x y = let′ (replace e x y) (ee-replace e₁ (x ↑) (y ↑))

  env-replace-let : Env Γ Δ → Env Γ Δ
  env-replace-let ε = ε
  env-replace-let (skip ρ) = skip (env-replace-let ρ)
  env-replace-let (ρ ▹ x) = (env-replace-let ρ) ▹ replace-let x

  ee-dedup : EE Γ Δ → EE Γ Δ
  ee-dedup (env ρ) = env (env-replace-let ρ)
  ee-dedup (let′ x ρ) = let x' = (replace-let x) in
    let′ x' (ee-replace (ee-dedup ρ) (x' ↑) (var v₀))

  -- env-let-out : Env Γ Δ → Env Γ Δ
  -- env-let-out ε = ε
  -- env-let-out (skip ρ) = skip (env-let-out ρ)
  -- env-let-out (ρ ▹ x) = (env-let-out ρ) ▹ (let-out x)

  -- {-# TERMINATING #-}
  -- ee-let-out : EE Γ Δ → EE Γ Δ
  -- ee-let-out (env ρ) = env ρ
  -- ee-let-out (let′ x (env ρ)) = let′ x (env ρ)
  -- ee-let-out (let′ x (let′ y ρ)) with (stren y v₀)
  -- -- ... | just (y' , _) = let′ y' (let′ (x ↑) (ee-sub (ee-let-out ρ) sub-swap))
  -- ... | just y' = let′ y' (ee-let-out (let′ (x ↑) (ee-sub ρ sub-swap)))
  -- ... | nothing = (let′ x (ee-let-out (let′ y  ρ)))

  -- ee-dedup : EE Γ Δ → EE Γ Δ
  -- ee-dedup (env x) = env x
  -- ee-dedup (let′ x e) = let′ x (ee-replace (ee-dedup e) (x ↑) (var v₀))

  ee-OPT : EE Γ Δ → EE Γ Δ
  ee-OPT ρ = ee-inline $ ee-opt (ee-inline (ee-opt $ ee-inline ρ)) --??

  data NamedEnv : Ctx → Set where
    ε : NamedEnv ε
    _▹_ : NamedEnv Γ → String → NamedEnv (Γ ▹ is)

  from-named : NamedEnv Γ → FEnv Γ
  from-named ε = _
  from-named (_▹_ {is = ix s} ρ x) = from-named ρ , index (fresh-ix-named s x) --fresh-ix x
  from-named (_▹_ {is = ar s} ρ x) = from-named ρ , plain (mkar x) --mkar x

  -- Show chain using SemFuthark
  env-fut′ : Env Γ Δ → NamedEnv Γ → NamedEnv Δ → State ℕ String
  env-fut′ ε ρ ν = return ""
  env-fut′ (skip e) (ρ ▹ _) ν = env-fut′ e ρ ν
  env-fut′ (e ▹ x) (ρ ▹ n) ν = do
    r ← env-fut′ e ρ ν
    v ← to-str x (from-named ν)
    return $ printf "%s\nlet d%s = %s" r n v

  ee-fut′ : EE Γ Δ → NamedEnv Γ → NamedEnv Δ → State ℕ String
  ee-fut′ (env ρ) = env-fut′ ρ
  ee-fut′ (let′ {s = s} x e) ρ ν = do
    c ← get
    modify suc
    v ← to-str x (from-named ν)
    let n = proj₂ (runState fresh-var c) --fresh-var c
    r ← ee-fut′ e ρ (ν ▹ n)
    return $ printf "let %s = %s\n%s" n v r

  -- Apply optimisations and generate the code.
  ee-clean : EE Γ Γ → _
  ee-clean e = ee-dedup $ ee-OPT $ ee-dedup $ ee-OPT e

  ee-fut : EE Γ Γ → NamedEnv Γ → String
  ee-fut e ρ = proj₂ $ runState (ee-fut′ (ee-clean e) ρ ρ) 0

  -- nodedup-ee-fut : EE Γ Γ → NamedEnv Γ → String
  -- nodedup-ee-fut e ρ = proj₂ $ runState (ee-fut′ (ee-opt $ ee-opt e) ρ ρ) 0

  -- This is the "entry point" that computes derivatives
  -- and generates the Futhark code for the variable names
  -- passed through NamedEnv
  pp : E Γ (ar s) → NamedEnv Γ → String
  pp e ρ = ee-fut ({- env-norm-lets $ -} grad e 𝟙 zero-ee) ρ

  -- nodedup-pp : E Γ (ar s) → NamedEnv Γ → String
  -- nodedup-pp e ρ = nodedup-ee-fut ({- env-norm-lets $ -} grad e one zero-ee) ρ

  module Pretty where
    import PP

    named-ppenv : NamedEnv Γ → PP.FEnv Γ
    named-ppenv ε = _
    named-ppenv (ρ ▹ x) = named-ppenv ρ , x

    pretty-env′ : Env Γ Δ → NamedEnv Γ → NamedEnv Δ → State ℕ String
    pretty-env′ ε ρ ν = return ""
    pretty-env′ (skip e) (ρ ▹ _) ν = pretty-env′ e ρ ν
    pretty-env′ (e ▹ x) (ρ ▹ n) ν = do
      r ← pretty-env′ e ρ ν
      v ← PP.pp x (named-ppenv ν)
      return $ printf "%s\n\nlet d%s = %s" r n v

    pretty-ee′ : EE Γ Δ → NamedEnv Γ → NamedEnv Δ → State ℕ String
    pretty-ee′ (env ρ) = pretty-env′ ρ
    pretty-ee′ (let′ {s = s} x e) ρ ν = do
      c ← get
      modify suc
      v ← PP.pp x (named-ppenv ν)
      let n = proj₂ (runState fresh-var c) --fresh-var c
      r ← pretty-ee′ e ρ (ν ▹ n)
      return $ printf "elet %s = %s\n\n%s" n v r

    pretty-ee : EE Γ Γ → NamedEnv Γ → String
    pretty-ee e ρ =
      let
        ee = ee-OPT $ ee-dedup $ ee-OPT e
        r  = runState (pretty-ee′ ee ρ ρ) 0
      in proj₂ r

    ee-pretty : EE Γ Γ → NamedEnv Γ → String
    ee-pretty e ρ = pretty-ee (ee-clean e) ρ

    pretty : E Γ (ar s) → NamedEnv Γ → String
    pretty e ρ = ee-pretty ({- env-norm-lets $ -} grad e 𝟙 zero-ee) ρ

    seed-pretty : E Γ (ar s) → E Γ (ar s) → NamedEnv Γ → String
    seed-pretty e s ρ = ee-pretty ({- env-norm-lets $ -} grad e s zero-ee) ρ

  open Primitives
  open Microgpt

  -- grad-gpt-loss-e = ee-OPT $ ee-dedup $ ee-OPT (grad gpt-loss-e 𝟙 zero-ee)

  -- gpt-loss-s : String
  -- gpt-loss-s = proj₂ (runState (to-str (multiopt gpt-loss-e OPT) ((from-named (ε ▹ "mask" ▹ "wpe" ▹ "wqry" ▹ "wkey" ▹ "wval" ▹ "wout" ▹ "wup" ▹ "wdown" ▹ "wvoc" ▹ "wseq" ▹ "target")))) 0)

  mgpt-forward-s : String
  mgpt-forward-s = proj₂ (runState (to-str ( multiopt mgpt-forward-e OPT)
    (from-named
      (ε ▹ "wp" ▹ "wkey" ▹ "wqry" ▹ "wval" ▹ "wo"
         ▹ "mask" ▹ "wu" ▹ "wd" ▹ "wc" ▹ "ws"))) 0)

  mgpt-forward-pp : String
  mgpt-forward-pp = proj₂ (runState (PP.pp (multiopt mgpt-forward-e OPT)
    ((((((((((_ , "mask") , "wpe") , "wqry") , "wkey") , "wval")
      , "wout") , "wup") , "wdown") , "wvoc") , "wseq")) 0)

  bgpt-forward-s : String
  bgpt-forward-s = proj₂ (runState (to-str ( multiopt bgpt-forward-e OPT)
    (from-named
      (ε ▹ "wp" ▹ "wkey" ▹ "wqry" ▹ "wval" ▹ "wo"
         ▹ "mask" ▹ "wu" ▹ "wd" ▹ "wc" ▹ "ws"))) 0)


  -- grad-gpt-loss-s : String
  -- grad-gpt-loss-s = pp gpt-loss-e
  --   (ε ▹ "mask" ▹ "wpe" ▹ "wqry" ▹ "wkey" ▹ "wval" ▹ "wout" ▹ "wup"
  --      ▹ "wdown" ▹ "wvoc" ▹ "wseq" ▹ "target")

  -- grad-gpt-loss-pp = Pretty.pretty gpt-loss-e
  --   (ε ▹ "mask" ▹ "wpe" ▹ "wqry" ▹ "wkey" ▹ "wval" ▹ "wout" ▹ "wup"
      --  ▹ "wdown" ▹ "wvoc" ▹ "wseq" ▹ "target")

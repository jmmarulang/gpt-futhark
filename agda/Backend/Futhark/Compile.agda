-- Verified compilation of E (Lang.agda) into the Futhark DSL F (Syntax.agda).
--
-- The translation follows the NbE approach of Futhark.agda: arrays are
-- represented by `Tab`s, which are F terms in a normal form where
--   * lets that do not depend on the loop indices of an array stay in
--     front of its loops (lets/ilet), and
--   * the elements are computed by scalar F expressions (elem) under
--     one loop per dimension (loop).
-- Selecting from a Tab binds the selected index (ilet) instead of
-- materialising the array, so (sel (imap e) i) patterns disappear by
-- construction.  The values in the environment are syntax, so no Kripke
-- function spaces are needed; going under binders is just weakening.
--
-- Soundness (module Soundness) is stated against Eval.agda.
module Backend.Futhark.Compile where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Fin as Fin using (Fin)
open import Data.Product as Prod using (_,_; _×_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥-elim)
open import Data.List using ([]; _∷_)
open import Data.List.Relation.Unary.All using ([]; _∷_)
open import Relation.Binary.PropositionalEquality hiding ([_])
open import Relation.Nullary hiding (⌊_⌋)

open import Ar hiding (sum; imapb; selb; slide; backslide; map; Ix)
import Ar as A
open import Lang hiding (imap; sel; sum)
open import Backend.Futhark.Syntax renaming (_∈_ to _∈ᶠ_; Uop to FUop; wk to wkᶠ; wkv to wkvᶠ;
                            _⊆_ to _⊆ᶠ_; ⊆-eq to ⊆ᶠ-eq)
                  hiding (Γ; Δ; Ξ; τ; σ; m; n; k; s; p; q)
open import Real

variable
  Θ Θ₀ Θ₁ Θ₂ Φ : FCtx

-- Arrays under construction.
data Tab (Θ : FCtx) : S → Set where
  lets : F Θ p → Tab (Θ ▹ ar p) s → Tab Θ s
  ilet : I Θ n → Tab (Θ ▹ ix n) s → Tab Θ s
  elem : F Θ [] → Tab Θ []
  loop : Tab (Θ ▹ ix n) s → Tab Θ (n ∷ s)

reify : Tab Θ s → F Θ s
reify (lets a t) = let′ a (reify t)
reify (ilet i t) = ilet i (reify t)
reify (elem e) = e
reify (loop t) = imap (reify t)

wkT : Θ ⊆ᶠ Φ → Tab Θ s → Tab Φ s
wkT w (lets a t) = lets (wkᶠ w a) (wkT (keep w) t)
wkT w (ilet i t) = ilet (wkI w i) (wkT (keep w) t)
wkT w (elem e) = elem (wkᶠ w e)
wkT w (loop t) = loop (wkT (keep w) t)

-- Turn an arbitrary F array into a Tab by selecting its elements.
eta : F Θ s → Tab Θ s
eta {s = []} a = elem a
eta {s = n ∷ s} a = loop (eta (sel (wkᶠ ↑ a) (var here)))

konst : Kop → Tab Θ s
konst {s = []} o = elem (kop o)
konst {s = n ∷ s} o = loop (konst o)

-- Apply a scalar transformation to every element.  The transformation
-- is given in every context that extends Θ₀, as it is applied under
-- the binders of the Tab.
mapT : Θ₀ ⊆ᶠ Θ → (∀ {Φ} → Θ₀ ⊆ᶠ Φ → F Φ [] → F Φ []) → Tab Θ s → Tab Θ s
mapT w f (lets a t) = lets a (mapT (skip w) f t)
mapT w f (ilet i t) = ilet i (mapT (skip w) f t)
mapT w f (elem e) = elem (f w e)
mapT w f (loop t) = loop (mapT (skip w) f t)

-- Combine two Tabs elementwise.  The lets of both arguments stay in
-- front of the loops of the result, and the loops are merged.
zipT : Bop → Θ₁ ⊆ᶠ Θ → Θ₂ ⊆ᶠ Θ → Tab Θ₁ s → Tab Θ₂ s → Tab Θ s
zipT o w₁ w₂ (lets x a) b = lets (wkᶠ w₁ x) (zipT o (keep w₁) (skip w₂) a b)
zipT o w₁ w₂ (ilet i a) b = ilet (wkI w₁ i) (zipT o (keep w₁) (skip w₂) a b)
zipT o w₁ w₂ a (lets x b) = lets (wkᶠ w₂ x) (zipT o (skip w₁) (keep w₂) a b)
zipT o w₁ w₂ a (ilet i b) = ilet (wkI w₂ i) (zipT o (skip w₁) (keep w₂) a b)
zipT o w₁ w₂ (elem x) (elem y) = elem (bop o (wkᶠ w₁ x) (wkᶠ w₂ y))
zipT o w₁ w₂ (loop a) (loop b) = loop (zipT o (keep w₁) (keep w₂) a b)

-- Selections bind the index instead of building the array.
selAll : Tab Θ s → Idx Θ s → Tab Θ []
selAll (lets a t) is = lets a (selAll t (wkIdx ↑ is))
selAll (ilet j t) is = ilet j (selAll t (wkIdx ↑ is))
selAll (elem e) [] = elem e
selAll (loop t) (i ∷ is) = ilet i (selAll t (wkIdx ↑ is))

selP : ∀ s → Tab Θ (s ⊗ p) → Idx Θ s → Tab Θ p
selP [] t [] = t
selP (n ∷ s) (lets a t) is = lets a (selP (n ∷ s) t (wkIdx ↑ is))
selP (n ∷ s) (ilet j t) is = ilet j (selP (n ∷ s) t (wkIdx ↑ is))
selP (n ∷ s) (loop t) (i ∷ is) = ilet i (selP s t (wkIdx ↑ is))

-- One loop per dimension of s.
nests : ∀ s → Tab (Θ ▹▹ s) p → Tab Θ (s ⊗ p)
nests [] t = t
nests (n ∷ s) t = loop (nests s t)

nestsS : ∀ s → Tab (Θ ▹▹ s) [] → Tab Θ s
nestsS [] t = t
nestsS (n ∷ s) t = loop (nestsS s t)

-- Keep the lets of a Tab in front, and continue with the rest.
withCore : Θ₀ ⊆ᶠ Θ → Tab Θ s → (∀ {Φ} → Θ₀ ⊆ᶠ Φ → Tab Φ s → Tab Φ q) → Tab Θ q
withCore w (lets a t) k = lets a (withCore (skip w) t k)
withCore w (ilet i t) k = ilet i (withCore (skip w) t k)
withCore w t k = k w t

sums : ∀ s → F (Θ ▹▹ s) [] → F Θ []
sums [] e = e
sums (n ∷ s) e = sum (sums s e)

ifeqs : Idx Θ s → Idx Θ s → F Θ [] → F Θ []
ifeqs [] [] e = e
ifeqs (i ∷ is) (j ∷ js) e = ifeq i j (ifeqs is js e)

idivs : s * p ≈ q → Idx Θ q → Idx Θ s
idivs [] [] = []
idivs (cons {n = n} ⦃ refl ⦄ ⦃ pf ⦄) (k ∷ ks) = div n k ∷ idivs pf ks

imods : s * p ≈ q → Idx Θ q → Idx Θ p
imods [] [] = []
imods (cons {m = m} ⦃ refl ⦄ ⦃ pf ⦄) (k ∷ ks) = mod m k ∷ imods pf ks

icombs : p * q ≈ s → Idx Θ p → Idx Θ q → Idx Θ s
icombs [] [] [] = []
icombs (cons ⦃ refl ⦄ ⦃ pf ⦄) (i ∷ is) (j ∷ js) = comb i j ∷ icombs pf is js

-- Softmax is the only unary operation of E that is not scalar.
isℙ : (o : Uop) → Dec (o ≡ ℙₒ)
isℙ ⊟ₒ = no λ ()
isℙ reluₒ = no λ ()
isℙ √ₒ = no λ ()
isℙ 𝟙/ₒ = no λ ()
isℙ 𝕚+ₒ = no λ ()
isℙ lnₒ = no λ ()
isℙ ℙₒ = yes refl
isℙ (scₒ n) = no λ ()

uopᶠ : (o : Uop) → ¬ o ≡ ℙₒ → FUop
uopᶠ ⊟ₒ _ = negₒ
uopᶠ reluₒ _ = reluₒ
uopᶠ √ₒ _ = sqrtₒ
uopᶠ 𝟙/ₒ _ = invₒ
uopᶠ 𝕚+ₒ _ = indpₒ
uopᶠ lnₒ _ = lnₒ
uopᶠ ℙₒ ne = ⊥-elim (ne refl)
uopᶠ (scₒ n) _ = scₒ n

-- Elements of selb (selected at the combined index).
selbCore : p * q ≈ s → Idx Θ₀ p → Θ₀ ⊆ᶠ Φ → Tab Φ s → Tab Φ q
selbCore {q = q} pf is w t =
  nestsS q (selAll (wkT (wk▹▹ {s = q} ⊆ᶠ-eq) t) (icombs pf (wkIdx (wk▹▹ {s = q} ⊆ᶠ-eq) (wkIdx w is)) (vars q)))

-- Softmax, with the elements fused into its body; the result is
-- materialised, as every element depends on all of them.
smCore : Θ₀ ⊆ᶠ Φ → Tab Φ s → Tab Φ s
smCore {s = s} _ t =
  lets (softmax (reify (selAll (wkT (wk▹▹ {s = s} ⊆ᶠ-eq) t) (vars s)))) (eta (var here))

-- Elements of zero-but.
zbLeaf : Idx Θ₀ s → Idx Θ₀ s → Θ₀ ⊆ᶠ Φ → F Φ [] → F Φ []
zbLeaf is js w = ifeqs (wkIdx w is) (wkIdx w js)

-- Environments map E variables to values in the target context.
Val : FCtx → IS → Set
Val Θ (ix s) = Idx Θ s
Val Θ (ar s) = Tab Θ s

data Env (Θ : FCtx) : Ctx → Set where
  ε   : Env Θ ε
  _▹_ : Env Θ Γ → Val Θ is → Env Θ (Γ ▹ is)

wkV : Θ ⊆ᶠ Φ → Val Θ is → Val Φ is
wkV {is = ix s} w v = wkIdx w v
wkV {is = ar s} w v = wkT w v

wkEnv : Θ ⊆ᶠ Φ → Env Θ Γ → Env Φ Γ
wkEnv w ε = ε
wkEnv w (σ ▹ v) = wkEnv w σ ▹ wkV w v

lookupEnv : is ∈ Γ → Env Θ Γ → Val Θ is
lookupEnv here (σ ▹ v) = v
lookupEnv (there x) (σ ▹ v) = lookupEnv x σ

-- Go under the binders of Θ ▹▹ s, binding a source variable to them.
under : ∀ s → Env Θ Γ → Val (Θ ▹▹ s) is → Env (Θ ▹▹ s) (Γ ▹ is)
under s σ v = wkEnv (wk▹▹ {s = s} ⊆ᶠ-eq) σ ▹ v

compile : E Γ is → Env Θ Γ → Val Θ is
compile (var x) σ = lookupEnv x σ
compile (kop o) σ = konst o
compile (uop o e) σ with isℙ o
... | yes refl = withCore ⊆ᶠ-eq (compile e σ) smCore
... | no ne = mapT ⊆ᶠ-eq (λ _ → uop (uopᶠ o ne)) (compile e σ)
compile (bop o e e₁) σ = zipT o ⊆ᶠ-eq ⊆ᶠ-eq (compile e σ) (compile e₁ σ)
compile (mop {s = s} imapsₒ e) σ = nestsS s (compile e (under s σ (vars s)))
compile (mop {s = s} (imapₒ refl) e) σ = nests s (compile e (under s σ (vars s)))
compile (mop {q = q} (imapbₒ pf) e) σ =
  nestsS q (selAll (compile e (under q σ (idivs pf (vars q)))) (imods pf (vars q)))
compile (mop {s = s} {p = p} sumₒ e) σ =
  nestsS p (elem (sums s (reify (selAll (wkT (keep▹▹ {s = s} (wk▹▹ {s = p} ⊆ᶠ-eq))
                                              (compile e (under s σ (vars s))))
                                        (wkIdx (wk▹▹ {s = s} ⊆ᶠ-eq) (vars p))))))
compile (sop selsₒ e i) σ = selAll (compile e σ) (compile i σ)
compile (sop {p = p} (selₒ refl) e i) σ = selP p (compile e σ) (compile i σ)
compile (sop (selbₒ pf) e i) σ = withCore ⊆ᶠ-eq (compile e σ) (selbCore pf (compile i σ))
compile (zero-but i j e) σ = mapT ⊆ᶠ-eq (zbLeaf (compile i σ) (compile j σ)) (compile e σ)
compile (let′ e e₁) σ = lets (reify (compile e σ)) (compile e₁ (wkEnv ↑ σ ▹ eta (var here)))

-- Top level: array variables are kept, index variables are split into
-- one 1-d index per dimension.
⌊_⌋ : Ctx → FCtx
⌊ ε ⌋ = ε
⌊ Γ ▹ ar s ⌋ = ⌊ Γ ⌋ ▹ ar s
⌊ Γ ▹ ix s ⌋ = ⌊ Γ ⌋ ▹▹ s

idEnv : Env ⌊ Γ ⌋ Γ
idEnv {ε} = ε
idEnv {Γ ▹ ar s} = wkEnv ↑ idEnv ▹ eta (var here)
idEnv {Γ ▹ ix s} = under s idEnv (vars s)

compile-top : E Γ (ar s) → F ⌊ Γ ⌋ s
compile-top e = reify (compile e idEnv)


module Soundness (r : Real) (rp : RealProp r) where
  open Real.Real r
  open import Eval r rp
  import Backend.Futhark.Semantics as FEval
  module FE = FEval r
  open FE using (evalI; evalIdx; evalI-wk; evalIdx-wk; ifeqᵣ; uopᵣ; bopᵣ; kopᵣ; hd; Softmax-cong;
                ext; wk-env-keep▹▹)
          renaming (eval to evalᶠ; ⟦_⟧ᶜ to ⟦_⟧ᶠ; wk-env to wkᶠ-env; wk-env-id to wkᶠ-env-id;
                    eval-wk to evalᶠ-wk; eval-cong to evalᶠ-cong; reflᶜ to reflᶠ;
                    Softmax to Softmaxᶠ)

  ⟦_⟧ᵀ : Tab Θ s → ⟦ Θ ⟧ᶠ → Ar s R
  ⟦ t ⟧ᵀ ν = evalᶠ (reify t) ν

  -- Weakening and Tabs
  reify-wk : (w : Θ ⊆ᶠ Φ) (t : Tab Θ s) → reify (wkT w t) ≡ wkᶠ w (reify t)
  reify-wk w (lets a t) = cong (let′ _) (reify-wk (keep w) t)
  reify-wk w (ilet i t) = cong (ilet _) (reify-wk (keep w) t)
  reify-wk w (elem e) = refl
  reify-wk w (loop t) = cong imap (reify-wk (keep w) t)

  ⟦⟧-wk : (w : Θ ⊆ᶠ Φ) (t : Tab Θ s) (ν : ⟦ Φ ⟧ᶠ) → ⟦ wkT w t ⟧ᵀ ν ≈ᵃ ⟦ t ⟧ᵀ (wkᶠ-env w ν)
  ⟦⟧-wk w t ν i = cong (λ e → evalᶠ e ν i) (reify-wk w t) ∙ evalᶠ-wk w (reify t) ν i

  evalIdx-↑ : ∀ {τ} (is : Idx Θ s) (ν : ⟦ Θ ⟧ᶠ) (x : FE.⟦ τ ⟧ᵗ)
            → evalIdx (wkIdx ↑ is) (ν , x) ≡ evalIdx is ν
  evalIdx-↑ is ν x = evalIdx-wk ↑ is (ν , x) ∙ cong (evalIdx is) (wkᶠ-env-id ν)

  -- Environments for Θ ▹▹ s
  wk-env-wk▹▹ : (w : Θ ⊆ᶠ Φ) (ν : ⟦ Φ ⟧ᶠ) (is : P s)
              → wkᶠ-env (wk▹▹ {s = s} w) (ext ν is) ≡ wkᶠ-env w ν
  wk-env-wk▹▹ {s = []} w ν [] = refl
  wk-env-wk▹▹ {s = n ∷ s} w ν (i ∷ is) = wk-env-wk▹▹ (skip w) (ν , i) is

  wk-env-ext : (ν : ⟦ Θ ⟧ᶠ) (is : P s) → wkᶠ-env (wk▹▹ {s = s} ⊆ᶠ-eq) (ext ν is) ≡ ν
  wk-env-ext ν is = wk-env-wk▹▹ ⊆ᶠ-eq ν is ∙ wkᶠ-env-id ν

  evalIdx-vars : (ν : ⟦ Θ ⟧ᶠ) (is : P s) → evalIdx (vars s) (ext ν is) ≡ is
  evalIdx-vars {s = []} ν [] = refl
  evalIdx-vars {s = n ∷ s} ν (i ∷ is) =
    cong₂ _∷_ (evalI-wk (wk▹▹ {s = s} ⊆ᶠ-eq) (var here) (ext (ν , i) is)
               ∙ cong (FE.lookup here) (wk-env-wk▹▹ ⊆ᶠ-eq (ν , i) is))
              (evalIdx-vars (ν , i) is)

  -- Operations on Tabs
  eta-sound : (a : F Θ s) (ν : ⟦ Θ ⟧ᶠ) → ⟦ eta a ⟧ᵀ ν ≈ᵃ evalᶠ a ν
  eta-sound {s = []} a ν i = refl
  eta-sound {s = n ∷ s} a ν (i ∷ is) =
    eta-sound (sel (wkᶠ ↑ a) (var here)) (ν , i) is
    ∙ evalᶠ-wk ↑ a (ν , i) (i ∷ is)
    ∙ cong (λ ρ → evalᶠ a ρ (i ∷ is)) (wkᶠ-env-id ν)

  konst-sound : ∀ s o (ν : ⟦ Θ ⟧ᶠ) i → ⟦ konst {s = s} o ⟧ᵀ ν i ≡ kopᵣ o
  konst-sound [] o ν [] = refl
  konst-sound (n ∷ s) o ν (i ∷ is) = konst-sound s o (ν , i) is

  mapT-sound : (w : Θ₀ ⊆ᶠ Θ) (f : ∀ {Φ} → Θ₀ ⊆ᶠ Φ → F Φ [] → F Φ [])
               (g : ⟦ Θ₀ ⟧ᶠ → R → R)
             → (∀ {Φ} (w′ : Θ₀ ⊆ᶠ Φ) ν′ e → evalᶠ (f w′ e) ν′ [] ≡ g (wkᶠ-env w′ ν′) (evalᶠ e ν′ []))
             → (t : Tab Θ s) (ν : ⟦ Θ ⟧ᶠ)
             → ∀ i → ⟦ mapT w f t ⟧ᵀ ν i ≡ g (wkᶠ-env w ν) (⟦ t ⟧ᵀ ν i)
  mapT-sound w f g hf (lets a t) ν i = mapT-sound (skip w) f g hf t (ν , _) i
  mapT-sound w f g hf (ilet j t) ν i = mapT-sound (skip w) f g hf t (ν , _) i
  mapT-sound w f g hf (elem e) ν [] = hf w ν e
  mapT-sound w f g hf (loop t) ν (i ∷ is) = mapT-sound (skip w) f g hf t (ν , i) is

  zipT-sound : (o : Bop) (w₁ : Θ₁ ⊆ᶠ Θ) (w₂ : Θ₂ ⊆ᶠ Θ) (a : Tab Θ₁ s) (b : Tab Θ₂ s) (ν : ⟦ Θ ⟧ᶠ)
             → ∀ i → ⟦ zipT o w₁ w₂ a b ⟧ᵀ ν i
                     ≡ bopᵣ o (⟦ a ⟧ᵀ (wkᶠ-env w₁ ν) i) (⟦ b ⟧ᵀ (wkᶠ-env w₂ ν) i)
  zipT-sound o w₁ w₂ (lets x a) b ν i =
    zipT-sound o (keep w₁) (skip w₂) a b (ν , _) i
    ∙ cong (λ z → bopᵣ o z _) (evalᶠ-cong (reify a) (reflᶠ FE.▹ evalᶠ-wk w₁ x ν) i)
  zipT-sound o w₁ w₂ (ilet j a) b ν i =
    zipT-sound o (keep w₁) (skip w₂) a b (ν , _) i
    ∙ cong (λ z → bopᵣ o (⟦ a ⟧ᵀ (wkᶠ-env w₁ ν , z) i) _) (evalI-wk w₁ j ν)
  zipT-sound o w₁ w₂ a@(elem _) (lets x b) ν i =
    zipT-sound o (skip w₁) (keep w₂) a b (ν , _) i
    ∙ cong (bopᵣ o _) (evalᶠ-cong (reify b) (reflᶠ FE.▹ evalᶠ-wk w₂ x ν) i)
  zipT-sound o w₁ w₂ a@(loop _) (lets x b) ν i =
    zipT-sound o (skip w₁) (keep w₂) a b (ν , _) i
    ∙ cong (bopᵣ o _) (evalᶠ-cong (reify b) (reflᶠ FE.▹ evalᶠ-wk w₂ x ν) i)
  zipT-sound o w₁ w₂ a@(elem _) (ilet j b) ν i =
    zipT-sound o (skip w₁) (keep w₂) a b (ν , _) i
    ∙ cong (λ z → bopᵣ o _ (⟦ b ⟧ᵀ (wkᶠ-env w₂ ν , z) i)) (evalI-wk w₂ j ν)
  zipT-sound o w₁ w₂ a@(loop _) (ilet j b) ν i =
    zipT-sound o (skip w₁) (keep w₂) a b (ν , _) i
    ∙ cong (λ z → bopᵣ o _ (⟦ b ⟧ᵀ (wkᶠ-env w₂ ν , z) i)) (evalI-wk w₂ j ν)
  zipT-sound o w₁ w₂ (elem x) (elem y) ν [] =
    cong₂ (bopᵣ o) (evalᶠ-wk w₁ x ν []) (evalᶠ-wk w₂ y ν [])
  zipT-sound o w₁ w₂ (loop a) (loop b) ν (i ∷ is) =
    zipT-sound o (keep w₁) (keep w₂) a b (ν , i) is

  selAll-sound : (t : Tab Θ s) (is : Idx Θ s) (ν : ⟦ Θ ⟧ᶠ)
               → ⟦ selAll t is ⟧ᵀ ν [] ≡ ⟦ t ⟧ᵀ ν (evalIdx is ν)
  selAll-sound (lets a t) is ν =
    selAll-sound t (wkIdx ↑ is) (ν , _) ∙ cong (⟦ t ⟧ᵀ (ν , _)) (evalIdx-↑ is ν _)
  selAll-sound (ilet j t) is ν =
    selAll-sound t (wkIdx ↑ is) (ν , _) ∙ cong (⟦ t ⟧ᵀ (ν , _)) (evalIdx-↑ is ν _)
  selAll-sound (elem e) [] ν = refl
  selAll-sound (loop t) (i ∷ is) ν =
    selAll-sound t (wkIdx ↑ is) (ν , _) ∙ cong (⟦ t ⟧ᵀ (ν , _)) (evalIdx-↑ is ν _)

  selP-sound : ∀ s (t : Tab Θ (s ⊗ p)) (is : Idx Θ s) (ν : ⟦ Θ ⟧ᶠ)
             → ∀ j → ⟦ selP s t is ⟧ᵀ ν j ≡ ⟦ t ⟧ᵀ ν (evalIdx is ν ++ j)
  selP-sound [] t [] ν j = refl
  selP-sound (n ∷ s) (lets a t) is ν j =
    selP-sound (n ∷ s) t (wkIdx ↑ is) (ν , _) j
    ∙ cong (λ z → ⟦ t ⟧ᵀ (ν , _) (z ++ j)) (evalIdx-↑ is ν _)
  selP-sound (n ∷ s) (ilet i t) is ν j =
    selP-sound (n ∷ s) t (wkIdx ↑ is) (ν , _) j
    ∙ cong (λ z → ⟦ t ⟧ᵀ (ν , _) (z ++ j)) (evalIdx-↑ is ν _)
  selP-sound (n ∷ s) (loop t) (i ∷ is) ν j =
    selP-sound s t (wkIdx ↑ is) (ν , _) j
    ∙ cong (λ z → ⟦ t ⟧ᵀ (ν , _) (z ++ j)) (evalIdx-↑ is ν _)

  nests-sound : ∀ s (t : Tab (Θ ▹▹ s) p) (ν : ⟦ Θ ⟧ᶠ)
              → ∀ ij → ⟦ nests s t ⟧ᵀ ν ij ≡ ⟦ t ⟧ᵀ (ext {s = s} ν (proj₁ (splitP {s = s} ij)))
                                                    (proj₂ (splitP {s = s} ij))
  nests-sound [] t ν ij = refl
  nests-sound (n ∷ s) t ν (i ∷ ij) = nests-sound s t (ν , i) ij

  nestsS-sound : ∀ s (t : Tab (Θ ▹▹ s) []) (ν : ⟦ Θ ⟧ᶠ)
               → ∀ i → ⟦ nestsS s t ⟧ᵀ ν i ≡ ⟦ t ⟧ᵀ (ext ν i) []
  nestsS-sound [] t ν [] = refl
  nestsS-sound (n ∷ s) t ν (i ∷ is) = nestsS-sound s t (ν , i) is

  withCore-sound : (w : Θ₀ ⊆ᶠ Θ) (t : Tab Θ s) (k : ∀ {Φ} → Θ₀ ⊆ᶠ Φ → Tab Φ s → Tab Φ q)
                   (G : ⟦ Θ₀ ⟧ᶠ → Ar s R → Ar q R)
                 → (∀ {Φ} (w′ : Θ₀ ⊆ᶠ Φ) (t′ : Tab Φ s) ν′
                    → ⟦ k w′ t′ ⟧ᵀ ν′ ≈ᵃ G (wkᶠ-env w′ ν′) (⟦ t′ ⟧ᵀ ν′))
                 → (ν : ⟦ Θ ⟧ᶠ) → ⟦ withCore w t k ⟧ᵀ ν ≈ᵃ G (wkᶠ-env w ν) (⟦ t ⟧ᵀ ν)
  withCore-sound w (lets a t) k G hk ν = withCore-sound (skip w) t k G hk (ν , _)
  withCore-sound w (ilet i t) k G hk ν = withCore-sound (skip w) t k G hk (ν , _)
  withCore-sound w t@(elem _) k G hk ν = hk w t ν
  withCore-sound w t@(loop _) k G hk ν = hk w t ν

  sums-sound : ∀ s (e : F (Θ ▹▹ s) []) (ν : ⟦ Θ ⟧ᶠ)
             → evalᶠ (sums s e) ν [] ≡ A.sum _+_ (fromℕ 0) (λ i → evalᶠ e (ext {s = s} ν i) [])
  sums-sound [] e ν = refl
  sums-sound (n ∷ s) e ν =
    sum₁-cong _+_ (fromℕ 0) {λ i → evalᶠ (sums s e) (ν , hd i) []}
                            {λ i → A.sum _+_ (fromℕ 0) (λ j → evalᶠ e (ext {s = n ∷ s} ν (i ++ j)) [])}
              λ { (i ∷ []) → sums-sound s e (ν , i) }

  -- zero-but
  zbR : P s → P s → R → R
  zbR [] [] x = x
  zbR (i ∷ is) (j ∷ js) x = ifeqᵣ i j (zbR is js x)

  ifeqs-sound : (is js : Idx Θ s) (e : F Θ []) (ν : ⟦ Θ ⟧ᶠ)
              → evalᶠ (ifeqs is js e) ν [] ≡ zbR (evalIdx is ν) (evalIdx js ν) (evalᶠ e ν [])
  ifeqs-sound [] [] e ν = refl
  ifeqs-sound (i ∷ is) (j ∷ js) e ν = cong (ifeqᵣ (evalI i ν) (evalI j ν)) (ifeqs-sound is js e ν)

  zbR-cases : (i j : P s) (x : R) → (i ≡ j × zbR i j x ≡ x) ⊎ (¬ i ≡ j × zbR i j x ≡ fromℕ 0)
  zbR-cases [] [] x = inj₁ (refl , refl)
  zbR-cases (i ∷ is) (j ∷ js) x with i Fin.≟ j | zbR-cases is js x
  ... | no ¬p | _ = inj₂ ((λ { refl → ¬p refl }) , refl)
  ... | yes refl | inj₁ (refl , q) = inj₁ (refl , q)
  ... | yes refl | inj₂ (ne , q) = inj₂ ((λ { refl → ne refl }) , q)

  zb-cases : (i j : P s) (x : Ar p R) (k : P p)
           → (i ≡ j × zb i j x k ≡ x k) ⊎ (¬ i ≡ j × zb i j x k ≡ fromℕ 0)
  zb-cases i j x k with i ≟ₚ j
  ... | yes eq = inj₁ (eq , refl)
  ... | no ne = inj₂ (ne , refl)

  zbR-zb : (i j : P s) (x : Ar p R) (k : P p) → zbR i j (x k) ≡ zb i j x k
  zbR-zb i j x k with zbR-cases i j (x k) | zb-cases i j x k
  ... | inj₁ (_ , a) | inj₁ (_ , b) = a ∙ sym b
  ... | inj₂ (_ , a) | inj₂ (_ , b) = a ∙ sym b
  ... | inj₁ (eq , _) | inj₂ (ne , _) = ⊥-elim (ne eq)
  ... | inj₂ (ne , _) | inj₁ (eq , _) = ⊥-elim (ne eq)

  -- Index arithmetic
  idivs-sound : (pf : s * p ≈ q) (ks : Idx Θ q) (ν : ⟦ Θ ⟧ᶠ)
              → evalIdx (idivs pf ks) ν ≡ ix-div (evalIdx ks ν) pf
  idivs-sound [] [] ν = refl
  idivs-sound (cons ⦃ refl ⦄ ⦃ pf ⦄) (k ∷ ks) ν = cong (_ ∷_) (idivs-sound pf ks ν)

  imods-sound : (pf : s * p ≈ q) (ks : Idx Θ q) (ν : ⟦ Θ ⟧ᶠ)
              → evalIdx (imods pf ks) ν ≡ ix-mod (evalIdx ks ν) pf
  imods-sound [] [] ν = refl
  imods-sound (cons ⦃ refl ⦄ ⦃ pf ⦄) (k ∷ ks) ν = cong (_ ∷_) (imods-sound pf ks ν)

  icombs-sound : (pf : p * q ≈ s) (is : Idx Θ p) (js : Idx Θ q) (ν : ⟦ Θ ⟧ᶠ)
               → evalIdx (icombs pf is js) ν ≡ ix-combine (evalIdx is ν) (evalIdx js ν) pf
  icombs-sound [] [] [] ν = refl
  icombs-sound (cons ⦃ refl ⦄ ⦃ pf ⦄) (i ∷ is) (j ∷ js) ν = cong (_ ∷_) (icombs-sound pf is js ν)

  -- The relation between source and target environments.
  RelV : Val Θ is → ⟦ is ⟧ˢ → ⟦ Θ ⟧ᶠ → Set
  RelV {is = ix s} v x ν = evalIdx v ν ≡ x
  RelV {is = ar s} t x ν = ⟦ t ⟧ᵀ ν ≈ᵃ x

  Rel : Env Θ Γ → ⟦ Γ ⟧ᶜ → ⟦ Θ ⟧ᶠ → Set
  Rel ε _ _ = ⊤
  Rel (σ ▹ v) (ρ , x) ν = Rel σ ρ ν × RelV v x ν

  RelV-wk : (w : Θ ⊆ᶠ Φ) (v : Val Θ is) (x : ⟦ is ⟧ˢ) (ν : ⟦ Φ ⟧ᶠ)
          → RelV v x (wkᶠ-env w ν) → RelV (wkV w v) x ν
  RelV-wk {is = ix s} w v x ν h = evalIdx-wk w v ν ∙ h
  RelV-wk {is = ar s} w t x ν h i = ⟦⟧-wk w t ν i ∙ h i

  Rel-wk : (w : Θ ⊆ᶠ Φ) (σ : Env Θ Γ) (ρ : ⟦ Γ ⟧ᶜ) (ν : ⟦ Φ ⟧ᶠ)
         → Rel σ ρ (wkᶠ-env w ν) → Rel (wkEnv w σ) ρ ν
  Rel-wk w ε ρ ν h = tt
  Rel-wk w (σ ▹ v) (ρ , x) ν (h₁ , h₂) = Rel-wk w σ ρ ν h₁ , RelV-wk w v x ν h₂

  Rel-under : ∀ s (σ : Env Θ Γ) (ρ : ⟦ Γ ⟧ᶜ) (ν : ⟦ Θ ⟧ᶠ) (is : P s)
            → Rel σ ρ ν → Rel (wkEnv (wk▹▹ {s = s} ⊆ᶠ-eq) σ) ρ (ext ν is)
  Rel-under s σ ρ ν is h = Rel-wk _ σ ρ (ext ν is) (subst (Rel σ ρ) (sym (wk-env-ext ν is)) h)

  Rel-↑ : ∀ {τ} (σ : Env Θ Γ) (ρ : ⟦ Γ ⟧ᶜ) (ν : ⟦ Θ ⟧ᶠ) (x : FE.⟦ τ ⟧ᵗ)
        → Rel σ ρ ν → Rel (wkEnv ↑ σ) ρ (ν , x)
  Rel-↑ σ ρ ν x h = Rel-wk _ σ ρ (ν , x) (subst (Rel σ ρ) (sym (wkᶠ-env-id ν)) h)

  lookup-rel : (x : is ∈ Γ) (σ : Env Θ Γ) (ρ : ⟦ Γ ⟧ᶜ) (ν : ⟦ Θ ⟧ᶠ)
             → Rel σ ρ ν → RelV (lookupEnv x σ) (lookup x ρ) ν
  lookup-rel here (σ ▹ v) (ρ , x) ν (_ , h) = h
  lookup-rel (there x) (σ ▹ v) (ρ , _) ν (h , _) = lookup-rel x σ ρ ν h

  -- The scalar operations of E and F agree.
  eval-uop : (o : Uop) (ne : ¬ o ≡ ℙₒ) (e : E Γ (ar s)) (ρ : ⟦ Γ ⟧ᶜ)
           → ∀ i → uopᵣ (uopᶠ o ne) (eval e ρ i) ≡ eval (uop o e) ρ i
  eval-uop ⊟ₒ ne e ρ i = refl
  eval-uop reluₒ ne e ρ i = refl
  eval-uop √ₒ ne e ρ i = refl
  eval-uop 𝟙/ₒ ne e ρ i = refl
  eval-uop 𝕚+ₒ ne e ρ i = refl
  eval-uop lnₒ ne e ρ i = refl
  eval-uop ℙₒ ne e ρ i = ⊥-elim (ne refl)
  eval-uop (scₒ n) ne e ρ i = refl

  bop-case : (o : Bop) (a b : Tab Θ s) (x y : Ar s R) (ν : ⟦ Θ ⟧ᶠ)
           → ⟦ a ⟧ᵀ ν ≈ᵃ x → ⟦ b ⟧ᵀ ν ≈ᵃ y
           → ⟦ zipT o ⊆ᶠ-eq ⊆ᶠ-eq a b ⟧ᵀ ν ≈ᵃ A.zipWith (bopᵣ o) x y
  bop-case o a b x y ν ha hb i =
    zipT-sound o ⊆ᶠ-eq ⊆ᶠ-eq a b ν i
    ∙ cong₂ (bopᵣ o) (cong (λ z → ⟦ a ⟧ᵀ z i) (wkᶠ-env-id ν) ∙ ha i)
                     (cong (λ z → ⟦ b ⟧ᵀ z i) (wkᶠ-env-id ν) ∙ hb i)

  -- Main theorem: compilation preserves the semantics.
  sound : (e : E Γ is) (σ : Env Θ Γ) (ρ : ⟦ Γ ⟧ᶜ) (ν : ⟦ Θ ⟧ᶠ)
        → Rel σ ρ ν → RelV (compile e σ) (eval e ρ) ν
  sound (var x) σ ρ ν h = lookup-rel x σ ρ ν h
  sound (kop 𝟘ₒ) σ ρ ν h i = konst-sound _ 𝟘ₒ ν i
  sound (kop 𝟙ₒ) σ ρ ν h i = konst-sound _ 𝟙ₒ ν i
  sound (uop {s = s} o e) σ ρ ν h with isℙ o
  ... | yes refl = λ i →
    withCore-sound ⊆ᶠ-eq (compile e σ) smCore (λ _ → Softmaxᶠ) hk ν i
    ∙ Softmax-cong (sound e σ ρ ν h) i
    where
      hk : ∀ {Φ} (w′ : _ ⊆ᶠ Φ) (t′ : Tab Φ s) ν′ → ⟦ smCore w′ t′ ⟧ᵀ ν′ ≈ᵃ Softmaxᶠ (⟦ t′ ⟧ᵀ ν′)
      hk w′ t′ ν′ i =
        eta-sound (var here) (ν′ , _) i
        ∙ Softmax-cong (λ k → selAll-sound (wkT (wk▹▹ {s = s} ⊆ᶠ-eq) t′) (vars s) (ext ν′ k)
                              ∙ ⟦⟧-wk (wk▹▹ {s = s} ⊆ᶠ-eq) t′ (ext ν′ k) _
                              ∙ cong₂ ⟦ t′ ⟧ᵀ (wk-env-ext ν′ k) (evalIdx-vars ν′ k)) i
  ... | no ne = λ i →
    mapT-sound ⊆ᶠ-eq _ (λ _ → uopᵣ (uopᶠ o ne)) (λ _ _ _ → refl) (compile e σ) ν i
    ∙ cong (uopᵣ (uopᶠ o ne)) (sound e σ ρ ν h i)
    ∙ eval-uop o ne e ρ i
  sound (bop ⊞ₒ a b) σ ρ ν h =
    bop-case ⊞ₒ (compile a σ) (compile b σ) _ _ ν (sound a σ ρ ν h) (sound b σ ρ ν h)
  sound (bop ⊠ₒ a b) σ ρ ν h =
    bop-case ⊠ₒ (compile a σ) (compile b σ) _ _ ν (sound a σ ρ ν h) (sound b σ ρ ν h)
  sound (mop {s = s} imapsₒ e) σ ρ ν h i =
    nestsS-sound s _ ν i
    ∙ sound e (under s σ (vars s)) (ρ , i) (ext ν i) (Rel-under s σ ρ ν i h , evalIdx-vars ν i) []
  sound (mop {s = s} (imapₒ refl) e) σ ρ ν h i =
    nests-sound s _ ν i
    ∙ sound e (under s σ (vars s)) (ρ , l) (ext ν l) (Rel-under s σ ρ ν l h , evalIdx-vars ν l) _
    where l = proj₁ (splitP {s = s} i)
  sound (mop {q = q} (imapbₒ pf) e) σ ρ ν h k =
    nestsS-sound q _ ν k
    ∙ selAll-sound t (imods pf (vars q)) (ext ν k)
    ∙ cong (⟦ t ⟧ᵀ (ext ν k)) (imods-sound pf (vars q) (ext ν k)
                              ∙ cong (λ z → ix-mod z pf) (evalIdx-vars ν k))
    ∙ sound e (under q σ (idivs pf (vars q))) (ρ , ix-div k pf) (ext ν k)
            (Rel-under q σ ρ ν k h , (idivs-sound pf (vars q) (ext ν k)
                                      ∙ cong (λ z → ix-div z pf) (evalIdx-vars ν k)))
            (ix-mod k pf)
    where t = compile e (under q σ (idivs pf (vars q)))
  sound (mop {s = s} {p = p} sumₒ e) σ ρ ν h j =
    nestsS-sound p _ ν j
    ∙ sums-sound s _ (ext ν j)
    ∙ sum-cong _+_ (fromℕ 0) (λ i → elem-eq i)
    ∙ sym (sum-inv _+_ (fromℕ 0) {λ i → eval e (ρ , i)} j)
    where
      σ′ = under s σ (vars s)
      t = compile e σ′
      K′ = keep▹▹ {s = s} (wk▹▹ {s = p} ⊆ᶠ-eq)
      ix₂ = wkIdx (wk▹▹ {s = s} ⊆ᶠ-eq) (vars p)
      elem-eq : ∀ i → evalᶠ (reify (selAll (wkT K′ t) ix₂)) (ext (ext ν j) i) []
                      ≡ eval e (ρ , i) j
      elem-eq i =
        selAll-sound (wkT K′ t) ix₂ (ext (ext ν j) i)
        ∙ ⟦⟧-wk K′ t (ext (ext ν j) i) _
        ∙ cong₂ ⟦ t ⟧ᵀ (wk-env-keep▹▹ _ (ext ν j) i ∙ cong (λ z → ext z i) (wk-env-ext ν j))
                       (evalIdx-wk _ (vars p) _
                        ∙ cong (evalIdx (vars p)) (wk-env-ext (ext ν j) i)
                        ∙ evalIdx-vars ν j)
        ∙ sound e σ′ (ρ , i) (ext ν i) (Rel-under s σ ρ ν i h , evalIdx-vars ν i) j
  sound (sop selsₒ e i) σ ρ ν h [] =
    selAll-sound (compile e σ) (compile i σ) ν
    ∙ cong (⟦ compile e σ ⟧ᵀ ν) (sound i σ ρ ν h)
    ∙ sound e σ ρ ν h _
  sound (sop {p = p} (selₒ refl) e i) σ ρ ν h j =
    selP-sound p (compile e σ) (compile i σ) ν j
    ∙ cong (λ z → ⟦ compile e σ ⟧ᵀ ν (z ++ j)) (sound i σ ρ ν h)
    ∙ sound e σ ρ ν h _
  sound (sop {q = q} (selbₒ pf) e i) σ ρ ν h j =
    withCore-sound ⊆ᶠ-eq (compile e σ) (selbCore pf ix₁) G hk ν j
    ∙ cong (λ z → ⟦ compile e σ ⟧ᵀ ν (ix-combine z j pf))
           (cong (evalIdx ix₁) (wkᶠ-env-id ν) ∙ sound i σ ρ ν h)
    ∙ sound e σ ρ ν h _
    where
      ix₁ = compile i σ
      G = λ ν₀ a j → a (ix-combine (evalIdx ix₁ ν₀) j pf)
      hk : ∀ {Φ} (w′ : _ ⊆ᶠ Φ) (t′ : Tab Φ _) ν′
         → ⟦ selbCore pf ix₁ w′ t′ ⟧ᵀ ν′ ≈ᵃ G (wkᶠ-env w′ ν′) (⟦ t′ ⟧ᵀ ν′)
      hk w′ t′ ν′ j =
        nestsS-sound q _ ν′ j
        ∙ selAll-sound (wkT (wk▹▹ {s = q} ⊆ᶠ-eq) t′) _ (ext ν′ j)
        ∙ ⟦⟧-wk (wk▹▹ {s = q} ⊆ᶠ-eq) t′ (ext ν′ j) _
        ∙ cong₂ ⟦ t′ ⟧ᵀ (wk-env-ext ν′ j)
                        (icombs-sound pf _ (vars q) (ext ν′ j)
                         ∙ cong₂ (λ a b → ix-combine a b pf)
                                 (evalIdx-wk _ (wkIdx w′ ix₁) (ext ν′ j)
                                  ∙ cong (evalIdx (wkIdx w′ ix₁)) (wk-env-ext ν′ j)
                                  ∙ evalIdx-wk w′ ix₁ ν′)
                                 (evalIdx-vars ν′ j))
  sound (zero-but i j e) σ ρ ν h k =
    mapT-sound ⊆ᶠ-eq (zbLeaf ix₁ ix₂) g hf (compile e σ) ν k
    ∙ cong₂ (λ a b → zbR a b (⟦ compile e σ ⟧ᵀ ν k))
            (cong (evalIdx ix₁) (wkᶠ-env-id ν) ∙ sound i σ ρ ν h)
            (cong (evalIdx ix₂) (wkᶠ-env-id ν) ∙ sound j σ ρ ν h)
    ∙ cong (zbR (eval i ρ) (eval j ρ)) (sound e σ ρ ν h k)
    ∙ zbR-zb (eval i ρ) (eval j ρ) (eval e ρ) k
    where
      ix₁ = compile i σ
      ix₂ = compile j σ
      g = λ ν₀ x → zbR (evalIdx ix₁ ν₀) (evalIdx ix₂ ν₀) x
      hf : ∀ {Φ} (w′ : _ ⊆ᶠ Φ) ν′ e′ → evalᶠ (zbLeaf ix₁ ix₂ w′ e′) ν′ [] ≡ g (wkᶠ-env w′ ν′) (evalᶠ e′ ν′ [])
      hf w′ ν′ e′ = ifeqs-sound (wkIdx w′ ix₁) (wkIdx w′ ix₂) e′ ν′
                    ∙ cong₂ (λ a b → zbR a b (evalᶠ e′ ν′ [])) (evalIdx-wk w′ ix₁ ν′) (evalIdx-wk w′ ix₂ ν′)
  sound (let′ e e₁) σ ρ ν h =
    sound e₁ (wkEnv ↑ σ ▹ eta (var here)) (ρ , eval e ρ) (ν , _)
          (Rel-↑ σ ρ ν _ h , λ i → eta-sound (var here) (ν , _) i ∙ sound e σ ρ ν h i)

  -- Top level
  ⌊_⌋ᵉ : ⟦ Γ ⟧ᶜ → ⟦ ⌊ Γ ⌋ ⟧ᶠ
  ⌊_⌋ᵉ {ε} ρ = tt
  ⌊_⌋ᵉ {Γ ▹ ar s} (ρ , x) = ⌊ ρ ⌋ᵉ , x
  ⌊_⌋ᵉ {Γ ▹ ix s} (ρ , x) = ext ⌊ ρ ⌋ᵉ x

  idEnv-rel : (ρ : ⟦ Γ ⟧ᶜ) → Rel (idEnv {Γ}) ρ ⌊ ρ ⌋ᵉ
  idEnv-rel {ε} ρ = tt
  idEnv-rel {Γ ▹ ar s} (ρ , x) =
    Rel-↑ idEnv ρ ⌊ ρ ⌋ᵉ x (idEnv-rel ρ) , eta-sound (var here) (⌊ ρ ⌋ᵉ , x)
  idEnv-rel {Γ ▹ ix s} (ρ , x) =
    Rel-under s idEnv ρ ⌊ ρ ⌋ᵉ x (idEnv-rel ρ) , evalIdx-vars ⌊ ρ ⌋ᵉ x

  compile-top-sound : (e : E Γ (ar s)) (ρ : ⟦ Γ ⟧ᶜ) → evalᶠ (compile-top e) ⌊ ρ ⌋ᵉ ≈ᵃ eval e ρ
  compile-top-sound e ρ = sound e idEnv ρ ⌊ ρ ⌋ᵉ (idEnv-rel ρ)

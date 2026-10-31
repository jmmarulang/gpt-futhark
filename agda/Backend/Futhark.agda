-- Verified Futhark backend.
--
-- This module is the interface to the backend in Backend/Futhark/:
--
--   Syntax.agda     F, a small DSL that mirrors the Futhark we generate
--   Semantics.agda  the meaning of F, in the style of Eval.agda
--   Compile.agda    compilation E → F and its soundness proof
--   Print.agda      printing F as Futhark (the only unverified step)
--
-- Main theorem (Compile.agda, module Soundness):
--
--   compile-top-sound : (e : E Γ (ar s)) (ρ : ⟦ Γ ⟧ᶜ)
--                     → evalᶠ (compile-top e) ⌊ ρ ⌋ᵉ ≈ᵃ eval e ρ
--
-- where eval is the semantics of E from Eval.agda.  The proof uses the
-- operations of Real only, none of the properties in RealProp.
--
--
-- Design decisions
-- ================
--
-- 1. A separate target language F instead of a subset of E.
--    Futhark needs index arithmetic (i * 4 + j, i / 4, i % 4 for
--    reshapes), which E cannot express, since its index terms are
--    variables only.  Adding index operations to E would touch every
--    file that matches on E, and an `IsFut e` check would be needed to
--    make sure that printing is total.  Instead, F is Futhark-shaped by
--    construction:
--      * loops (imap, sum) and selections (sel) run over a single
--        dimension; arrays are still multi-dimensional,
--      * scalar operations work on scalars only (kop, uop, bop, ifeq),
--      * sum is scalar-valued: sums over arrays become an imap of sums,
--        which is the default because it exposes more parallelism,
--      * index terms are I: variables, div, mod and comb (remQuot and
--        combine), so imapb/selb need no special support in Futhark,
--      * softmax binds its indices, like isoftmaxN in the prelude, so
--        its argument is fused into its body,
--      * ilet binds an index term; it replaces substitution (see 3).
--    E, Grad and Opt are unchanged.  imapb/selb stay in E, as the
--    zero-but eliminations in Opt rely on one-hot indices being
--    variables.
--
-- 2. Compilation is NbE into syntax, following Futhark.agda.  Arrays
--    are represented by `Tab`s:
--        lets : F Θ p → Tab (Θ ▹ ar p) s → Tab Θ s
--        ilet : I Θ n → Tab (Θ ▹ ix n) s → Tab Θ s
--        elem : F Θ [] → Tab Θ []
--        loop : Tab (Θ ▹ ix n) s → Tab Θ (n ∷ s)
--    loop plays the role of `combined`, and lets/ilet the role of the
--    (String → String) wrappers in Futhark.agda.  Invariant: the lets
--    in front of a loop do not depend on its index, so they are
--    computed once, outside of it.
--      * No array lets are introduced (except in the softmax case, see
--        TODO 1); a let is never moved under a binder that it was not
--        under in the source.
--      * The lets of the operands of elementwise operations (mapT,
--        zipT) are kept in front of the loops of the result.
--      * Selecting from a Tab binds the index (ilet) instead of
--        building the array, so (sel (imap e) i) patterns cannot
--        survive.
--      * Sharing follows the source: let-bound arrays are materialised,
--        all other arrays are fused into their consumers.  The policy
--        lives in the let′ case of compile, and the soundness proof
--        does not depend on it.
--    The values in the environment are F syntax, so no Kripke function
--    spaces are needed: going under a binder is weakening, and applying
--    an array to an index is ilet.  compile is structurally recursive,
--    with no TERMINATING pragmas and no State monad (de Bruijn indices).
--
-- 3. Soundness is a first-order logical relation (Rel in Compile.agda)
--    between the source environment (Eval) and the target environment
--    (Semantics): index variables evaluate to the same index, and the
--    Tab of an array variable denotes the same array pointwise.
--
-- 4. Printing (Print.agda) is unverified, but every F construct maps
--    directly onto a Futhark construct or a prelude helper.  ilet is
--    always inlined.  Bound variables are named x<d> and i<d>, where d
--    is the binder depth, so the names of free variables must not have
--    this form.
--
--
-- TODO
-- ====
--
-- 1. Opaque arrays in Tab.  Arrays that cannot be decomposed (softmax
--    results, variables) are represented by a let-bound variable and
--    `eta`.  This leads to copies such as
--      let x = isoftmax1 n (…) in imap1 n (\i -> x[i])
--    and the let in smCore is never shared: selAll copies it to every
--    consumer.  Add a constructor arr : F Θ s → Tab Θ s with
--    reify (arr a) = a, selection as a chain of sel, and mapT/zipT
--    expanding it elementwise (by recursion on the other argument only,
--    so that termination stays structural).  Then softmax becomes
--    arr (softmax …), variables become arr (var x), and eta goes away.
--
-- 2. imapb without index arithmetic.  imapb pf e over
--    q = [o₁*i₁, o₂*i₂, …] can be generated as loops over
--    o₁, i₁, o₂, i₂, … with a flatten after each pair:
--      flatten (imap1 o₁ (\a₁ -> imap1 i₁ (\b₁ ->
--        flatten (imap1 o₂ (\a₂ -> imap1 i₂ (\b₂ -> body)))))))
--    This keeps the layout of the result, avoids index computations,
--    and leaves plain loops for later interchange.  Needs:
--      * flat : F Γ (m ∷ n ∷ s) → F Γ (m * n ∷ s) with
--        eval (flat a) ρ (k ∷ ks) = eval a ρ (q ∷ r ∷ ks),
--        (q , r) = remQuot n k, which matches Ar.ix-div/ix-mod,
--      * a Tab constructor flat; selecting at k ∷ ks binds
--        div n k ∷ mod m k ∷ ks; zipT of two flats with the same
--        factors stays a flat, other cases expand elementwise,
--      * the body compiled once in Θ ▹▹ s, then weakened into the
--        interleaved context (the o variables keep their order),
--      * Futhark size types: flatten gives [o * i]f32, not [q]f32, so
--        the printer has to insert a size coercion (:> [q]f32).
--    At rank 1 the lets of the body are computed once per index of s.
--    At rank k they can only be placed after oₖ, so they are recomputed
--    ∏_{d<k} |i_d| times (still fewer than once per element, as now).
--
-- 3. Optimisations on F, in the style of Opt.agda (∃ e′ → e ≈ e′), and
--    later driven by a cost model (e-graphs):
--      * hoisting lets that do not depend on the index out of loop and
--        sum (needs strengthening with a proof, like stren-∃ in Lang),
--      * sum strategy: imap of sums vs. sum of imaps (see TODO 4),
--      * imapb strategy: fusion (default) vs. materialising the blocked
--        array s ⊗ p (rarely better, due to memory traffic),
--      * inlining let-bound arrays that are pure index remappings
--        (transposes, reshapes): a share? policy in the let′ case.
--
-- 4. Cost model for sums: imap of sums vs. sum of imaps.
--    For a sum over arrays, Sum λ i → (lets in Imap λ j → …), compile
--    puts the output loop outside and a scalar sum inside:
--      imap j. isum i. (lets; element j)
--    The lets of the summand depend on the summation index i (they were
--    under the sum in the source), so they are recomputed for every
--    output element j.  The alternative is the sum of imaps:
--      isum i. (lets; imap j. element j)
--    which computes the lets once per i, but accumulates arrays of the
--    output shape, sequentially over i.  Neither is better in general:
--      * imap of sums exposes the output loop as a parallel map and
--        needs no temporaries, even when it recomputes the lets,
--      * sum of imaps pays off when the lets are expensive compared to
--        the cost of the array accumulations and of the lost
--        parallelism.
--    Imap of sums is the default (it is what Futhark.agda produces and
--    what parallel hardware prefers).  Choosing per sum needs a cost
--    model (sizes, cost of the lets, available parallelism), e.g. as
--    part of the e-graph work.  Implementing the alternative needs:
--      * an array-valued sum in F, sumv : F (Γ ▹ ix n) s → F Γ s with
--        eval (sumv e) ρ = Ar.sum (zipWith _+_) (K 0) (λ i → eval e (ρ , i)),
--        printed as a loop that accumulates with map2 (F.+), or as an
--        isumvN helper; its soundness follows from sum-inv,
--      * either a partial sum in Tab, sumT : Tab (Θ ▹ ix n) p → Tab Θ p,
--        where selection pushes the index inside (giving the fused
--        scalar isum) and reify chooses between the two forms, or a
--        rewrite rule on F (imap j. isum i. e ↔ sumv i. imap j. e).
--    Both forms are sound, so the choice is a policy that can change
--    without touching the proofs.  Hoisting lets that do not depend on
--    i (TODO 3) is independent of this choice and always profitable.
--    The same trade-off appears for imapb (TODO 2, TODO 3): fusion vs.
--    materialising the blocked array, where cache behaviour and memory
--    traffic usually favour fusion.
--
-- 5. The prelude only defines isoftmax1; the printer emits isoftmaxN for
--    rank N.  Add helpers when a higher rank is needed.
--
-- 6. Turn the examples (sum over lets, sum of an imap, softmax of a let,
--    the GPT forward pass) into refl regression tests.
module Backend.Futhark where

open import Data.Nat using (ℕ; suc)
open import Data.Nat.Show using () renaming (show to show-nat)
open import Data.String using (String; _++_)
open import Data.List using (_∷_)

open import Ar using (S)
open import Lang using (Ctx; IS; ix; ar; E; ε; _▹_)
open import Backend.Futhark.Syntax using (FCtx; _▹▹_)
import Backend.Futhark.Print as P

open import Backend.Futhark.Compile public using (compile-top; ⌊_⌋; module Soundness)
open import Backend.Futhark.Print public using (show)

private
  variable
    Γ : Ctx
    is : IS
    s : S

-- Names of the variables of a source context.  An index variable x of
-- shape s becomes the 1-d indices x0, x1, … in ⌊ Γ ⌋.
data Names : Ctx → Set where
  ε   : Names ε
  _▹_ : Names Γ → String → Names (Γ ▹ is)

private
  ixNames : ∀ {Θ} s → ℕ → String → P.Names Θ → P.Names (Θ ▹▹ s)
  ixNames Data.List.[] d x ν = ν
  ixNames (n ∷ s) d x ν = ixNames s (suc d) x (ν P.▹ (x ++ show-nat d))

toNames : Names Γ → P.Names ⌊ Γ ⌋
toNames ε = P.ε
toNames (_▹_ {is = ar s} ν x) = toNames ν P.▹ x
toNames (_▹_ {is = ix s} ν x) = ixNames s 0 x (toNames ν)

-- The Futhark expression for e, given names for its free variables.
toFuthark : E Γ (ar s) → Names Γ → String
toFuthark e ν = show (compile-top e) (toNames ν)

# gpt-futhark

Agda framework for verified numerical code (neural networks): a DSL with
semantics, verified optimisations, AD, and code generation to Futhark.
Accompanies the paper "Correctness meets high performance in Agda".

## Layout (agda/)

- `Ar.agda` arrays as functions from indices (also pointwise equality
  `_≈ᵃ_` and generic sum lemmas); `Lang.agda` the DSL E (also `WkSub`,
  `Syntax`, `Primitives`, `Primitives.Microgpt` with the GPT model);
  `Real.agda` the reals (`Real`) and their laws (`RealProp`);
  `Eval.agda` semantics of E (depends only on `Real`; lemmas that need
  `RealProp`, including the delta rules for one-hot arrays, are in
  `Eval.ZeroBut`); `RSum.agda` sums of reals over shapes (linearity,
  Fubini, nested and blocked shapes); `Opt.agda` verified optimisations.
- `AD.agda` **verified reverse-mode AD** (wrapper, re-exports the theorems).
  Its header records the design decisions, trusted base and TODO list;
  read it before working on AD. Implementation in `AD/`: `Grad.agda`
  (grad, sharing-preserving vjp), `VJP.agda` (semantic vjp V),
  `GradCorrect.agda` (grad agrees with V), `Jacobian.agda` (J and V = Jᵀ),
  `Correct.agda`, `Dual.agda` (dual numbers: J is the derivative, and the
  dot-product test for grad).
- `GradTerm.agda` is an obsolete attempt at a terminating old Grad; it no
  longer type-checks.
- `Backend/Futhark.agda` **verified Futhark backend** (wrapper). Its header
  comment records the design decisions and the TODO list; read it before
  working on the backend. Implementation in `Backend/Futhark/`:
  `Syntax.agda` (target DSL F), `Semantics.agda`, `Compile.agda`
  (E → F by NbE into syntax, soundness proof against Eval), `Print.agda`
  (unverified printer to the helpers in `src/futhark/microgpt.fut`).
- `Futhark.agda` the old, unverified backend (kept; no longer used by
  Extraction). Its test₄–test₆ are refl regression tests for the sem-sum fix.
- `Extraction.agda` pipeline: grad, optimise, generate code (uses
  `AD.Grad` and `Backend.Futhark`). `ToFile.agda` prints `grad-bgpt-loss-s`.
- `README.lagda.md` is outdated; leave it until a planned rewrite.
  TODO: its AD section is up to date, but it does not type-check (the
  CNN example uses `mconv`, now `CNN.mconv`; the Opt and extraction
  examples are probably stale too).

## Toolchain and checking

- Agda 2.8.0, standard library 2.3 (the README still says 2.7.0.1 / 2.1.1).
- Type-check from `agda/`. This container has no `~/.agda` library
  configuration, so pass the include paths:
  `agda -i . -i /usr/share/agda-stdlib/src Backend/Futhark.agda`.
- The backend and AD must pass `agda --safe Backend/Futhark.agda` and
  `agda --safe AD.agda` (no postulates, holes or termination pragmas).
- Normalising the full gradient interactively runs out of memory (the
  container has ~1 GB). To get generated code, compile ToFile with the
  GHC backend into a directory outside the repo and rerun the command
  if GHC is killed (`--make` resumes):
  `agda --compile --compile-dir=<scratch>/build --ghc-flag=-O0 ToFile.agda`
  then run `<scratch>/build/ToFile`.
- When changing grad or the pipeline, compare the generated code with a
  baseline built before the change (`cmp`; it should be identical).
- To compare two generated programs from different backends, erase bound
  names (`x<n>`, `i<n>`, `t<n>`), expand `imapN` sugar and drop
  parentheses before diffing.

## Working conventions

- Discuss and agree on a plan before writing Agda code.
- Do not change existing files to fix bugs without asking; prepare a
  separate patch first and apply it only when asked.
- The user commits changes; do not commit.
- Match the surrounding style: short comments, no `TERMINATING` pragmas,
  proofs in the style of Eval.agda / Opt.agda.

## State (2026-11-06)

Verified backend complete for all E constructs and used by Extraction;
next steps are the TODO list in `agda/Backend/Futhark.agda`.

Verified AD complete (`AD.agda`, all `--safe`): grad = Jᵀ (Correct.agda)
and grad passes the dot-product test against dual numbers (Dual.agda).
Extraction uses `AD.Grad`; the generated GPT gradient is byte-identical
to the one from the old `Grad.agda` (deleted). Next steps are the TODO
list in `agda/AD.agda`; the cleanup of `RealProp` (towards commutative
ring laws) is to be done together with Opt.

# gpt-futhark

Agda framework for verified numerical code (neural networks): a DSL with
semantics, verified optimisations, AD, and code generation to Futhark.
Accompanies the paper "Correctness meets high performance in Agda".

## Layout (agda/)

- `Ar.agda` arrays as functions from indices; `Lang.agda` the DSL E (also
  `WkSub`, `Syntax`, `Primitives`, `Primitives.Microgpt` with the GPT model);
  `Eval.agda` semantics of E; `Opt.agda` verified optimisations; `Grad.agda` AD.
- `Backend/Futhark.agda` **verified Futhark backend** (wrapper). Its header
  comment records the design decisions and the TODO list; read it before
  working on the backend. Implementation in `Backend/Futhark/`:
  `Syntax.agda` (target DSL F), `Semantics.agda`, `Compile.agda`
  (E → F by NbE into syntax, soundness proof against Eval), `Print.agda`
  (unverified printer to the helpers in `src/futhark/microgpt.fut`).
- `Futhark.agda` the old, unverified backend (kept; no longer used by
  Extraction). Its test₄–test₆ are refl regression tests for the sem-sum fix.
- `Extraction.agda` pipeline: grad, optimise, generate code (uses
  `Backend.Futhark`). `ToFile.agda` prints `grad-bgpt-loss-s`.
- `README.lagda.md` is outdated; leave it until a planned rewrite.

## Toolchain and checking

- Agda 2.8.0, standard library 2.3 (the README still says 2.7.0.1 / 2.1.1).
- Type-check from `agda/`, e.g. `agda Backend/Futhark.agda`. The backend
  must pass `agda --safe Backend/Futhark.agda` (no postulates, holes or
  termination pragmas).
- Normalising the full gradient interactively runs out of memory (the
  container has ~1 GB). To get generated code, compile ToFile with the
  GHC backend into a directory outside the repo and rerun the command
  if GHC is killed (`--make` resumes):
  `agda --compile --compile-dir=<scratch>/build --ghc-flag=-O0 ToFile.agda`
  then run `<scratch>/build/ToFile`.
- To compare two generated programs, erase bound names (`x<n>`, `i<n>`,
  `t<n>`), expand `imapN` sugar and drop parentheses before diffing.

## Working conventions

- Discuss and agree on a plan before writing Agda code.
- Do not change existing files to fix bugs without asking; prepare a
  separate patch first and apply it only when asked.
- The user commits changes; do not commit.
- Match the surrounding style: short comments, no `TERMINATING` pragmas,
  proofs in the style of Eval.agda / Opt.agda.

## State (2026-10-31)

Verified backend complete for all E constructs and used by Extraction.
Its output for the GPT loss gradient matches the old backend up to names,
except that softmax is no longer recomputed per element. Next steps are
the TODO list in `agda/Backend/Futhark.agda` (opaque arrays in Tab,
imapb via flatten, Opt-style passes and a cost model on F).

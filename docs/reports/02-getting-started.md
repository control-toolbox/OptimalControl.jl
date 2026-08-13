# Getting started — specification

**PR**: 11 · **Depends on**: PRs 5–10 · **Status**: specification
**Scope**: `docs/src/index.md`, `docs/src/getting-started/*`, `docs/src-literate/tutorial.jl`

## Objective

Take someone from `] add OptimalControl` to a solved, plotted problem without leaving the
section, then hand them a curated path into the rest of the site. Written **last** because it
is a synthesis: it links everywhere, so writing it before the targets exist means writing it
twice.

Primary profile: **Applied** ([`00-cahier-des-charges.md`](00-cahier-des-charges.md) §3).
The Geometric and Simulator profiles get one signpost each at the end of the guided tour.

## Pages

| id | title | path | source |
| --- | --- | --- | --- |
| `index` | OptimalControl.jl | `index.md` | `docs/src/index.md` (in place, largely survives) |
| `getting-started-installation` | Installation | `getting-started/installation.md` | new (harvest `index.md` §Installation) |
| `getting-started-first-problem` | Your first problem | `getting-started/first-problem.md` | new |
| `getting-started-guided-tour` | Guided tour | `getting-started/guided-tour.md` | `attic/tutorial.md` + `src-literate/tutorial.jl` |

---

## Page details

### `index.md` — the VitePress root

Not listed in `pages=` (`docs/make.jl:221`). Stays where it is; PR 11 edits it in place.

- **Keep**: the scope paragraph, `## [Mathematical formulation](@id math-formulation)` — the
  Bolza cost, dynamics, the four constraint families, free times and extra variables — the
  `## Citing us` block with the Zenodo DOI, `## Contributing`, and the whole
  `## Reproducibility` machinery (`_downloads_toml`, the three `@raw html` `<details>`).
- **Move out**: `## Installation` → `getting-started/installation.md`. Leave a one-line
  pointer.
- **Rewrite**: `## Basic usage`. It is currently an inert ```` ```julia ```` fence. Make it
  an executed `@example`, and make it identical to the opening of
  `getting-started/first-problem.md` so the reader recognises it.
- **Add**: a short "Where to go next" table — one row per top-level section, one sentence
  each. This is the only place on the site that surveys everything.

**API traps**: the four cross-refs at the end of `## Basic usage` point at
`example-double-integrator-energy`, `manual-abstract-syntax`, `manual-solve`, `manual-plot`.
All four anchors change. New targets: `@ref examples-double-integrator-energy`,
`@ref modelling-abstract-syntax`, `@ref solve-overview`, `@ref results-plot`.

---

### `getting-started/installation.md`

- **Purpose** — get the package and the optional pieces installed, and explain *why* there are
  optional pieces.
- **Outline**
  - `## Install` — `] add OptimalControl`
  - `## You will also need a solver` — `NLPModelsIpopt` for the default path; a table of the
    alternatives (`MadNLP`, `MadNCL`, `Knitro`, `Uno`) and what each needs
  - `## Optional: plotting` — `Plots`, and what `ExtensionError(:Plots)` looks like without it
  - `## Optional: flows` — `OrdinaryDiffEqTsit5`, and the bare `MethodError` without it
  - `## Optional: saving solutions` — `JLD2`, `JSON3`
  - `## Optional: GPU` — `ExaModels`, `MadNLPGPU`, `CUDA`
  - `## Checking your setup` — a snippet that loads everything and prints `methods()`
- **API covered** — none directly; `methods()` in the last section.
- **Executed examples** — the setup check only. Everything else is inert `] add` fences.
- **Source** — new. Harvest the `!!! tip` linking control-toolbox discussion #64 from
  `index.md`.
- **API traps** — the current `index.md` implies `using OptimalControl, NLPModelsIpopt, Plots`
  is the whole story. Since v2.1.0-beta the flow path needs an integrator too, and that is
  the single most common first failure. Give it a `!!! warning`.

**Why this page exists at all.** The optional-dependency structure is a deliberate design
decision (`BREAKING.md` §"Start here": keeping SciML's install cost off users who never write
a flow). Users hit it as a mysterious `MethodError`. One page, early, converts a trap into a
feature.

---

### `getting-started/first-problem.md`

- **Purpose** — the shortest complete story: define, solve, look at it. Fifteen lines of code,
  no options, no theory.
- **Outline**
  - `## The problem` — double integrator, energy minimisation, with the maths
  - `## Define it` — `@def`
  - `## Solve it` — bare `solve(ocp)`
  - `## Look at it` — `plot(sol)`, then `objective(sol)`, `iterations(sol)`, `successful(sol)`
  - `## What just happened` — `solve` picked `(:collocation, :adnlp, :ipopt, :cpu)`; point at
    `@ref solve-choosing-a-method`
  - `## Next`
- **API covered** — `@def`, `solve`, `plot`, `objective`, `iterations`, `successful`,
  `state`, `control`, `time_grid`.
- **Executed examples** — all of it. This page must be `Draft = false`-clean.
- **Source** — new; the model problem is `attic/example-double-integrator-energy.md`
  §"problem definition".
- **API traps** — none new, but respect **1-D is a scalar**: the control is scalar, so
  `control(sol)(t)` returns a `Number`.

The problem to use (same as `index.md` §Basic usage):

```julia
@def ocp begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end
```

---

### `getting-started/guided-tour.md` — Literate

- **Purpose** — the one long-form narrative on the site. Double integrator end to end
  (direct **and** indirect), then Goddard as a realistic problem.
- **Source** — `docs/src-literate/tutorial.jl` (503 lines). The structure survives; the code
  needs a full v2.1 audit.
- **Pipeline** — `Literate.markdown` / `.notebook` / `.script`, as today
  (`docs/make.jl:189-199`), but output to `docs/src/getting-started/`, `.../notebooks/`,
  `.../scripts/`. Update the Binder badge path.
- **Outline** (keep the existing arc)
  - The problem, and installing
  - `@def` and the macro-free form side by side
  - First solve; initial guess; the costate
  - Goddard: direct method in depth, grid continuation
  - GPU
  - Indirect: PMP, the shooting function, the flow
  - Going further — **three** signposts, one per profile of §3
- **API traps to fix in `tutorial.jl`**
  - Preamble must gain `using OrdinaryDiffEqTsit5` **before** the first `Flow`.
  - The indirect section: check every flow call for a positional variable
    (`f(t0,x0,p0,tf,λ)` → `variable=λ`) and for `augment=` (→ `variable_costate=`).
  - `has_abstract_definition`, `definition`, `describe`, `methods` — all still valid.
  - The `methods()` count is quoted in prose somewhere; the real number is **12**
    (10 CPU + 2 GPU), and `src/helpers/methods.jl`'s own docstring is wrong about it. Fix
    both in PR 6, then quote the right figure here.
- **Acceptance** — the notebook and the script regenerate; the markdown executes with
  `Draft = false`.

---

## Outgoing links

| From | To |
| --- | --- |
| `index.md` "Where to go next" | every top-level section |
| `installation.md` | `@ref solve-choosing-a-method`, `@ref results-plot`, `@ref flows-overview`, `@ref solve-gpu` |
| `first-problem.md` | `@ref modelling-abstract-syntax`, `@ref solve-overview`, `@ref results-solution`, `@ref results-plot` |
| `guided-tour.md` | `@ref modelling-functional-api`, `@ref solve-initial-guess`, `@ref solve-gpu`, `@ref flows-shooting`, `@ref geometry-overview`, `@ref examples-singular-control` |

> The Examples section has **no landing page** in the sitemap — it is a flat list of six
> problems. Nothing may link to a bare `@ref examples`; link to a specific example. If a
> gallery index turns out to be wanted, it is a PR 10 addition, not an assumption.

## Acceptance criteria

- [ ] A reader can install, define, solve and plot without leaving the section.
- [ ] `installation.md` names all four optional-dependency families and the error each one's
      absence produces.
- [ ] `first-problem.md` executes end to end with `Draft = false`.
- [ ] `tutorial.jl` has no v2.0 spelling left (grep it against
      [`00-cahier-des-charges.md`](00-cahier-des-charges.md) §8.2).
- [ ] The notebook and script outputs regenerate at the new paths and the Binder badge points
      at the new location.
- [ ] `index.md`'s four cross-refs resolve to the new anchors.

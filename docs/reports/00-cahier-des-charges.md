# Documentation rewrite — cahier des charges

**Date**: 2026-08-09 · **Target**: OptimalControl.jl v2.1.0-beta · **Status**: specification
**Scope**: everything under `docs/`, plus `src/deprecated.jl`
**Out of scope**: the sibling packages' own documentation sites; the `Tutorials` repository

> **How to read this.** Part I says why the current site fails and who we are writing for.
> Part II is the specification proper — the sitemap and the conventions every page must obey;
> that is the part to keep open while writing. Part III is the work order and the acceptance
> criteria.

---

## Part I — State and audience

### 1. Executive summary

The site describes an API that no longer exists, and the doc environment cannot even resolve
against the current package. Three things happened in v2.1.0-beta and none of them reached
`docs/`:

1. **Differential geometry moved to CTLie.** `Lie` → `ad`, `⋅` removed with no alias,
   `HamiltonianLift` → `LiftedHamiltonianFunction` (and re-parented: `<: Function`, no longer
   `<: AbstractHamiltonian`). `docs/src/manual-differential-geometry.md` — 634 lines, the most
   API-dense page on the site — teaches the removed spellings throughout.
2. **The `Flow` API changed shape.** `Flow(f::Function)` is gone (wrap in a `Data` type);
   constrained flows take `constraint=`/`multiplier=` keywords instead of positional arguments;
   the variable is a mandatory keyword, not a 5th positional; `augment=` became
   `variable_costate=`; and SciML is no longer a hard dependency, so **every flow example needs
   `using OrdinaryDiffEqTsit5` in its preamble** or it fails with a bare `MethodError`.
3. **The type vocabulary moved to `CTBase.Data` and is now exported.** `VectorField`,
   `Hamiltonian`, `HamiltonianVectorField`, `ControlLaw`, `OpenLoop`/`ClosedLoop`/
   `DynClosedLoop`, `PathConstraint`, `Multiplier` — all reachable unqualified. The docs still
   write `OptimalControl.VectorField` and carry an admonition explaining why the qualification
   is necessary. It is not.

On top of that, two structural problems that predate the upgrade:

4. **One "Manual" node holds thirteen pages** covering modelling, AI, solving, plotting,
   geometry and flows (`docs/make.jl:231-252`). It is a junk drawer.
5. **The internal CTX split leaks into the user-facing site.** `docs/src/api/subpackages.md`
   is a list of six sibling packages; `docs/src/api/public.md:11` opens with an admonition
   explaining that `Lift` "is defined in CTFlows". A user of the OptimalControl DSL should not
   have to know that CTFlows exists.

### 2. The build is broken

Not "stale" — **broken**. Verified:

| Problem | Evidence |
| --- | --- |
| `docs/Project.toml` pins `CTBase = "=0.18.8"`, `CTModels = "=0.10.1"`, `CTFlows = "0.8"` | root `Project.toml` requires `0.28` / `0.15` / `0.16`. The doc environment cannot resolve. |
| `CTLie` absent from `docs/Project.toml` | it owns `ad`, `Lift`, `Poisson`, `∂ₜ`, `@Lie` |
| `DifferentiationInterface` and `ForwardDiff` absent | without them the whole geometry API is **inert** (extension-gated via `src/imports/ad.jl`) |
| `OrdinaryDiffEqTsit5` absent | `docs/Project.toml` has `OrdinaryDiffEq`, but the flow pages need an integrator armed |
| `docs/make.jl:108` fetches `Base.get_extension(CTFlows, :CTFlowsODE)` | that extension was deleted. Returns `nothing`, which then enters the `Modules` vector and the `setdocmeta!` loop at `docs/make.jl:126-129` |
| `make.jl` never does `using CTLie`, and `CTLie` is not in `Modules` | CTLie docstrings have no `DocTestSetup` and cannot be pulled by `@docs` |
| `docs/inventories/` does not exist | referenced 11 times in `make.jl:42-98`; `DocumenterInterLinks` silently falls back to the URLs |

### 3. Who we are writing for

**The reader is a user of the OptimalControl DSL, not a contributor to the ecosystem.**
Three profiles, in decreasing order of how much of the site they read:

| Profile | Wants | Enters via |
| --- | --- | --- |
| **Applied** — engineer/researcher with a problem to solve | model it, solve it with a direct method, look at the solution | Getting started → Modelling → Solve → Results |
| **Geometric** — control theorist doing indirect methods | flows, shooting, singular controls, Lie/Poisson brackets | Flows → Geometry, usually via Examples |
| **Simulator** — has a controlled ODE, not an optimisation problem | integrate under an open-loop or feedback control, inspect the trajectory, estimate parameters | Flows § open/closed loop; Modelling § problems without control |

The third profile is currently **invisible on the site** even though the code fully supports
it: `Flow(ControlledVectorField(f), OpenLoop(u))` returns a `StateFlowTrajectory` that
`state` / `control` / `objective` / `plot` all accept, exactly like an optimal control
solution. Same for control-free models used for ODE parameter estimation — supported and
tested (`test/problems/control_free.jl`) but only reachable through one example page.

**Consequence for the writing**: the site is organised by what these people are doing, never
by which package implements it. The word "CTFlows" appears in the user-facing pages only in
the Ecosystem annex and the Migration page.

### 4. What "done" means

- A user can go from `] add OptimalControl` to a solved, plotted problem without leaving
  Getting started.
- Every technical capability listed in §6 has a page that names it.
- Each of the **193** symbols in `names(OptimalControl)` appears in at least one guide page
  **and** in exactly one API-reference theme ([`99-api-coverage.md`](99-api-coverage.md) is
  the checklist, and PR 4 makes the build itself verify half of it).
- `julia --project=docs docs/make.jl` runs with `draft = false` and the log has no
  `@ref`/`@extref` resolution errors.
- Every deprecated spelling from v2.0 fails with a message naming its replacement.

---

## Part II — Specification

### 5. Principles

1. **Organised by capability.** Top-level sections are named after what the user is doing.
   No "Manual", no "Miscellaneous".
2. **The ecosystem is an implementation detail.** No `OptimalControl.` qualification in
   examples unless the symbol genuinely is not exported (only `LiftedHamiltonianFunction`,
   `PreModel`, `Model`, `Solution`, `ADNLP`, `Ipopt`, `Collocation`, … — see
   [`99-api-coverage.md`](99-api-coverage.md) §"Imported, not exported"). CTX package names
   appear only in the Ecosystem annex and the Migration page.
3. **Every page runs.** Code is in `@example`/`@repl` blocks that execute, not in inert
   ```` ```julia ```` fences. The exception is a page that shows a *deprecated* or
   *erroring* spelling — those stay inert and say so.
4. **One page, one task.** If a page needs "and" in its title, it is two pages.
5. **Capability first, then the tools.** Each page opens with what you can do, then the
   functions that do it, then a worked snippet. Not the reverse.
6. **Cross-link forward.** Guides link to the API reference for signatures and to Examples
   for the full story. They do not inline a full docstring.

### 6. Capability inventory the site must cover

The user's own framing, turned into a checklist. Each line must be reachable from the
sitemap and appear in [`99-api-coverage.md`](99-api-coverage.md).

**Modelling**
- define a problem with `@def` (abstract syntax)
- define the same problem with the functional API, macro-free
- define a problem **without a control** — parameter estimation in ODEs
- introspect a problem: dimensions, names, dynamics, costs, constraints, traits
- get an LLM to write the `@def` for you

**Direct resolution**
- `solve` in one line; understand what it chose for you
- give an initial guess: `@init`, vectors, functions, warm start from a `Solution`
- choose a method: the 12 `(discretizer, modeler, solver, parameter)` combinations
- pass options; understand routing, `route_to`, `bypass`
- explicit mode with typed components
- solve on GPU

**Results**
- introspect a solution: trajectories, costate, duals, status, iterations
- plot: layouts, groups, styles, control norm, constraints, normalised time
- save and load (JLD2, JSON3)

**Indirect resolution — flows**
- build a flow from an OCP + a control law (the PMP path)
- build a flow from a Hamiltonian, a pseudo-Hamiltonian + a control law, a Hamiltonian
  vector field, a pseudo-Hamiltonian vector field + a control law
- build a flow from a plain vector field
- build a flow from a **controlled** vector field + an **open-loop** control → particular
  solutions of the controlled system
- build a flow from a controlled vector field + a **closed-loop** (feedback) control
- inspect the trajectory it returns exactly like an OCP solution (`state`, `control`,
  `objective`, `plot`)
- **accessors**: recover the Hamiltonian, the Hamiltonian vector field, the
  pseudo-Hamiltonian, the control law, the gradients — from a flow built from an OCP + a law
- concatenate arcs: switching times, jumps on state and costate, multi-phase accessors
- constrained arcs: `constraint=`/`multiplier=` pairs, boundary arcs
- write a shooting function and solve it

**Geometry** (what makes the singular-control example possible)
- `Lift` a vector field to a Hamiltonian
- `ad` — Lie derivative and Lie bracket (the former `Lie`)
- `Poisson` bracket
- `@Lie` — the `[X, Y]` / `{H, K}` notation, nesting, evaluation points
- `∂ₜ` — partial time derivative
- choose the AD backend: `dg_ad_backend`, `dg_ad_backend!`

### 7. Sitemap

Page ids are the target filenames under `docs/src/`. `index.md` stays the VitePress root and
is not listed in `pages=`.

```
Home                        index.md

Getting started             getting-started/installation.md
                            getting-started/first-problem.md
                            getting-started/guided-tour.md          ← Literate

Modelling                   modelling/formulation.md
                            modelling/abstract-syntax.md
                            modelling/functional-api.md
                            modelling/without-control.md
                            modelling/inspect.md
                            modelling/with-ai.md

Solve (direct)              solve/overview.md
                            solve/initial-guess.md
                            solve/choosing-a-method.md
                            solve/options.md
                            solve/explicit-mode.md
                            solve/gpu.md

Results                     results/solution.md
                            results/plot.md
                            results/save-load.md

Flows (indirect)            flows/overview.md
                            flows/from-ocp.md
                            flows/from-hamiltonians.md
                            flows/simulation.md
                            flows/accessors.md
                            flows/multi-phase.md
                            flows/constrained-arcs.md
                            flows/shooting.md

Geometry                    geometry/overview.md
                            geometry/lift.md
                            geometry/ad.md
                            geometry/poisson.md
                            geometry/lie-macro.md
                            geometry/ad-backend.md

Examples                    examples/*.md                            ← see 08

API reference               api/<theme>.md                           ← generated, see 09
                            api/internals.md                         ← generated
                            api/ecosystem.md

Migrating to v2.1           migration.md
```

Ordering rationale: **Results comes before Flows**, contrary to the old site. A trajectory
returned by a flow is inspected and plotted with the same functions as a solution returned by
`solve`, so Results must already be on the table when Flows starts.

### 8. Cross-cutting conventions

Every page spec inherits these. Violations are review blockers.

#### 8.1 Preamble

- **Any page that calls `Flow`** must have `using OrdinaryDiffEqTsit5` in its `@setup` or
  first `@example` block. SciML is no longer a hard dependency; without it `Flow` fails with
  a bare `MethodError` (`BREAKING.md`, §"Start here: `Flow` needs an integrator").
- **Any page that calls `solve`** needs a solver loaded — `using NLPModelsIpopt` for the
  default path.
- **Any page that plots** needs `using Plots`; without it `plot` throws
  `ExtensionError(:Plots)` (`CTModels.jl/src/Display/Display.jl:69`).
- **Any page that saves/loads** needs `using JLD2` and/or `using JSON3`.
- Geometry pages need nothing extra: `DifferentiationInterface` and `ForwardDiff` are armed
  by `src/imports/ad.jl` — but `docs/Project.toml` must list them (see
  [`01-infrastructure.md`](01-infrastructure.md)).

#### 8.2 Spelling

| Never write | Write instead | Why |
| --- | --- | --- |
| `OptimalControl.VectorField`, `OptimalControl.Hamiltonian`, … | `VectorField`, `Hamiltonian`, … | exported since v2.1.0-beta (`src/imports/ctbase.jl`) |
| `Lie(X, f)` | `ad(X, f)` | renamed |
| `X ⋅ f` | `ad(X, f)` | removed, no alias |
| `HamiltonianLift` | `Lift(f)` to build; `OptimalControl.LiftedHamiltonianFunction` to name the type | renamed and re-parented |
| `autonomous=`, `variable=`, `inplace=` | `is_autonomous=`, `is_variable=`, `is_inplace=` | prefixed |
| `Flow(f)` with `f::Function` | `Flow(VectorField(f))`, `Flow(Hamiltonian(f))`, … | the bare function no longer says what it is |
| `Flow(ocp, u, g, μ)` | `Flow(ocp, u; constraint=g, multiplier=μ)` | keywords, and they come as a pair |
| `f(t0, x0, p0, tf, λ)` | `f(t0, x0, p0, tf; variable=λ)` | mandatory keyword on `NonFixed` |
| `augment=true` | `variable_costate=true` | renamed; returns `(xf, pf, pvf)` |
| `CTSolvers.Modelers.ADNLP()`, `CTDirect.Collocation()` | `OptimalControl.ADNLP()`, `OptimalControl.Collocation()` | neither module name is re-exported |
| `time(ocp)`, `success(sol)` | `times(ocp)` / `time_grid(sol)`, `successful(sol)` | no longer re-exported |

#### 8.3 Shape — "1-D is a scalar"

The ecosystem rule, stated in full at
[`Handbook/philosophy/dimension-and-shape.md`](https://github.com/control-toolbox/Handbook/blob/main/philosophy/dimension-and-shape.md):

> **A one-dimensional quantity is a scalar, never a length-1 vector.**

It applies to **state, costate, control and variable**, end to end: the functions the user
writes, the values integrators pass around, and the trajectories a solution returns.

**This is not aspirational — it is implemented and tested.**
`test/suite/shape/test_shape_contract.jl` pins it at OptimalControl's boundary: for `n=1, m=1`
the recorded callback arguments are `isa Number` on the **direct** path *and* on the
**indirect** path, and a third testset asserts the two paths present the *same* shape. That
last one is the seam nothing upstream can check.

Four consequences the pages must respect:

1. **Write 1-D scalar-style.** `lagrange(t, x, u, v) = 0.5u^2`, not `0.5u[1]^2`.
   `x0 = 1.0`, not `[1.0]`. `xf::Real`, not `xf::Vector`.
2. **The in-place buffer is the exception, and stays a vector.** A scalar cannot be mutated,
   so the derivative buffer is always an `n`-vector written by index, *even for `n = 1`*:

   ```julia
   # 1-D dynamics: r is a length-1 vector; x, u, v are scalars
   f!(r, t, x, u, v) = (r[1] = -x + u; nothing)
   ```

   Inputs follow "1-D = scalar"; the output buffer does not. State the asymmetry once, on
   `modelling/functional-api.md`, and do not repeat it everywhere.
3. **`[1]`-indexed code still works** (`x[1] == x` for a scalar), so migrating a reader's
   script is non-breaking. Say that once, on the migration page. But **do not teach it** — a
   guide that writes `u[1]` for a scalar control is teaching the pre-rule mental model.
4. **Coercion is dimension-driven, not value-driven.** `only` when `dim == 1`, `identity`
   otherwise.

> ⚠️ **The single largest factual error in the old documentation.**
> `attic/manual-macro-free.md:252-279` is a section titled *"Scalar vs vector: a subtlety of
> the functional API"* whose entire content is now false. It states that callbacks
> *"always receive `x`, `u`, and `v` as vectors, regardless of their dimension"*, that
> *"dimension-1 components must always be indexed"*, and closes with a `!!! warning` calling
> the callback/solution asymmetry *"intentional"*. The rule was created to **remove** that
> asymmetry, and it did. The section must be deleted, not corrected — see
> [`03-modelling.md`](03-modelling.md).

#### 8.4 Code cells

- ≤ 75 characters per line. Long calls wrap with one argument per line and a trailing comma
  (`Handbook/philosophy/documentation.md` §"Code cell line width").
- Submodule imports bind the name only: `using CTBase: Data`, never `using CTBase.Data`.
  In practice guides should not need either — everything is re-exported.
- Never `using LinearAlgebra` in a page that also demonstrates `⋅` deprecation.

#### 8.5 Anchors and links

- Every page that others link to declares an explicit anchor:
  `# Title` followed by `{#id}` is not Documenter syntax — use
  `# [Title](@id section-id)`, as the current pages do
  (`manual-abstract.md` uses `@id manual-abstract-syntax`).
- Anchor ids follow the file path: `modelling/abstract-syntax.md` → `@id modelling-abstract-syntax`.
- Links to sibling-package docs use `@extref` and **must** have an `InterLinks` entry in
  `make.jl`. CTLie has none today — [`01-infrastructure.md`](01-infrastructure.md) adds it.
  Until it exists, do not write `[`ad`](@extref)`.

#### 8.6 Admonitions

Reserved meanings, so they stay scannable:

- `!!! tip` — a shortcut or a better spelling.
- `!!! note` — a cross-reference or a scope statement.
- `!!! warning` — a v2.0 spelling that no longer works, or a silent-failure trap
  (e.g. `H isa AbstractHamiltonian` is now `false`).
- `!!! danger` — unused. If it feels warranted, the page is wrong.

#### 8.7 Page template

```markdown
# [Title](@id section-page)

One paragraph: what you can do on this page, and when you'd want to.

## <capability 1>
...worked, executed example...

## <capability 2>
...

## See also
- [related guide](@ref other-page)
- [API reference](@ref api-theme)
```

No page ends without a "See also". No page opens with a function signature.

### 9. Report template for sections 02–08

Each per-section report follows this shape:

```markdown
# <Section> — specification

**PR**: #N · **Depends on**: ... · **Status**: ...

## Objective
Which question the section answers, for which profile (§3).

## Pages
| id | title | path | source |
(source = `attic/<file>.md §<section>` or `new`)

## Page details
### <page id>
- **Purpose** — one sentence
- **Outline** — the `##` headings
- **API covered** — explicit symbol list (feeds 99-api-coverage.md)
- **Executed examples** — what must actually run
- **Source** — harvest from the attic, or new
- **API traps** — what the old page says that is now false

## Outgoing links
## Acceptance criteria
```

---

## Part III — Work order and acceptance

### 10. PR sequence

See the board in [`README.md`](README.md). Rationale for the order:

- **Infrastructure first (PR 2)**: nothing can be verified until `docs/Project.toml` resolves.
  This PR also archives the old pages and lands the full skeleton, so every later PR is
  "fill in pages", never "and also change the nav".
- **API reference early (PR 4)**: later guide PRs link into it. If it lands last, every guide
  accumulates broken `@ref`s that `warnonly=true` hides.
- **Modelling → Solve → Results → Flows → Geometry**: each reuses the previous one's examples.
  The flow pages inspect trajectories with the accessors documented in Results.
- **Examples after Flows and Geometry**: the singular-control example depends on both.
- **Getting started last (PR 11)**: it is a synthesis and a curated path through everything
  else. Writing it first means rewriting it.
- **PR 3 (deprecations) is independent** and can land at any point.

### 11. Verification, per PR

1. **Resolve** — `julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'`.
   This currently fails; PR 2 must make it pass.
2. **Draft build** — set `draft = true` in `docs/make.jl` and run
   `julia --project=docs docs/make.jl`. Fast; validates structure and links only.
3. **Full build of the touched section** — `draft = false`, and confirm the section's
   `@example` blocks execute.
4. **Read the log.** `makedocs` is called with `warnonly=true` (`docs/make.jl:215`), so a
   broken `@ref` or an unresolved `@extref` **does not fail the build**. Grep the log for
   `Error:`, `Warning:`, `cannot resolve` before declaring a PR green.
5. **VitePress** — `cd docs && npm install && npx vitepress build build/1`.
6. **Coverage** — tick the rows this PR closes in [`99-api-coverage.md`](99-api-coverage.md).

For PR 3 additionally: run the test suite via `ct-dev-mcp` (`get_test_command` → run with
`tee` → `generate_report`) and confirm `test/suite/reexport/` and `test/suite/flows/` pass
after the three assertions in `test/suite/reexport/test_ctlie.jl:81-84` are rewritten.

### 12. Global acceptance criteria

- [ ] `docs/Project.toml` resolves against the root `Project.toml`.
- [ ] `docs/make.jl` runs with `draft = false`, log clean of resolution errors.
- [ ] No user-facing page contains `Lie(`, ` ⋅ `, `HamiltonianLift`, `OptimalControl.VectorField`,
      `autonomous=`, `Flow(ocp, u, g,` — except the Migration page, in inert fences.
- [ ] Every capability in §6 has a page.
- [ ] [`99-api-coverage.md`](99-api-coverage.md) has no uncovered re-exported symbol.
- [ ] `docs/attic/` is gone.
- [ ] Every deprecated v2.0 spelling in the table of §8.2 either throws a `PreconditionError`
      naming its replacement, or is documented in the Migration page as unshimmable with the
      reason (`augment=`, the `is_`-prefixed keywords).

### 13. Known repository defects to fix along the way

Found during the exploration; each belongs to the PR that touches its area.

| Defect | Evidence | Fix in |
| --- | --- | --- |
| `methods()` docstring says 11 methods / "9 CPU"; real counts are 10 CPU + 2 GPU = 12, and `methods()[9]` is mislabelled | `src/helpers/methods.jl` | PR 6 |
| Module docstrings show `CTSolvers.Modelers.ADNLP()` / `CTDirect.Collocation()`, undefined under `using OptimalControl` | `src/OptimalControl.jl:33-36`, `src/solve/dispatch.jl:31-32`, `src/solve/canonical.jl:40-41` | PR 6 |
| `src/helpers/describe.jl` missing from the 14-file list, so `describe` appears in no generated API page although 4 guide pages document it | `docs/api_reference.jl` | PR 4 |
| `docs/src-literate/tutorial_pre.jl` is never referenced (the Literate loop is hardcoded to `["tutorial.jl"]`) | `docs/make.jl:189` | PR 2 |
| `CTDirect.DirectShooting` exists (`CTDirect.jl/src/direct_shooting.jl`, `id == :direct_shooting`) but is in neither `methods()` nor the registry — unreachable from OptimalControl | — | PR 6: wire it in, or document the limitation |
| `docs/inventories/` referenced 11 times but does not exist | `docs/make.jl:42-98` | PR 2 |
| `docs/src/assets/Manifest.toml` and the Literate outputs (`notebooks/`, `scripts/`) are committed build artifacts | — | PR 2: decide keep-or-gitignore |

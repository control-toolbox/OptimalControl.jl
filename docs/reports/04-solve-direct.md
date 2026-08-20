# Solve (direct) — specification

**PR**: 6 · **Depends on**: PR 5 · **Status**: specification
**Scope**: `docs/src/solve/*`, plus three docstring fixes in `src/`

## Objective

Make `solve` fully understood — not just "call it", but *what it chose for you and how to
choose differently*. The user's own framing: "résoudre avec les méthodes directes via la
méthode solve, donc bien comprendre les possibilités de cette méthode."

Primary profile: **Applied**.

## Pages

| id | title | path | source |
| --- | --- | --- | --- |
| `solve-overview` | Solve a problem | `solve/overview.md` | `attic/manual-solve.md` |
| `solve-initial-guess` | Set an initial guess | `solve/initial-guess.md` | `attic/manual-initial-guess.md` |
| `solve-choosing-a-method` | Choosing a method | `solve/choosing-a-method.md` | **new** — split out of `attic/manual-solve.md` |
| `solve-options` | Options and routing | `solve/options.md` | `attic/manual-solve-advanced.md` |
| `solve-explicit-mode` | Explicit mode | `solve/explicit-mode.md` | `attic/manual-solve-explicit.md` |
| `solve-gpu` | Solving on GPU | `solve/gpu.md` | `attic/manual-solve-gpu.md` |

**Why the split.** `attic/manual-solve.md` currently mixes "call `solve`", "available
methods", "choosing a method", "solver requirements" and "passing options to strategies" in
304 lines. Method selection is the single richest thing about this API — 12 combinations
across 4 families — and deserves its own page.

---

## The mental model the section must convey

Three layers, all spelled `solve`, all `CommonSolve.solve`:

| Layer | File | What it does |
| --- | --- | --- |
| Dispatch | `src/solve/dispatch.jl` | `solve(ocp, description::Symbol...; kwargs...)`; detects the mode, resolves the registry |
| Descriptive | `src/solve/descriptive.jl` | completes the symbol tuple, routes flat kwargs to families, builds the strategies |
| Explicit | `src/solve/explicit.jl` | takes typed components, completes what is missing |
| Canonical | `src/solve/canonical.jl` | `solve(ocp, guess, discretizer, modeler, solver; display)` — no defaults, no completion |

**The one thing every user must know**: the mode is detected **by argument type, not by
keyword name** (`src/solve/mode_detection.jl`, `src/helpers/kwarg_extraction.jl:_extract_kwarg`).
A kwarg whose *value* is an `AbstractDiscretizer`/`AbstractNLPModeler`/`AbstractNLPSolver`
switches you into explicit mode. Mixing typed components with symbol tokens throws
`IncorrectArgument`. This is surprising and belongs on `solve/overview.md`, not buried in the
advanced page.

---

## Page details

### `solve/overview.md`

- **Purpose** — call `solve`, read what it printed, know what it decided.
- **Outline**
  - `## Quick start` — `sol = solve(ocp)`
  - `## Reading the display` — the configuration table, and where each value came from
    (`:user` / `:default` / `:computed`)
  - `## Turning the display off` — `display=false`
  - `## The defaults` — `(:collocation, :adnlp, :ipopt, :cpu)`, and *why*: completion picks
    the first match top-to-bottom in `methods()`
  - `## Two ways to steer it` — descriptive (symbols) vs explicit (typed); **detection is by
    type**; mixing is an error. Links to both pages.
  - `## When it fails` — `successful(sol)`, `status(sol)`, `message(sol)`,
    `constraints_violation(sol)`
- **API covered** — `solve`, `display` kwarg, `successful`, `status`, `message`,
  `constraints_violation`, `iterations`.
- **Source** — `attic/manual-solve.md` §"Quick start", §"Display", §"Solver requirements".
- **API traps** — none in the prose; the code is current.

### `solve/initial-guess.md`

- **Purpose** — every way to hand `solve` a starting point.
- **Outline**
  - `## The default guess` — what you get if you say nothing
  - `## The `@init` macro` — `q(t) := sin(t)`, `x(T) := X`, `u := 0.1`, the `log = true`
    trailing argument
  - `## Constants, vectors, functions` — and how vectors are interpolated onto the grid
  - `## Mixing them`
  - `## Warm start from a solution` — pass a `Solution` directly
  - `## Costate and multipliers`
  - `## `init` or `initial_guess`` — aliases; passing both is an `IncorrectArgument`
- **API covered** — `@init`, `build_initial_guess`, the `init=` / `initial_guess=` kwargs.
- **Source** — `attic/manual-initial-guess.md` (627 lines). Drop the final "legacy NamedTuple
  construction" section, or move it to `migration.md`.
- **API traps**
  - `_INITIAL_GUESS_ALIASES` (`src/helpers/descriptive_routing.jl:81`) is what makes both
    spellings work; supplying both throws (`_extract_action_kwarg`).
  - Several CTModels init helpers exist but are **not** re-exported —
    `initial_guess`, `pre_initial_guess`, `validate_initial_guess`, `initial_state`,
    `initial_control`, `initial_variable`, `PreInitialGuess`. Do not document them as
    available. Flag as an open question whether they should be surfaced.

### `solve/choosing-a-method.md` — **new page**

- **Purpose** — the map of what can be combined with what, and how to ask for it.
- **Outline**
  - `## The four families` — discretizer, NLP modeler, NLP solver, parameter (device)
  - `## What is available` — `methods()`, printed live. **12 combinations**: 10 CPU
    (`{:adnlp, :exa} × {:ipopt, :madnlp, :uno, :madncl, :knitro}`) + 2 GPU
    (`:exa × {:madnlp, :madncl}`)
  - `## Partial descriptions` — `solve(ocp, :madnlp)` completes the rest; completion takes the
    first match top-to-bottom, which is why the default is `(:collocation, :adnlp, :ipopt, :cpu)`
  - `## Ambiguity` — what `AmbiguousDescription` looks like and how to resolve it
  - `## What each solver needs installed` — a table: `:ipopt` → `NLPModelsIpopt`, `:madnlp` →
    `MadNLP`, `:madncl` → `MadNCL`, `:knitro` → `NLPModelsKnitro` (+ licence), `:uno` →
    `UnoSolver`
  - `## Inspecting a strategy` — `describe(:adnlp)`, `describe(:ipopt)`, `describe(:collocation)`;
    note that `describe` also covers the **indirect** side (`:di`, `:sciml`) and the parameters
    (`:cpu`, `:gpu`)
  - `## Discretization schemes` — `scheme=` (alias `disc_method=`): `:trapeze`, `:midpoint`
    (default), `:euler` / `:euler_explicit` / `:euler_forward`, `:euler_implicit` /
    `:euler_backward`, `:gauss_legendre_2`, `:gauss_legendre_3`, `:variable`; plus `grid_size`
    (default 250) and an explicit non-uniform `time_grid`
- **API covered** — `methods`, `describe`, `id`, `metadata`, `option_names`, `option_type`,
  `option_default`, `option_defaults`, `option_description`, `has_option`, `strategy_ids`,
  `type_from_id`, `parameter`, `default_parameter`, `available_parameters`, `create_registry`.
- **Source** — `attic/manual-solve.md` §"Available methods", §"Choosing a method",
  §"Solver requirements"; discretizer options from `CTDirect.jl/src/collocation.jl`.
- **API traps / repo defects to fix in this PR**
  1. **`src/helpers/methods.jl`'s docstring is wrong**: it claims `length(m) == 11` and
     "CPU methods (9 total)", and says `methods()[9] == (:collocation, :exa, :madnlp, :gpu)`.
     The truth is 10 + 2 = 12, and `methods()[9]` is `(:collocation, :exa, :madncl, :cpu)`.
     Fix the docstring, then let the page print `methods()` live rather than quoting a number.
  2. **`CTDirect.DirectShooting` — out of scope, decided.** It exists
     (`CTDirect.jl/src/direct_shooting.jl`, `id == :direct_shooting`) but is not functional
     yet, which is why it is in neither `src/imports/ctdirect.jl` nor `methods()`/the
     registry. **Do not wire it in and do not mention it on the page.** The section
     documents `:collocation` as the only discretizer, without qualification.
  3. `describe` is missing from `docs/api_reference.jl`'s file list — fixed in PR 2, verify.

### `solve/options.md`

- **Purpose** — how a flat keyword finds its way to the right strategy, and the two escape
  hatches.
- **Outline**
  - `## Option routing` — flat kwargs are routed by name in **`:strict` mode**: an unknown
    option is an `IncorrectArgument`, not a silent no-op
  - `## Ambiguous options` — when two strategies declare the same name;
    `route_to(adnlp=:sparse, ipopt=:cpu)`
  - `## Undeclared solver options` — `bypass(v)` (alias `force(v)`) skips validation
  - `## Where a value came from` — `option_value`, `option_source`, `is_user`, `is_default`,
    `is_computed`
  - `## Action options vs strategy options` — `init`/`initial_guess` and `display` are handled
    before routing and win over a same-named strategy option unless you `route_to`
- **API covered** — `route_to`, `bypass`, `force`, `options`, `option_value`, `option_source`,
  `is_user`, `is_default`, `is_computed`, `has_option`.
- **Source** — `attic/manual-solve-advanced.md` (208 lines), accurate. Add the
  action-vs-strategy precedence rule, which is currently undocumented.
- **API traps** — `RoutedOption` and `BypassValue` are imported, not exported; do not name
  the types in examples, only the functions.

### `solve/explicit-mode.md`

- **Purpose** — hand `solve` typed components instead of symbols.
- **Outline**
  - `## When you want this` — programmatic construction, reusing a configured strategy
  - `## Basic usage`
  - `## Partial components` — give one, the rest is completed
  - `## Per-component options`
  - `## Mixing modes is forbidden`
  - `## Inspecting the components you built`
- **API covered** — `solve` with `discretizer=`/`modeler=`/`solver=`, `options`, `methods`,
  `bypass`, `is_user`, `is_default`, plus the constructors
  `OptimalControl.Collocation()`, `OptimalControl.ADNLP()`, `OptimalControl.Exa()`,
  `OptimalControl.Ipopt()`, `OptimalControl.MadNLP()`, `OptimalControl.MadNCL()`,
  `OptimalControl.Knitro()`, `OptimalControl.Uno()`.
- **Source** — `attic/manual-solve-explicit.md` (252 lines). It already uses the correct
  `OptimalControl.` spelling — it is the only page that does.
- **API traps / repo defect to fix in this PR**
  - **Three module docstrings show a spelling that does not work**:
    `src/OptimalControl.jl:33-36`, `src/solve/dispatch.jl:31-32`,
    `src/solve/canonical.jl:40-41` all write `CTSolvers.Modelers.ADNLP()` /
    `CTSolvers.Solvers.Ipopt()` / `CTDirect.Collocation()`. Neither `CTSolvers` nor `CTDirect`
    is re-exported, so those names are undefined under `using OptimalControl`. Fix all three
    to `OptimalControl.ADNLP()` etc.
  - The component types (`Collocation`, `ADNLP`, `Exa`, `Ipopt`, `MadNLP`, `MadNCL`,
    `Knitro`, `Uno`) are **imported, not exported** — the `OptimalControl.` prefix is
    mandatory, and this page must say why in one sentence.

### `solve/gpu.md`

- **Purpose** — run the same problem on a GPU.
- **Outline**
  - `## Prerequisites` — `ExaModels`, `MadNLPGPU`, `CUDA`
  - `## The problem must be coordinatewise` — link back to
    `@ref modelling-abstract-syntax` §dynamics
  - `## Descriptive mode` — the `:gpu` token
  - `## Explicit mode` — parameterised strategy types
  - `## What combinations work` — `:exa` × {`:madnlp`, `:madncl`} only
  - `## Performance notes`
- **API covered** — `solve` with `:gpu`, `CPU`, `GPU`, `available_parameters`,
  `default_parameter`, `parameter`, `describe(:gpu)`.
- **Source** — `attic/manual-solve-gpu.md` (175 lines), accurate.
- **API traps** — none known. Note that `:cpu`/`:gpu` mean the same thing on the flow side
  (`Flow(...; method=:gpu)`), tested by `test/suite/flows/test_gpu_routing.jl` — cross-link
  from `@ref flows-overview`.
- **Build caveat** — this page cannot execute in CI without a GPU. Guard it with
  ```` ```@meta\nDraft = true\n``` ```` or keep its blocks inert, and say so at the top.

---

## Outgoing links

| From | To |
| --- | --- |
| `overview.md` | `@ref solve-choosing-a-method`, `@ref solve-explicit-mode`, `@ref solve-initial-guess`, `@ref results-solution` |
| `initial-guess.md` | `@ref results-solution` (warm start), `@ref modelling-abstract-syntax` |
| `choosing-a-method.md` | `@ref solve-options`, `@ref solve-gpu`, API reference |
| `options.md` | `@ref solve-choosing-a-method`, `@ref solve-explicit-mode` |
| `explicit-mode.md` | `@ref solve-options`, `@ref solve-choosing-a-method` |
| `gpu.md` | `@ref modelling-abstract-syntax`, `@ref flows-overview` |

## Acceptance criteria

- [x] `methods()` is printed live on `choosing-a-method.md`, never quoted as a number.
- [x] `src/helpers/methods.jl`'s docstring reports 12 methods and the right `methods()[9]`.
      Verified live: `length(methods()) == 12`, `methods()[9] == (:collocation, :exa, :madncl,
      :cpu)`.
- [x] The three module docstrings no longer show `CTSolvers.Modelers.ADNLP()` /
      `CTDirect.Collocation()`. Fixed in `src/OptimalControl.jl`, `src/solve/dispatch.jl`,
      `src/solve/canonical.jl`; the corrected `OptimalControl.Collocation()` /
      `OptimalControl.ADNLP()` / `OptimalControl.Ipopt()` spelling verified to actually resolve.
- ~~[ ] `DirectShooting` is either reachable and documented, or explicitly listed as a known
      limitation.~~ Neither, deliberately: the per-page spec for `choosing-a-method.md`
      explicitly says "Do not wire it in and do not mention it on the page" (confirmed still
      unreachable — not in `src/imports/ctdirect.jl`, not in the registry). That instruction is
      more specific than this checkbox and takes precedence; the page presents `:collocation`
      as the only discretizer, unqualified, per the spec's own page-level direction.
- ~~[ ] Every symbol in the per-page "API covered" lists appears and executes.~~ True for every
      page except `choosing-a-method.md`'s `strategy_ids`/`type_from_id`/`available_parameters`:
      verified live that these require a populated `StrategyRegistry`, and the only one with the
      real built-in strategies is internal (`OptimalControl.get_strategy_registry()`, not
      re-exported) — calling them as the spec's outline implies (on a bare strategy type, or on
      an empty `create_registry()`) throws. Documented honestly in an "Advanced: the strategy
      registry" section instead of faking a working example; `describe`/`methods()` cover the
      same ground for actual users. All other pages' listed symbols do appear and execute,
      including three gaps caught and closed after the first full build (`has_option` on
      `options.md`, `methods()` on `explicit-mode.md`, `build_initial_guess` on
      `initial-guess.md`).
- [x] `gpu.md` is honest about not executing in CI. Kept `Draft = true` (the only page in this
      section that does), with a note at the top explaining why — confirmed live that even
      loading `CUDA`/`MadNLPGPU` in this dev environment isn't enough to construct
      `MadNLP{GPU}()` (a missing-extension error persists even after `using MadNLPGPU`,
      apparently needing real hardware to fully resolve).
- [x] Mode detection **by type** is stated on `overview.md`, not only in the advanced page —
      and demonstrated live there via the mixed-mode `IncorrectArgument`.

**Also found and fixed, beyond the checklist above:**
- A real inconsistency between descriptive and explicit mode when both `init=` and
  `initial_guess=` are supplied at once: explicit mode throws a clear "Conflicting aliases"
  error; descriptive mode (the common case) silently consumes `initial_guess` and lets the
  leftover `init` fall through to strategy-option routing, producing a confusing "unknown
  option `:init`" error instead. Verified live under the correct dev `LOAD_PATH` (a first pass
  of ad-hoc testing had accidentally exercised the *registered* OptimalControl package instead
  of this worktree's source — re-verified everything once the mistake was caught). Documented
  as-is on `initial-guess.md` rather than silently smoothed over; not fixed in `src/` since
  it's outside this PR's declared scope (only the two docstring fixes were).

# Migration and deprecations — specification

**PRs**: 3 (the shims, code) and 12 (the page, docs) · **Status**: specification
**Scope**: `src/deprecated.jl`, `test/suite/reexport/test_deprecated.jl`,
`test/suite/reexport/test_ctlie.jl`, `test/suite/flows/test_flow_api.jl`, `BREAKING.md`,
`docs/src/migration.md`

## Objective

Today a v2.0 script fails with `UndefVarError: Lie not defined` or a bare `MethodError`.
Nothing tells you what replaced it. Two deliverables:

1. **Part 1 (PR 3, code)** — a shim layer so every removed spelling throws a
   `CTBase.PreconditionError` naming its replacement.
2. **Part 2 (PR 12, docs)** — one page that is the old→new table, and the honest list of what
   could *not* be shimmed.

PR 3 is independent of every docs PR and can land at any point.

---

# Part 1 — `src/deprecated.jl` (PR 3)

## Design

One file, `src/deprecated.jl`, included from `src/OptimalControl.jl` **after** the
`imports/` block (the shims reference `AbstractVectorField`, `Model`, `AbstractSolution`,
`Flow` — all installed there) and before `helpers/`. Concretely, between the commented-out
`redefine.jl` line and the helpers block.

Every shim throws:

```julia
CTBase.PreconditionError(msg; reason, suggestion, context)
```

verified signature at `CTBase/src/Exceptions/types.jl:126-140` — positional `msg::String`,
keyword-only `reason` / `suggestion` / `context`, all `Union{String,Nothing}`.

**Why `PreconditionError` and not `IncorrectArgument`**: the arguments are individually fine;
it is the *spelling* the current API no longer accepts. That is a contract failure, which is
exactly what `PreconditionError` is for (`Handbook/philosophy/exceptions.md`).

**Piracy is deliberate and must be banner-commented.** These methods extend functions and
types owned by CTFlows, CTModels, Base and LinearAlgebra. OptimalControl sits at the top of
the stack and is the only place a *user-facing* migration message belongs. The precedent is
already in the repo: `src/helpers/describe.jl:51-55` pirates
`CTBase.Strategies.describe(::Symbol)` under a `# NOTE:` banner. Follow that style.

## Verdict table

| Target | Shim from OptimalControl? | Already upstream? | Decision |
| --- | --- | --- | --- |
| `Lie(X, f)` / `Lie(X, Y)` → `ad` | yes — free name, catch-all method, no piracy | no | **do it**, `export Lie` |
| `X ⋅ f` → `ad(X, f)` | yes — **only** as `import LinearAlgebra: ⋅` + methods on `dot` | no | **do it**, that form only |
| `HamiltonianLift` → `LiftedHamiltonianFunction` | yes — throwing *function* | no | **do it** |
| `success(sol)` → `successful(sol)` | yes — `Base.success(::AbstractSolution)` | no | **do it**, do **not** export |
| `time(ocp)` → `times(ocp)`; `time(sol)` → `time_grid(sol)` | yes — `Base.time(::Model)` / `(::AbstractSolution)` | no | **do it**, do **not** export |
| `Flow(f::Function)` | yes — piracy on `CTFlows.Flows.Flow` | no | **do it** |
| flow call `f(t0,x0,p0,tf,λ)` | yes — one method on the `AbstractHamiltonianFlow` alias | no | **do it** — best value/cost of the set |
| flow call `f(t0,x0,tf,λ)` (state flow) | yes — same pattern on `AbstractStateFlow` | no | **do it**, for symmetry |
| `Flow(ocp, u, g, μ)` | only as a 4-arity specialisation; the exact signature would **overwrite** upstream | **yes** — `PreconditionError` at `CTFlows/…/src/Flows/building.jl:1019` | **skip**; filed [CTFlows#401](https://github.com/control-toolbox/CTFlows.jl/issues/401) (its `suggestion` string is wrong for this case) |
| flow call `augment=true` | **no** — same positional signature as the still-valid call, so a shim would overwrite CTFlows' own `OptimalControlFlow` method; confirmed this breaks precompilation (`ERROR: Method overwriting is not permitted during Module precompilation`) | no | **skip**; filed [CTFlows#402](https://github.com/control-toolbox/CTFlows.jl/issues/402) |
| flow call `f(...; saveat=, abstol=, reltol=, alg=, ...)` (per-call integrator option override) | **no** — same reason as `Flow(ocp, u, g, μ)`: the call signature is closed (`variable`/`unsafe`/`variable_costate` only), so a shim would overwrite CTFlows' own call method | no — bare `MethodError`, not caught anywhere | **skip**; document in `BREAKING.md` (§"Flow call convention" point 4). Construction-time options (`Flow(ocp, u; abstol=...)`) are unaffected and still work. Not filed upstream: this looks like a deliberate CTFlows design choice (options are baked into the flow's type at construction), not a bug — unlike the two rows above. |
| `@Lie … autonomous=false` | n/a | **yes** — `IncorrectArgument` at `CTLie/src/lie_macro.jl:381` | **skip** |
| `autonomous=` / `variable=` / `inplace=` on the `Data` constructors | **no** — 14 entry points, and the workaround duplicates CTBase's trait detection | no | **skip**; optional CTBase issue |

## The three items that need care

### `⋅` — must re-export LinearAlgebra's binding, not define a new one

`⋅` is **not reachable today**: `src/imports/examodels.jl` does `using LinearAlgebra:
LinearAlgebra`, which binds only the module name, and `test/suite/reexport/test_ctlie.jl:82`
asserts `!is_exported(OptimalControl, :⋅)`. So `X ⋅ f` is currently an `UndefVarError`.

If OptimalControl defined a **new** generic `⋅` and exported it, a user writing
`using OptimalControl, LinearAlgebra` would get an export-conflict warning and every bare `⋅`
— including the idiomatic `p ⋅ f(x, u)` in their own Hamiltonians — would become an
`UndefVarError`. That is a worse regression than the one being fixed.

The correct form:

```julia
import LinearAlgebra: ⋅      # the same binding, not a new function
export ⋅
LinearAlgebra.dot(X::AbstractVectorField, f::Function) = throw(...)
```

Because `⋅ === dot` and OptimalControl's `⋅` is an import alias, both `using` statements
resolve to the same binding and Julia stays silent. This is also exactly the v2.0 topology
(old CTBase did `using LinearAlgebra`, added `⋅` methods, and exported the name).

Two costs to state in the file header: `using OptimalControl` re-introduces
`LinearAlgebra.dot` into user scope, and `dot(::AbstractVectorField, ::Function)` is a method
on a very hot generic. Ship the `AbstractVectorField` method; a `dot(::Function, ::Function)`
overload is optional and higher-risk.

### `HamiltonianLift` — a function, not a type

`HamiltonianLift` was a *type* in v2.0, so `H isa HamiltonianLift` was legal. A throwing
**function** makes that a `TypeError` — ugly but loud. An `abstract type` stand-in with a
throwing constructor would make the same test return `false` **silently**, which is precisely
the failure mode `BREAKING.md` warns about for `H isa AbstractHamiltonian`. Choose the loud
one.

### The 5-positional flow call — one method covers everything

`AbstractHamiltonianFlow` is a type alias over the third parameter
(`AbstractFlow{TD,VD,HamiltonianDynamics}`), so a single method catches `OptimalControlFlow`,
`HamiltonianFlow` and `MultiPhaseHamiltonianFlow`:

```julia
function (f::CTFlows.Flows.AbstractHamiltonianFlow)(
    t0::Real, x0, p0, tf::Real, variable
)
```

No 5-positional method exists anywhere upstream, so this **adds** a method rather than
overwriting one. The optional state-flow twin on `AbstractStateFlow` is disjoint
(`StateDynamics` vs `HamiltonianDynamics`) — no ambiguity.

**One hazard that cannot be fixed here**: on an `OptimalControlFlow`, the old state-call
`f(t0, x0, tf, λ)` with a real `λ` silently matches the 4-positional Hamiltonian method and
misreads the arguments. Note it on the migration page; it belongs upstream.

## Tests

**New file**: `test/suite/reexport/test_deprecated.jl`, defining `test_deprecated()`.
Discovery is automatic (`test/runtests.jl` scans `suite/*/test_*` and builds
`Symbol(:test_, name)`); nothing to register.

The two **flow-shaped** shims go in `test/suite/flows/test_flow_api.jl` instead — it already
loads the integrator and has the OCP fixtures.

Assertion style, matching the neighbours
(`test/suite/flows/test_flow_api.jl:255,269`, `test/suite/reexport/test_ctflows.jl:153`):

```julia
Test.@test_throws OptimalControl.PreconditionError Lie(X, Y)
```

and, because the message *is* the feature, assert it:

```julia
err = try Lie(X, Y) catch e; e end
Test.@test err isa OptimalControl.PreconditionError
Test.@test occursin("deprecated", err.msg)
Test.@test occursin("ad(X, f)", err.suggestion)
```

### Existing assertions that become false — must be rewritten in the same PR

| Location | Current | Why it breaks |
| --- | --- | --- |
| `test/suite/reexport/test_ctlie.jl:81` | `@test !is_exported(OptimalControl, :Lie)` | we now export `Lie` |
| `test/suite/reexport/test_ctlie.jl:82` | `@test !is_exported(OptimalControl, :⋅)` | we now export `⋅` |
| `test/suite/reexport/test_ctlie.jl:84` | `@test !isdefined(OptimalControl, :HamiltonianLift)` | we now define it |

Replace that "Removed API" testset with "Removed API is now shimmed", asserting the new
contract. For `⋅`, add the binding-identity check — it is what prevents the export conflict:

```julia
Test.@test getfield(OptimalControl, :⋅) === LinearAlgebra.dot
```

### Assertions that keep passing (verified, no change needed)

- `test_ctmodels.jl:224-228` — `!is_exported(:success)` ✓ (never exported);
  `getfield(OptimalControl, :success) === Base.success` ✓ (writing `Base.success(...)`
  qualified creates no OptimalControl binding); the `parentmodule` check ✓ (our method's
  parent is `OptimalControl`, not `CTModels.Solutions`).
- `test_ctmodels.jl:249-256` — same reasoning for `time`.
- `test_ctflows.jl:43` — `Flow isa UnionAll` ✓.
- `test_flow_api.jl:133,134,153,170` — 3- and 4-positional `MethodError` expectations;
  our shims are 5-positional. Disjoint ✓.

## Also in PR 3

- **`BREAKING.md`**: both removal tables currently say the names are simply gone. Add that
  they now fail with a `PreconditionError` naming the replacement — the migration document is
  where that contract belongs.
- **Two upstream issues**, filed not fixed:
  - CTFlows: the `PreconditionError` at `src/Flows/building.jl:1019` has a `suggestion` that
    is wrong for the `Flow(ocp, u, g, μ)` case — it says the OCP flow takes no positional
    argument beyond the model (false: `Flow(ocp, law)` is supported) and never mentions
    `constraint=`/`multiplier=`.
  - CTFlows: add `augment=nothing` to the three call methods and throw when it is non-`nothing`.
- **No `docs/` change.** `docs/make.jl` has `warnonly=true` and the DocumenterReference
  extension scans `src/`, so `deprecated.jl` gets an Internals page for free.

## Acceptance criteria (PR 3)

- [x] `src/deprecated.jl` exists, is included after `imports/`, and has the piracy banner
      plus the "not shimmed, and why" list.
- [x] `Lie`, `⋅`, `HamiltonianLift` are exported; `success`, `time`, `Flow` are not
      re-exported by this file.
- [x] `using OptimalControl, LinearAlgebra` produces **no** export-conflict warning.
- [x] Every shim's message names its replacement, verified by an `occursin` assertion.
- [x] The three `test_ctlie.jl` assertions are rewritten; the full suite is green via
      `ct-dev-mcp` (`get_test_command` → run + `tee` → `generate_report`).
- [x] `BREAKING.md` records the new contract.
- [x] The two CTFlows issues are filed and linked from `BREAKING.md`.

---

# Part 2 — `docs/src/migration.md` (PR 12)

- **Purpose** — one page a v2.0 user can read top to bottom and fix their script.
- **Outline**
  - `## Start here: `Flow` needs an integrator` — the single most common first failure
  - `## What was renamed` — the old→new table, matching
    [`00-cahier-des-charges.md`](00-cahier-des-charges.md) §8.2
  - `## What changed shape` — the `Flow` call convention, constrained flows,
    `augment=` → `variable_costate=`, the `is_` keyword prefix
  - `## What changed meaning silently` — the three that will **not** announce themselves:
    - `Lift(f)` on a plain `Function` no longer returns an `AbstractHamiltonian`
    - `OpenLoop` is unconditionally non-autonomous — `u(t)`, never `u()`
    - on an `OptimalControlFlow`, `f(t0, x0, tf, λ)` matches the Hamiltonian method and
      misreads its arguments
  - `## What you get instead of an error` — the shim table: which spellings now throw a
    `PreconditionError`
  - `## What could not be shimmed, and why` — `augment=`, the `is_`-prefixed constructor
    keywords; Julia cannot dispatch on a keyword name. What the raw `MethodError` looks like
    (it does name the offending keyword)
  - `## Legacy initial guesses` — the NamedTuple form dropped from
    `attic/manual-initial-guess.md`
  - `## v1.x → v2.0` — a pointer to `BREAKING.md`, not a copy
- **Code blocks are inert.** This is the one page in the site that deliberately shows
  spellings that error; it must not execute. Say so at the top.
- **Source** — `BREAKING.md` is the authority; this page is its user-facing rendering, not a
  duplicate. Keep them in sync by making the page link into `BREAKING.md` for the detail.

## Acceptance criteria (PR 12)

- [ ] The page covers every row of §8.2 and every row of the verdict table above.
- [ ] The three silent-semantics changes each have a `!!! warning`.
- [ ] The page is explicitly non-executing and says why.
- [ ] `geometry/overview.md`, `geometry/ad.md`, `geometry/lift.md`, `results/solution.md`
      and `flows/simulation.md` all link here.

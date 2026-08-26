# [Migrating to v2.1](@id migration)

```@meta
Draft = false
```

!!! note "This page does not execute"

    Unlike every other page on this site, the code blocks here deliberately show **spellings
    that error** — that is the whole point. They are plain ```` ```julia ```` fences, not
    `@example` blocks, and are not run when the docs build. Every error message quoted below
    was verified by running it against the current package; treat the page as accurate
    reference, not as tested output.

`OptimalControl.jl` v2.1.0-beta reorganised the ecosystem so that every name has exactly one
owner. Most of the fallout is mechanical — a `Lie` becomes an `ad`, a `success` becomes a
`successful` — and every mechanical rename now fails loudly with a message naming its
replacement, instead of a bare `UndefVarError`. A few changes are semantic and will **not**
announce themselves; those get their own warnings below.

The full technical record of every breaking change is [`BREAKING.md`](https://github.com/control-toolbox/OptimalControl.jl/blob/main/BREAKING.md)
in the repository root — this page is its user-facing rendering, organised around "what do I
do about it" rather than "what changed and why." Read `BREAKING.md` for the reasoning; read
this page to fix a script.

## Start here: `Flow` needs an integrator

This is the single most common first failure. SciML is no longer a hard dependency of the
stack — the user chooses and loads an ODE integrator explicitly:

```julia
using OptimalControl
using OrdinaryDiffEqTsit5   # ← new, and required before any Flow(...)

f = Flow(ocp, (x, p) -> p[2])
```

Without it, `Flow` fails with a clean `ExtensionError` naming `OrdinaryDiffEqTsit5` (or
`OrdinaryDiffEq`/`DifferentialEquations`) as the missing package — not a cryptic dispatch
error. This is by design: it keeps the install cost of the direct (`solve`) path off users who
never write a flow. See [Installation](@ref getting-started-installation) and
[Flows overview](@ref flows-overview).

## What was renamed

| v2.0 | v2.1.0-beta | Notes |
| --- | --- | --- |
| `OptimalControl.VectorField`, `OptimalControl.Hamiltonian`, … | `VectorField`, `Hamiltonian`, … | exported at top level since v2.1.0-beta; the qualified form still works, it's just no longer necessary |
| `Lie(X, f)` | `ad(X, f)` | renamed; `Lie(...)` now throws |
| `X ⋅ f` | `ad(X, f)` | removed, no operator alias; `X ⋅ f` now throws |
| `HamiltonianLift` | `Lift(f)` to build; `OptimalControl.LiftedHamiltonianFunction` to name the type | renamed **and** re-parented — see [What changed meaning silently](@ref migration-silent) |
| `autonomous=`, `variable=`, `inplace=` (constructor keywords) | `is_autonomous=`, `is_variable=`, `is_inplace=` | prefixed, on `VectorField`, `Hamiltonian`, `@Lie`, and friends |
| `Flow(f)` with `f::Function` | `Flow(VectorField(f))`, `Flow(Hamiltonian(f))`, `Flow(HamiltonianVectorField(f))` | the bare function no longer says what kind of flow to build |
| `Flow(ocp, u, g, μ)` (3 positional) | `Flow(ocp, u; constraint=g, multiplier=μ)` | keywords, and they come as a pair |
| `f(t0, x0, p0, tf, λ)` / `f(t0, x0, tf, λ)` | `f(t0, x0, p0, tf; variable=λ)` / `f(t0, x0, tf; variable=λ)` | `variable=` is a mandatory keyword on a `NonFixed` problem, never positional |
| `augment=true` | `variable_costate=true` | renamed; returns `(xf, pf, pvf)` instead of `(xf, pf)` |
| `CTSolvers.Modelers.ADNLP()`, `CTDirect.Collocation()` | `OptimalControl.ADNLP()`, `OptimalControl.Collocation()` | neither module name is re-exported; write against `OptimalControl` |
| `time(ocp)`, `time(sol)` | `times(ocp)`, `time_grid(sol)` | `time` is no longer re-exported (it's `Base.time`) |
| `success(sol)` | `successful(sol)` | `success` is no longer re-exported (it's `Base.success`) |

## What changed shape

Three call conventions changed signature, not just spelling.

**The flow call.** There is no positional slot for the variable any more:

```julia
# before
f(t0, x0, p0, tf, λ)
f(t0, x0, p0, tf; augment=true)

# after
f(t0, x0, p0, tf; variable=λ)
f(t0, x0, p0, tf; variable=λ, variable_costate=true)
```

`variable=` is mandatory on a `NonFixed` problem — omitting it does not silently default, it
throws naming exactly what to pass. New in v2.1.0-beta: `unsafe=false` — with `unsafe=true` the
ODE return code is not checked and integration failures don't throw, useful inside a shooting
loop where an intermediate failure should surface through the residual instead. Also new:
per-call integrator options (`saveat=`, `abstol=`, `reltol=`, `alg=`, …) no longer exist — the
call signature only accepts `variable`, `unsafe`, `variable_costate`. Pass integrator options
at **construction** time instead, where they still work exactly as before:

```julia
# after — set once, at construction, not per call
f = Flow(ocp, (x, p) -> p[2]; abstol=1e-8)
f(t0, x0, p0, tf)
```

**Constrained flows.** Positional arguments became a keyword pair:

```julia
# before
fb = Flow(ocp, u, g, μ)                            # 3 positional

# after
fb = Flow(ocp, u; constraint=g, multiplier=μ)      # paired keywords
```

The two keywords are a pair: one without the other is an `IncorrectArgument`. `constraint=`
gained a capability along the way — besides a plain `Function` or a `Data.PathConstraint`, it
now also accepts a `Symbol` naming a `:path` constraint already declared in the OCP:
`constraint=:vmax`.

**Constructor keywords take an `is_` prefix**, on `VectorField`, `Hamiltonian`, `@Lie`, and
every sibling `Data` constructor:

```julia
# before
VectorField(f; autonomous=false, variable=true)
@Lie [X, Y] autonomous=false

# after
VectorField(f; is_autonomous=false, is_variable=true)
@Lie [X, Y] is_autonomous=false
```

The old spelling on `@Lie` raises an `IncorrectArgument` at macro-expansion time — loud, not
silently ignored. On the plain `Data` constructors it is not shimmed (see below): Julia cannot
dispatch on a keyword *name*, and a workaround would need to duplicate CTBase's own trait
detection across 14 entry points.

## [What changed meaning silently](@id migration-silent)

Three changes will not announce themselves as an error. Each is confirmed by running it against
the current package.

!!! warning "`Lift(f::Function)` is no longer an `AbstractHamiltonian`"

    In v2.0, lifting a plain function and lifting a typed `VectorField` produced the same kind
    of object. In v2.1.0-beta only the typed path does:

    ```julia
    H = Lift(f)          # f::Function
    H isa AbstractHamiltonian   # false in v2.1.0-beta, true in v2.0
    ```

    `H` is now an `OptimalControl.LiftedHamiltonianFunction`, `<: Function` only. Any `isa` or
    `<:` test against the old hierarchy is quietly wrong. `Lift(X::AbstractVectorField)` is
    unaffected — only the bare-function overload changed. See [Lift](@ref geometry-lift).

!!! warning "`OpenLoop` rejects the wrong arity only when the flow runs, not when it's built"

    An open-loop control must be a function of time, `u(t)` (or `u(t, v)`). A bare constant
    closure **constructs without error** and only fails once the flow actually runs:

    ```julia
    bad_law = OpenLoop(() -> 1.0)          # constructs fine — the trap
    Flow(ControlledVectorField(fc), bad_law)(t0, x0, tf)   # MethodError here, not above
    ```

    The `MethodError` points at the call site, far from the actual mistake at construction.
    `is_autonomous` is not a real choice for `OpenLoop` either way — passing it emits a `@warn`
    that it has no effect, rather than silently doing nothing. See
    [Simulation](@ref flows-simulation).

!!! warning "The old 4-positional state-flow call silently misreads on an `OptimalControlFlow`"

    v2.0's state-flow convention was `f(t0, x0, tf, λ)` — 4 positional arguments. v2.1.0-beta's
    genuine (non-deprecated) call for a `Fixed`-time `OptimalControlFlow` is also 4 positional:
    `f(t0, x0, p0, tf)`. If a v2.0 script calls the old convention against an
    `OptimalControlFlow` with a real number in the 4th slot, it **matches** the new signature
    instead of erroring — `tf` silently becomes `p0` and `λ` silently becomes `tf`:

    ```julia
    f(t0, x0, tf, λ)   # intended: state flow, tf and lambda as before
    # actually runs as f(t0, x0, p0=tf, tf=λ)  — arguments shifted by one position
    ```

    It throws only when the 4th argument's type doesn't match `p0`'s expected shape — so
    whether this is caught depends entirely on what happens to be in that slot. There is no
    shim for this: the deprecated 4-positional signature is disjoint on `AbstractStateFlow` (a
    plain vector-field flow, unaffected) but genuinely ambiguous on `AbstractHamiltonianFlow`,
    where it collides with the real v2.1.0-beta call. This one is on the caller to catch by eye.

## What you get instead of an error

Every removed spelling below throws `CTBase.Exceptions.PreconditionError` naming its
replacement — confirmed by running each one against the current package:

```julia
julia> Lie(X, f)
ERROR: PreconditionError: `Lie(X, f) / Lie(X, Y)` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use ad(X, f) or ad(X, Y)

julia> X ⋅ f
ERROR: PreconditionError: `X \cdot f` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use ad(X, f)

julia> HamiltonianLift(f)
ERROR: PreconditionError: `HamiltonianLift` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use Lift(f) for a plain function, or CTLie.LiftedHamiltonianFunction

julia> time(ocp)
ERROR: PreconditionError: `time(ocp)` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use times(ocp)

julia> time(sol)
ERROR: PreconditionError: `time(sol)` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use time_grid(sol)

julia> success(sol)
ERROR: PreconditionError: `success(sol)` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use successful(sol)

julia> Flow(f)   # f::Function
ERROR: PreconditionError: `Flow(f::Function)` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use Flow(VectorField(f)), Flow(Hamiltonian(f)), or Flow(HamiltonianVectorField(f))

julia> f(t0, x0, p0, tf, λ)   # 5-positional, on a Hamiltonian flow
ERROR: PreconditionError: `f(t0, x0, p0, tf, lambda)` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use f(t0, x0, p0, tf; variable=lambda)

julia> f(t0, x0, tf, λ)   # 4-positional, on a plain state flow (AbstractStateFlow)
ERROR: PreconditionError: `f(t0, x0, tf, lambda)` is deprecated
Reason  this spelling was removed in v2.1.0-beta
Hint    use f(t0, x0, tf; variable=lambda)
```

The last row is the disjoint, safe half of the previous section's warning: on a plain
`AbstractStateFlow` (not an `OptimalControlFlow`), the 4-positional call is unambiguous and
shimmed cleanly. The hazard is specific to `OptimalControlFlow`/`AbstractHamiltonianFlow`.

## What could not be shimmed, and why

Julia dispatches on argument types and arity, not on keyword names or "this call used to mean
something else" — a few removed spellings can't be intercepted without either overwriting a
method CTFlows still needs, or duplicating trait-detection logic that belongs upstream.

| Spelling | What actually happens today | Why it isn't shimmed |
| --- | --- | --- |
| `Flow(ocp, u, g, μ)` (3 positional) | Upstream `PreconditionError` (not from `OptimalControl`) — but its `suggestion` text is currently wrong for this case | A 4-arity shim here would overwrite CTFlows' own method for this exact signature. Filed as [CTFlows#401](https://github.com/control-toolbox/CTFlows.jl/issues/401). |
| `augment=true` | Bare `MethodError`, not caught anywhere | Same positional signature as the still-valid call — a shim would overwrite CTFlows' own `OptimalControlFlow` method and breaks precompilation (`Method overwriting is not permitted`). Filed as [CTFlows#402](https://github.com/control-toolbox/CTFlows.jl/issues/402). |
| Per-call integrator options (`saveat=`, `abstol=`, `reltol=`, `alg=`, …) | Bare `MethodError` | Same reason: the call signature is closed to `variable`/`unsafe`/`variable_costate` only; a shim would overwrite CTFlows' own call method. Unlike the two rows above, this looks like a deliberate design choice (options belong at construction, baked into the flow's type), not a bug — not filed upstream. Construction-time options are unaffected. |
| `@Lie [X, Y] autonomous=false` | `IncorrectArgument`, raised at macro-expansion time | Already thrown upstream in CTLie — nothing to add. |
| `autonomous=`/`variable=`/`inplace=` on `VectorField`, `Hamiltonian`, and other `Data` constructors | Silently ignored or `MethodError`, depending on the constructor | Julia cannot dispatch on a keyword's *name*; a shim would mean re-detecting the trait by hand at all 14 entry points, duplicating logic CTBase already owns. |

## Legacy initial guesses

The `@init` macro ([Initial guess](@ref solve-initial-guess)) is the documented way to build an
initial guess in v2.1.0-beta. The older direct `NamedTuple` construction still works —
it was never removed — it's just no longer shown anywhere in the current docs, so there is no
way to discover it still works without this page:

```julia
# still works, not the documented path
sol = solve(ocp; init=(state=[-0.2, 0.1], control=-0.2))

# component labels work too
sol = solve(ocp; init=(q=-1.0, v=0.0, u=0.1, tf=2.0))
```

Prefer `@init` for new code — it validates labels against the problem and reads closer to the
mathematics. There is still no way to provide an initial guess for the costate/multipliers
directly; that remains true in both forms.

## v1.x → v2.0

For the older v1.x → v2.0 migration (the direct-mode API rewrite, option routing, the methods
system), see the second section of [`BREAKING.md`](https://github.com/control-toolbox/OptimalControl.jl/blob/main/BREAKING.md#breaking-changes-v1x--v20)
directly — it predates this page and isn't duplicated here.

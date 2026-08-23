# Breaking Changes: v2.0 → v2.1.0-beta

This section describes the breaking changes when migrating from **OptimalControl.jl v2.0.5-beta** to **v2.1.0-beta**. For the v1.x → v2.0 migration, see [the section below](#breaking-changes-v1x--v20).

Three symbol families physically changed package in this release, as the ecosystem was reorganised so that each name has exactly one owner. Most of the fallout is mechanical, but three items are semantic and will not announce themselves as import errors.

## Start here: `Flow` needs an integrator

Every example's preamble changes. SciML is no longer a hard dependency of the stack — the user chooses and loads an integrator:

```julia
using OptimalControl
using OrdinaryDiffEqTsit5   # ← new, and required before any Flow(...)

f = Flow(ocp, (x, p) -> p[2])
```

Without it, `Flow` fails with a clean `ExtensionError` naming `OrdinaryDiffEqTsit5` (or `OrdinaryDiffEq`/`DifferentialEquations`) as the missing package. This is by design: it keeps the install cost of the direct path off users who never write a flow.

## Differential geometry moved to CTLie

`Lift`, `Poisson`, `∂ₜ` and `@Lie` are re-exported from the same names as before, so most code is unaffected. Two changes are not cosmetic:

| v2.0 | v2.1.0-beta | Notes |
| --- | --- | --- |
| `Lie(X, f)` | `ad(X, f)` | renamed; `Lie(...)` now throws `PreconditionError` |
| `X ⋅ f` | `ad(X, f)` | removed; `X ⋅ f` now throws `PreconditionError` |
| `HamiltonianLift` | `CTLie.LiftedHamiltonianFunction` | renamed; `HamiltonianLift(...)` now throws `PreconditionError` |

`LiftedHamiltonianFunction` is `<: Function`, no longer `<: AbstractHamiltonian`. Any `isa` or `<:` test against the old hierarchy is now wrong:

```julia
H = Lift(F)          # F::Function
H isa AbstractHamiltonian   # false in v2.1.0-beta, true in v2.0
```

Note that `Lift` is overloaded on its input: `Lift(X::AbstractVectorField)` still returns a `Hamiltonian`. Only the plain-`Function` overload changed.

## Flow call convention

The signature changed, not just the spelling.

```julia
# before
f(t0, x0, p0, tf, λ)
f(t0, x0, p0, tf; augment=true)

# after
f(t0, x0, p0, tf; variable=λ)
f(t0, x0, p0, tf; variable=λ, variable_costate=true)
```

1. **There is no positional slot for the variable any more**, and `variable=` is **mandatory** on a `NonFixed` problem. The old positional spellings `f(t0, x0, p0, tf, λ)` and `f(t0, x0, tf, λ)` raise a `PreconditionError` suggesting `variable=λ`; omitting it raises a `PreconditionError` whose suggestion is literally *"Pass `variable=v` when calling the flow"* — it does not silently default.
2. **`augment=true` → `variable_costate=true`.** It integrates the augmented adjoint `ṗᵥ = -∂H/∂v` and returns `(xf, pf, pvf)` instead of `(xf, pf)`. The old spelling is not shimmed — it fails with a bare `MethodError` today, not a `PreconditionError` — because a shim here would mean overwriting CTFlows' own method; filed as [CTFlows#402](https://github.com/control-toolbox/CTFlows.jl/issues/402) instead.
3. **New `unsafe=false`.** With `unsafe=true` the ODE retcode is not checked and failures do not throw — useful inside a shooting loop, where an intermediate failure should surface through the residual.
4. **Integrator options can no longer be overridden per call.** In v2.0, keywords like `saveat=`, `abstol=`, `reltol=`, `alg=` were forwarded straight through to OrdinaryDiffEq.jl at *call* time:

   ```julia
   # before — worked at call time
   f(t0, x0, p0, tf; abstol=1e-8)
   f((t0, tf), x0, p0; saveat=range(t0, tf, 100))
   ```

   The call signature now only accepts `variable`, `unsafe` and `variable_costate`; anything else is a bare `MethodError`, not a `PreconditionError` — this spelling is **not shimmed** (it would mean overwriting CTFlows' own call method, the same reason `Flow(ocp, u, g, μ)` above and `augment=` are not shimmed either). Pass integrator options at **construction** time instead, where they still work exactly as before:

   ```julia
   # after — set once, at construction
   f = Flow(ocp, (x, p) -> p[2]; abstol=1e-8)
   f(t0, x0, p0, tf)
   ```

## Constrained flows: keywords replace positional arguments

```julia
# before
fb = Flow(ocp, u, g, μ)                            # 3 positional

# after
fb = Flow(ocp, u; constraint=g, multiplier=μ)      # paired keywords
```

The old positional form already raises a `PreconditionError` today, but with a misleading suggestion — fix filed as [CTFlows#401](https://github.com/control-toolbox/CTFlows.jl/issues/401).

The two are a pair: one without the other is an `IncorrectArgument`.

`constraint` now accepts three spellings, which is a capability gain rather than a rename — a plain `Function`, a `Data.PathConstraint`, **or a `Symbol` naming a `:path` constraint already declared in the OCP**:

```julia
fb = Flow(ocp, u; constraint=:vmax, multiplier=μ)  # reuse the model's own constraint
```

## Constructor keywords take an `is_` prefix

```julia
# before
VectorField(f; autonomous=false, variable=true)
@Lie [X, Y] autonomous=false

# after
VectorField(f; is_autonomous=false, is_variable=true)
@Lie [X, Y] is_autonomous=false
```

The old spelling on `@Lie` raises an `IncorrectArgument` at macro-expansion time rather than being ignored.

## Two names are no longer re-exported

| Name | Why |
| --- | --- |
| `time` | It is `Base.time`. `time(ocp)` and `time(sol)` now throw `PreconditionError`; use `times(ocp)` or `time_grid(sol)`. |
| `success` | `Base.success` is the name. `success(sol)` now throws `PreconditionError`; use `successful(sol)`. |

## Newly re-exported

The full `CTBase.Data` type vocabulary is now available without reaching into the package by hand — `Flow` dispatches on these, so building a flow explicitly needed them:

`VectorField`, `Hamiltonian`, `HamiltonianVectorField`, `ComposedHamiltonian`, `PseudoHamiltonian`, `ControlLaw`, `OpenLoop`, `ClosedLoop`, `DynClosedLoop`, `PathConstraint`, `StateConstraint`, `ControlConstraint`, `MixedConstraint`, `Multiplier`, and their abstract supertypes.

⚠️ `OpenLoop`, `ClosedLoop`, `DynClosedLoop` and the constraint kinds are **factory functions, not types**. They all build a `ControlLaw{F,Kind,…}` / `PathConstraint{F,Kind,…}`; the kind is a trait parameter, so `OpenLoop <: AbstractControlLaw` is a `TypeError`. Dispatch on the trait.

Also new: `CTLie.dg_ad_backend` / `dg_ad_backend!` (global AD-backend control), `CTFlows.MultiPhase` (`n_phases`, `get_flow`, `get_switching_time`, …), and `CTSolvers.Integrators` (`SciML`, `final_state`, `evaluate_at`).

## `OpenLoop` is unconditionally non-autonomous

An open-loop control depends only on time — `u(t)` (or `u(t, v)`) — never on the state or costate, and autonomy is a property of the OCP, not of the control law itself. `OpenLoop` therefore does not offer `is_autonomous` as a real choice, unlike `ClosedLoop`/`DynClosedLoop`:

```julia
OpenLoop(t -> 1.0)              # the only spelling — always u(t), or u(t, v) with is_variable=true
OpenLoop(() -> 1.0)             # wrong: constructs silently, MethodError once the flow is run
```

`is_autonomous` is kept as a misuse-detector keyword only: passing it (`true` or `false`) emits a `@warn` explaining that it has no effect, rather than silently doing nothing or being treated as a real choice. `ClosedLoop` and `DynClosedLoop` are unaffected — `is_autonomous` still governs their arity exactly as before.

See [control-toolbox/CTBase.jl#515](https://github.com/control-toolbox/CTBase.jl/issues/515).

## For package authors: the strategy contract

If you define your own `AbstractStrategy`, you must now implement `parameter`:

```julia
CTBase.Strategies.parameter(::Type{<:MyStrategy}) = nothing               # non-parameterized
CTBase.Strategies.parameter(::Type{MyStrategy{P}}) where {P} = P          # parameterized
```

This is **not** a rename of `CTSolvers.Strategies.get_parameter_type`, which returned `nothing` by default. The CTBase generic throws `NotImplemented` instead, and option routing calls it — so a strategy that omits it fails at `solve` time rather than being treated as non-parameterized.

A caller that cannot guarantee a third-party strategy implements the contract should reach for the non-throwing `CTBase.Strategies.parameter(strategy_type, default)` — the `get(dict, key, default)`-style 2-arg accessor (CTBase ≥ 0.28.8-beta) — rather than writing its own `try`/`catch` around `NotImplemented`. OptimalControl's own display code does exactly this, and warns once per strategy type when the fallback is taken.

## `describe` now covers every strategy

`describe(:id)` previously only knew the *solve* registry (discretizer, NLP modeler, NLP solver). The AD backend and the ODE integrator are strategies in the same sense — `describe(:di)` and `describe(:sciml)` now work from the same single entry point, which merges the solve registry with CTFlows' flow registry (`Base.merge(::CTBase.Strategies.StrategyRegistry...)`, CTBase ≥ 0.28.8-beta).

---

# Breaking Changes: v1.x → v2.0

This document describes the breaking changes when migrating from **OptimalControl.jl v1.1.6** (last stable release) to **v2.0.0**.

!!! note "v2.0.5-beta Compatibility"
    **v2.0.5-beta** is fully backward compatible with v2.0.4. It adds a Paderborn tutorial with Literate + Binder setup, narrows CTBase to `=0.18.8` and CTModels to `=0.10.1` for stricter version pinning, and includes README updates and code formatting, with no breaking changes.

!!! note "v2.0.4 Compatibility"
    **v2.0.4** is fully backward compatible with v2.0.3. It contains documentation improvements (scalar/vector convention warning, :exa modeler incompatibility note) and build system changes (logger filter) with no breaking changes.

!!! note "v2.0.3 Compatibility"
    **v2.0.3** is fully backward compatible with v2.0.2. It adds the functional API (macro-free) for defining optimal control problems programmatically and updates CTModels to v0.10, with no breaking changes to existing code.

!!! note "v2.0.2 Compatibility"
    **v2.0.2** is fully backward compatible with v2.0.1. It contains a dependency update (UnoSolver v0.2 → v0.3) with no breaking changes.

!!! note "v2.0.1 Compatibility"
    **v2.0.1** is fully backward compatible with v2.0.0. It contains documentation improvements and an export change (`build_initial_guess` is now explicitly reexported) with no breaking changes.

## Overview

Version 2.0.0 represents a major architectural redesign of OptimalControl.jl, introducing:

- **Complete solve architecture redesign** with descriptive and explicit modes
- **GPU/CPU parameter system** for heterogeneous computing
- **Advanced option routing** with introspection and disambiguation tools
- **New solver integrations** (Uno, MadNCL)
- **Control-free problems** support with augmented Hamiltonian approach
- **CTFlows enhancements** with `augment=true` and direct OCP flow creation
- **Modernized reexport system** using `@reexport import`

## Removed Functions

The following functions from v1.1.6 have been removed and replaced:

### CTDirect Functions

| v1.1.6 Function        | v2.0.0 Replacement | Notes                                                  |
| ---------------------- | ------------------ | ------------------------------------------------------ |
| `direct_transcription` | `discretize`       | New function from CTDirect.jl                          |
| `set_initial_guess`    | `@init` macro      | Use the `@init` macro for initial guess construction   |
| `build_OCP_solution`   | `ocp_solution`     | New function from CTSolvers.jl                         |

**Migration example:**

```julia
# v1.1.6
docp = direct_transcription(ocp, grid_size=100)
set_initial_guess(docp, x_init, u_init)
sol = build_OCP_solution(docp, nlp_sol)

# v2.0.0
docp = discretize(ocp, Collocation(); grid_size=100)
init = @init ocp begin
    x = x_init
    u = u_init
end
sol = ocp_solution(docp, nlp_sol)
```

## Changed Exports

### CTBase Exceptions

**Removed exports:**

- `IncorrectMethod`
- `IncorrectOutput`
- `UnauthorizedCall`

**Added exports:**

- `PreconditionError`

These exceptions are still available via `CTBase.IncorrectMethod`, etc., but are no longer re-exported by OptimalControl.jl.

### CTFlows Types

The following types are **no longer exported** (but still available via qualified access):

- `VectorField` → use `OptimalControl.VectorField` or `CTFlows.VectorField`
- `Hamiltonian` → use `OptimalControl.Hamiltonian` or `CTFlows.Hamiltonian`
- `HamiltonianLift` → use `OptimalControl.HamiltonianLift` or `CTFlows.HamiltonianLift`
- `HamiltonianVectorField` → use `OptimalControl.HamiltonianVectorField` or `CTFlows.HamiltonianVectorField`

**Migration example:**

```julia
# v1.1.6
X = VectorField(f)

# v2.0.0
X = OptimalControl.VectorField(f)
# or
using CTFlows: VectorField
X = VectorField(f)
```

## New Solve Architecture

The `solve` function has been completely redesigned with two modes:

### Descriptive Mode (Symbolic)

```julia
# Specify strategies using symbols
sol = solve(ocp, :collocation, :adnlp, :ipopt, :cpu)

# Partial specification (auto-completed)
sol = solve(ocp, :ipopt)  # Uses first matching method
sol = solve(ocp, :gpu)    # Uses first GPU method
```

### Explicit Mode (Typed Components)

```julia
# Specify strategies using typed components
sol = solve(ocp; 
    discretizer=Collocation(),
    modeler=ADNLP(),
    solver=Ipopt()
)
```

### Methods System

The `methods()` function now returns **4-tuples** instead of 3-tuples:

```julia
# v1.1.6
methods()  # Returns (discretizer, modeler, solver)

# v2.0.0
methods()  # Returns (discretizer, modeler, solver, parameter)
# Example: (:collocation, :adnlp, :ipopt, :cpu)
```

The 4th element is the **parameter** (`:cpu` or `:gpu`) for execution backend.

## Option Routing System

v2.0.0 introduces automatic option routing with new introspection tools:

### New Functions

- `describe(strategy)` — Display available options for a strategy
- `route_to(strategy=value)` — Disambiguate shared options
- `bypass(option=value)` — Pass undeclared options to strategies

**Example:**

```julia
# Inspect available options
describe(:ipopt)
describe(:collocation)

# Disambiguate shared options
sol = solve(ocp, :ipopt; 
    max_iter=100,                    # Shared option (auto-routed)
    route_to(solver=:print_level=>0) # Explicitly route to solver
)

# Pass undeclared options
sol = solve(ocp, :ipopt; 
    bypass(solver=:custom_option=>42)
)
```

## Initial Guess with @init Macro

v2.0.0 introduces the `@init` macro for constructing initial guesses:

```julia
# v2.0.0
init = @init ocp begin
    u = 0.5
    x = [1.0, 2.0]
end

sol = solve(ocp; initial_guess=init)
# or using alias
sol = solve(ocp; init=init)
```

The old functional approach is no longer supported.

## New Features (Non-Breaking)

These features are new in v2.0.0 but don't break existing code:

### Control-Free Problems Support

Support for optimal control problems without control variables:

```julia
ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x ∈ R², state
    ẋ(t) == f(x(t))  # No control
    ∫(L(x(t))) → min
end
```

### New Solvers

- **Uno**: CPU-only nonlinear optimization solver
- **MadNCL**: GPU-capable solver

Total of 5 solvers: Ipopt, MadNLP, Uno, MadNCL, Knitro

### Additional Discretization Schemes

**Basic schemes:**

- `:trapeze` — Trapezoidal rule
- `:midpoint` — Midpoint rule
- `:euler` / `:euler_explicit` / `:euler_forward` — Explicit Euler
- `:euler_implicit` / `:euler_backward` — Implicit Euler

**ADNLP-only schemes:**

- `:gauss_legendre_2` — 2-point Gauss-Legendre collocation
- `:gauss_legendre_3` — 3-point Gauss-Legendre collocation

### GPU Support

Explicit GPU/CPU selection via parameter:

```julia
# CPU execution (default)
sol = solve(ocp, :collocation, :adnlp, :ipopt, :cpu)

# GPU execution (requires ExaModels + MadNLP/MadNCL)
using CUDA, MadNLPGPU
sol = solve(ocp, :collocation, :exa, :madnlp, :gpu)
```

## CTFlows Features

### Control-Free Problems

v2.0.0 introduces comprehensive support for control-free problems (optimal control without control variables) with enhanced CTFlows integration:

**Augmented Hamiltonian approach:**

```julia
# v1.1.6: Manual augmented Hamiltonian construction
function H_aug(t, x_, p_)
    x, λ = x_
    p, _ = p_
    return H(t, x, p, λ)
end
f = Flow(Hamiltonian(H_aug))

# v2.0.0: Direct OCP flow creation
f = Flow(ocp)
```

**Automatic costate computation:**

```julia
# v2.0.0: augment=true automatically computes p_λ(tf)
function shoot!(s, p0, λ)
    _, px_tf, pλ_tf = f(t0, x0, p0, tf, λ; augment=true)
    s[1] = px_tf  # p(tf) = 0
    s[2] = pλ_tf  # p_λ(tf) = 0
end
```

**Mathematical framework:**

- Complete augmented system dynamics with proper transversality conditions
- Automatic handling of Lagrange costs: $p_\lambda(t_f) = 0$
- Automatic handling of Mayer costs: $p_\omega(t_f) = -2\omega$
- Initial conditions: $p_\lambda(t_0) = 0$ by construction

## Dependency Updates

v2.0.0 requires updated versions of CTX packages:

| Package   | v1.1.6    | v2.0.0 |
| --------- | --------- | ------ |
| CTBase    | 0.16-0.17 | 0.18   |
| CTModels  | 0.6       | 0.9    |
| CTDirect  | 0.x       | 1.0    |
| CTSolvers | N/A       | 0.4    |
| CTParser  | 0.7-0.8   | 0.8    |

**New dependency:** CTSolvers.jl (handles NLP modeling and solving)

## Summary

The main breaking changes are:

1. **Removed functions**: `direct_transcription`, `set_initial_guess`, `build_OCP_solution`
2. **Changed exports**: Some CTBase exceptions and CTFlows types no longer exported
3. **New solve architecture**: Descriptive/explicit modes with 4-tuple methods
4. **Initial guess**: Use `@init` macro instead of functional approach

For detailed usage examples, see the [documentation](https://control-toolbox.org/OptimalControl.jl/stable/).

# Breaking Changes: v1.x → v2.0

This document describes the breaking changes when migrating from **OptimalControl.jl v1.1.6** (last stable release) to **v2.0.0**.

## Overview

Version 2.0.0 represents a major architectural redesign of OptimalControl.jl, introducing:

- **Complete solve architecture redesign** with descriptive and explicit modes
- **GPU/CPU parameter system** for heterogeneous computing
- **Advanced option routing** with introspection and disambiguation tools
- **New solver integrations** (Uno, MadNCL)
- **Control-free problems** support
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

### Control-Free Problems

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

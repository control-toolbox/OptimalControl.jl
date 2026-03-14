# [Solve: explicit mode](@id manual-solve-explicit)

```@meta
CollapsedDocStrings = false
Draft = false
```

This manual explains the **explicit mode** of the [`solve`](@ref) function, where you pass typed strategy instances directly instead of symbolic tokens. This gives you full control over component configuration and validation.

For basic usage with symbolic tokens, see [Solve a problem](@ref manual-solve).

## Overview

In explicit mode, you create strategy instances with their options, then pass them to `solve`:

```@example explicit
using OptimalControl
using NLPModelsIpopt
using CTDirect, CTSolvers

t0 = 0
tf = 1
x0 = [-1, 0]

ocp = @def begin
    t ∈ [ t0, tf ], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ẋ(t)  == [v(t), u(t)]
    0.5∫( u(t)^2 ) → min
end

# Create strategy instances
disc = Collocation(grid_size=100, scheme=:trapeze)
mod  = ADNLP(backend=:optimized)
sol  = Ipopt(max_iter=1000, print_level=0)

# Solve with explicit components
result = solve(ocp; discretizer=disc, modeler=mod, solver=sol)
nothing # hide
```

The mode is **automatically detected**: if any of `discretizer`, `modeler`, or `solver` keywords contain a typed component (not a symbol), explicit mode is used.

## Basic usage

### Creating strategy instances

Each strategy is constructed with its options as keyword arguments:

```@example explicit
# Discretizer with custom grid and scheme
disc = Collocation(grid_size=50, scheme=:midpoint)

# Modeler with specific backend
mod = ADNLP(backend=:optimized, show_time=false)

# Solver with iteration limit and tolerance
sol = Ipopt(max_iter=500, tol=1e-6, print_level=0)
nothing # hide
```

### Passing to solve

Use the `discretizer`, `modeler`, and `solver` keyword arguments:

```@example explicit
result = solve(ocp; 
    discretizer=disc, 
    modeler=mod, 
    solver=sol,
    display=false
)
nothing # hide
```

## Partial components

You don't need to specify all three components. Missing ones are auto-completed using the default strategy registry:

```@example explicit
# Only specify the solver
result = solve(ocp; 
    solver=Ipopt(max_iter=2000, print_level=0),
    display=false
)
nothing # hide
```

In this case:

- `discretizer` defaults to `Collocation()` (with default options)
- `modeler` defaults to `ADNLP()` (with default options)
- `solver` uses your custom `Ipopt` instance

You can mix and match:

```@example explicit
# Custom discretizer and solver, default modeler
result = solve(ocp;
    discretizer=Collocation(grid_size=200, scheme=:trapeze),
    solver=Ipopt(max_iter=100, print_level=0),
    display=false
)
nothing # hide
```

## Component options

### Options at construction

All options are passed when creating the strategy instance:

```@example explicit
# Configure Collocation
disc = Collocation(
    grid_size=150,
    scheme=:gauss_legendre_2
)

# Configure ADNLP
mod = ADNLP(
    backend=:optimized,
    show_time=true
)

# Configure Ipopt
sol = Ipopt(
    max_iter=1000,
    tol=1e-8,
    print_level=5,
    acceptable_tol=1e-6
)
nothing # hide
```

### Validation modes

Strategies support two validation modes:

- **`:strict`** (default): Rejects unknown options with a detailed error message
- **`:permissive`**: Accepts unknown options with a warning, stores them with `:user` source

```@example explicit
# Strict mode (default) - will error on unknown options
solver_strict = Ipopt(max_iter=500, print_level=0)

# Permissive mode - accepts unknown options
solver_permissive = Ipopt(
    max_iter=500, 
    print_level=0,
    custom_option=42;  # Unknown option
    mode=:permissive
)
nothing # hide
```

!!! warning "Permissive mode"

    Use `:permissive` mode only when you need to pass options that aren't declared in the strategy metadata (e.g., experimental solver options). The option will be passed to the underlying solver without validation.

### No routing needed

In explicit mode, there's no option routing or ambiguity:

- Options go directly to the component you're configuring
- No need for `route_to` (it's only for descriptive mode)
- No automatic routing between strategies

```@example explicit
# Each component gets its own options directly
disc = Collocation(grid_size=100)
sol = Ipopt(max_iter=500, tol=1e-6, print_level=0)

result = solve(ocp; discretizer=disc, solver=sol, display=false)
nothing # hide
```

## When to use explicit mode

Explicit mode is useful when you:

1. **Pre-configure and reuse components** across multiple solves:

```@example explicit
# Configure once
my_solver = Ipopt(max_iter=2000, tol=1e-8, print_level=0)

# Reuse for multiple problems
sol1 = solve(ocp; solver=my_solver, display=false)

# Create a variant
ocp2 = @def begin
    t ∈ [ 0, 2 ], time
    x ∈ R, state
    u ∈ R, control
    x(0) == 1
    x(2) == 0
    ẋ(t) == u(t)
    ∫( u(t)^2 ) → min
end

sol2 = solve(ocp2; solver=my_solver, display=false)
nothing # hide
```

2. **Need permissive mode** for exotic/undeclared options:

```julia
solver = Ipopt(
    max_iter=1000,
    experimental_option=123;
    mode=:permissive
)
solve(ocp; solver=solver)
```

3. **Want full type safety** and explicit control:

```julia
# Types are explicit, no symbol-to-type resolution
disc :: Collocation = Collocation(grid_size=100)
mod  :: ADNLP       = ADNLP()
sol  :: Ipopt       = Ipopt(max_iter=500)

solve(ocp; discretizer=disc, modeler=mod, solver=sol)
```

4. **Use GPU-parameterized types** (see [GPU manual](@ref manual-solve-gpu)):

```julia
using CUDA, MadNLPGPU, ExaModels

disc = Collocation(grid_size=100)
mod  = Exa{GPU}()
sol  = MadNLP{GPU}()

solve(ocp; discretizer=disc, modeler=mod, solver=sol)
```

## Mixing modes is forbidden

You **cannot** mix symbolic tokens and typed components in the same `solve` call:

```julia
# ERROR: Cannot mix descriptive and explicit modes
solve(ocp, :adnlp, :ipopt; discretizer=Collocation())

# ERROR: Cannot mix modes
solve(ocp, :collocation; solver=Ipopt())
```

Choose one mode:

- **Descriptive**: `solve(ocp, :collocation, :adnlp, :ipopt; options...)`
- **Explicit**: `solve(ocp; discretizer=..., modeler=..., solver=...)`

## Inspecting components

Use the introspection tools to examine configured components:

```@example explicit
# Create a configured solver
solver = Ipopt(max_iter=1000, tol=1e-6, print_level=0)

# Get its options
opts = options(solver)

# Check which options are user-set vs defaults
is_user(opts, :max_iter)     # true
```

```@example explicit
is_default(opts, :acceptable_tol)  # true (not set by user)
```

```@example explicit
# Get option values
option_value(opts, :max_iter)
```

```@example explicit
# See all option names
option_names(opts)
```

For more on introspection, see [Advanced options](@ref manual-solve-advanced).

## See also

- **[Basic solve (descriptive)](@ref manual-solve)**: symbolic token mode
- **[Advanced options](@ref manual-solve-advanced)**: `route_to`, `bypass`, introspection
- **[GPU solving](@ref manual-solve-gpu)**: `Exa{GPU}()` and `MadNLP{GPU}()` types
- **[CTSolvers Strategies](https://control-toolbox.org/CTSolvers.jl/stable/guides/implementing_a_strategy.html)**: strategy implementation guide

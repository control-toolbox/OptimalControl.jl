# [Solve: explicit mode](@id manual-solve-explicit)

This manual explains the **explicit mode** of the [`solve`](@ref) function, where you pass typed strategy instances directly instead of symbolic tokens. This gives you full control over component configuration and validation.

For basic usage with symbolic tokens, see [Solve a problem](@ref manual-solve).

## Overview

In explicit mode, you create strategy instances with their options, then pass them to `solve`:

```@example explicit
using OptimalControl
using NLPModelsIpopt

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
disc = OptimalControl.Collocation(grid_size=100, scheme=:trapeze)
mod  = OptimalControl.ADNLP(backend=:optimized)
sol  = OptimalControl.Ipopt(max_iter=1000, print_level=0)

# Solve with explicit components
result = solve(ocp; discretizer=disc, modeler=mod, solver=sol)
nothing # hide
```

The mode is **automatically detected**: if any of `discretizer`, `modeler`, or `solver` keywords contain a typed component (not a symbol), explicit mode is used.

## Basic usage

### Creating strategy instances

Each strategy is constructed with its options as keyword arguments. First, load the required solver packages:

```julia
# Load solver packages (only what you need)
using NLPModelsIpopt   # for Ipopt
using MadNLP           # for MadNLP
using UnoSolver        # for Uno
using MadNCL           # for MadNCL (also requires MadNLP)
using NLPModelsKnitro  # for Knitro (commercial license required)
# GPU solving also requires: using CUDA and using MadNLPGPU
```

```@example explicit
# Discretizer with custom grid and scheme
disc = OptimalControl.Collocation(grid_size=50, scheme=:midpoint)

# Modeler with specific backend
mod = OptimalControl.ADNLP(backend=:optimized, show_time=false)

# Solver with iteration limit and tolerance
sol = OptimalControl.Ipopt(max_iter=500, tol=1e-6, print_level=0)
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

You don't need to specify all three components. Missing ones are auto-completed using the default strategy registry, following the **same priority order** as in descriptive mode (see `methods()`):

```@example explicit
# Only specify the solver
result = solve(ocp; 
    solver=OptimalControl.Ipopt(max_iter=2000, print_level=0),
    display=false
)
nothing # hide
```

The completion algorithm searches `methods()` from top to bottom to find the first matching quadruplet, then builds the missing components with their default options. In this case:

- `discretizer` defaults to `Collocation()` (first discretizer in `methods()`)
- `modeler` defaults to `ADNLP()` (first modeler compatible with `Ipopt`)
- `solver` uses your custom `Ipopt` instance

!!! note "Priority order matters"

    Just like in descriptive mode, the order in `methods()` determines which defaults are used. For example:
    
    - `solve(ocp; solver=Ipopt())` → uses `ADNLP()` (first modeler compatible with Ipopt)
    - `solve(ocp; modeler=Exa())` → uses `Ipopt()` (first solver in the list)
    - `solve(ocp; discretizer=Collocation())` → uses `ADNLP()` and `Ipopt()` (first matching pair)

You can mix and match:

```@example explicit
# Custom discretizer and solver, default modeler
result = solve(ocp;
    discretizer=OptimalControl.Collocation(grid_size=200, scheme=:trapeze),
    solver=OptimalControl.Ipopt(max_iter=100, print_level=0),
    display=false
)
nothing # hide
```

## Component options

### Options at construction

All options are passed when creating the strategy instance:

```@example explicit
# Configure Collocation
disc = OptimalControl.Collocation(
    grid_size=150,
    scheme=:gauss_legendre_2
)

# Configure ADNLP
mod = OptimalControl.ADNLP(
    backend=:optimized,
    show_time=true
)

# Configure Ipopt
sol = OptimalControl.Ipopt(
    max_iter=1000,
    tol=1e-8,
    print_level=5,
    acceptable_tol=1e-6
)
nothing # hide
```

### Passing undeclared options

By default, strategies use **strict validation**: any option not declared in the strategy metadata raises an error. This prevents typos and ensures you're using valid options.

However, NLP solvers have many options, and not all of them are declared in OptimalControl's strategy metadata. For example, Ipopt has an option `mumps_print_level` for controlling MUMPS debug output, which is not in the Ipopt strategy metadata.

To pass undeclared options, use `bypass()` (or its alias `force()`):

```@example explicit
# Bypass validation for mumps_print_level
solver = OptimalControl.Ipopt(
    max_iter=500, 
    print_level=0,
    mumps_print_level=bypass(1)  # Undeclared option
)
nothing # hide
```

!!! note "Alias: force = bypass"
    You can use `force` as an alias for `bypass`: `mumps_print_level=force(1)`

!!! warning "Use bypass sparingly"

    The `bypass` mechanism skips validation for the wrapped option. Use it only when:
    
    - You need to pass an option to the underlying solver that isn't declared in the strategy metadata
    - You're certain the option name and value are correct
    
    Bypassed options are passed directly to the solver without type checking or validation.

!!! info "Alternative: permissive mode"

    If you have many undeclared options, you can use `mode=:permissive` to disable validation globally. However, this is not recommended as it will also ignore typos in valid option names.

### Strategy options must be configured at construction

In explicit mode, options specific to a strategy must be passed when constructing that strategy. They are not routed from the `solve` call.

The following syntax is **invalid**:

```julia
disc = OptimalControl.Collocation()
solve(ocp; disc, backend=:generic)
```

Because `disc` is a typed component, this call automatically selects explicit mode. `backend` is not an option of the `solve` action; it is an option of a modeler or solver strategy. The error does not mean that `backend` was lost or not transmitted. It means that an explicit component was combined with descriptive-style option syntax.

Configure the modeler first, then pass the configured strategy to `solve`:

```julia
disc = OptimalControl.Collocation()
modeler = OptimalControl.ADNLP(backend=:generic)
result = solve(ocp; discretizer=disc, modeler=modeler)
```

If an option is declared by one of the completed strategies, the error identifies that strategy and suggests constructing it with the option. If the option is not declared by any strategy, the error reports an unknown option and lists the options accepted directly by `solve`, such as `initial_guess`, `init`, and `display`.

`route_to` is only for descriptive mode. Likewise, `bypass` and `force` do not bypass explicit-mode validation. They can be used for undeclared options while constructing a strategy:

```julia
modeler = OptimalControl.ADNLP(custom_option=bypass(value))
solve(ocp; modeler=modeler)
```

### No routing needed

In explicit mode, there is no automatic option routing:

- Strategy options are passed to strategy constructors
- `solve` accepts action options and typed component instances
- `route_to` is only relevant to descriptive mode

```@example explicit
# Each component gets its own options directly
disc = OptimalControl.Collocation(grid_size=100)
sol = OptimalControl.Ipopt(max_iter=500, tol=1e-6, print_level=0)

result = solve(ocp; discretizer=disc, solver=sol, display=false)
nothing # hide
```

## Mixing modes is forbidden

You **cannot** mix symbolic tokens and typed components in the same `solve` call:

```julia
# ERROR: Cannot mix descriptive and explicit modes
solve(ocp, :adnlp, :ipopt; discretizer=OptimalControl.Collocation())

# ERROR: Cannot mix modes
solve(ocp, :collocation; solver=OptimalControl.Ipopt())
```

Choose one mode:

- **Descriptive**: `solve(ocp, :collocation, :adnlp, :ipopt; options...)`
- **Explicit**: `solve(ocp; discretizer=..., modeler=..., solver=...)`

## Inspecting components

Use the introspection tools to examine configured components:

```@example explicit
# Create a configured solver
solver = OptimalControl.Ipopt(max_iter=1000, tol=1e-6, print_level=0)

# Get its options
opts = options(solver)

# Check which options are user-set vs defaults
is_user(opts, :max_iter)     # true
```

```@example explicit
is_default(opts, :mu_strategy)  # true (not set by user)
```

```@example explicit
# Get option values
opts[:max_iter]
```

```@example explicit
# See all option names
keys(opts)
```

## See also

- **[Basic solve (descriptive)](@ref manual-solve)**: symbolic token mode
- **[Advanced options](@ref manual-solve-advanced)**: `route_to`, `bypass`, introspection
- **[GPU solving](@ref manual-solve-gpu)**: `Exa{GPU}()` and `MadNLP{GPU}()` types

# [Solve a problem](@id manual-solve)

This manual explains how to use the [`solve`](@ref) function to solve optimal control problems with OptimalControl.jl. The `solve` function provides a **descriptive mode** where you specify strategies using symbolic tokens, with automatic option routing and validation.

For advanced usage, see:

- [Advanced options and disambiguation](@ref manual-solve-advanced)
- [Explicit mode with typed components](@ref manual-solve-explicit)
- [GPU solving](@ref manual-solve-gpu)

## Quick start

Let us define a basic optimal control problem:

```@example main
using OptimalControl

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
nothing # hide
```

The simplest way to solve it is:

```@example main
using NLPModelsIpopt
sol = solve(ocp)
nothing # hide
```

This uses default strategies: collocation discretization, ADNLP modeler, and Ipopt solver, all running on CPU.

!!! warning "Solver extension required"

    You must load a solver package (e.g., `using NLPModelsIpopt`) before calling `solve`. Otherwise, you'll get:
    
    ```julia
    julia> solve(ocp)
    ERROR: ExtensionError. Please make: julia> using NLPModelsIpopt
    ```

## Display

Control the configuration display with the `display` option:

```@example main
# Suppress all output
sol = solve(ocp; display=false)
nothing # hide
```

## Initial guess

Provide an initial guess using `initial_guess` (or the alias `init`):

```@example main
# Using the @init macro
init = @init ocp begin
    u = 0.5
end

sol = solve(ocp; initial_guess=init, grid_size=50, display=false)
nothing # hide
```

```@example main
# Or using the alias
sol = solve(ocp; init=init, grid_size=50, display=false)
nothing # hide
```

For more details on initial guess specification, see [Set an initial guess](@ref manual-initial-guess).

## Available methods

OptimalControl.jl provides multiple solving strategies. To see all available combinations, call:

```@example main
methods()
```

Each method is a **quadruplet** `(discretizer, modeler, solver, parameter)`:

1. **Discretizer** — how to discretize the continuous OCP:
   - `:collocation`: collocation method (currently the only option)

2. **Modeler** — how to build the NLP model:
   - `:adnlp`: uses [`ADNLPModels.ADNLPModel`](@extref) with automatic differentiation
   - `:exa`: uses [`ExaModels.ExaModel`](@extref) with SIMD optimization (GPU-capable)

3. **Solver** — which NLP solver to use:
   - `:ipopt`: [Ipopt](https://coin-or.github.io/Ipopt/) interior point solver (CPU-only)
   - `:madnlp`: [MadNLP](https://madnlp.github.io/MadNLP.jl/) pure-Julia solver (GPU-capable)
   - `:uno`: [Uno](https://unosolver.readthedocs.io) unified nonlinear optimization solver (CPU-only)
   - `:madncl`: [MadNCL](https://github.com/MadNLP/MadNCL.jl) (GPU-capable)
   - `:knitro`: [Knitro](https://www.artelys.com/solvers/knitro/) commercial solver (license required)

4. **Parameter** — execution backend:
   - `:cpu`: CPU execution (default)
   - `:gpu`: GPU execution (only for `:exa` modeler with `:madnlp` or `:madncl` solvers)

You can inspect which strategies use a given parameter:

```@example main
describe(:cpu)
```

```@example main
describe(:gpu)
```

!!! note "Priority order"

    The order of methods in the list above determines the **priority** for auto-completion. When you provide a partial description, the first matching method from top to bottom is selected. This is why the first method `(:collocation, :adnlp, :ipopt, :cpu)` is the default.

The first method in the list is the default, so:

```julia
solve(ocp)
```

is equivalent to:

```julia
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)
```

## Choosing a method

You can specify a complete method description:

```@example main
using MadNLP
sol = solve(ocp, :collocation, :adnlp, :madnlp, :cpu)
nothing # hide
```

Or provide a **partial description**. Missing tokens are auto-completed using the **first matching method** from `methods()` (top-to-bottom priority):

```@example main
# Only specify the solver → defaults to :collocation, :adnlp, :cpu
sol = solve(ocp, :madnlp; print_level=MadNLP.ERROR)
nothing # hide
```

The completion algorithm searches `methods()` from top to bottom and selects the first quadruplet that matches all provided tokens. For example:

- `solve(ocp, :madnlp)` matches `(:collocation, :adnlp, :madnlp, :cpu)` (first match with `:madnlp`)
- `solve(ocp, :exa)` matches `(:collocation, :exa, :ipopt, :cpu)` (first match with `:exa`)
- `solve(ocp, :gpu)` matches `(:collocation, :exa, :madnlp, :gpu)` (first GPU method)

All of these are equivalent (they all complete to `:collocation, :adnlp, :ipopt, :cpu`):

```julia
solve(ocp)                                      # empty → use first method
solve(ocp, :collocation)                        # specify discretizer
solve(ocp, :adnlp)                              # specify modeler
solve(ocp, :ipopt)                              # specify solver
solve(ocp, :cpu)                                # specify parameter
solve(ocp, :collocation, :adnlp)                # specify discretizer + modeler
solve(ocp, :collocation, :ipopt)                # specify discretizer + solver
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)  # complete description
```

## [Solver requirements](@id manual-solve-solver-requirements)

Each solver requires its package to be loaded to provide the solver implementation:

- **Ipopt**: `using NLPModelsIpopt`
- **MadNLP**: `using MadNLP` (CPU) or `using MadNLPGPU` (GPU)
- **Uno**: `using UnoSolver`
- **MadNCL**: `using MadNCL` and `using MadNLP` (requires both)
- **Knitro**: `using NLPModelsKnitro` (commercial license required)

For GPU solving with MadNLP or MadNCL, you also need: `using CUDA`

## Passing options to strategies

You can pass options as keyword arguments. They are **automatically routed** to the appropriate strategy:

```@example main
sol = solve(ocp, :madnlp; 
    grid_size=100,              # → discretizer (Collocation)
    max_iter=500,               # → solver (MadNLP)
    print_level=MadNLP.ERROR    # → solver (MadNLP)
)
nothing # hide
```

The solve function displays the configuration and shows which options were applied:

```@example main
sol = solve(ocp, :ipopt; 
    grid_size=50, 
    scheme=:trapeze,
    max_iter=100,
    print_level=0
)
nothing # hide
```

Notice the `📦 Configuration` box showing:

- **Discretizer**: `collocation` with `grid_size = 50, scheme = trapeze`
- **Modeler**: `adnlp` (no custom options)
- **Solver**: `ipopt` with `max_iter = 100, print_level = 0`

## [Strategy options](@id manual-solve-strategy-options)

Each strategy declares its available options. You can inspect them using `describe`.

!!! note "Understanding default values"
    When `describe` shows `(default: NotProvided)` for an option, it means OptimalControl does not override the strategy's native default value. For example:
    - For Ipopt options with `(default: NotProvided)`, Ipopt's own default values are used
    - For MadNLP options with `(default: NotProvided)`, MadNLP's own default values are used
    - For other strategies, the same principle applies

    Only options with explicit default values (e.g., `(default: 100)`) are overridden by OptimalControl.

### Discretizer options

The collocation discretizer supports multiple integration schemes:

- `:trapeze` - Trapezoidal rule (second-order accurate)
- `:midpoint` - Midpoint rule (second-order accurate)  
- `:euler` or `:euler_explicit` or `:euler_forward` - Explicit Euler method (first-order accurate)
- `:euler_implicit` or `:euler_backward` - Implicit Euler method (first-order accurate, more stable for stiff problems)

!!! note "Additional schemes with ADNLP modeler"

    When using the `:adnlp` modeler, two additional high-order collocation schemes are available:

    - `:gauss_legendre_2` - 2-point Gauss-Legendre collocation (fourth-order accurate)
    - `:gauss_legendre_3` - 3-point Gauss-Legendre collocation (sixth-order accurate)

    These schemes provide higher accuracy but require more computational effort.

```@example main
describe(:collocation)
```

### Modeler options

```@example main
describe(:adnlp)
```

```@example main
using CUDA
describe(:exa)
```

### Solver options

```@example main
using NLPModelsIpopt
describe(:ipopt)
```

```@example main
using MadNLPGPU
describe(:madnlp)
```

```@example main
using MadNCL
describe(:madncl)
```

```@example main
using UnoSolver
describe(:uno)
```

### Official documentation

For complete option lists, see the official documentation:

- **ADNLP**: [ADNLPModels documentation](https://jso.dev/ADNLPModels.jl/stable/)
- **Exa**: [ExaModels documentation](https://exanauts.github.io/ExaModels.jl/stable/)
- **Ipopt**: [Ipopt options](https://coin-or.github.io/Ipopt/OPTIONS.html)
- **MadNLP**: [MadNLP options](https://madnlp.github.io/MadNLP.jl/stable/options/)
- **Uno**: [Uno documentation](https://unosolver.readthedocs.io)
- **MadNCL**: [MadNCL documentation](https://github.com/MadNLP/MadNCL.jl)
- **Knitro**: [Knitro options](https://www.artelys.com/docs/knitro/3_referenceManual/userOptions.html)

## See also

- **[Advanced options](@ref manual-solve-advanced)**: option routing, `route_to` for disambiguation, `bypass` for unknown options, introspection tools
- **[Explicit mode](@ref manual-solve-explicit)**: using typed components (`Collocation()`, `Ipopt()`) instead of symbols
- **[GPU solving](@ref manual-solve-gpu)**: using the `:gpu` parameter or `Exa{GPU}()` / `MadNLP{GPU}()` types
- **[Initial guess](@ref manual-initial-guess)**: detailed guide on the `@init` macro
- **[Solution](@ref manual-solution)**: working with the returned solution object

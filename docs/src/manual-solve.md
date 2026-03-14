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
   - `:ipopt`: [Ipopt](https://coin-or.github.io/Ipopt/) interior point solver
   - `:madnlp`: [MadNLP](https://madnlp.github.io/MadNLP.jl/) pure-Julia solver (GPU-capable)
   - `:madncl`: [MadNCL](https://madnlp.github.io/MadNLP.jl/) (GPU-capable)
   - `:knitro`: [Knitro](https://www.artelys.com/solvers/knitro/) commercial solver (license required)

4. **Parameter** — execution backend:
   - `:cpu`: CPU execution (default)
   - `:gpu`: GPU execution (only for `:exa` modeler with `:madnlp` or `:madncl` solvers)

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

Or provide a **partial description**. Missing tokens are auto-completed using the first matching method from `methods()`:

```@example main
# Only specify the solver → defaults to :collocation, :adnlp, :cpu
sol = solve(ocp, :madnlp)
nothing # hide
```

All of these are equivalent (they all complete to `:collocation, :adnlp, :ipopt, :cpu`):

```julia
solve(ocp)                              # empty → use first method
solve(ocp, :collocation)                # specify discretizer
solve(ocp, :adnlp)                      # specify modeler
solve(ocp, :ipopt)                      # specify solver
solve(ocp, :cpu)                        # specify parameter
solve(ocp, :collocation, :adnlp)        # specify discretizer + modeler
solve(ocp, :collocation, :ipopt)        # specify discretizer + solver
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)  # complete description
```

## Passing options to strategies

You can pass options as keyword arguments. They are **automatically routed** to the appropriate strategy:

```@example main
sol = solve(ocp, :madnlp; 
    grid_size=100,           # → discretizer (Collocation)
    max_iter=500,            # → solver (MadNLP)
    print_level=MadNLP.ERROR # → solver (MadNLP)
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

## Strategy options

Each strategy declares its available options. You can inspect them using `describe`:

```@example main
using CTDirect, CTSolvers
describe(Collocation)
```

```@example main
describe(ADNLP)
```

```@example main
describe(Ipopt)
```

Common options include:

**Discretizer (Collocation)**:

- `grid_size` (default: `250`): number of time steps
- `scheme` (default: `:midpoint`): discretization scheme (`:midpoint`, `:trapeze`, `:euler`, `:euler_implicit`, `:gauss_legendre_2`, `:gauss_legendre_3`)

**Modeler (ADNLP)**:

- `backend` (default: `:optimized`): AD backend (`:optimized`, `:manual`, `:default`)
- `show_time` (default: `false`): display model building time

**Solver (Ipopt)**:

- `max_iter` (default: `3000`): maximum iterations
- `tol` (default: `1e-8`): convergence tolerance
- `print_level` (default: `5`): output verbosity (0-12)

For complete option lists, see:

- [Ipopt options](https://coin-or.github.io/Ipopt/OPTIONS.html)
- [MadNLP options](https://madnlp.github.io/MadNLP.jl/stable/options/)

!!! note "ExaModels syntax limitations"

    When using `:exa` modeler (especially for [GPU solving](@ref manual-solve-gpu)):
    - Dynamics must be declared coordinate-by-coordinate: `∂(q)(t) == v(t)` instead of `ẋ(t) == [v(t), u(t)]`
    - Nonlinear constraints must be scalar expressions
    - Only ExaModels-supported operations are allowed (see [ExaModels documentation](https://exanauts.github.io/ExaModels.jl/stable))

## Initial guess

Provide an initial guess using `initial_guess` (or the alias `init`):

```@example main
# Using the @init macro (recommended)
init = @init begin
    u = 0.5
end

sol = solve(ocp; initial_guess=init, grid_size=50, print_level=0)
nothing # hide
```

```@example main
# Or using the alias
sol = solve(ocp; init=init, grid_size=50, print_level=0)
nothing # hide
```

For more details on initial guess specification, see [Set an initial guess](@ref manual-initial-guess).

## Display control

Control the configuration display with the `display` option:

```@example main
# Suppress all output
sol = solve(ocp; display=false)
nothing # hide
```

## See also

- **[Advanced options](@ref manual-solve-advanced)**: option routing, `route_to` for disambiguation, `bypass` for unknown options, introspection tools
- **[Explicit mode](@ref manual-solve-explicit)**: using typed components (`Collocation()`, `Ipopt()`) instead of symbols
- **[GPU solving](@ref manual-solve-gpu)**: using the `:gpu` parameter or `Exa{GPU}()` / `MadNLP{GPU}()` types
- **[Initial guess](@ref manual-initial-guess)**: detailed guide on the `@init` macro
- **[Solution](@ref manual-solution)**: working with the returned solution object

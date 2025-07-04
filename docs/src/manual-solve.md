# [The solve function](@id manual-solve)

```@meta
CollapsedDocStrings = false
```

In this manual, we explain the [`solve`](@ref) function from [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package.

```@docs; canonical=false
solve(::CTModels.Model, ::Symbol...)
```

## Basic usage

Let us define a basic optimal control problem.

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
    ẋ(t)  == [v(t), u(t)]
    0.5∫( u(t)^2 ) → min
end
nothing # hide
```

We can now solve the problem:

```@example main
using NLPModelsIpopt
solve(ocp)
nothing # hide
```

Note that we must import NLPModelsIpopt.jl before calling `solve`.  
This is because the default method uses a direct approach, which transforms the optimal control problem into a nonlinear program (NLP) of the form:

```math
\text{minimize}\quad F(y), \quad\text{subject to the constraints}\quad g(y) \le 0, \quad h(y) = 0. 
```

!!! caveat

    Calling `solve` without loading a NLP solver package first will notify the user:

    ```julia
    julia> solve(ocp)
    ERROR: ExtensionError. Please make: julia> using NLPModelsIpopt
    ```

## [Resolution methods and algorithms](@id manual-solve-methods)

OptimalControl.jl offers a list of methods. To get it, simply call `available_methods`.

```@example main
available_methods()
```

Each line is a method, with priority going from top to bottom. This means that 

```julia
solve(ocp)
```

is equivalent to 

```julia
solve(ocp, :direct, :adnlp, :ipopt)
```

1. The first symbol refers to the general class of method. The only possible value is:
    - `:direct`: currently, only the so-called [direct approach](https://en.wikipedia.org/wiki/Optimal_control#Numerical_methods_for_optimal_control) is implemented. Direct methods discretise the original optimal control problem and solve the resulting NLP. In this case, the main `solve` method redirects to [`CTDirect.solve`](@extref).
2. The second symbol refers to the NLP modeler. The possible values are:
    - `:adnlp`: the NLP problem is modeled by a [`ADNLPModels.ADNLPModel`](@extref). It provides automatic differentiation (AD)-based models that follow the [NLPModels.jl](https://github.com/JuliaSmoothOptimizers/NLPModels.jl) API.
    - `:exa`: the NLP problem is modeled by a [`ExaModels.ExaModel`](@extref). It provides automatic differentiation and [SIMD](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data) abstraction.
3. The third symbol specifies the NLP solver. Possible values are:
   - `:ipopt`: calls [`NLPModelsIpopt.ipopt`](@extref) to solve the NLP problem.
   - `:madnlp`: creates a [MadNLP.MadNLPSolver](@extref) instance from the NLP problem and solve it. [MadNLP.jl](https://madnlp.github.io/MadNLP.jl) is an open-source solver in Julia implementing a filter line-search interior-point algorithm like Ipopt.
   - `:knitro`: uses the [Knitro](https://www.artelys.com/solvers/knitro/) solver (license required).

!!! warning

    The dynamics must be defined coordinatewise to use ExaModels.jl (`:exa`).

For instance, let us try MadNLP solver with ExaModel modeller.

```@example main
using MadNLP

ocp = @def begin
    t ∈ [ t0, tf ], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ∂(q)(t) == v(t)
    ∂(v)(t) == u(t)
    0.5∫( u(t)^2 ) → min
end

solve(ocp, :exa, :madnlp)
nothing # hide
```

Note that you can provide a partial description. If multiple full descriptions contain it, priority is given to the first one in the list. Hence, all of the following calls are equivalent:

```julia
solve(ocp)
solve(ocp, :direct                )
solve(ocp,          :adnlp        )
solve(ocp,                  :ipopt)
solve(ocp, :direct, :adnlp        )
solve(ocp, :direct,         :ipopt)
solve(ocp, :direct, :adnlp, :ipopt)
```

## [Direct method](@id manual-solve-direct-method)

The main options for the direct method, with their [default] values, are:

- `display` ([`true`], `false`): setting `display = false` disables output.
- `init`: information for the initial guess. It can be given as numerical values, functions, or an existing solution. See [how to set an initial guess](@ref manual-initial-guess).
- `grid_size` ([`250`]): number of time steps in the (uniform) time discretization grid.  
  More precisely, if `N = grid_size` and the initial and final times are `t0` and `tf`, then the step length `Δt = (tf - t0) / N`.
- `time_grid` ([`nothing`]): explicit time grid (can be non-uniform).  
  If `time_grid = nothing`, a uniform grid of length `grid_size` is used.
- `disc_method` ([`:trapeze`], `:midpoint`, `:euler`, `:euler_implicit`, `:gauss_legendre_2`, `:gauss_legendre_3`): the discretisation scheme to transform the dynamics into nonlinear equations. See the [discretization method tutorial](https://control-toolbox.org/Tutorials.jl/stable/tutorial-discretisation.html) for more details.
- `adnlp_backend` ([`:optimized`], `:manual`, `:default`): backend used for automatic differentiation to create the [`ADNLPModels.ADNLPModel`](@extref).

For advanced usage, see:
- [discrete continuation tutorial](https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html),
- [NLP manipulation tutorial](https://control-toolbox.org/Tutorials.jl/stable/tutorial-nlp.html).

!!! note

    The main [`solve`](@ref) method from OptimalControl.jl simply redirects to [`CTDirect.solve`](@extref) in that case.

## [NLP solvers specific options](@id manual-solve-solvers-specific-options)

In addition to these options, all remaining keyword arguments passed to `solve` will be transmitted to the NLP solver used.

Please check the list of [Ipopt options](https://coin-or.github.io/Ipopt/OPTIONS.html) and the [NLPModelsIpopt.jl documentation](https://jso.dev/NLPModelsIpopt.jl).
```@example main
sol = solve(ocp; max_iter=0, tol=1e-6, display=false)
iterations(sol)
```

Similarly, please check the [MadNLP.jl documentation](https://madnlp.github.io/MadNLP.jl) and the list of [MadNLP.jl options](https://madnlp.github.io/MadNLP.jl/stable/options/).
```@example main
sol = solve(ocp, :madnlp; max_iter=0, tol=1e-6, display=false)
iterations(sol)
```

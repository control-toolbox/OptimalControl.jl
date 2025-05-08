# [The solve function](@id tutorial-solve)

In this tutorial, we explain the [`solve`](@ref) function from [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package.

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
    x(tf) == [ 0, 0 ]
    ẋ(t)  == [ v(t), u(t) ]
    ∫( 0.5u(t)^2 ) → min
end
nothing # hide
```

We can now solve the problem:

```@example main
using NLPModelsIpopt
solve(ocp)
nothing # hide
```

Notice that we need to load the `NLPModelsIpopt` package before calling `solve`.
This is because the method currently implements a direct approach, where the optimal control problem is transcribed to a nonlinear optimization problem (NLP) of the form
```math
\text{minimize}\quad F(y), \quad\text{subject to the constraints}\quad g(y)=0, \quad h(y)\le 0. 
```

Calling `solve` without loading a NLP solver package first will notify the user:

```julia
julia> solve(ocp)
ERROR: ExtensionError. Please make: julia> using NLPModelsIpopt
```

## Resolution methods and algorithms

OptimalControl offers a list of methods to solve your optimal control problem. To get the list of methods, simply call `available_methods`.

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

The first symbol `:direct` refers to the general class of method, with only the so-called [direct approach](https://en.wikipedia.org/wiki/Optimal_control#Numerical_methods_for_optimal_control) currently implemented.
Direct methods discretize the original optimal control problem and solve the resulting NLP problem.
The second symbol `:adnlp` is for the choice of NLP modeler. 
We currently use [ADNLPModels.jl](https://jso.dev/ADNLPModels.jl) which provides an automatic differentiation (AD)-based model implementations that conform to the [NLPModels.jl](https://github.com/JuliaSmoothOptimizers/ADNLPModels.jl) API.
The third symbol corresponds to the NLP solver, with the possible values:
- `:ipopt` (default value) for Ipopt (via the [NLPModelsIpopt.jl](https://github.com/JuliaSmoothOptimizers/NLPModelsIpopt.jl) package).
- `:madnlp` is [MadNLP.jl](https://madnlp.github.io/MadNLP.jl), an open-source nonlinear programming solver purely implemented in Julia, which implements a filter line-search interior-point algorithm, as the one in Ipopt.
- `:knitro` for the [Knitro](https://www.artelys.com/solvers/knitro/) solver (requires a license).

For instance, let us try MadNLP.jl.

```@example main
using MadNLP
solve(ocp, :madnlp)
nothing # hide
```

Note that you can provide a partial description. 
If several full descriptions contain it, the priority is given to first one in the list. 
Hence, these calls are all equivalent:

```julia
solve(ocp)
solve(ocp, :direct                )
solve(ocp,          :adnlp        )
solve(ocp,                  :ipopt)
solve(ocp, :direct, :adnlp        )
solve(ocp, :direct,         :ipopt)
solve(ocp, :direct, :adnlp, :ipopt)
```

## Direct method

The options for the direct method are listed [here](https://control-toolbox.org/OptimalControl.jl/stable/dev-ctdirect.html#CTDirect.solve-Tuple{Model,%20Vararg{Symbol}}). The main options, with their [default values], are:
- `display` ([true], false): setting `display` to false will disable output.
- `grid_size` ([250]): size of the (uniform) time discretization grid. More precisely, it is the number of time steps, that is if `N = grid_size` and if the initial and final times are denoted respectively `t0` and `tf`, then we have `Δt = (tf - t0) / N`.
- `disc_method` ([`:trapeze`], `:midpoint`, `:euler`, `:euler_implicit`, `:gauss_legendre_2`, `:gauss_legendre_3`): see [discretisation methods](https://control-toolbox.org/Tutorials.jl/stable/tutorial-discretisation.html).
- `init`: info for the starting guess, which can be provided as numerical values, functions, or an existing solution. See [initial guess tutorial](@ref tutorial-initial-guess). 

For examples of more advanced use, see 
- [discrete continuation](https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html),
- [NLP direct handling](https://control-toolbox.org/Tutorials.jl/stable/tutorial-nl.html).


## NLP solver specific options

In addition to these options, all remaining keyword arguments passed to `solve` will be transmitted to the NLP solver used.

Please check the list of [Ipopt options](https://coin-or.github.io/Ipopt/OPTIONS.html) and the [NLPModelsIpopt.jl documentation](https://jso.dev/NLPModelsIpopt.jl).
```@example main
solve(ocp; max_iter=0)
nothing # hide
```

Similarly, please check the [MadNLP.jl documentation](https://madnlp.github.io/MadNLP.jl) and the list of [MadNLP.jl options](https://madnlp.github.io/MadNLP.jl/stable/options/).
```@example main
solve(ocp, :madnlp; max_iter=0)
nothing # hide
```

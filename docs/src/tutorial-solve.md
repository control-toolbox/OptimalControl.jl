# [The solve function](@id tutorial-solve)

In this tutorial, we explain the [`solve`](@ref) function from [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package.

## Basic usage

Les us define a basic optimal control problem.

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

Let us try to solve the problem:

```@setup main_repl
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
```

```julia
julia> solve(ocp)
ERROR: ExtensionError. Please make: julia> using NLPModelsIpopt
```

As you can see, an error occured since we need the package [NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl).

Actually, the default solving method is what we call a 
[direct method](https://en.wikipedia.org/wiki/Optimal_control#Numerical_methods_for_optimal_control). 
In a direct method, the optimal control problem is transcribed to a nonlinear optimization problem (NLP) of the form

```math
\text{minimize}\quad F(y), \quad\text{subject to the constraints}\quad g(y)=0, \quad h(y)\le 0. 
```

OptimalControl.jl package makes the transcription but it needs a package to model the NLP problem and 
another one to solve it. NLPModelsIpopt.jl package provides an interface to the well-known solver 
[Ipopt](https://coin-or.github.io/Ipopt/) that can be used to solve general nonlinear programming problems.

```@example main
using NLPModelsIpopt

solve(ocp)
nothing # hide
```
## Options

### Methods

OptimalControl.jl offers a list of methods to solve your optimal control problem. To get the list of methods, simply call `available_methods`.

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

The first symbol `:direct` refers to the general class of method, with only the so-called direct approach currently implemented.
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

### Direct method

The options for the direct method are listed in the [`direct_solve`](@ref) keywords:
+++ faire la liste complete

- `init`: +++option can be used to set an initial guess for the solver. See the [initial guess tutorial](@ref tutorial-initial-guess). 
- `grid_size`: option corresponds to the size of the (uniform) time discretization grid. More precisely, it is the number of steps, that is if `N = grid_size` and if the initial and final times are denoted respectively `t0` and `tf`, then we have:
```julia
Δt = (tf - t0) / N
```
- +++`disc_method`
- `time_grid` option is the grid of times: `t0, t1, ..., tf`. If the initial and/or the final times are free, then you can provide a normalised grid between 0 and 1. Note that you can set either `grid_size` or `time_grid` but not both.

```@example main
sol = solve(ocp; grid_size=10, display=false)
time_grid(sol)
```

Or with MadNLP.jl:

```@example main
sol = solve(ocp, :madnlp; grid_size=10, display=false)
time_grid(sol)
```

### NLP solver specific options

+++You can provide any option of NLPModelsIpopt.jl or Ipopt with a pair `keyword=value`. 
Please check the list of [Ipopt options](https://coin-or.github.io/Ipopt/OPTIONS.html) and the [NLPModelsIpopt.jl documentation](https://jso.dev/NLPModelsIpopt.jl).

```@example main
+++check solve(ocp; max_iter=0)
nothing # hide
```

Similarly, If you use the MadNLP.jl solver, then you can provide any option of it. 
Please check the [MadNLP.jl documentation](https://madnlp.github.io/MadNLP.jl) and the list of [MadNLP.jl options](https://madnlp.github.io/MadNLP.jl/stable/options/).

```@example main
+++ printlevel solve(ocp, :madnlp; max_iter=1, display=true)
nothing # hide
```

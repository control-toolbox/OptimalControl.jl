# [Double integrator: time minimisation](@id double-integrator-time)

```@meta
Draft = false
```

The problem consists in minimising the final time $t_f$ for the double integrator system

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t), \quad u(t) \in [-1,1],
```

and the limit conditions

```math
    x(0) = (1,2), \quad x(t_f) = (0,0).
```

This problem can be interpretated as a simple model for a wagon with constant mass moving along
a line without fricton.

```@raw html
<img src="./assets/chariot.png" style="display: block; margin: 0 auto 20px auto;" width="300px">
```

First, we need to import the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package to define the 
optimal control problem and [NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl) to solve it. 
We also need to import the [Plots.jl](https://docs.juliaplots.org) package to plot the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Optimal control problem

Let us define the problem

```@example main
ocp = @def begin

    tf ∈ R,          variable
    t ∈ [0, tf],     time
    x = (q, v) ∈ R², state
    u ∈ R,           control

    -1 ≤ u(t) ≤ 1

    q(0)  == -1
    v(0)  == 0
    q(tf) == 0
    v(tf) == 0

    ẋ(t) == [v(t), u(t)]

    tf → min

end
nothing # hide
```

!!! note "Nota bene"

    For a comprehensive introduction to the syntax used above to define the optimal control problem, check [this abstract syntax tutorial](@ref tutorial-abstract-syntax). In particular, there are non-unicode alternatives for derivatives, integrals, *etc.*

## Solve and plot

Solve it

```@example main
sol = solve(ocp; grid_size=300, print_level=4)
nothing # hide
```

and plot the solution

```@example main
plot(sol)
```

!!! note "Nota bene"

    The `solve` function has options, see the [solve tutorial](@ref tutorial-solve). You can customise the plot, see the [plot tutorial](@ref tutorial-plot).

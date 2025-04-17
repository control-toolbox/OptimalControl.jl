# [Double integrator: time minimisation (abstract syntax)](@id double-integrator-time)

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
optimal control problem and [NLPModelsIpopt.jl](jso.dev/NLPModelsIpopt.jl) to solve it. 
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
    t ∈ [ 0, tf ],   time
    x = (q, v) ∈ R², state
    u ∈ R,           control

    tf ≥ 0
    -1 ≤ u(t) ≤ 1

    q(0)  == 1
    v(0)  == 2
    q(tf) == 0
    v(tf) == 0

    -5 ≤ q(t) ≤ 5,          (1)
    -3 ≤ v(t) ≤ 3,          (2)

    ẋ(t) == [ v(t), u(t) ]

    tf → min

end
nothing # hide
```

!!! tip "Convergence"

    In order to ensure convergence of the direct solver, we have added the state constraints labelled (1) and (2):

    ```math
    -5 \leq q(t) \leq 5,\quad -3 \leq v(t) \leq 3,\quad t \in [ 0, t_f ].
    ```

!!! note "Nota bene"

    For a comprehensive introduction to the syntax used above to describe the optimal control problem, check [this abstract syntax tutorial](@ref abstract). In particular, there are non-unicode alternatives for derivatives, integrals, *etc.*

## Solve and plot

Solve it

```@example main
sol = solve(ocp; print_level=4)
nothing # hide
```

and plot the solution

```@example main
plot(sol)
```

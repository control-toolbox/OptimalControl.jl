# [Double integrator: time minimisation (functional syntax)](@id double-int-f)

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

First, we need to import the `OptimalControl.jl` package to define the optimal control problem and `NLPModelsIpopt.jl` to solve it. 
We also need to import the `Plots.jl` package to plot the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Optimal control problem

Let us define the problem

```@example main
ocp = Model(variable=true)                       # variable is true since tf is free

variable!(ocp, 1, :tf)                           # dimension and name of the variable
time!(ocp, t0=0, indf=1)                         # initial time fixed to 0
                                                 # final time free and corresponds to the
                                                 # first component of the variable
state!(ocp, 2, :x, [:q, :v])                     # dimension of the state with names
control!(ocp, 1)                                 # dimension of the control

constraint!(ocp, :variable; lb=0)                # tf ≥ 0
constraint!(ocp, :control; lb=-1, ub=1)          # -1 ≤ u(t) ≤ 1
constraint!(ocp, :initial; val=[ 1, 2 ])         # initial condition
constraint!(ocp, :final;   val=[ 0, 0 ])         # final condition
constraint!(ocp, :state; lb=[-5, -3], ub=[5, 3]) # -5 ≤ q(t) ≤ 5, -3 ≤ v(t) ≤ 3

dynamics!(ocp, (x, u, tf) -> [ x[2], u ])        # dynamics of the double integrator

objective!(ocp, :mayer, (x0, xf, tf) -> tf)      # cost in Mayer form
nothing # hide
```

!!! tip "Convergence"

    In order to ensure convergence of the direct solver, we have added the state constraints labelled (1) and (2):

    ```math
    -5 \leq q(t) \leq 5,\quad -3 \leq v(t) \leq 3,\quad t \in [ 0, t_f ].
    ```

!!! note "Nota bene"

    - For details about the syntax used above to describe the optimal control problem, check the [`Model` documentation](@ref api-ctbase-model).
    - You can also define the optimal control problem with an abstract syntax. See for instance [basic time minimisation](@ref double-int) to compare or for a comprehensive introduction to the abstract syntax, check [this tutorial](@ref abstract).

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

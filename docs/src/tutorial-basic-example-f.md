# [Double integrator: energy min (functional syntax)](@id basic-f)

Let us consider a wagon moving along a rail, whom acceleration can be controlled by a force $u$.
We denote by $x = (x_1, x_2)$ the state of the wagon, that is its position $x_1$ and its velocity $x_2$.

```@raw html
<img src="./assets/chariot.png" style="display: block; margin: 0 auto 20px auto;" width="300px">
```

We assume that the mass is constant and unitary and that there is no friction. The dynamics we consider is given by

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t), \quad u(t) \in \R,
```

which is simply the [double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674) system.
Les us consider a transfer starting at time $t_0 = 0$ and ending at time $t_f = 1$, for which we want to minimise the transfer energy

```math
    \frac{1}{2}\int_{0}^{1} u^2(t) \, \mathrm{d}t
```

starting from the condition $x(0) = (-1, 0)$ and with the goal to reach the target $x(1) = (0, 0)$.

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
ocp = Model()                                   # empty optimal control problem

time!(ocp, t0=0, tf=1)                          # initial and final times
state!(ocp, 2)                                  # dimension of the state
control!(ocp, 1)                                # dimension of the control

constraint!(ocp, :initial; val=[ -1, 0 ])       # initial condition
constraint!(ocp, :final;   val=[  0, 0 ])       # final condition

dynamics!(ocp, (x, u) -> [ x[2], u ])           # dynamics of the double integrator

objective!(ocp, :lagrange, (x, u) -> 0.5u^2)    # cost in Lagrange form
nothing # hide
```

!!! note "Nota bene"

    - For details about the syntax used above to describe the optimal control problem, check the [`Model` documentation](@ref api-ctbase-model).
    - You can also define the optimal control problem with an abstract syntax. See for instance [basic example](@ref basic) to compare or for a comprehensive introduction to the abstract syntax, check [this tutorial](@ref tutorial-abstract).

## Solve and plot

We can solve it simply with:

```@example main
sol = solve(ocp)
nothing # hide
```

And plot the solution with:

```@example main
plot(sol)
```

## State constraint

We add the path constraint

```math
x_2(t) \le 1.2.
```

```@example main
constraint!(ocp, :state; rg=2, ub=1.2)
sol = solve(ocp)
plot(sol)
```
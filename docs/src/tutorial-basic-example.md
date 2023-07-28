# [Basic example](@id basic)

Let us consider a wagon moving along a rail, whom acceleration can be controlled by a force $u$.
We denote by $x = (x_1, x_2)$ the state of the wagon, that is its position $x_1$ and its velocity $x_2$.

```@raw html
<img src="./assets/chariot.png" style="display: block; margin: 0 auto 20px auto;" width="300px">
```

We assume that the mass is constant and unitary and that there is no friction. The dynamics is thus given by

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t) \in \mathbb{R},
```

which is simply the [double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674) system.
Les us consider a transfer starting at time $t_0 = 0$ and ending at time $t_f = 1$, for which we want to minimise the transfer energy

```math
    \frac{1}{2}\int_{0}^{1} u^2(t) \, \mathrm{d}t
```

starting from the condition $x(0) = (-1, 0)$ and with the goal to reach the target $x(1) = (0, 0)$.

!!! note "Solution and details"

    See the page 
    [Double integrator: energy minimisation](https://control-toolbox.org/docs/ctproblems/stable/problems/double_integrator_energy.html#DIE) 
    for the analytical solution and details about this problem.

```@setup main
using Plots
using Plots.PlotMeasures
plot(args...; kwargs...) = Plots.plot(args...; kwargs..., leftmargin=20px)
```

First, we need to import the `OptimalControl.jl` package:

```@example main
using OptimalControl
```

Then, we can define the problem

```@example main
t0 = 0
tf = 1

@def ocp begin
    t ∈ [ t0, tf ], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == [-1, 0]
    x(tf) == [0, 0]
    ẋ(t) == A * x(t) + B * u(t)
    ∫( 0.5u(t)^2 ) → min
end

A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
nothing # hide
```

Solve it

```@example main
sol = solve(ocp)
nothing # hide
```

and plot the solution

```@example main
plot(sol, size=(600, 450))
```

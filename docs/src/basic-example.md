# Basic example

Consider we want to minimise the cost functional

```math
    \frac{1}{2}\int_{0}^{1} u^2(t) \, \mathrm{d}t
```

subject to the dynamical constraints for $t \in [0, 1]$

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t) \in \mathbb{R},
```

and the limit conditions

```math
    x(0) = (-1, 0), \quad x(1) = (0, 0).
```

First, we need to import the `OptimalControl.jl` package:

```@example main
using OptimalControl
```

Then, we can define the problem

```@example main
t0 = 0
tf = 1
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]

@def ocp_di begin
    t ∈ [ t0, tf ], time                         # time interval
    x ∈ R², state                                # state
    u ∈ R, control                               # control
    x(t0) == [-1, 0],    (initial_con)           # initial condition
    x(tf) == [0, 0],    (final_con)              # final condition
    ẋ(t) == A * x(t) + B * u(t)                  # dynamics
    ∫( 0.5u(t)^2 ) → min                         # objective
end
nothing # hide
```

Solve it

```@example main
sol_di = solve(ocp_di)
nothing # hide
```

and plot the solution

```@example main
plot(sol_di, size=(700, 700))
```

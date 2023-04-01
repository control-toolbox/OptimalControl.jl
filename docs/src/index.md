# Introduction to the `OptimalControl.jl` package

The `OptimalControl.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox). It aims to provide tools to solve optimal control problems by direct and indirect methods. An optimal control problem can be described as minimising the cost functional

```math
g(t_0, x(t_0), t_f, x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))~\mathrm{d}t
```

where the state $x$ and the control $u$ are functions subject, for $t \in [t_0, t_f]$,
to the differential constraint

```math
   \dot{x}(t) = f(t, x(t), u(t))
```

and other constraints such as

```math
\begin{array}{llcll}
~\xi_l  &\le& \xi(t, u(t))        &\le& \xi_u, \\
\eta_l &\le& \eta(t, x(t))       &\le& \eta_u, \\
\psi_l &\le& \psi(t, x(t), u(t)) &\le& \psi_u, \\
\phi_l &\le& \phi(t_0, x(t_0), t_f, x(t_f)) &\le& \phi_u.
\end{array}
```

**Contents.**

```@contents
Pages = ["index.md", "api.md"]
Depth = 2
```

## Installation

To install a package from the control-toolbox ecosystem, please visit the [installation page](https://github.com/control-toolbox#installation).

## Basic usage

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
ocp = Model()
state!(ocp, 2)   # dimension of the state
control!(ocp, 1) # dimension of the control
time!(ocp, [0, 1]) # time interval
constraint!(ocp, :initial, [-1, 0]) # initial condition
constraint!(ocp, :final,   [0, 0]) # final condition
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u) # dynamics
objective!(ocp, :lagrange, (x, u) -> 0.5u^2) # objective
```

Solve it

```@example main
sol = solve(ocp)
```

and plot the solution

```@example main
plot(sol, size=(700, 700))
```

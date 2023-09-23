# LQR: energy and distance minimisation

The energy and distance minimisation LQR problem consists in minimising

```math
    0.5\int_{0}^{5} x_1^2(t) + x_2^2(t) + u^2(t) \, \mathrm{d}t 
```

subject to the constraints

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = -x_1(t) + u(t), \quad u(t) \in \R
```

and the limit conditions.

```math
    x(0) = (0,1)
```

We define A and B as 

```math
    A = \begin{pmatrix} 0 & 1 \\ -1 & 0 \\ \end{pmatrix}, B = \begin{pmatrix} 0 \\ 1 \\ \end{pmatrix}
```

First, we need to import the `OptimalControl.jl` package:

```@example main
using OptimalControl
```

Then, we can define the problem

```@example main
@def ocp begin
    t0 = 0
    tf = 5
    x0 = [0; 1]
    A = [0 1; -1 0]
    B = [0; 1]
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == x0, initial_con
    ẋ(t) == A * x(t) + B * u(t)
    ∫(0.5 * (x₁(t)^2 + x₂(t)^2 + u(t)^2)) → min
end
nothing # hide
```

Solve it

```@example main
sol = solve(ocp)
nothing # hide
```

and plot the solution

```@example main
plot(sol, size=(700, 450))
```
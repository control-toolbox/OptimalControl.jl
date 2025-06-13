# [How to compute flows](@id manual-flow-others)

```@meta
CollapsedDocStrings = false
```

In this tutorial, we explain the `Flow` function, in particular to compute flows from a Hamiltonian vector fields, but also from general vector fields.

```@docs; canonical=false
Flow
```

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

The **pseudo-Hamiltonian** of this problem is

```math
    H(x, p, u) = p_q\, q + p_v\, v + p^0 u^2 /2,
```

where $p^0 = -1$ since we are in the normal case. From the Pontryagin maximum principle, the maximising control is given in feedback form by

```math
u(x, p) = p_v
```

since $\partial^2_{uu} H = p^0 = - 1 < 0$. 

```@example main
u(x, p) = p[2]
nothing # hide
```

Actually, if $(x, u)$ is a solution of the optimal control problem, 
then, the Pontryagin maximum principle tells us that there exists a costate $p$ such that $u(t) = u(x(t), p(t))$
and such that the pair $(x, p)$ satisfies:

```math
\begin{array}{l}
    \dot{x}(t) = \displaystyle\phantom{-}\nabla_p H(x(t), p(t), u(x(t), p(t))), \\[0.5em]
    \dot{p}(t) = \displaystyle         - \nabla_x H(x(t), p(t), u(x(t), p(t))).
\end{array}
```

The `Flow` function aims to compute $(x, p)$ from the optimal control problem `ocp` and the control in feedback form `u(x, p)`.

!!! note "Nota bene"

    Actually, writing $z = (x, p)$, then the pair $(x, p)$ is also solution of
    
    ```math
        \dot{z}(t) = \vec{\mathbf{H}}(z(t)),
    ```
    where $\mathbf{H}(z) = H(z, u(z))$ and $\vec{\mathbf{H}} = (\nabla_p \mathbf{H}, -\nabla_x \mathbf{H})$. This is what is actually computed by `Flow`.

Let us try to get the associated flow:

```julia
julia> f = Flow(ocp, u)
ERROR: ExtensionError. Please make: julia> using OrdinaryDiffEq
```

As you can see, an error occured since we need the package [OrdinaryDiffEq.jl](https://docs.sciml.ai/DiffEqDocs).
This package provides numerical integrators to compute solutions of the ordinary differential equation 
$\dot{z}(t) = \vec{\mathbf{H}}(z(t))$.

!!! note "OrdinaryDiffEq.jl"

    The package OrdinaryDiffEq.jl is part of [DifferentialEquations.jl](https://docs.sciml.ai/DiffEqDocs). You can either use one or the other.

```@example main
using OrdinaryDiffEq
f = Flow(ocp, u)
nothing # hide
```

Now we have the flow of the associated Hamiltonian vector field, we can use it. Some simple calculations shows that the initial covector $p(0)$ solution of the Pontryagin maximum principle is $[12, 6]$. Let us check that integrating the flow from $(t_0, x_0) = (0, [-1, 0])$ to the final time $t_f$ we reach the target $x_f = [0, 0]$.

```@example main
p0 = [12, 6]
xf, pf = f(t0, x0, p0, tf)
xf
```

## Extremals and trajectories

The pairs $(x, p)$ solution of the Hamitonian vector field are called *extremals*. We can compute some constructing the flow from the optimal control problem and the control in feedback form. Another way to compute extremals is to define explicitely the Hamiltonian.

```@example main
H(x, p, u) = p[1] * x[2] + p[2] * u - 0.5 * u^2     # pseudo-Hamiltonian
H(x, p) = H(x, p, u(x, p))                          # Hamiltonian

z = Flow(Hamiltonian(H))
xf, pf = z(t0, x0, p0, tf)
```

You can also provide the Hamiltonian vector field.

```@example main
Hv(x, p) = [x[2], p[2]], [0.0, -p[1]]     # Hamiltonian vector field

z = Flow(HamiltonianVectorField(Hv))
xf, pf = z(t0, x0, p0, tf)
```

Note that if you call the flow on `tspan=(t0, tf)`, then you obtain the output solution 
from OrdinaryDiffEq.jl.

```@example main
sol = z((t0, tf), x0, p0)
xf, pf = sol(tf)[1:2], sol(tf)[3:4]
```

You can also compute trajectories from the control dynamics $(x, u) \mapsto (v, u)$ and a control law 
$t \mapsto u(t)$.

```@example main
u(t) = 6-12t
x = Flow((t, x) -> [x[2], u(t)]; autonomous=false) # the vector field depends on t
x(t0, x0, tf)
```

Again, giving a `tspan` you get an output solution from OrdinaryDiffEq.jl.

```@example main
sol = x((t0, tf), x0)
plot(sol)
```

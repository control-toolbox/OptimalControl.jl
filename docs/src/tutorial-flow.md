# [How to compute flows](@id manual-flow)

In this tutorial, we explain the `Flow` function from [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package.

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

If you prefer to get the state, costate and control trajectories at any time, you can call the flow like this:

```@example main
sol = f((t0, tf), x0, p0)
nothing # hide
```

In this case, you obtain a data that you can plot exactly like when solving the optimal control problem 
with the function `solve`. See for instance the [basic example](@ref tutorial-basic-solve-plot) or the 
[plot tutorial](@ref tutorial-plot).

```@example main
using Plots
plot(sol)
```

You can notice from the graph of `v` that the integrator has made very few steps:

```@example main
time_grid(sol)
```

!!! note "Time grid"

    The function [`time_grid`](@ref) returns the discretized time grid returned by the solver. In this case, the solution has been computed by numerical integration with an adaptive step-length Runge-Kutta scheme.

To have a better visualisation (the accuracy won't change), you can provide a fine grid.

```@example main
sol = f((t0, tf), x0, p0; saveat=range(t0, tf, 100))
plot(sol)
```

The argument `saveat` is an option from OrdinaryDiffEq.jl. Please check the 
[list of common options](https://docs.sciml.ai/DiffEqDocs/stable/basics/common_solver_opts/#solver_options).
For instance, one can change the integrator with the keyword argument `alg` or the absolute tolerance with 
`abstol`. Note that you can set an option when declaring the flow or set an option in a particular call of the flow. 
In the following example, the integrator will be `BS5()` and the absolute tolerance will be `abstol=1e-8`.

```@example main
f = Flow(ocp, u; alg=BS5(), abstol=1)   # alg=BS5(), abstol=1
xf, pf = f(t0, x0, p0, tf; abstol=1e-8) # alg=BS5(), abstol=1e-8
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

## Non-autonomous case

Let us consider the following optimal control problem:

```@example main
t0 = 0
tf = π/4
x0 = 0
xf = tan(π/4) - 2log(√(2)/2)

ocp = @def begin

    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == u(t) * (1 + tan(t)) # The dynamics depend explicitly on t

    0.5∫( u(t)^2 ) → min

end
nothing # hide
```

The **pseudo-Hamiltonian** of this problem is

```math
    H(t, x, p, u) = p\, u\, (1+\tan\, t) + p^0 u^2 /2,
```

where $p^0 = -1$ since we are in the normal case. From the Pontryagin maximum principle, the maximising control is given in feedback form by

```math
u(t, x, p) = p\, (1+\tan\, t)
```

since $\partial^2_{uu} H = p^0 = - 1 < 0$. 

```@example main
u(t, x, p) = p * (1 + tan(t))
nothing # hide
```

As before, the `Flow` function aims to compute $(x, p)$ from the optimal control problem `ocp` and the control in feedback form `u(t, x, p)`. However, we must indicate that the control depends on $t$, that is it is non-autonomous.

```@example main
f = Flow(ocp, u; autonomous=false)
nothing # hide
```

Now we have the flow of the associated Hamiltonian vector field, we can use it. Some simple calculations shows that the initial covector $p(0)$ solution of the Pontryagin maximum principle is $1$. Let us check that integrating the flow from $(t_0, x_0) = (0, 0)$ to the final time $t_f = \pi/4$ we reach the target $x_f = \tan(\pi/4) - 2 \log(\sqrt{2}/2)$.

```@example main
p0 = 1
xf, pf = f(t0, x0, p0, tf)
xf - (tan(π/4) - 2log(√(2)/2))
```

## Variable

Let us consider an optimal control problem with a (decision / optimisation) variable.

```@example main
t0 = 0
x0 = 0

ocp = @def begin

    tf ∈ R, variable             # the optimisation variable is tf
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0
    x(tf) == 1
    
    ẋ(t) == tf * u(t)

    tf + 0.5∫(u(t)^2) → min

end
nothing # hide
```

As you can see, the variable is the final time `tf`. Note that the dynamics depends on `tf`.
From the Pontryagin maximum principle, the solution is given by:

```@example main
tf = (3/2)^(1/4)
p0 = 2tf/3
nothing # hide
```

The input arguments of the maximising control are now the state `x`, the costate `p` and the variable `tf`.

```@example main
u(x, p, tf) = tf * p
nothing # hide
```

Let us check that the final condition `x(tf) = 1` is satisfied.

```@example main
f = Flow(ocp, u)
xf, pf = f(t0, x0, p0, tf, tf)
```

The usage of the flow `f` is the following: `f(t0, x0, p0, tf, v)` where `v` is the variable. If one wants
to compute the state at time `t1 = 0.5`, then, one must write:

```@example main
t1 = 0.5
x1, p1 = f(t0, x0, p0, t1, tf)
```

!!! note "Free times"

    In the particular cases: the initial time `t0` is the only variable, the final time `tf` is the only variable, or the initial and final times `t0` and `tf` are the only variables and are in order `v=(t0, tf)`, the times do not need to be repeated in the call of the flow:

    ```@example main
    xf, pf = f(t0, x0, p0, tf)
    ```

Since the variable is the final time, we can make the time-reparameterisation $t = s\, t_f$ to normalise
the time $s$ in $[0, 1]$.

```@example main
ocp = @def begin

    tf ∈ R, variable
    s ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control

    x(0) == 0
    x(1) == 1
    
    ẋ(s) == tf^2 * u(s)

    tf + (0.5*tf)*∫(u(s)^2) → min

end

f = Flow(ocp, u)
xf, pf = f(0, x0, p0, 1, tf)
```

Another possibility is to add a new state variable $t_f(s)$. The problem has no variable anymore.

```@example main
ocp = @def begin

    s ∈ [0, 1], time
    y = (x, tf) ∈ R², state
    u ∈ R, control

    x(0) == 0
    x(1) == 1

    dx = tf(s)^2 * u(s)
    dtf = 0 * u(s) # 0
    ẏ(s) == [dx, dtf]

    tf(1) + 0.5∫(tf(s) * u(s)^2) → min

end

u(y, q) = y[2] * q[1]

f = Flow(ocp, u)
yf, pf = f(0, [x0, tf], [p0, 0], 1)
```

!!! danger "Bug"

    Note that in the previous optimal control problem, we have `dtf = 0 * u(s)` instead of `dtf = 0`. The latter does not work.

!!! note "Goddard problem"

    In the [Goddard problem](https://control-toolbox.org/Tutorials.jl/stable/tutorial-goddard.html#tutorial-goddard-structure), you may find other constructions of flows, especially for singular and boundary arcs.


## Concatenation of arcs

In this part, we present how to concatenate several flows. Let us consider the following problem.

```@example main
t0 =  0
tf =  1
x0 = -1
xf =  0

@def ocp begin

    t ∈ [ t0, tf ], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    -1 ≤ u(t) ≤ 1

    ẋ(t) == -x(t) + u(t)

    ∫( abs(u(t)) ) → min

end
nothing # hide
```

From the Pontryagin maximum principle, the optimal control is a concatenation of an off arc ($u=0$) followed by a 
positive bang arc ($u=1$). The initial costate is 

```math
p_0 = \frac{1}{x_0 - (x_f-1) e^{t_f}}
```

and the switching time is $t_1 = -\ln(p_0)$.

```@example main
p0 = 1/( x0 - (xf-1) * exp(tf) )
t1 = -log(p0)
nothing  # hide
```

Let us define the two flows and the concatenation. Note that the concatenation of two flows is a flow.

```@example main
f0 = Flow(ocp, (x, p) -> 0)     # off arc: u = 0
f1 = Flow(ocp, (x, p) -> 1)     # positive bang arc: u = 1

f = f0 * (t1, f1)               # f0 followed by f1 whenever t ≥ t1
nothing # hide
```

Now, we can check that the state reach the target.

```@example main
sol = f((t0, tf), x0, p0)
plot(sol)
```

!!! note "Goddard problem"

    In the [Goddard problem](https://control-toolbox.org/Tutorials.jl/stable/tutorial-goddard.html#tutorial-goddard-plot), you may find more complex concatenations.

For the moment, this concatenation is not equivalent to an exact concatenation.

```@example main
f = Flow(x ->  x)
g = Flow(x -> -x)

x0 = 1
φ(t) = (f * (t/2, g))(0, x0, t)
ψ(t) = g(t/2, f(0, x0, t/2), t)

println("φ(t) = ", abs(φ(1)-x0))
println("ψ(t) = ", abs(ψ(1)-x0))

t = range(1, 5e2, 201)

plt = plot(yaxis=:log, legend=:bottomright, title="Comparison of concatenations", xlabel="t")
plot!(plt, t, t->abs(φ(t)-x0), label="OptimalControl")
plot!(plt, t, t->abs(ψ(t)-x0), label="Classical")
```

## State constraints

We consider an optimal control problem with a state constraints of order 1.[^1] 

[^1]: B. Bonnard, L. Faubourg, G. Launay & E. Tr´elat, Optimal Control With State Constraints And The Space Shuttle Re-entry Problem, J. Dyn. Control Syst., 9 (2003), no. 2, 155–199.

```@example main
t0 = 0
tf = 2
x0 = 1
xf = 1/2
lb = 0.1

ocp = @def begin

    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1

    x(t0) == x0
    x(tf) == xf

    x(t) - lb ≥ 0           # state constraint

    ẋ(t) == u(t)

    ∫( x(t)^2 ) → min

end
nothing # hide
```

The **pseudo-Hamiltonian** of this problem is

```math
    H(t, x, p, u, \eta) = p\, u + p^0 x^2 + \eta\, c(x),
```

where $ p^0 = -1 $ since we are in the normal case, and where $c(x) = x - l_b$. Along a boundary arc, when $c(x(t)) = 0$, we have $x(t) = l_b$, so $ x(\cdot) $ is constant. Differentiating, we obtain $\dot{x}(t) = u(t) = 0$. Hence, along a boundary arc, the control in feedback form is:


```math
u(x, p) = 0.
```

From the maximizing condition, along a boundary arc, we have $p(t) = 0$. Differentiating, we obtain $\dot{p}(t) = 2 x(t) - \eta(t) = 0$. Hence, along a boundary arc, the dual variable $\eta$ is given in feedback form by:

```math
\eta(x, p) = 2x.
```

The optimal control is a concatenation of 3 arcs: a negative bang arc followed by a boundary arc, followed by a positive bang arc. The initial covector is approximately $-0.982237546583301$, the first switching time is $t_1 = 0.9$, and the exit time of the boundary is $t_2 = 1.6$. Let us check this by concatenating the three flows.

```@example main
u(x, p) = 0     # boundary control
c(x, u) = x-lb  # constraint
η(x, p) = 2x    # dual variable

f1 = Flow(ocp, (x, p) -> -1)
f2 = Flow(ocp, u, c, η)
f3 = Flow(ocp, (x, p) -> +1)

t1 = 0.9
t2 = 1.6
f = f1 * (t1, f2) * (t2, f3)

p0 = -0.982237546583301
xf, pf = f(t0, x0, p0, tf)
xf
```

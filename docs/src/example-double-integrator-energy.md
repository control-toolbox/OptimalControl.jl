# [Double integrator: energy minimisation](@id example-double-integrator-energy)

Let us consider a wagon moving along a rail, whose acceleration can be controlled by a force $u$.
We denote by $x = (x_1, x_2)$ the state of the wagon, where $x_1$ is the position and $x_2$ the velocity.

```@raw html
<img src="./assets/chariot.svg" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

We assume that the mass is constant and equal to one, and that there is no friction. The dynamics are given by

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t),\quad u(t) \in \R,
```

which is simply the [double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674) system. Let us consider a transfer starting at time $t_0 = 0$ and ending at time $t_f = 1$, for which we want to minimise the transfer energy

```math
    \frac{1}{2}\int_{0}^{1} u^2(t) \, \mathrm{d}t
```

starting from $x(0) = (-1, 0)$ and aiming to reach the target $x(1) = (0, 0)$.

First, we need to import the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package to define the optimal control problem, [NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl) to solve it, and [Plots.jl](https://docs.juliaplots.org) to visualise the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Optimal control problem

Let us define the problem with the [`@def`](@ref) macro:

```@raw html
<div class="responsive-columns-left-priority">
<div>
```

```@example main
t0 = 0
tf = 1
x0 = [-1, 0]
xf = [0, 0]
ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == xf
    ẋ(t) == [x₂(t), u(t)]
    0.5∫( u(t)^2 ) → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

### Mathematical formulation

```math
    \begin{aligned}
        & \text{Minimise} && \frac{1}{2}\int_0^1 u^2(t) \,\mathrm{d}t \\
        & \text{subject to} \\
        & && \dot{x}_1(t) = x_2(t), \\[0.5em]
        & && \dot{x}_2(t) = u(t), \\[1.0em]
        & && x(0) = (-1,0), \\[0.5em] 
        & && x(1) = (0,0).
    \end{aligned}
```

```@raw html
</div>
</div>
```

!!! note "Nota bene"

    For a comprehensive introduction to the syntax used above to define the optimal control problem, see [this abstract syntax tutorial](@ref manual-abstract-syntax). In particular, non-Unicode alternatives are available for derivatives, integrals, *etc.*

## [Solve and plot](@id example-double-integrator-energy-solve-plot)

### Direct method

We can [`solve`](@ref) it simply with:

```@example main
sol = solve(ocp)
nothing # hide
```

And [`plot`](@ref) the solution with:

```@example main
plot(sol)
```

!!! note "Nota bene"

    The `solve` function has options, see the [solve tutorial](@ref manual-solve). You can customise the plot, see the [plot tutorial](@ref manual-plot).

### Indirect method

The first solution was obtained using the so-called direct method.[^1] Another approach is to use an [indirect simple shooting](@extref tutorial-indirect-simple-shooting) method. We begin by importing the necessary packages.

```@example main
using OrdinaryDiffEq # Ordinary Differential Equations (ODE) solver
using NonlinearSolve # Nonlinear Equations (NLE) solver
```

To define the shooting function, we must provide the maximising control in feedback form:

```@example main
# maximising control, H(x, p, u) = p₁x₂ + p₂u - u²/2
u(x, p) = p[2]

# Hamiltonian flow
f = Flow(ocp, u)

# state projection, p being the costate
π((x, p)) = x

# shooting function
S(p0) = π( f(t0, x0, p0, tf) ) - xf
nothing # hide
```

We are now ready to solve the shooting equations.

```@example main
# auxiliary in-place NLE function
nle!(s, p0, λ) = s[:] = S(p0)

# initial guess for the Newton solver
p0_guess = [1, 1]

# NLE problem with initial guess
prob = NonlinearProblem(nle!, p0_guess)

# resolution of S(p0) = 0
sol = solve(prob; show_trace=Val(true))
p0_sol = sol.u # costate solution

# print the costate solution and the shooting function evaluation
println("\ncostate: p0 = ", p0_sol)
println("shoot: S(p0) = ", S(p0_sol), "\n")
```

To plot the solution obtained by the indirect method, we need to build the solution of the optimal control problem. This is done using the costate solution and the flow function.

```@example main
sol = f((t0, tf), x0, p0_sol; saveat=range(t0, tf, 100))
plot(sol)
```

[^1]: J. T. Betts. Practical methods for optimal control using nonlinear programming. Society for Industrial and Applied Mathematics (SIAM), Philadelphia, PA, 2001.

!!! note

    - You can use [MINPACK.jl](@extref Tutorials Resolution-of-the-shooting-equation) instead of [NonlinearSolve.jl](https://docs.sciml.ai/NonlinearSolve).
    - For more details about the flow construction, visit the [Compute flows from optimal control problems](@ref manual-flow-ocp) page.
    - In this simple example, we have set an arbitrary initial guess. It can be helpful to use the solution of the direct method to initialise the shooting method. See the [Goddard tutorial](@extref Tutorials tutorial-goddard) for such a concrete application.

## State constraint

### Direct method: constrained case

We add the path constraint

```math
    x_2(t) \le 1.2.
```

Let us model, solve and plot the optimal control problem with this constraint.

```@example main
# the upper bound for x₂
a = 1.2

# the optimal control problem
ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x₂(t) ≤ a
    x(t0) == x0
    x(tf) == xf
    ẋ(t) == [x₂(t), u(t)]
    0.5∫( u(t)^2 ) → min
end

# solve with a direct method using default settings
sol = solve(ocp)

# plot the solution
plt = plot(sol; label="Direct", size=(800, 600))
```

### Indirect method: constrained case

The pseudo-Hamiltonian is (considering the normal case):

```math
H(x, p, u, \mu) = p_1 x_2 + p_2 u - \frac{u^2}{2} + \mu\, c(x),
```

with $c(x) = x_2 - a$. Along a boundary arc we have $c(x(t)) = 0$. Differentiating, we obtain:

```math
    \frac{\mathrm{d}}{\mathrm{d}t}c(x(t)) = \dot{x}_2(t) = u(t) = 0.
```

The zero control is maximising; hence, $p_2(t) = 0$ along the boundary arc.

```math
    \dot{p}_2(t) = -p_1(t) - \mu(t) \quad \Rightarrow \mu(t) = -p_1(t).
```

Since the adjoint vector is continuous at the entry time $t_1$ and the exit time $t_2$, we have four unknowns: the initial costate $p_0 \in \mathbb{R}^2$ and the times $t_1$ and $t_2$. We need four equations: the target condition provides two, reaching the constraint at time $t_1$ gives $c(x(t_1)) = 0$, and finally $p_2(t_1) = 0$.

```@example main
# flow for unconstrained extremals
f = Flow(ocp, (x, p) -> p[2])

ub = 0          # boundary control
c(x) = x[2]-a   # constraint: c(x) ≥ 0
μ(p) = -p[1]    # dual variable

# flow for boundary extremals
g = Flow(ocp, (x, p) -> ub, (x, u) -> c(x), (x, p) -> μ(p))

# shooting function
function shoot!(s, p0, t1, t2)
    x_t0, p_t0 = x0, p0
    x_t1, p_t1 = f(t0, x_t0, p_t0, t1)
    x_t2, p_t2 = g(t1, x_t1, p_t1, t2)
    x_tf, p_tf = f(t2, x_t2, p_t2, tf)
    s[1:2] = x_tf - xf
    s[3] = c(x_t1)
    s[4] = p_t1[2]
end
nothing # hide
```

We are now ready to solve the shooting equations.

```@example main
# auxiliary in-place NLE function
nle!(s, ξ, λ) = shoot!(s, ξ[1:2], ξ[3], ξ[4])

# initial guess for the Newton solver
ξ_guess = [40, 10, 0.25, 0.75]

# NLE problem with initial guess
prob = NonlinearProblem(nle!, ξ_guess)

# resolution of the shooting equations
sol = solve(prob; show_trace=Val(true))
p0, t1, t2 = sol.u[1:2], sol.u[3], sol.u[4]

# print the costate solution and the entry and exit times
println("\np0 = ", p0, "\nt1 = ", t1, "\nt2 = ", t2)
```

To reconstruct the trajectory obtained with the state constraint, we concatenate the flows: one unconstrained arc up to the entry time $t_1$, a boundary arc between $t_1$ and $t_2$, and finally another unconstrained arc up to $t_f$.  
This concatenation allows us to compute the complete solution — state, costate, and control — which we can then plot together with the direct solution for comparison.

```@example main
# concatenation of the flows
φ = f * (t1, g) * (t2, f)

# compute the solution: state, costate, control...
flow_sol = φ((t0, tf), x0, p0; saveat=range(t0, tf, 100))      

# plot the solution on the previous plot
plot!(plt, flow_sol; label="Indirect", color=2, linestyle=:dash)
```

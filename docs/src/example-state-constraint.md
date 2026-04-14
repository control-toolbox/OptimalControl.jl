# [State constraint](@id example-state-constraint)

```@meta
Draft = false
```

This example illustrates how state constraints of different orders affect the structure of optimal solutions for the double integrator energy minimization problem. It demonstrates both direct and indirect solution approaches. Some examples with state constraints of different orders are solved analytically in Bryson et al.[^1] and Jacobson et al.[^2].

Let us consider a wagon moving along a rail, whose acceleration can be controlled by a force $u$.
We denote by $x = (q, v)$ the state of the wagon, where $q$ is the position and $v$ the velocity.

```@raw html
<img src="./assets/chariot_q.svg" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

We assume that the mass is constant and equal to one, and that there is no friction. The dynamics are given by

```math
    \dot q(t) = v(t), \quad \dot v(t) = u(t),\quad u(t) \in \R,
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
t0 = 0; tf = 1; x0 = [-1, 0]; xf = [0, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

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
        & && \dot{x}(t) = [v(t), u(t)], \\[1.0em]
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

## First-order state constraint

We now add a path constraint on the maximal velocity:

```math
    v(t) \le 1.2.
```

This is a **first-order state constraint**: differentiating $g(x) = v_{\max} - v$ once already makes the control appear,

```math
    \frac{\mathrm{d}}{\mathrm{d}t}g(x(t)) = -\dot{v}(t) = -u(t),
```

which fixes $u = 0$ on the boundary arc.

The workflow demonstrates a practical strategy: a direct method on a coarse grid first identifies the problem structure and provides an initial guess for the indirect method, which then computes a precise solution via shooting based on Pontryagin's Maximum Principle.

!!! note

    The direct solution can be refined using a finer discretization grid for higher accuracy.

### Direct method: constrained case

Let us model, solve and plot the optimal control problem with this constraint.

```@example main
# the upper bound for v
v_max = 1.2

# the optimal control problem
ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    v(t) ≤ v_max    # state constraint

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫( u(t)^2 ) → min
end

# solve with a direct method
direct_sol = solve(ocp; grid_size=50)

# plot the solution
plt = plot(direct_sol; label="Direct", size=(800, 600))
```

The solution has three phases (unconstrained-constrained-unconstrained arcs), requiring definition of Hamiltonian flows for each phase and a shooting function to enforce boundary and switching conditions.

### Indirect method: constrained case

Under the normal case, the pseudo-Hamiltonian reads:

```math
H(x, p, u, \mu) = p_1 v + p_2 u - \frac{u^2}{2} + \mu\, g(x),
```

where $g(x) = v_{\max} - v$. Along a boundary arc we have $g(x(t)) = 0$; differentiating gives:

```math
    \frac{\mathrm{d}}{\mathrm{d}t}g(x(t)) = -\dot{v}(t) = -u(t) = 0.
```

The zero control maximises the Hamiltonian, so $p_2(t) = 0$ along that arc. From the adjoint equation we then have

```math
    \dot{p}_2(t) = -p_1(t) + \mu(t) = 0 \quad \Rightarrow \mu(t) = p_1(t).
```

Because the adjoint vector is continuous at both the entry time $t_1$ and the exit time $t_2$, the unknowns are $p_0 \in \mathbb{R}^2$ together with $t_1$ and $t_2$. The target condition supplies two equations, $g(x(t_1)) = 0$ enforces the state constraint, and $p_2(t_1) = 0$ encodes the switching condition.

```@example main
using OrdinaryDiffEq # Ordinary Differential Equations (ODE) solver
using NonlinearSolve # Nonlinear Equations (NLE) solver

# flow for unconstrained extremals
f_interior = Flow(ocp, (x, p) -> p[2])

ub = 0              # boundary control
g(x) = v_max - x[2] # constraint: g(x) ≥ 0
μ(p) = p[1]         # dual variable

# flow for boundary extremals
f_boundary = Flow(ocp, (x, p) -> ub, (x, u) -> g(x), (x, p) -> μ(p))

# shooting function
function shoot!(s, p0, t1, t2)
    x_t0, p_t0 = x0, p0
    x_t1, p_t1 = f_interior(t0, x_t0, p_t0, t1)
    x_t2, p_t2 = f_boundary(t1, x_t1, p_t1, t2)
    x_tf, p_tf = f_interior(t2, x_t2, p_t2, tf)
    s[1:2] = x_tf - xf
    s[3] = g(x_t1)
    s[4] = p_t1[2]
end
nothing # hide
```

We can derive an initial guess for the costate and the entry/exit times from the direct solution:

```@example main
t = time_grid(direct_sol) # the time grid as a vector
x = state(direct_sol)     # the state as a function of time
p = costate(direct_sol)   # the costate as a function of time

# initial costate
p0 = p(t0)

# times where constraint is active
t12 = t[ 0 .≤ (g ∘ x).(t) .≤ 1e-3 ]

# entry and exit times
t1 = minimum(t12) # entry time
t2 = maximum(t12) # exit time
nothing # hide
```

We can now solve the shooting equations.

```@example main
# auxiliary in-place NLE function
nle!(s, ξ, _) = shoot!(s, ξ[1:2], ξ[3], ξ[4])

# initial guess for the Newton solver
ξ_guess = [p0..., t1, t2]

# NLE problem with initial guess
prob = NonlinearProblem(nle!, ξ_guess)

# resolution of the shooting equations
shooting_sol = solve(prob; show_trace=Val(true))
p0, t1, t2 = shooting_sol.u[1:2], shooting_sol.u[3], shooting_sol.u[4]

# print the costate solution and the entry and exit times
println("\np0 = ", p0, "\nt1 = ", t1, "\nt2 = ", t2)
```

To reconstruct the constrained trajectory, concatenate the flows as follows: an unconstrained arc until $t_1$, a boundary arc from $t_1$ to $t_2$, and a final unconstrained arc from $t_2$ to $t_f$.  
This composition yields the full solution (state, costate, and control), which we then plot alongside the direct method for comparison.

```@example main
# concatenation of the flows
φ = f_interior * (t1, f_boundary) * (t2, f_interior)

# compute the solution: state, costate, control...
indirect_sol = φ((t0, tf), x0, p0; saveat=range(t0, tf, 100))      

# plot the solution on the previous plot
plot!(plt, indirect_sol; label="Indirect", color=2, linestyle=:dash)
```

!!! note

    - You can use [MINPACK.jl](@extref Tutorials Resolution-of-the-shooting-equation) instead of [NonlinearSolve.jl](https://docs.sciml.ai/NonlinearSolve).
    - For more details about the flow construction, visit the [Compute flows from optimal control problems](@ref manual-flow-ocp) page.
    - For the unconstrained version of this problem, see the [Energy minimisation](@ref example-double-integrator-energy) example.

## Second-order state constraint

We now consider the same double integrator with different boundary conditions and a constraint on the **position** $x_1 = q$:[^1]

```math
    q(t) \le a.
```

The boundary conditions are $x(0) = (0, 1)$ and $x(1) = (0, -1)$.

This is a **second-order state constraint**: the control $u$ appears only after differentiating $g(x) = a - q$ twice,

```math
    \frac{\mathrm{d}}{\mathrm{d}t}g(x(t)) = -\dot{q}(t) = -v(t) \quad \text{(no control)},
```

```math
    \frac{\mathrm{d}^2}{\mathrm{d}t^2}g(x(t)) = -\dot{v}(t) = -u(t) \quad \text{(control appears)}.
```

On a boundary arc where $g(x(t)) = 0$, both derivatives must vanish, forcing $v(t) = 0$ and $u(t) = 0$.

### Solution structure

The unconstrained optimal trajectory for these boundary conditions is $q(t) = t - t^2$, which reaches its maximum $1/4$ at $t = 1/2$. A characteristic feature of second-order state constraints is the existence of an intermediate regime between the unconstrained and boundary-arc cases[^3]. The solution structure depends on $a$:

- **Unconstrained** ($a \ge 1/4$): the constraint is never active
- **Touch point** ($1/6 \le a \le 1/4$): the trajectory touches $q = a$ at a single instant, without sliding along the boundary
- **Boundary arc** ($a < 1/6$): the trajectory remains on $q = a$ for a finite time interval, during which $v(t) = 0$ and $u(t) = 0$

### Direct method

We compare the two constrained cases using the direct method, taking $a = 1/5$ (touch point) and $a = 1/7$ (boundary arc).

```@example main
# new boundary conditions
x0_bd = [0.0, 1.0]; xf_bd = [0.0, -1.0]

# Case 1: touch point (a = 1/5, in range [1/6, 1/4])
a_touch = 1/5

ocp_touch = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    q(t) ≤ a_touch

    x(t0) == x0_bd
    x(tf) == xf_bd

    ẋ(t) == [v(t), u(t)]

    0.5∫( u(t)^2 ) → min
end

sol_touch = solve(ocp_touch; grid_size=100, display=false)
nothing # hide
```

```@example main
# Case 2: boundary arc (a = 1/7, below 1/6)
a_arc = 1/7

ocp_arc = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    q(t) ≤ a_arc

    x(t0) == x0_bd
    x(tf) == xf_bd

    ẋ(t) == [v(t), u(t)]

    0.5∫( u(t)^2 ) → min
end

sol_arc = solve(ocp_arc; grid_size=100, display=false)
nothing # hide
```

```@example main
plt_bd = plot(sol_touch; label="Touch point (a = 1/5)", size=(800, 600))
plot!(plt_bd, sol_arc;  label="Boundary arc (a = 1/7)", color=2, linestyle=:dash)
```

[^1]: Bryson, A.E., Denham, W.F., & Dreyfus, S.E. (1963). *Optimal programming problems with inequality constraints I: necessary conditions for extremal solutions*. AIAA Journal, 1(11), 2544–2550. [doi.org/10.2514/3.2107](https://doi.org/10.2514/3.2107)

[^2]: Jacobson, D.H., Lele, M.M., & Speyer, J.L. (1971). *New necessary conditions of optimality for control problems with state-variable inequality constraints*. Journal of Mathematical Analysis and Applications, 35, 255–284.

[^3]: Bryson, A.E. & Ho, Y.-C. (1975). *Applied Optimal Control: Optimization, Estimation and Control*. CRC Press.

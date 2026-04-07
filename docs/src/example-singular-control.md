# [Singular control](@id example-singular-control)

For control-affine systems of the form

```math
\dot{q}(t) = f_0(q(t)) + u(t) f_1(q(t)), \quad u(t) \in [u_{\min}, u_{\max}],
```

the pseudo-Hamiltonian is $H = H_0 + u H_1$, where $H_i(q, p) = \langle p, f_i(q) \rangle$ are the Hamiltonian lifts of the vector fields $f_0$ and $f_1$.

When the **switching function** $H_1$ vanishes on a time interval (i.e., $H_1(q(t), p(t)) = 0$ for $t \in [t_1, t_2]$), the arc is called **singular**. On such arcs, the control cannot be determined directly from the maximization condition and must be computed by successive differentiation of $H_1$ along the flow.

This page demonstrates how to compute singular controls both by hand and using differential geometry tools from OptimalControl.jl, then verifies the result numerically using direct and indirect methods.

First, we import the necessary packages:

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Problem definition

We consider a vehicle moving in the plane with drift. The state is $q = (x, y, \theta)$ where $(x, y)$ is the position and $\theta$ is the orientation. The dynamics are:

```math
\dot{x}(t) = \cos\theta(t), \quad \dot{y}(t) = \sin\theta(t) + x(t), \quad \dot{\theta}(t) = u(t),
```

with control constraint $u(t) \in [-1, 1]$.

We want to find the time-optimal transfer from the origin $(0, 0)$ with free initial orientation to the target position $(1, 0)$ with free final orientation:

```@example main
ocp = @def begin
    
    tf ∈ R, variable
    t ∈ [0, tf], time
    q = (x, y, θ) ∈ R³, state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1                     # Control bounds
    -π/2 ≤ θ(t) ≤ π/2                 # State bounds (helps direct method convergence)

    x(0) == 0
    y(0) == 0
    x(tf) == 1
    y(tf) == 0

    ∂(q)(t) == [cos(θ(t)), sin(θ(t)) + x(t), u(t)]

    tf → min

end
nothing # hide
```

This is a control-affine system with:

```math
f_0(q) = \begin{pmatrix} \cos\theta \\ \sin\theta + x \\ 0 \end{pmatrix}, \quad
f_1(q) = \begin{pmatrix} 0 \\ 0 \\ 1 \end{pmatrix}.
```

## Direct method

We solve the problem using a direct method:

```@example main
direct_sol = solve(ocp; display=false)
println("Optimal time: tf = ", variable(direct_sol))
nothing # hide
```

Let's plot the solution:

```@example main
opt = (state_bounds_style=:none, control_bounds_style=:none)
plt = plot(direct_sol; label="Direct", size=(800, 800), opt...)
```

## Singular control by hand

The pseudo-Hamiltonian for this time-optimal problem is:

```math
H(q, p, u) = p_1 \cos\theta + p_2(\sin\theta + x) + p_3 u.
```

This is control-affine: $H = H_0 + u H_1$ with:

```math
H_0(q, p) = p_1 \cos\theta + p_2(\sin\theta + x), \quad H_1(q, p) = p_3.
```

The switching function is $H_1 = p_3$. On a singular arc, we have $H_1 = 0$ and all its time derivatives must vanish.

**First derivative:**

```math
\dot{H}_1 = \{H, H_1\} = \{H_0, H_1\} =: H_{01}.
```

Computing the Poisson bracket:

```math
H_{01} = \frac{\partial H_0}{\partial p_1} \frac{\partial H_1}{\partial x} - \frac{\partial H_0}{\partial x} \frac{\partial H_1}{\partial p_1}
       + \frac{\partial H_0}{\partial p_2} \frac{\partial H_1}{\partial y} - \frac{\partial H_0}{\partial y} \frac{\partial H_1}{\partial p_2}
       + \frac{\partial H_0}{\partial p_3} \frac{\partial H_1}{\partial \theta} - \frac{\partial H_0}{\partial \theta} \frac{\partial H_1}{\partial p_3}.
```

Since $H_1 = p_3$ depends only on $p_3$, the only non-zero contribution comes from the $(\theta, p_3)$ pair:

```math
H_{01} = \frac{\partial H_0}{\partial \theta} \frac{\partial H_1}{\partial p_3} - \frac{\partial H_0}{\partial p_3} \frac{\partial H_1}{\partial \theta} = (-p_1 \sin\theta + p_2 \cos\theta) \cdot 1 - 0 = -p_1 \sin\theta + p_2 \cos\theta.
```

On the singular arc, $H_{01} = 0$, which gives the constraint:

```math
p_2 \cos\theta = p_1 \sin\theta.
```

**Second derivative:**

```math
\dot{H}_{01} = \{H, H_{01}\} = \{H_0, H_{01}\} + u \{H_1, H_{01}\} =: H_{001} + u H_{101}.
```

For the arc to remain singular, $\dot{H}_{01} = 0$, which gives:

```math
u_s = -\frac{H_{001}}{H_{101}},
```

whenever $H_{101} \neq 0$. Computing $H_{001} = \{H_0, H_{01}\}$ with $H_{01} = -p_1 \sin\theta + p_2 \cos\theta$, the only non-zero contribution comes from the $(x, p_1)$ pair:

```math
H_{001} = \frac{\partial H_0}{\partial x} \frac{\partial H_{01}}{\partial p_1} - \frac{\partial H_0}{\partial p_1} \frac{\partial H_{01}}{\partial x} = p_2 \cdot (-\sin\theta) - \cos\theta \cdot 0 = -p_2 \sin\theta.
```

Computing $H_{101} = \{H_1, H_{01}\}$ with $H_1 = p_3$ and $H_{01} = -p_1 \sin\theta + p_2 \cos\theta$, the only non-zero contribution comes from the $(\theta, p_3)$ pair:

```math
H_{101} = \frac{\partial H_1}{\partial \theta} \frac{\partial H_{01}}{\partial p_3} - \frac{\partial H_1}{\partial p_3} \frac{\partial H_{01}}{\partial \theta} = 0 - 1 \cdot (-p_1 \cos\theta - p_2 \sin\theta) = p_1 \cos\theta + p_2 \sin\theta.
```

Therefore:

```math
u_s = -\frac{H_{001}}{H_{101}} = \frac{p_2 \sin\theta}{p_1 \cos\theta + p_2 \sin\theta}.
```

!!! note "Non-degeneracy condition"

    We can show that $H_{101} \neq 0$ on the singular arc. From the constraint $p_1 \sin\theta = p_2 \cos\theta$, if we had $H_{101} = p_1 \cos\theta + p_2 \sin\theta = 0$, then:

    ```math
    \begin{pmatrix} \cos\theta & \sin\theta \\ -\sin\theta & \cos\theta \end{pmatrix}
    \begin{pmatrix} p_1 \\ p_2 \end{pmatrix} = \begin{pmatrix} 0 \\ 0 \end{pmatrix}.
    ```

    Since this matrix has determinant 1 (hence is invertible), we would have $p_1 = p_2 = 0$. Combined with $p_3 = 0$ (from $H_1 = 0$), this gives $p = 0$, which is impossible for a time-minimization problem.

**Simplification using the constraint:**

Multiply numerator and denominator by $\sin\theta$:

```math
u_s = \frac{p_2 \sin^2\theta}{p_1 \cos\theta \sin\theta + p_2 \sin^2\theta}.
```

From the constraint $p_1 \sin\theta = p_2 \cos\theta$, we have $p_1 \cos\theta \sin\theta = p_2 \cos^2\theta$. Substituting in the denominator:

```math
u_s = \frac{p_2 \sin^2\theta}{p_2 \cos^2\theta + p_2 \sin^2\theta} = \frac{p_2 \sin^2\theta}{p_2(\cos^2\theta + \sin^2\theta)} = \sin^2\theta.
```

So the singular control is:

```math
u_s(\theta) = \sin^2\theta.
```

Let's overlay this on the numerical solution:

```@example main
T = time_grid(direct_sol)
θ(t) = state(direct_sol)(t)[3]
us(t) = sin(θ(t))^2
plot!(plt, T, us; subplot=7, line=:dash, lw=2, label="us (hand)")
plot(plt[7]; size=(800, 400))
```

## Singular control via Poisson brackets

We can compute the same result using the differential geometry tools from OptimalControl.jl. See the [differential geometry tools manual](@ref manual-differential-geometry) for detailed explanations.

First, define the vector fields:

```@example main
F0(q) = [cos(q[3]), sin(q[3]) + q[1], 0]
F1(q) = [0, 0, 1]
nothing # hide
```

Compute their Hamiltonian lifts:

```@example main
H0 = Lift(F0)
H1 = Lift(F1)
nothing # hide
```

Compute the iterated Poisson brackets:

```@example main
H01 = @Lie {H0, H1}
H001 = @Lie {H0, H01}
H101 = @Lie {H1, H01}
nothing # hide
```

The singular control is:

```@example main
us_bracket(q, p) = -H001(q, p) / H101(q, p)
nothing # hide
```

Let's verify this gives the same result:

```@example main
q(t) = state(direct_sol)(t)
p(t) = costate(direct_sol)(t)
us_b(t) = us_bracket(q(t), p(t))
plot!(plt, T, us_b; subplot=7, line=:dashdot, lw=2, label="us (brackets)")
plot(plt[7]; size=(800, 400))
```

Both methods give the same singular control, which matches the numerical solution from the direct method.

## Indirect shooting method

We now solve the problem using an indirect shooting method based on the singular control we computed. This approach is similar to the one used in the [double integrator example](@ref example-double-integrator-energy).

First, import the necessary packages:

```@example main
using OrdinaryDiffEq
using NonlinearSolve
```

Define the singular control in feedback form:

```@example main
u_indirect(x) = sin(x[3])^2
nothing # hide
```

Build the flow for the singular arc:

```@example main
f = Flow(ocp, (x, p, tf) -> u_indirect(x))
nothing # hide
```

Define the shooting function. We have 5 unknowns: the initial costate $p_0 \in \mathbb{R}^3$, the initial orientation $\theta_0$, and the final time $t_f$. We must define 5 equations to solve for these unknowns.

```@example main
t0 = 0

function shoot!(s, p0, θ0, tf)

    q_t0, p_t0 = [0, 0, θ0], p0
    q_tf, p_tf = f(t0, q_t0, p_t0, tf)
    
    s[1] = q_tf[1] - 1      # x(tf) = 1 (boundary condition)
    s[2] = q_tf[2]          # y(tf) = 0 (boundary condition)
    s[3] = p_t0[3]          # pθ(0) = 0 (transversality condition)
    s[4] = p_tf[3]          # pθ(tf) = 0 (transversality condition)
    
    # H(tf) = 1 (for time-optimal with p^0 = -1)
    pxf = p_tf[1]
    pyf = p_tf[2]
    θf = q_tf[3]
    s[5] = pxf * cos(θf) + pyf * (sin(θf) + 1) - 1

    return nothing
end
nothing # hide
```

Use the direct solution to provide an initial guess:

```@example main
p0 = costate(direct_sol)(t0)
θ0 = state(direct_sol)(t0)[3]
tf = variable(direct_sol)

println("Initial guess:")
println("p0 = ", p0)
println("θ0 = ", θ0)
println("tf = ", tf)
nothing # hide
```

Set up and solve the nonlinear system:

```@example main
# Auxiliary in-place NLE function
nle!(s, ξ, _) = shoot!(s, ξ[1:3], ξ[4], ξ[5])

# Initial guess for the Newton solver
ξ_guess = [p0..., θ0, tf]

# NLE problem with initial guess
prob = NonlinearProblem(nle!, ξ_guess)

# Resolution of the shooting equations
shooting_sol = solve(prob; show_trace=Val(false))
p0_sol, θ0_sol, tf_sol = shooting_sol.u[1:3], shooting_sol.u[4], shooting_sol.u[5]

println("Shooting solution:")
println("p0 = ", p0_sol)
println("θ0 = ", θ0_sol)
println("tf = ", tf_sol)
nothing # hide
```

Reconstruct the indirect solution:

```@example main
indirect_sol = f((t0, tf_sol), [0, 0, θ0_sol], p0_sol; saveat=range(t0, tf_sol, 100))
nothing # hide
```

Plot the indirect solution alongside the direct solution:

```@example main
plot!(plt, indirect_sol; label="Indirect", color=2, linestyle=:dash, opt...)
```

The indirect and direct solutions match very well, confirming that our singular control computation is correct.

## See also

- [Differential geometry tools](@ref manual-differential-geometry) — Mathematical definitions and usage of `Lift`, `Poisson`, `@Lie`
- [Goddard tutorial](@extref Tutorials tutorial-goddard) — More complex example with bang, singular, and boundary arcs
- [Compute flows from optimal control problems](@ref manual-flow-ocp) — Using flows for indirect methods

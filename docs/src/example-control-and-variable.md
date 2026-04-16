# [Problems mixing control and variable](@id example-control-and-variable)

Problems mixing control and variable are optimal control problems that contain both a control variable and a constant parameter (variable) to optimize. They extend control-free problems by adding an explicit control input to the dynamics, while still optimizing constant parameters.

Such problems are used for:

- Identifying unknown parameters and control inputs simultaneously from observed data
- Finding optimal parameters and associated control laws for a given performance criterion

This page demonstrates two examples that extend the control-free problems by adding a control input and a quadratic control cost term.

First, we import the necessary packages:

```@example main-growth-cv
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Example 1: Exponential growth rate estimation with control

Consider a system with exponential growth and an additive control:

```math
\dot{x}(t) = \lambda \cdot x(t) + u(t), \quad x(0) = 2
```

where $\lambda$ is an unknown growth rate parameter and $u(t)$ is a control input. We have observed data with some perturbations and want to estimate $\lambda$ and the optimal control $u$ by minimizing the squared error plus a quadratic control cost:

```math
\min_{\lambda, u} \int_0^{2} \bigl( (x(t) - x_{\text{obs}}(t))^2 + \frac{1}{2} u(t)^2 \bigr) \, \mathrm{d}t
```

The underlying model has $\lambda = 0.5$, but the observed data includes perturbations.

### [Problem definition](@id example-control-and-variable-problem-1)

```@example main-growth-cv
# observed data (analytical solution with λ = 0.5)
λ_true = 0.5
model(t) = 2 * exp(λ_true * t)
perturbation(t) = 2e-1*sin(4π*t)
data(t) = model(t) + perturbation(t)

# optimal control problem (parameter estimation with control)
t0 = 0; tf = 2; x0 = 2
ocp = @def begin
    λ ∈ R, variable              # growth rate to estimate
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control
    
    x(t0) == x0
    ẋ(t) == λ * x(t) + u(t)
    
    ∫((x(t) - data(t))^2 + 0.5*u(t)^2) → min  # fit to observed data with control cost
end
nothing # hide
```

### [Direct method](@id example-control-and-variable-direct-1)

```@example main-growth-cv
direct_sol = solve(ocp; grid_size=20, display=false)
println("Estimated growth rate: λ = ", variable(direct_sol))
println("Objective value: ", objective(direct_sol))
nothing # hide
```

```@example main-growth-cv
# plot direct solution
plt = plot(direct_sol; size=(800, 600), label="Direct")

# Add data on first plot
t_grid = time_grid(direct_sol)
plot!(plt, t_grid, data.(t_grid); subplot=1, line=:dot, lw=2, label="Data", color=:black)
```

The estimated parameter should be close to $\lambda \approx 0.5$.

### [Indirect method](@id example-control-and-variable-indirect-1)

We now solve the same problem using an indirect shooting method based on Pontryagin's Maximum Principle. First, we import the necessary packages:

```@example main-growth-cv
using OrdinaryDiffEq  # ODE solver
using NonlinearSolve  # Nonlinear solver
```

For problems mixing control and variable, we use an **augmented Hamiltonian** approach with the maximising control. The pseudo-Hamiltonian for this problem is:

```math
H(t, x, p, u, \lambda) = p(\lambda x + u) - (x - x_{\text{obs}}(t))^2 - \frac{1}{2} u^2
```

The maximisation condition $\partial H/\partial u = 0$ gives the control in feedback form:

```math
u(t, x, p, \lambda) = p
```

To handle the variable parameter $\lambda$, we treat it as an additional state with zero dynamics. This gives us the augmented system with state $(x, \lambda)$ and costate $(p, p_\lambda)$, where:

```math
\begin{aligned}
\frac{\mathrm{d}x}{\mathrm{d}t} &= \frac{\partial H}{\partial p} = \lambda x + u \\
\frac{\mathrm{d}\lambda}{\mathrm{d}t} &= 0 \quad \text{(constant parameter)} \\
\frac{\mathrm{d}p}{\mathrm{d}t} &= -\frac{\partial H}{\partial x} = -p\lambda + 2(x - x_{\text{obs}}(t)) \\
\frac{\mathrm{d}p_\lambda}{\mathrm{d}t} &= -\frac{\partial H}{\partial \lambda} = -p x
\end{aligned}
```

Using the maximising control $u = p$, the dynamics of $x$ becomes $\dot x = \lambda x + p$.

The transversality condition for the variable parameter requires $p_\lambda(t_f) - p_\lambda(t_0) = 0$. Assuming $p_\lambda(t_0) = 0$, we have to satisfy:

```math
p_\lambda(t_f) = -\int_{t_0}^{t_f} \frac{\partial H}{\partial \lambda}(t, x(t), p(t), \lambda) \, \mathrm{d}t = 0
```

We use CTFlows' `augment=true` feature to automatically compute $p_\lambda(t_f)$ without manually constructing the augmented system.

```@example main-growth-cv
# Maximising control from Hamiltonian (non-autonomous: t is required)
u(t, x, p, λ) = p

# Create Hamiltonian flow from OCP with control
f = Flow(ocp, u)
nothing # hide
```

!!! note

    For more details about the flow construction, see [this page](@ref manual-flow-others).

The shooting function enforces the transversality conditions $p(t_f) = 0$ and $p_\lambda(t_f) = 0$. Using `augment=true`, the flow automatically returns $(x(t_f), p(t_f), p_\lambda(t_f))$, with $p_\lambda(t_0) = 0$ by construction.

```@example main-growth-cv
# Shooting function: S(p0, λ) = (p(tf), pλ(tf))
# We want both components to be zero at tf
function shoot!(s, p0, λ)
    _, px_tf, pλ_tf = f(t0, x0, p0, tf, λ; augment=true)
    s[1] = px_tf
    s[2] = pλ_tf
    return nothing
end

# Auxiliary in-place NLE function
nle!(s, y, _) = shoot!(s, y...)
nothing # hide
```

We use the direct solution to initialize the shooting method:

```@example main-growth-cv
# Extract solution from direct method for initialization
p_direct = costate(direct_sol)
λ_direct = variable(direct_sol)

# Initial guess
p0_guess = p_direct(t0)
λ_guess = λ_direct

# NLE problem with initial guess (2 unknowns: p0, λ)
prob_indirect = NonlinearProblem(nle!, [p0_guess, λ_guess])

# Solve shooting equations
shooting_sol = solve(prob_indirect; show_trace=Val(false))
p0_sol, λ_sol = shooting_sol.u

println("Indirect solution:")
println("Initial costate: p0 = ", p0_sol)
println("Parameter: λ = ", λ_sol)
nothing # hide
```

Finally, we compute and plot the indirect solution:

```@example main-growth-cv
# Compute and plot indirect solution
indirect_sol = f((t0, tf), x0, p0_sol, λ_sol; saveat=range(t0, tf, 200))
plot!(plt, indirect_sol; linestyle=:dash, lw=2, label="Indirect", color=2)
```

The direct and indirect solutions match closely, both fitting the perturbed observed data.

## Example 2: Harmonic oscillator pulsation optimization with control

```@setup main-harmonic-cv
using OptimalControl
using NLPModelsIpopt
using Plots
using OrdinaryDiffEq  # ODE solver
using NonlinearSolve  # Nonlinear solver
```

Consider a harmonic oscillator with an additive control:

```math
\ddot{q}(t) = -\omega^2 q(t) + u(t)
```

with initial conditions $q(0) = 1$, $\dot{q}(0) = 0$ and final condition $q(1) = 0$. We want to find the minimal pulsation $\omega$ and optimal control $u$ satisfying these constraints:

```math
    \begin{aligned}
        & \text{Minimise} && \omega^2 + \frac{1}{2}\int_0^1 u(t)^2 \, \mathrm{d}t \\
        & \text{subject to} \\
        & && \ddot{q}(t) = -\omega^2 q(t) + u(t), \\[1.0em]
        & && q(0) = 1, \quad \dot{q}(0) = 0, \\[0.5em]
        & && q(1) = 0.
    \end{aligned}
```

Without the control term ($u = 0$), the analytical solution is $\omega = \pi/2 \approx 1.5708$, giving $q(t) = \cos(\pi t / 2)$.

### [Problem definition](@id example-control-and-variable-problem-2)

```@example main-harmonic-cv
# optimal control problem (pulsation optimization with control)
q0 = 1; v0 = 0
t0 = 0; tf = 1
ocp = @def begin
    ω ∈ R, variable              # pulsation to optimize
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    
    q(t0) == q0
    v(t0) == v0
    q(tf) == 0.0                  # final condition
    
    ẋ(t) == [v(t), -ω^2 * q(t) + u(t)]
    
    ω^2 + 0.5∫(u(t)^2) → min   # minimize pulsation with control cost
end
nothing # hide
```

### [Direct method](@id example-control-and-variable-direct-2)

```@example main-harmonic-cv
direct_sol = solve(ocp; grid_size=20, display=false)
println("Optimal pulsation: ω = ", variable(direct_sol))
println("Objective value: ", objective(direct_sol))
nothing # hide
```

```@example main-harmonic-cv
plt = plot(direct_sol; size=(800, 600), label="Direct")
```

### [Indirect method](@id example-control-and-variable-indirect-2)

We now solve the same problem using an indirect shooting method. For problems mixing control and variable, we use an **augmented Hamiltonian** approach with the maximising control. The pseudo-Hamiltonian for this problem is:

```math
H(x, p, u, \omega) = p_1 v + p_2(-\omega^2 q + u) - \frac{1}{2} u^2
```

The maximisation condition $\partial H/\partial u = 0$ gives the control in feedback form:

```math
u(x, p, \omega) = p_2
```

To handle the variable parameter $\omega$, we treat it as an additional state with zero dynamics. This gives us the augmented system with state $(q, v, \omega)$ and costate $(p_1, p_2, p_\omega)$, where:

```math
\begin{aligned}
\frac{\mathrm{d}q}{\mathrm{d}t} &= \frac{\partial H}{\partial p_1} = v \\
\frac{\mathrm{d}v}{\mathrm{d}t} &= \frac{\partial H}{\partial p_2} = -\omega^2 q + u \\
\frac{\mathrm{d}\omega}{\mathrm{d}t} &= 0 \quad \text{(constant parameter)} \\
\frac{\mathrm{d}p_1}{\mathrm{d}t} &= -\frac{\partial H}{\partial q} = \omega^2 p_2 \\
\frac{\mathrm{d}p_2}{\mathrm{d}t} &= -\frac{\partial H}{\partial v} = -p_1 \\
\frac{\mathrm{d}p_\omega}{\mathrm{d}t} &= -\frac{\partial H}{\partial \omega} = 2\omega q p_2
\end{aligned}
```

Using the maximising control $u = p_2$, the dynamics of $v$ becomes $\dot v = -\omega^2 q + p_2$.

For this problem with a Mayer cost $g(\omega) = \omega^2$, the transversality condition for the variable parameter is:

```math
p_\omega(t_f) - p_\omega(t_0)= -\frac{\partial g}{\partial \omega} = -2\omega
```

Assuming $p_\omega(t_0) = 0$, we have:

```math
p_\omega(t_f) = -\int_{t_0}^{t_f} \frac{\partial H}{\partial \omega}(t, x(t), p(t), \omega) \, \mathrm{d}t = -2\omega
```

We use CTFlows' `augment=true` feature to automatically compute $p_\omega(t_f)$ without manually constructing the augmented system:

```@example main-harmonic-cv
# Maximising control from Hamiltonian
u(x, p, ω) = p[2]

# Create Hamiltonian flow from OCP with control
f = Flow(ocp, u)
nothing # hide
```

!!! note

    For more details about the flow construction, see [this page](@ref manual-flow-others).

The shooting function enforces the conditions:

- Final condition: $q(t_f) = 0$
- Free final velocity: $p_2(t_f) = 0$
- Transversality condition for Mayer cost: $p_\omega(t_f) + 2\omega = 0$

Using `augment=true`, the flow automatically returns $(x(t_f), p(t_f), p_\omega(t_f))$, with $p_\omega(t_0) = 0$ by construction.

```@example main-harmonic-cv
# Shooting function: S(p0, ω)
function shoot!(s, p0, ω)
    x_tf, p_tf, pω_tf = f(t0, [q0, v0], p0, tf, ω; augment=true)
    q_tf = x_tf[1]
    pv_tf = p_tf[2]
    s[1] = q_tf         # q(tf) = 0
    s[2] = pv_tf        # p2(tf) = 0 (free final velocity)
    s[3] = pω_tf + 2ω  # pω(tf) + 2ω = 0 (Mayer cost transversality)
    return nothing
end

# Auxiliary in-place NLE function
nle!(s, y, _) = shoot!(s, y[1:2], y[3])
nothing # hide
```

We use the direct solution to initialize the shooting method:

```@example main-harmonic-cv
# Extract solution from direct method for initialization
p_direct = costate(direct_sol)
ω_direct = variable(direct_sol)

# Initial guess
p0_guess = p_direct(t0)
ω_guess = ω_direct

# NLE problem with initial guess
prob_indirect = NonlinearProblem(nle!, [p0_guess..., ω_guess])

# Solve shooting equations
shooting_sol = solve(prob_indirect; show_trace=Val(false))
p0_sol, ω_sol = shooting_sol.u[1:2], shooting_sol.u[3]

println("Indirect solution:")
println("Initial costate: p0 = ", p0_sol)
println("Parameter: ω = ", ω_sol)
nothing # hide
```

Finally, we compute and plot the indirect solution:

```@example main-harmonic-cv
# Compute and plot indirect solution
indirect_sol = f((t0, tf), [q0, v0], p0_sol, ω_sol; saveat=range(t0, tf, 200))
plot!(plt, indirect_sol; linestyle=:dash, lw=2, label="Indirect", color=2)
```

The direct and indirect solutions match closely.

!!! note "Applications"

    Problems mixing control and variable appear in many contexts:
    - **System identification**: simultaneously estimating physical parameters (mass, damping, stiffness) and control inputs from experimental data
    - **Optimal design**: finding optimal geometric or physical parameters (length, stiffness, etc.) together with associated control laws
    - **Inverse problems**: reconstructing unknown inputs or initial conditions from partial observations while optimizing system parameters
    
    See the [syntax documentation](@ref manual-abstract-control-free) for more details on defining control-free problems, and the [flow documentation](@ref manual-flow-ocp) for problems with variables and controls.

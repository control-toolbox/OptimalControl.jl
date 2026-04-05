# [Control-free problems](@id example-control-free)

Control-free problems are optimal control problems without a control variable. They are used for **optimizing constant parameters in dynamical systems**, such as:

- Identifying unknown parameters from observed data (parameter estimation)
- Finding optimal parameters for a given performance criterion

This page demonstrates two simple examples with known analytical solutions.

First, we import the necessary packages:

```@example main-growth
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Example 1: Exponential growth rate estimation

Consider a system with exponential growth:

```math
\dot{x}(t) = \lambda \cdot x(t), \quad x(0) = 2
```

where $\lambda$ is an unknown growth rate parameter. We have observed data with some perturbations and want to estimate $\lambda$ by minimizing the squared error:

```math
\min_{\lambda} \int_0^{2} (x(t) - x_{\text{obs}}(t))^2 \, dt
```

The underlying model has $\lambda = 0.5$, but the observed data includes perturbations.

### [Problem definition](@id example-control-free-problem-1)

```@example main-growth
# observed data (analytical solution with λ = 0.5)
λ_true = 0.5
model(t) = 2 * exp(λ_true * t)
perturbation(t) = 2e-1*sin(4π*t)
data(t) = model(t) + perturbation(t)

# optimal control problem (parameter estimation)
t0 = 0; tf = 2; x0 = 2
ocp = @def begin
    λ ∈ R, variable              # growth rate to estimate
    t ∈ [t0, tf], time
    x ∈ R, state
    
    x(t0) == x0
    ẋ(t) == λ * x(t)
    
    ∫((x(t) - data(t))^2) → min  # fit to observed data
end
nothing # hide
```

### Direct method

```@example main-growth
direct_sol = solve(ocp; display=false)
println("Estimated growth rate: λ = ", variable(direct_sol))
println("Objective value: ", objective(direct_sol))
nothing # hide
```

```@example main-growth
# plot direct solution
plt = plot(direct_sol; size=(800, 400), label="Direct")

# Add data on first plot
t_grid = time_grid(direct_sol)
plot!(plt, t_grid, data.(t_grid); subplot=1, line=:dot, lw=2, label="Data", color=:black)
```

The estimated parameter should be close to $\lambda \approx 0.5$.

### Indirect method

We now solve the same problem using an indirect shooting method based on Pontryagin's Maximum Principle. First, we import the necessary packages:

```@example main-growth
using OrdinaryDiffEq  # ODE solver
using NonlinearSolve  # Nonlinear solver
```

For control-free problems with a variable parameter, we use an **augmented Hamiltonian** approach: the variable $\lambda$ is treated as an additional state with zero dynamics. The Hamiltonian is:

```math
H(t, x, p, \lambda) = p \lambda x - (x - x_{\text{obs}}(t))^2
```

Defining the augmented state $x\_\text{aug} = (x, \lambda)$ and augmented costate $p\_\text{aug} = (p, p_\lambda)$, we construct the augmented Hamiltonian:

```@example main-growth
# Hamiltonian
H(t, x, p, λ) = p*λ*x - (x - data(t))^2

# Augmented Hamiltonian
function H_aug(t, x_, p_)
    x, λ = x_
    p, _ = p_
    return H(t, x, p, λ)
end

# Create Hamiltonian flow
f = Flow(OptimalControl.Hamiltonian(H_aug; autonomous=false))
nothing # hide
```

!!! note

    For more details about the flow construction, see [this page](@ref manual-flow-others).

The shooting function enforces the transversality conditions $p(t_f) = 0$ and $p_\lambda(t_f) = 0$:

```@example main-growth
# Shooting function: S(p0, λ) = (p(tf), pλ(tf))
function shoot!(s, p0, λ)
    _, p_tf_ = f(t0, [x0, λ], [p0, 0], tf)
    s[:] = p_tf_
    return nothing
end

# Auxiliary in-place NLE function
nle!(s, y, _) = shoot!(s, y...)
nothing # hide
```

We use the direct solution to initialize the shooting method:

```@example main-growth
# Extract solution from direct method for initialization
p_direct = costate(direct_sol)
λ_direct = variable(direct_sol)

# Initial guess
p0_guess = p_direct(t0)
λ_guess = λ_direct

# NLE problem with initial guess
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

```@example main-growth
# Compute indirect solution trajectory
x0_sol_ = [x0, λ_sol]
p0_sol_ = [p0_sol, 0.0]
indirect_sol = f((t0, tf), x0_sol_, p0_sol_; saveat=range(t0, tf, 200))

# Plot comparison
plot!(plt, indirect_sol; vars = (0, 1), subplot=1, line=:dash, lw=2, label="Indirect", color=:red)
plot!(plt, indirect_sol; vars = (0, 3), subplot=2, line=:dash, lw=2, label="Indirect", color=:red)
```

The direct and indirect solutions match closely, both fitting the perturbed observed data.

## Example 2: Harmonic oscillator pulsation optimization

```@setup main-harmonic
using OptimalControl
using NLPModelsIpopt
using Plots
using OrdinaryDiffEq  # ODE solver
using NonlinearSolve  # Nonlinear solver
```

Consider a harmonic oscillator:

```math
\ddot{q}(t) = -\omega^2 q(t)
```

with initial conditions $q(0) = 1$, $\dot{q}(0) = 0$ and final condition $q(1) = 0$. We want to find the minimal pulsation $\omega$ satisfying these constraints:

```math
    \begin{aligned}
        & \text{Minimise} && \omega^2 \\
        & \text{subject to} \\
        & && \ddot{q}(t) = -\omega^2 q(t), \\[1.0em]
        & && q(0) = 1, \quad \dot{q}(0) = 0, \\[0.5em]
        & && q(1) = 0.
    \end{aligned}
```

The analytical solution is $\omega = \pi/2 \approx 1.5708$, giving $q(t) = \cos(\pi t / 2)$.

### [Problem definition](@id example-control-free-problem-2)

```@example main-harmonic
# optimal control problem (pulsation optimization)
q0 = 1; v0 = 0
t0 = 0; tf = 1
ocp = @def begin
    ω ∈ R, variable              # pulsation to optimize
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    
    q(t0) == q0
    v(t0) == v0
    q(tf) == 0.0                  # final condition
    
    ẋ(t) == [v(t), -ω^2 * q(t)]
    
    ω^2 → min   # minimize pulsation
end
nothing # hide
```

### [Direct method](@id example-control-free-direct-2)

```@example main-harmonic
direct_sol = solve(ocp; display=false)
println("Optimal pulsation: ω = ", variable(direct_sol))
println("Objective value: ω² = ", objective(direct_sol))
println("Expected: ω = π/2 ≈ 1.5708, ω² ≈ 2.4674")
nothing # hide
```

```@example main-harmonic
plot(direct_sol; size=(800, 400))
```

The optimal pulsation should be close to $\omega = \pi/2 \approx 1.5708$, and the objective $\omega^2 \approx 2.4674$.

## Comparison with analytical solutions

For the harmonic oscillator, we can compare the numerical solution with the analytical one:

```@example main-harmonic
# analytical solution
t_analytical = range(0, 1, 100)
q_analytical = cos.(π * t_analytical / 2)
v_analytical = -(π/2) * sin.(π * t_analytical / 2)

# plot comparison
plt = plot(direct_sol; size=(800, 600), label="Direct")
plot!(plt, t_analytical, q_analytical; 
      label="q (analytical)", linestyle=:dash, linewidth=2, subplot=1)
plot!(plt, t_analytical, v_analytical; 
      label="v (analytical)", linestyle=:dash, linewidth=2, subplot=2)
```

The numerical and analytical solutions should match very closely.

### [Indirect method](@id example-control-free-indirect-2)

We now solve the same problem using an indirect shooting method. For this control-free problem with a variable parameter, we use an **augmented Hamiltonian** approach: the variable $\omega$ is treated as an additional state with zero dynamics. The Hamiltonian is:

```math
H(x, p, \omega) = p_1 v + p_2 (-\omega^2 q)
```

Defining the augmented state $x\_\text{aug} = (q, v, \omega)$ and augmented costate $p\_\text{aug} = (p_1, p_2, p_\omega)$, we construct the augmented Hamiltonian:

```@example main-harmonic
# Hamiltonian
H(x, p, ω) = p[1]*x[2] + p[2]*(-ω^2*x[1])

# Augmented Hamiltonian
function H_aug(x_, p_)
    q, v, ω = x_
    p1, p2, pω = p_
    return H([q, v], [p1, p2], ω)
end

# Create Hamiltonian flow
f = Flow(OptimalControl.Hamiltonian(H_aug))
nothing # hide
```

!!! note

    For more details about the flow construction, see [this page](@ref manual-flow-others).

The shooting function enforces the conditions:

- Final condition: $q(t_f) = 0$
- Free final velocity: $p_2(t_f) = 0$
- Transversality condition for Mayer cost: $p_\omega(t_f) + 2\omega = 0$

```@example main-harmonic
# Shooting function: S(p0, ω)
function shoot!(s, p0, ω)
    x_tf, p_tf = f(t0, [q0, v0, ω], [p0..., 0], tf)
    s[1] = x_tf[1]
    s[2] = p_tf[2]
    s[3] = p_tf[3] + 2ω
    return nothing
end

# Auxiliary in-place NLE function
nle!(s, y, _) = shoot!(s, y[1:2], y[3])
nothing # hide
```

We use the direct solution to initialize the shooting method:

```@example main-harmonic
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

```@example main-harmonic
# Compute indirect solution trajectory
x0_sol_ = [q0, v0, ω_sol]
p0_sol_ = [p0_sol..., 0.0]
indirect_sol = f((t0, tf), x0_sol_, p0_sol_; saveat=range(t0, tf, 200))

# Plot comparison
plot!(plt, indirect_sol; vars = (0, 1), subplot=1, line=:dash, lw=2, label="Indirect", color=:red)
plot!(plt, indirect_sol; vars = (0, 2), subplot=2, line=:dash, lw=2, label="Indirect", color=:red)
plot!(plt, indirect_sol; vars = (0, 4), subplot=3, line=:dash, lw=2, label="Indirect", color=:red)
plot!(plt, indirect_sol; vars = (0, 5), subplot=4, line=:dash, lw=2, label="Indirect", color=:red)
```

The direct and indirect solutions match closely, both finding the optimal pulsation $\omega \approx \pi/2$.

!!! note "Applications"

    Control-free problems appear in many contexts:
    - **System identification**: estimating physical parameters (mass, damping, stiffness) from experimental data
    - **Optimal design**: finding optimal geometric or physical parameters (length, stiffness, etc.)
    - **Inverse problems**: reconstructing unknown inputs or initial conditions from partial observations
    
    See the [syntax documentation](@ref manual-abstract-control-free) for more details on defining control-free problems.

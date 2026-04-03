# [Control-free problems](@id example-control-free)

Control-free problems are optimal control problems without a control variable. They are used for **optimizing constant parameters in dynamical systems**, such as:

- Identifying unknown parameters from observed data (parameter estimation)
- Finding optimal parameters for a given performance criterion

This page demonstrates two simple examples with known analytical solutions.

First, we import the necessary packages:

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Example 1: Exponential growth rate estimation

Consider a system with exponential growth:

```math
\dot{x}(t) = p \cdot x(t), \quad x(0) = 2
```

where $p$ is an unknown growth rate parameter. We have observed data following $x_{\text{obs}}(t) = 2 e^{0.5 t}$ and want to estimate $p$ by minimizing the squared error:

```math
\min_{p} \int_0^{10} (x(t) - x_{\text{obs}}(t))^2 \, dt
```

The analytical solution is $p = 0.5$.

### [Problem definition](@id example-control-free-problem-1)

```@example main
# observed data (analytical solution)
data(t) = 2.0 * exp(0.5 * t)

# optimal control problem (parameter estimation)
ocp1 = @def begin
    p ∈ R, variable              # growth rate to estimate
    t ∈ [0, 10], time
    x ∈ R, state
    
    x(0) == 2.0
    ẋ(t) == p * x(t)
    
    ∫((x(t) - data(t))^2) → min  # fit to observed data
end
nothing # hide
```

### [Solution](@id example-control-free-solution-1)

```@example main
sol1 = solve(ocp1; display=false)
println("Estimated growth rate: p = ", variable(sol1))
println("Objective value: ", objective(sol1))
println("Expected: p = 0.5, objective ≈ 0.0")
nothing # hide
```

```@example main
plot(sol1; size=(800, 400))
```

The estimated parameter should be very close to $p = 0.5$, and the objective (squared error) should be nearly zero since we're fitting to the exact analytical solution.

## Example 2: Harmonic oscillator pulsation optimization

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

```@example main
# optimal control problem (pulsation optimization)
ocp2 = @def begin
    ω ∈ R, variable              # pulsation to optimize
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    
    q(0) == 1.0
    v(0) == 0.0
    q(1) == 0.0                  # final condition
    
    ẋ(t) == [v(t), -ω^2 * q(t)]
    
    ω^2 → min   # minimize pulsation
end
nothing # hide
```

### [Solution](@id example-control-free-solution-2)

```@example main
sol2 = solve(ocp2; display=false)
println("Optimal pulsation: ω = ", variable(sol2))
println("Objective value: ω² = ", objective(sol2))
println("Expected: ω = π/2 ≈ 1.5708, ω² ≈ 2.4674")
nothing # hide
```

```@example main
plot(sol2; size=(800, 400))
```

The optimal pulsation should be close to $\omega = \pi/2 \approx 1.5708$, and the objective $\omega^2 \approx 2.4674$.

## Comparison with analytical solutions

For the harmonic oscillator, we can compare the numerical solution with the analytical one:

```@example main
# analytical solution
t_analytical = range(0, 1, 100)
q_analytical = cos.(π * t_analytical / 2)
v_analytical = -(π/2) * sin.(π * t_analytical / 2)

# plot comparison
plt = plot(sol2; size=(800, 600))
plot!(plt, t_analytical, q_analytical; 
      label="q (analytical)", linestyle=:dash, linewidth=2, subplot=1)
plot!(plt, t_analytical, v_analytical; 
      label="v (analytical)", linestyle=:dash, linewidth=2, subplot=2)
```

The numerical and analytical solutions should match very closely.

!!! note "Applications"

    Control-free problems appear in many contexts:
    - **System identification**: estimating physical parameters (mass, damping, stiffness) from experimental data
    - **Optimal design**: finding optimal geometric or physical parameters (length, stiffness, etc.)
    - **Inverse problems**: reconstructing unknown inputs or initial conditions from partial observations
    
    See the [syntax documentation](@ref manual-abstract-control-free) for more details on defining control-free problems.

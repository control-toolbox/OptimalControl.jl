# [Control and variable together](@id examples-control-and-variable)

```@meta
Draft = false
```

The same two systems as [Parameter estimation without a control](@ref examples-control-free),
now with a control input and a quadratic control cost — estimating a parameter *and* a control
at the same time. Read that page first; this one skips the narration that doesn't change.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## Growth-rate estimation, with control

### Definition

```@example main
λ_true = 0.5
x_true(t) = 2 * exp(λ_true * t)
data(t) = x_true(t) + 0.2 * sin(4π * t)

t0 = 0
tf = 2
x0 = 2

ocp_growth = @def begin
    λ ∈ R, variable
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0

    ẋ(t) == λ * x(t) + u(t)

    ∫((x(t) - data(t))^2 + 0.5u(t)^2) → min
end
```

### Direct solution

```@example main
growth_sol = solve(ocp_growth; grid_size=20, display=false)
println("estimated λ = ", variable(growth_sol))
```

```@example main
t_grid = time_grid(growth_sol)
plt_growth = plot(growth_sol, :state, :control; label="Direct")
```

### Indirect solution

The data term makes the Lagrange integrand — and so the pseudo-Hamiltonian
$H(t,x,p,u,\lambda) = p(\lambda x+u) - (x-x_{\text{data}}(t))^2 - \tfrac12u^2$ — genuinely
non-autonomous. Maximising over $u$ gives $u(t,x,p,\lambda) = p$:

```@example main
u_growth(t, x, p, λ) = p
f_growth = Flow(ocp_growth, u_growth)

function shoot_growth!(s, ξ)
    p0, λ = ξ[1], ξ[2]
    _, p_tf, pλ_tf = f_growth(t0, x0, p0, tf; variable=λ, variable_costate=true)
    s[1] = p_tf
    s[2] = pλ_tf
    return nothing
end
```

```@example main
nle_growth!(s, ξ, _) = shoot_growth!(s, ξ)

p0_guess = costate(growth_sol)(t0)
λ_guess = variable(growth_sol)

prob_growth = NonlinearProblem(nle_growth!, [p0_guess, λ_guess])
shoot_sol_growth = NonlinearSolve.solve(prob_growth; show_trace=Val(false))
p0_sol_growth, λ_sol = shoot_sol_growth.u
```

### Comparison

```@example main
indirect_growth = f_growth((t0, tf), x0, p0_sol_growth; variable=λ_sol)
plot!(plt_growth, indirect_growth, :state, :control; label="Indirect", linestyle=:dash)
```

## Harmonic oscillator, with control

### Definition

```@example main
q0 = 1
v0 = 0
t0h = 0
tfh = 1

ocp_harmonic = @def begin
    ω ∈ R, variable
    t ∈ [t0h, tfh], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    q(t0h) == q0
    v(t0h) == v0
    q(tfh) == 0.0

    ẋ(t) == [v(t), -ω^2 * q(t) + u(t)]

    ω^2 + 0.5∫(u(t)^2) → min
end
```

$\omega$ only ever appears squared, in both the dynamics and the cost, so its sign carries no
physical meaning here — unlike the control-free version, where $\omega=\pi/2$ was forced by the
boundary conditions alone. With a control now sharing the work of steering $q$ to $0$, the
optimal $|\omega|$ is smaller: the direct and indirect solves below are expected to agree with
each other, not with $\pi/2$.

### Direct solution

```@example main
harmonic_sol = solve(ocp_harmonic; grid_size=20, display=false)
println("estimated ω = ", variable(harmonic_sol))
```

```@example main
plot(harmonic_sol, :state, :control; label="Direct")
```

### Indirect solution

Here neither the dynamics nor the cost depend explicitly on $t$, so the flow is autonomous.
Maximising $H = p_1v + p_2(-\omega^2q+u) - \tfrac12u^2$ over $u$ gives $u(x,p,\omega)=p_2$:

```@example main
u_harmonic(x, p, ω) = p[2]
f_harmonic = Flow(ocp_harmonic, u_harmonic)

function shoot_harmonic!(s, ξ)
    p0, ω = ξ[1:2], ξ[3]
    x_tf, p_tf, pω_tf = f_harmonic(t0h, [q0, v0], p0, tfh; variable=ω, variable_costate=true)
    s[1] = x_tf[1]
    s[2] = p_tf[2]
    s[3] = pω_tf + 2ω
    return nothing
end
```

```@example main
nle_harmonic!(s, ξ, _) = shoot_harmonic!(s, ξ)

p0_guess_h = costate(harmonic_sol)(t0h)
ω_guess = variable(harmonic_sol)

prob_harmonic = NonlinearProblem(nle_harmonic!, [p0_guess_h..., ω_guess])
shoot_sol_harmonic = NonlinearSolve.solve(prob_harmonic; show_trace=Val(false))
p0_sol_harmonic, ω_sol = shoot_sol_harmonic.u[1:2], shoot_sol_harmonic.u[3]
```

### Comparison

```@example main
indirect_harmonic = f_harmonic((t0h, tfh), [q0, v0], p0_sol_harmonic; variable=ω_sol)
plt_harmonic = plot(harmonic_sol, :state, :control; label="Direct")
plot!(plt_harmonic, indirect_harmonic, :state, :control; label="Indirect", linestyle=:dash)
```

## See also

- [Parameter estimation without a control](@ref examples-control-free) — the same two systems,
  without the control input.
- [From an OCP](@ref flows-from-ocp) — the maximising-control construction used above, in
  general.

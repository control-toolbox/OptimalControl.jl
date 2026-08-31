# [Parameter estimation without a control](@id examples-control-free)

```@meta
Draft = false
```

Two problems with no control anywhere — only a `variable` to fit to data. See
[No control](@ref modelling-without-control) for the modelling side of this;
this page is the full worked story, direct and indirect, for both.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## Growth-rate estimation

### The problem

Fit $\dot x = \lambda x$, $x(0)=2$, to noisy synthetic data generated with the true rate
$\lambda=0.5$, by minimising the squared error over $t \in [0,2]$.

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

    x(t0) == x0

    ẋ(t) == λ * x(t)

    ∫((x(t) - data(t))^2) → min
end
```

### Direct solution

```@example main
growth_sol = solve(ocp_growth; grid_size=20, display=false)
println("estimated λ = ", variable(growth_sol))
```

```@example main
t_grid = time_grid(growth_sol)
plt_growth = plot(growth_sol, :state; label="Direct")
plot!(
    plt_growth, t_grid, data.(t_grid);
    line=:dot, label="Data", color=:black,
)
```

`model(growth_sol)` gives back the underlying problem the solution was computed from — the same
object `ocp_growth` was `build`-ed into:

```@example main
model(growth_sol) === ocp_growth
```

### Indirect solution

The pseudo-Hamiltonian is $H(t,x,p,\lambda) = p\lambda x - (x - x_{\text{data}}(t))^2$; since
there is no control, the flow needs no law:

```@example main
f_growth = Flow(ocp_growth)
```

The costate $p$ and the variable's own costate $p_\lambda$ must both vanish at $t_f$
(transversality, with $p_\lambda(t_0)=0$):

```@example main
function shoot_growth!(s, ξ)
    p0, λ = ξ[1], ξ[2]
    _, p_tf, pλ_tf = f_growth(
        t0, x0, p0, tf; variable=λ, variable_costate=true
    )
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
plot!(
    plt_growth, indirect_growth, :state;
    label="Indirect", linestyle=:dash,
)
```

The direct and indirect estimates of $\lambda$ agree, and both curves fit the noisy data
equally well.

## Harmonic-oscillator pulsation

### The problem

$\ddot q = -\omega^2 q$, $q(0)=1$, $\dot q(0)=0$, $q(1)=0$ — find the pulsation $\omega$
minimising $\omega^2$. The analytical solution is $\omega=\pi/2$.

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

    q(t0h) == q0
    v(t0h) == v0
    q(tfh) == 0.0

    ẋ(t) == [v(t), -ω^2 * q(t)]

    ω^2 → min
end
```

### Direct solution

```@example main
harmonic_sol = solve(ocp_harmonic; grid_size=20, display=false)
println(
    "estimated ω = ", variable(harmonic_sol),
    "  (expected π/2 ≈ ", π / 2, ")",
)
```

```@example main
plot(harmonic_sol, :state; label="Direct")
```

### Indirect solution

```@example main
f_harmonic = Flow(ocp_harmonic)

function shoot_harmonic!(s, ξ)
    p0, ω = ξ[1:2], ξ[3]
    x_tf, p_tf, pω_tf = f_harmonic(
        t0h, [q0, v0], p0, tfh; variable=ω, variable_costate=true
    )
    s[1] = x_tf[1]           # q(tf) = 0
    s[2] = p_tf[2]           # free final velocity
    s[3] = pω_tf + 2ω        # Mayer-cost transversality
    return nothing
end
```

```@example main
nle_harmonic!(s, ξ, _) = shoot_harmonic!(s, ξ)

p0_guess_h = costate(harmonic_sol)(t0h)
ω_guess = variable(harmonic_sol)

prob_harmonic = NonlinearProblem(nle_harmonic!, [p0_guess_h..., ω_guess])
shoot_sol_harmonic = NonlinearSolve.solve(
    prob_harmonic; show_trace=Val(false)
)
p0_sol_harmonic, ω_sol = shoot_sol_harmonic.u[1:2], shoot_sol_harmonic.u[3]
println("indirect ω = ", ω_sol)
```

### Comparison

```@example main
indirect_harmonic = f_harmonic(
    (t0h, tfh), [q0, v0], p0_sol_harmonic; variable=ω_sol
)
plt_harmonic = plot(harmonic_sol, :state; label="Direct")
plot!(
    plt_harmonic, indirect_harmonic, :state;
    label="Indirect", linestyle=:dash,
)
```

## See also

- [No control](@ref modelling-without-control) — the modelling-side guide for
  control-free problems.
- [Control and variable together](@ref examples-control-and-variable) — the same two systems,
  with a control added back in.
- [From an OCP](@ref flows-from-ocp) — control-free flows (`Flow(ocp)`, no law), in general.

# [Control and variable together](@id examples-control-and-variable)

Some problems optimise a control and constant parameters at the same time: to identify a
parameter and the input that explains the data, or to find a parameter and the control law
that go best together. This page takes the two systems of
[Parameter estimation without a control](@ref examples-control-free), and adds a control to
their dynamics, with a quadratic cost. The method is the same; this page shows what the
control changes.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## [Growth rate, with a control](@id examples-control-and-variable-growth)

### [The problem](@id examples-control-and-variable-growth-problem)

The growth model gets an additive control, $\dot x = \lambda x + u$, and the cost a term
$\frac12 u^2$: the control can explain the part of the data that the model does not, at a
price.

```@raw html
<div class="responsive-columns-left-priority">
<div>
```

```@example main
λ_true = 0.5
x_obs(t) = 2 * exp(λ_true * t) + 0.2 * sin(4π * t)

t0, tf, x0 = 0, 2, 2

ocp_growth = @def begin
    λ ∈ R, variable
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0

    ẋ(t) == λ * x(t) + u(t)

    ∫((x(t) - x_obs(t))^2 + 0.5u(t)^2) → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

```math
\begin{aligned}
& \text{Minimise} && \int_0^2 \Big( \big(x(t) - x_{\text{obs}}(t)\big)^2 + \frac12 u(t)^2 \Big) \,\mathrm{d}t \\
& \text{subject to} && \dot x(t) = \lambda\, x(t) + u(t), \\[0.5em]
& && x(0) = 2, \\[0.5em]
& && \lambda \in \mathbb{R}.
\end{aligned}
```

```@raw html
</div>
</div>
```

### [Direct method](@id examples-control-and-variable-growth-direct)

```@example main
growth_sol = solve(ocp_growth; grid_size=20, display=false)
variable(growth_sol), objective(growth_sol)
```

```@example main
plt_growth = plot(growth_sol, :state, :control; label="direct", size=(800, 400))
```

### [Indirect method](@id examples-control-and-variable-growth-indirect)

The pseudo-Hamiltonian now depends on the control:

```math
H(t, x, p, u, \lambda) = p\,(\lambda x + u) - \big(x - x_{\text{obs}}(t)\big)^2 - \frac12 u^2 .
```

It is maximised where $\partial H / \partial u = p - u = 0$, so the control in feedback form
is $u = p$. The augmented system is the one of the control-free problem, with $\dot x$ gaining
the control:

```math
\begin{aligned}
\dot x &= \lambda x + p, &
\dot p &= -p \lambda + 2\big(x - x_{\text{obs}}(t)\big), \\
\dot \lambda &= 0, &
\dot p_\lambda &= -p\, x,
\end{aligned}
```

with the same conditions, $p(t_f) = 0$ and $p_\lambda(t_f) = 0$ from $p_\lambda(t_0) = 0$. The
flow takes the control law, a function of $(t, x, p, \lambda)$ since the problem depends on
time through the data:

```@example main
u_growth(t, x, p, λ) = p
f_growth = Flow(ocp_growth, u_growth)

function shoot_growth!(s, ξ, _)
    p0, λ = ξ
    _, p_tf, pλ_tf = f_growth(t0, x0, p0, tf; variable=λ, variable_costate=true)
    s[1] = p_tf      # free final state
    s[2] = pλ_tf     # free parameter
    return nothing
end

ξ_guess = [costate(growth_sol)(t0), variable(growth_sol)]
prob_growth = NonlinearProblem(shoot_growth!, ξ_guess)
p0_growth, λ_sol = NonlinearSolve.solve(prob_growth; show_trace=Val(false)).u
```

### [Comparison](@id examples-control-and-variable-growth-comparison)

```@example main
indirect_growth = f_growth((t0, tf), x0, p0_growth; variable=λ_sol)
(variable(growth_sol), λ_sol), (objective(growth_sol), objective(indirect_growth))
```

For the plot, the flow is built with `saveat`, so that the trajectory has 201 points (see
[Plotting a flow](@ref results-plot-flow)):

```@example main
f_growth_plot = Flow(ocp_growth, u_growth; saveat=range(t0, tf, 201), dense=false)
plot!(plt_growth, f_growth_plot((t0, tf), x0, p0_growth; variable=λ_sol), :state, :control;
      label="indirect", linestyle=:dash)
```

The two methods agree, up to the discretisation error of the 20-step grid.

```@example main
s = zeros(2); shoot_growth!(s, [p0_growth, λ_sol], nothing)                         # hide
@assert maximum(abs, s) < 1e-8                                                      # hide
@assert isapprox(variable(growth_sol), λ_sol; atol=1e-2)                            # hide
@assert isapprox(objective(growth_sol), objective(indirect_growth); rtol=1e-2)      # hide
nothing                                                                             # hide
```

## [Pulsation of an oscillator, with a control](@id examples-control-and-variable-harmonic)

### [The problem](@id examples-control-and-variable-harmonic-problem)

The oscillator gets a control force, $\ddot q = -\omega^2 q + u$, and the cost the energy of
the control: $\omega^2 + \frac12 \int_0^1 u^2$. The contrast with the control-free problem is
the point of this example. There, the boundary conditions alone forced $\omega = \pi/2$. Here,
any $\omega$ can reach the target, with the help of the control, and the optimum is a
trade-off: a larger $\omega$ costs more, but the oscillator then does more of the work. Only
$\omega^2$ appears in the problem, so $\omega$ and $-\omega$ give the same cost.

```@raw html
<div class="responsive-columns-left-priority">
<div>
```

```@example main
q0, v0 = 1, 0
t0h, tfh = 0, 1

ocp_harmonic = @def begin
    ω ∈ R, variable
    t ∈ [t0h, tfh], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    q(t0h) == q0
    v(t0h) == v0
    q(tfh) == 0

    ẋ(t) == [v(t), -ω^2 * q(t) + u(t)]

    ω^2 + 0.5∫(u(t)^2) → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

```math
\begin{aligned}
& \text{Minimise} && \omega^2 + \frac12 \int_0^1 u(t)^2 \,\mathrm{d}t \\
& \text{subject to} && \ddot q(t) = -\omega^2 q(t) + u(t), \\[0.5em]
& && q(0) = 1, \quad \dot q(0) = 0, \\[0.5em]
& && q(1) = 0.
\end{aligned}
```

```@raw html
</div>
</div>
```

### [Direct method](@id examples-control-and-variable-harmonic-direct)

```@example main
harmonic_sol = solve(ocp_harmonic; grid_size=20, display=false)
variable(harmonic_sol), objective(harmonic_sol)
```

```@example main
plt_harmonic = plot(harmonic_sol, :state, :control; label="direct", size=(800, 400))
```

### [Indirect method](@id examples-control-and-variable-harmonic-indirect)

The pseudo-Hamiltonian is

```math
H(x, p, u, \omega) = p_1 v + p_2 (-\omega^2 q + u) - \frac12 u^2,
```

maximised by $u = p_2$. The augmented system is the one of the control-free problem, with
$\dot v = -\omega^2 q + p_2$; the adjoint equations and the conditions do not change:
$p_2(t_f) = 0$, and $p_\omega(t_f) = -2\omega$ from $p_\omega(t_0) = 0$.

```@example main
u_harmonic(x, p, ω) = p[2]
f_harmonic = Flow(ocp_harmonic, u_harmonic)

function shoot_harmonic!(s, ξ, _)
    p0, ω = ξ[1:2], ξ[3]
    x_tf, p_tf, pω_tf = f_harmonic(t0h, [q0, v0], p0, tfh; variable=ω, variable_costate=true)
    s[1] = x_tf[1]        # q(tf) = 0
    s[2] = p_tf[2]        # free final velocity
    s[3] = pω_tf + 2ω     # transversality of the parameter
    return nothing
end

ξ_guess_h = [costate(harmonic_sol)(t0h)..., variable(harmonic_sol)]
prob_harmonic = NonlinearProblem(shoot_harmonic!, ξ_guess_h)
shooting_harmonic = NonlinearSolve.solve(prob_harmonic; show_trace=Val(false))
p0_harmonic, ω_sol = shooting_harmonic.u[1:2], shooting_harmonic.u[3]
```

### [Comparison](@id examples-control-and-variable-harmonic-comparison)

```@example main
indirect_harmonic = f_harmonic((t0h, tfh), [q0, v0], p0_harmonic; variable=ω_sol)
(variable(harmonic_sol), ω_sol), (objective(harmonic_sol), objective(indirect_harmonic))
```

```@example main
f_harmonic_plot = Flow(ocp_harmonic, u_harmonic; saveat=range(t0h, tfh, 101), dense=false)
plot!(plt_harmonic, f_harmonic_plot((t0h, tfh), [q0, v0], p0_harmonic; variable=ω_sol), :state, :control;
      label="indirect", linestyle=:dash)
```

The optimal pulsation is $|\omega| \approx 0.654$, well below $\pi/2$, for a cost of
$\approx 1.457$.

The shooting equations have another solution: $\omega = 0$, $p(0) = (-3, -3)$. Without
oscillator, the control alone steers the mass, $u(t) = -3(1 - t)$, and the cost is
$\frac12 \int_0^1 9(1 - t)^2 = 3/2$. It is an extremal, but not the minimum: its cost is
larger. The maximum principle gives necessary conditions only, and comparing the costs of the
extremals selects the optimum.

```@example main
s = zeros(3)
shoot_harmonic!(s, [-3.0, -3.0, 0.0], nothing)
s, objective(f_harmonic((t0h, tfh), [q0, v0], [-3.0, -3.0]; variable=0.0))
```

```@example main
@assert isapprox(abs(ω_sol), 0.6537637; atol=1e-6)                                     # hide
@assert isapprox(objective(indirect_harmonic), 1.4571067; atol=1e-6)                   # hide
@assert isapprox(abs(variable(harmonic_sol)), abs(ω_sol); atol=1e-2)                   # hide
@assert maximum(abs, s) < 1e-10                                                        # hide
@assert isapprox(objective(f_harmonic((t0h, tfh), [q0, v0], [-3.0, -3.0]; variable=0.0)), 1.5; atol=1e-8)   # hide
s3 = zeros(3); shoot_harmonic!(s3, shooting_harmonic.u, nothing)                       # hide
@assert maximum(abs, s3) < 1e-8                                                        # hide
nothing                                                                                # hide
```

## Applications

Problems with a control and parameters appear in many contexts:

- **system identification**: estimating physical parameters (mass, damping, stiffness) and the
  inputs, from experimental data;
- **optimal design**: finding geometric or physical parameters together with the control law
  that goes with them;
- **inverse problems**: reconstructing unknown inputs or initial conditions from partial
  observations, while optimising parameters of the system.

## See also

- [Parameter estimation without a control](@ref examples-control-free): the same two systems,
  without a control, and the derivation of the augmented system.
- [From an OCP](@ref flows-from-ocp): flows with a control law and a variable.

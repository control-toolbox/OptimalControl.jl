# [Parameter estimation without a control](@id examples-control-free)

A problem without a control optimises **constant parameters** of a dynamical system: the
parameters that make a model fit observed data, or the best parameters for a performance
criterion. This page solves two such problems, by the direct and the indirect methods: the
growth rate of an exponential model fitted to data, and the smallest pulsation of an
oscillator that reaches a target. [Control-free problems](@ref modelling-without-control)
explains how to write them.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## [Growth rate](@id examples-control-free-growth)

### [The problem](@id examples-control-free-growth-problem)

A quantity grows exponentially, $\dot x(t) = \lambda\, x(t)$, from $x(0) = 2$, at an unknown
rate $\lambda$. We observe it on $[0, 2]$, and the observations $x_{\text{obs}}$ are the model
with $\lambda = 0.5$, perturbed by a small oscillation. We estimate $\lambda$ by least
squares. The estimate is close to $0.5$, but not equal, because of the perturbation.

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

    x(t0) == x0

    ẋ(t) == λ * x(t)

    ∫((x(t) - x_obs(t))^2) → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

```math
\begin{aligned}
& \text{Minimise} && \int_0^2 \big(x(t) - x_{\text{obs}}(t)\big)^2 \,\mathrm{d}t \\
& \text{subject to} && \dot x(t) = \lambda\, x(t), \\[0.5em]
& && x(0) = 2, \\[0.5em]
& && \lambda \in \mathbb{R}.
\end{aligned}
```

```@raw html
</div>
</div>
```

### [Direct method](@id examples-control-free-growth-direct)

With a coarse grid of 20 steps:

```@example main
growth_sol = solve(ocp_growth; grid_size=20, display=false)
variable(growth_sol), objective(growth_sol)
```

```@example main
t_grid = range(t0, tf, 201)
plt_growth = plot(growth_sol, :state; label="direct", size=(800, 300))
plot!(plt_growth, t_grid, x_obs.(t_grid); line=:dot, color=:black, label="data")
```

### [Indirect method](@id examples-control-free-growth-indirect)

The problem has no control, so the maximum principle gives directly the **Hamiltonian**, with
$p^0 = -1$ (see [Notation and conventions](@ref modelling-formulation-conventions)):

```math
H(t, x, p, \lambda) = p\, \lambda x - \big(x - x_{\text{obs}}(t)\big)^2 .
```

The parameter $\lambda$ is treated as a state with zero dynamics, $\dot\lambda = 0$, and its
own costate $p_\lambda$. The **augmented system**, with state $(x, \lambda)$ and costate
$(p, p_\lambda)$, is

```math
\begin{aligned}
\dot x &= \frac{\partial H}{\partial p} = \lambda x, &
\dot p &= -\frac{\partial H}{\partial x} = -p \lambda + 2\big(x - x_{\text{obs}}(t)\big), \\
\dot \lambda &= 0, &
\dot p_\lambda &= -\frac{\partial H}{\partial \lambda} = -p\, x .
\end{aligned}
```

The final state is free, so $p(t_f) = 0$. The parameter is free too, and does not appear in
the cost, so $p_\lambda(t_0) = 0$ and $p_\lambda(t_f) = 0$, that is,

```math
p_\lambda(t_f) = -\int_{t_0}^{t_f} \frac{\partial H}{\partial \lambda}\big(t, x(t), p(t), \lambda\big)\,\mathrm{d}t = 0 .
```

The flow of the problem integrates the system in $(x, p)$, with $\lambda$ passed by keyword.
With `variable_costate=true`, it also integrates $p_\lambda$ from $0$, and returns
$(x(t_f), p(t_f), p_\lambda(t_f))$ (see
[The costate of the variable](@ref flows-from-ocp-variable-costate)):

```@example main
f_growth = Flow(ocp_growth)

function shoot_growth!(s, ξ, _)
    p0, λ = ξ
    _, p_tf, pλ_tf = f_growth(t0, x0, p0, tf; variable=λ, variable_costate=true)
    s[1] = p_tf      # free final state
    s[2] = pλ_tf     # free parameter
    return nothing
end
nothing # hide
```

The direct solution gives the initial guess:

```@example main
ξ_guess = [costate(growth_sol)(t0), variable(growth_sol)]
prob_growth = NonlinearProblem(shoot_growth!, ξ_guess)
p0_growth, λ_sol = NonlinearSolve.solve(prob_growth; show_trace=Val(false)).u
```

### [Comparison](@id examples-control-free-growth-comparison)

The two estimates differ in the third decimal: the direct method solves a discretised
problem, on a grid of 20 steps, and the indirect method the problem itself.

```@example main
variable(growth_sol), λ_sol
```

For the plot, the flow is built with `saveat`, so that the trajectory has 201 points (see
[Plotting a flow](@ref results-plot-flow)):

```@example main
f_growth_plot = Flow(ocp_growth; saveat=range(t0, tf, 201), dense=false)
indirect_growth = f_growth_plot((t0, tf), x0, p0_growth; variable=λ_sol)
plot!(plt_growth, indirect_growth, :state; label="indirect", linestyle=:dash)
```

The indirect estimate minimises the least-squares error: the error, computed by quadrature
for the model $2e^{\lambda t}$, is larger on both sides of $\lambda_{\text{sol}}$.

```@example main
ts = range(t0, tf, 2001); w = fill(step(ts), length(ts)); w[[1, end]] ./= 2    # hide
J(λ) = sum(w .* (2 .* exp.(λ .* ts) .- x_obs.(ts)) .^ 2)                        # hide
@assert J(λ_sol) < J(λ_sol - 1e-3) && J(λ_sol) < J(λ_sol + 1e-3)               # hide
@assert isapprox(λ_sol, variable(growth_sol); atol=5e-3) && abs(λ_sol - 0.5) < 1e-2   # hide
s = zeros(2); shoot_growth!(s, [p0_growth, λ_sol], nothing)                    # hide
@assert maximum(abs, s) < 1e-8                                                 # hide
nothing                                                                        # hide
```

## [Pulsation of an oscillator](@id examples-control-free-harmonic)

### [The problem](@id examples-control-free-harmonic-problem)

An oscillator $\ddot q = -\omega^2 q$ starts at rest at $q = 1$. We look for the smallest
pulsation $\omega$ for which it reaches $q = 0$ at $t = 1$. The solution is
$q(t) = \cos(\omega t)$, so $\cos\omega = 0$, and the smallest pulsation is $\omega = \pi/2$,
with $\omega^2 = \pi^2/4 \approx 2.4674$ and $q(t) = \cos(\pi t/2)$.

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

    q(t0h) == q0
    v(t0h) == v0
    q(tfh) == 0

    ẋ(t) == [v(t), -ω^2 * q(t)]

    ω^2 → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

```math
\begin{aligned}
& \text{Minimise} && \omega^2 \\
& \text{subject to} && \ddot q(t) = -\omega^2 q(t), \\[0.5em]
& && q(0) = 1, \quad \dot q(0) = 0, \\[0.5em]
& && q(1) = 0.
\end{aligned}
```

```@raw html
</div>
</div>
```

### [Direct method](@id examples-control-free-harmonic-direct)

```@example main
harmonic_sol = solve(ocp_harmonic; grid_size=20, display=false)
variable(harmonic_sol), objective(harmonic_sol)
```

The direct solution is close to the exact one, $q(t) = \cos(\pi t/2)$ and
$v(t) = -\frac{\pi}{2}\sin(\pi t/2)$:

```@example main
plt_harmonic = plot(harmonic_sol, :state; label="direct", size=(800, 300))
plot!(plt_harmonic, t -> cos(π * t / 2), 0, 1; subplot=1, label="exact", color=:black, line=:dot)
plot!(plt_harmonic, t -> -π / 2 * sin(π * t / 2), 0, 1; subplot=2, label="exact", color=:black, line=:dot)
```

### [Indirect method](@id examples-control-free-harmonic-indirect)

The Hamiltonian has no integral term, since the cost is a Mayer cost:

```math
H(x, p, \omega) = p_1 v - p_2\, \omega^2 q .
```

With the state $(q, v, \omega)$ and the costate $(p_1, p_2, p_\omega)$, the augmented system is

```math
\begin{aligned}
\dot q &= v, & \dot p_1 &= -\frac{\partial H}{\partial q} = \omega^2 p_2, \\
\dot v &= -\omega^2 q, & \dot p_2 &= -\frac{\partial H}{\partial v} = -p_1, \\
\dot \omega &= 0, & \dot p_\omega &= -\frac{\partial H}{\partial \omega} = 2\omega\, q\, p_2 .
\end{aligned}
```

The final velocity is free, so $p_2(t_f) = 0$. For the Mayer cost $g(\omega) = \omega^2$, the
transversality condition of the parameter is $p_\omega(t_f) = p^0 g'(\omega) = -2\omega$,
with $p_\omega(t_0) = 0$.

At the solution, $\omega = \pi/2$, and the adjoint equations with $p_2(1) = 0$ give
$p_2 = -A\cos(\pi t/2)$ and $p_1 = -\dot p_2 = -A\frac{\pi}{2}\sin(\pi t/2)$. Then
$p_\omega(1) = 2\omega \int_0^1 q\,p_2 = -\omega A$, so $A = 2$, and the initial costate is
$p(0) = (0, -2)$.

```@example main
f_harmonic = Flow(ocp_harmonic)

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

### [Comparison](@id examples-control-free-harmonic-comparison)

The indirect method finds $\omega = \pi/2$ and $p(0) = (0, -2)$; the direct method is close,
on its grid of 20 steps:

```@example main
variable(harmonic_sol), ω_sol, π / 2
```

```@example main
f_harmonic_plot = Flow(ocp_harmonic; saveat=range(t0h, tfh, 101), dense=false)
indirect_harmonic = f_harmonic_plot((t0h, tfh), [q0, v0], p0_harmonic; variable=ω_sol)
plot!(plt_harmonic, indirect_harmonic, :state; label="indirect", linestyle=:dash)
```

```@example main
@assert isapprox(ω_sol, π / 2; atol=1e-8) && isapprox(p0_harmonic, [0, -2]; atol=1e-7)   # hide
@assert isapprox(variable(harmonic_sol), π / 2; atol=1e-2)                             # hide
@assert isapprox(objective(harmonic_sol), π^2 / 4; atol=3e-2)                          # hide
@assert maximum(abs(state(indirect_harmonic)(t)[1] - cos(π * t / 2)) for t in 0:0.1:1) < 1e-7   # hide
nothing                                                                                # hide
```

## Applications

Problems without a control appear in many contexts:

- **system identification**: estimating physical parameters (mass, damping, stiffness) from
  experimental data;
- **optimal design**: finding geometric or physical parameters (a length, a stiffness) that
  optimise a criterion;
- **inverse problems**: reconstructing unknown inputs or initial conditions from partial
  observations.

## See also

- [Control-free problems](@ref modelling-without-control): how to write them.
- [Control and variable together](@ref examples-control-and-variable): the same two systems,
  with a control.
- [From an OCP](@ref flows-from-ocp): the flow of a problem without a control, and the costate
  of the variable.

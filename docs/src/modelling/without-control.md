# [Control-free problems](@id modelling-without-control)

## What this is for

Control-free problems are optimal control problems without a control. They are used to
**optimise constant parameters of a dynamical system**, for instance to

- identify unknown parameters from observed data (parameter estimation),
- find the parameters that are best for a given performance criterion.

This page shows how to declare and solve such problems. For the full story of the two
examples below, solved by both the direct and the indirect method, see
[Parameter estimation without a control](@ref examples-control-free).

## How to declare it

There is no dedicated syntax: simply never declare a control. Declare a `variable` (the
parameters), a time, a state, the dynamics and a cost, and omit the control line with
[`@def`](@ref modelling-abstract-syntax), or never call `control!` with the
[functional API](@ref modelling-functional-api). The functional API page builds the
parameter-estimation problem below both ways, side by side.

!!! warning "`control!(pre, 0)` is an error"

    With the functional API, a control-free problem is obtained by omission only.
    `control!(pre, 0)` throws an `IncorrectArgument`: a dimension must be positive.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Example: parameter estimation

A system with exponential growth, $\dot{x}(t) = \lambda\, x(t)$, $x(0) = 2$, where $\lambda$
is an unknown growth rate. We have noisy observed data $x_{\text{obs}}$ and estimate
$\lambda$ by minimising the squared error:

```math
\min_{\lambda} \int_0^{2} (x(t) - x_{\text{obs}}(t))^2 \, \mathrm{d}t.
```

The data come from the model with $\lambda = 0.5$, plus a perturbation. There is **no
control line**, only a `variable`:

```@example main
# observed data (analytical solution with λ = 0.5, plus a perturbation)
λ_true = 0.5
data(t) = 2 * exp(λ_true * t) + 2e-1 * sin(4π * t)

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

The model knows it has no control:

```@example main
is_control_free(ocp)
```

It solves like any other problem. The estimated parameter is the optimal value of the
variable:

```@example main
sol = solve(ocp; grid_size=20, display=false)
println("estimated λ = ", variable(sol), "   (true value: ", λ_true, ")")
nothing # hide
```

```@example main
@assert isapprox(variable(sol), λ_true; atol=5e-2)   # hide
nothing                                              # hide
```

The fitted state follows the data, up to the perturbation:

```@example main
plt = plot(sol, :state; size=(800, 400), label="Direct")
tg = time_grid(sol)
plot!(
    plt, tg, data.(tg);
    subplot=1, line=:dot, lw=2, label="Data", color=:black,
)
```

## Example: harmonic oscillator

The same shape with a Mayer cost: minimise the pulsation $\omega$ of $\ddot q = -\omega^2 q$
under $q(0) = 1$, $\dot q(0) = 0$ and $q(1) = 0$. The solution is $q(t) = \cos(\omega t)$, and
the smallest pulsation such that $\cos(\omega) = 0$ is $\omega = \pi/2$:

```@example main
ocp = @def begin
    ω ∈ R, variable              # pulsation to minimise
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state

    q(0) == 1.0
    v(0) == 0.0
    q(1) == 0.0

    ẋ(t) == [v(t), -ω^2 * q(t)]

    ω^2 → min
end
nothing # hide
```

Solving it recovers $\pi/2$:

```@example main
sol = solve(ocp; display=false)
println("ω = ", variable(sol), "   (π/2 = ", π / 2, ")")
nothing # hide
```

```@example main
@assert isapprox(variable(sol), π / 2; atol=1e-3)   # hide
nothing                                             # hide
```

## See also

- [Formulation](@ref modelling-formulation) — the control-free case, $m=0$.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — the control-free syntax.
- [Functional API](@ref modelling-functional-api) — the control-free functional-API form.
- [Parameter estimation without a control](@ref examples-control-free) — both problems above, direct **and** indirect, in full.
- [From an OCP](@ref flows-from-ocp) — building flows, including `Flow(ocp)` for a control-free problem.

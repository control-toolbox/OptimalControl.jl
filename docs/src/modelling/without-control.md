# [No control](@id modelling-without-control)

```@meta
Draft = false
```

## What this is for

Control-free problems are optimal control problems without a control variable — used for **optimising constant parameters in dynamical systems**, such as:

- identifying unknown parameters from observed data (parameter estimation),
- finding optimal parameters for a given performance criterion.

This page is the modelling-side guide: how to declare such a problem and the traps around it.
For the full worked story — both examples below solved **direct and indirect** — see
[Parameter estimation without a control](@ref examples-control-free).

## How to declare it

There is no dedicated syntax for "no control": simply never declare one. Declare a `variable`, a time, a state, dynamics, and a cost, and omit the control line entirely (on the [abstract syntax](@ref modelling-abstract-syntax)) or never call `control!` (on the [functional API](@ref modelling-functional-api)).

!!! warning "`control!(pre, 0)` is an error, not a spelling for \"no control\""

    A control-free problem is reached purely by omission. `control!(pre, 0)` throws
    `IncorrectArgument` — a dimension must be positive. Internally, a `PreModel` that never
    called `control!` keeps its default `EmptyControlModel`, and `is_control_free`/`has_control`
    read that from the *type* of the built model's control field, not from a dimension check.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Example: parameter estimation

A system with exponential growth, $\dot{x}(t) = \lambda\, x(t)$, $x(0) = 2$, where $\lambda$
is an unknown growth rate. We have noisy observed data and estimate $\lambda$ by minimising
the squared error:

```math
\min_{\lambda} \int_0^{2} (x(t) - x_{\text{obs}}(t))^2 \, \mathrm{d}t
```

The underlying model has $\lambda = 0.5$; the data adds a perturbation. Note there is **no
control line** — only a `variable`:

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

It solves like any other problem:

```@example main
sol = solve(ocp; grid_size=20, display=false)
println("estimated λ = ", variable(sol), "   (true value: ", λ_true, ")")
nothing # hide
```

```@example main
plt = plot(sol, :state; size=(800, 400), label="Direct")
tg = time_grid(sol)
plot!(
    plt, tg, data.(tg);
    subplot=1, line=:dot, lw=2, label="Data", color=:black,
)
```

The estimate is close to $\lambda \approx 0.5$. The indirect (PMP shooting) solution of the
same problem is worked in full in [Parameter estimation without a control](@ref examples-control-free).

## Example: harmonic oscillator

The same shape with a Mayer cost — minimise the pulsation $\omega$ of $\ddot q = -\omega^2 q$
under $q(0) = 1$, $\dot q(0) = 0$, $q(1) = 0$ (analytical solution $\omega = \pi/2$):

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

Both the direct and indirect solutions of this one are in
[Parameter estimation without a control](@ref examples-control-free).

## How the package knows

`is_control_free(ocp)` and `has_control(ocp)` don't check a dimension — they read the *type*
of the built model's control field. A `PreModel` that never called `control!` keeps its
default `EmptyControlModel`; `build` copies that straight into the immutable `Model`, and
`is_control_free` dispatches on that type. There is nothing to configure: reaching
`ControlFree` is purely a consequence of never calling `control!`.

## Adding a control back

To turn either of these examples into a controlled problem, declare a control and give
`Flow` a control law: `Flow(ocp, law)`. Two guards are worth knowing before you try:

- `Flow(ocp)` — no law — only works on a control-free model. On a model **with** a control
  it throws `PreconditionError("Flow from a with-control OCP is not supported")`, suggesting
  `Flow(ocp, law)`.
- `constraint=`/`multiplier=` on a control-free `Flow(ocp)` are rejected — `PreconditionError
  ("constrained flows are not supported for control-free problems")` — there is no control
  law and so no pseudo-Hamiltonian to carry a $\mu \cdot g$ term. Use
  `Flow(ocp, law; constraint=…, multiplier=…)` instead.

See [Control and variable together](@ref examples-control-and-variable) for a worked example
with both.

## See also

- [Formulation](@ref modelling-formulation) — the control-free case, $m=0$.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — the control-free syntax.
- [Functional API](@ref modelling-functional-api) — the control-free functional-API form.
- [Parameter estimation without a control](@ref examples-control-free) — both problems above, direct **and** indirect, in full.
- [From an OCP](@ref flows-from-ocp) — building flows in general.

# [From an OCP](@id flows-from-ocp)

This is the main path of the indirect method. You have worked out, from the maximum
principle, the control law that maximises the pseudo-Hamiltonian, and you want the
Hamiltonian flow it defines. `Flow(ocp, law)` reads the dynamics and the cost from the
problem, so you only write the law. The notation is the one of
[Notation and conventions](@ref modelling-formulation-conventions).

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5

t0 = 0
tf = 1
x0 = [-1, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end
nothing # hide
```

## The idea

For this problem, the pseudo-Hamiltonian is $H(x, p, u) = p_1 v + p_2 u + p^0 u^2/2$, with
$p^0 = -1$ in the normal case. Since $\partial^2_{uu} H = p^0 < 0$, $H$ is maximised where
$\partial_u H = p_2 - u = 0$: the control law is $u(x, p) = p_2$. `Flow` integrates the
Hamiltonian system of $\mathbf{H}(x, p) = H(x, p, u(x, p))$, from an initial state and costate.

## The simplest form

```@example main
f = Flow(ocp, (x, p) -> p[2])
p0 = [12, 6]
xf, pf = f(t0, x0, p0, tf)
```

The maximum principle gives $\dot p_1 = 0$ and $\dot p_2 = -p_1$, so $p(t) = (12, 6 - 12t)$
for the initial costate $p_0 = (12, 6)$: the flow reaches the target $x(1) = (0, 0)$ with
$p(1) = (12, -6)$.

```@example main
@assert isapprox(xf, [0, 0]; atol=1e-8) && isapprox(pf, [12, -6]; atol=1e-8)   # hide
nothing                                                                        # hide
```

## Passing a typed law

`Flow(ocp, law)` wraps the function in a `DynClosedLoop` law: a feedback on the state and
the costate. Writing it explicitly gives the same flow:

```@example main
f_typed = Flow(ocp, DynClosedLoop((x, p) -> p[2]))
xf_typed, _ = f_typed(t0, x0, p0, tf)
isapprox(xf_typed, xf; atol=1e-12)
```

The two other kinds of law, `ClosedLoop(x -> …)` and `OpenLoop(t -> …)`, do not involve the
costate: they build a flow of the state alone, to simulate a given control (see
[Simulation](@ref flows-simulation)).

## Non-autonomous problems

When the dynamics depend on $t$, the control law does too: `u(t, x, p)`.

```@example main
t0b = 0
tfb = π / 4
x0b = 0
xfb = tan(π / 4) - 2log(√2 / 2)

ocp_na = @def begin
    t ∈ [t0b, tfb], time
    x ∈ R, state
    u ∈ R, control
    x(t0b) == x0b
    x(tfb) == xfb
    ẋ(t) == u(t) * (1 + tan(t))
    0.5∫(u(t)^2) → min
end

fb = Flow(ocp_na, (t, x, p) -> p * (1 + tan(t)))
xf_na, pf_na = fb(t0b, x0b, 1, tfb)
xf_na - xfb
```

Here $H = p\,u\,(1 + \tan t) - u^2/2$ gives $u = p\,(1 + \tan t)$, and $p$ is constant since
$H$ does not depend on $x$. Then
$x(t_f) = p_0 \int_0^{\pi/4} (1 + \tan t)^2\,\mathrm{d}t = p_0\,(\tan(\pi/4) - 2\log(\sqrt 2/2))$,
so $p_0 = 1$ reaches the target.

```@example main
@assert abs(xf_na - xfb) < 1e-8   # hide
nothing                           # hide
```

## [Problems with a variable](@id flows-from-ocp-variable)

With an optimisation variable $v$, the control law takes it as a third argument:
`u(x, p, v)`, or `u(t, x, p, v)` for a non-autonomous problem. Take a problem whose variable
is the final time:

```@example main
ocp_v = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x ∈ R, state
    u ∈ R, control
    tf ≥ 0
    x(0) == 0
    x(tf) == 1
    ẋ(t) == tf * u(t)
    tf + 0.5∫(u(t)^2) → min
end

fc = Flow(ocp_v, (x, p, tf) -> tf * p)
nothing # hide
```

For a given $t_f$, the cheapest control reaching $x(t_f) = 1$ is the constant
$u = 1/t_f^2$, which costs $t_f + 1/(2t_f^3)$. This is minimal for $t_f^4 = 3/2$. The control
law $u = t_f\,p$ then gives the constant costate $p = u/t_f = 2t_f/3$.

The value of the variable is always passed with the keyword `variable`, even when it is the
final time:

```@example main
tf_val = (3 / 2)^(1 / 4)
p0c = 2tf_val / 3
xf_v, pf_v = fc(0, 0, p0c, tf_val; variable=tf_val)
xf_v
```

```@example main
@assert isapprox(xf_v, 1; atol=1e-8)   # hide
nothing                                # hide
```

Without it, the call raises an error:

```@repl main
try # hide
fc(0, 0, p0c, tf_val)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

and so does passing `variable` to the flow of a problem without a variable:

```@repl main
try # hide
f(t0, x0, p0, tf; variable=1)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

### Two other formulations of a free final time

Since the variable is the final time, the change of time $t = s\,t_f$ gives a problem on
$s \in [0, 1]$, where $t_f$ only appears as a parameter: $\mathrm{d}x/\mathrm{d}s = t_f^2\,u$,
and the cost becomes $t_f + (t_f/2)\int_0^1 u^2\,\mathrm{d}s$. The control law is unchanged:

```@example main
ocp_s = @def begin
    tf ∈ R, variable
    s ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control
    tf ≥ 0
    x(0) == 0
    x(1) == 1
    ẋ(s) == tf^2 * u(s)
    tf + (0.5 * tf) * ∫(u(s)^2) → min
end

fs = Flow(ocp_s, (x, p, tf) -> tf * p)
xf_s, _ = fs(0, 0, p0c, 1; variable=tf_val)
xf_s
```

Or $t_f$ becomes a state, with zero dynamics, and the problem has no variable any more. The
state is $y = (x, t_f)$, its costate $(p, p_{t_f})$, and the control law reads
$u = t_f\,p$ from them:

```@example main
ocp_y = @def begin
    s ∈ [0, 1], time
    y = (x, tf) ∈ R², state
    u ∈ R, control
    x(0) == 0
    x(1) == 1
    ẏ(s) == [tf(s)^2 * u(s), 0]
    tf(1) + 0.5∫(tf(s) * u(s)^2) → min
end

fy = Flow(ocp_y, (y, q) -> y[2] * q[1])
yf, qf = fy(0, [0, tf_val], [p0c, 0], 1)
```

The initial costate of $t_f$ is $0$, since $t_f(0)$ is free, and its final costate is
$-1$: the transversality condition of the Mayer term $t_f(1)$, with $p^0 = -1$.

```@example main
@assert isapprox(xf_s, 1; atol=1e-8)                                       # hide
@assert isapprox(yf, [1, tf_val]; atol=1e-8) && isapprox(qf[2], -1; atol=1e-8)   # hide
nothing                                                                    # hide
```

The constant `0` in the dynamics is fine for a flow. To solve this problem with the direct
method and the default modeler, write `0 * u(s)` instead (see
[Dynamics](@ref modelling-abstract-syntax-dynamics)).

## [The costate of the variable](@id flows-from-ocp-variable-costate)

With `variable_costate=true`, the point call also integrates the costate of the variable,
$\dot p_v = -\nabla_v H$ from $p_v(t_0) = 0$, and returns three values, `(xf, pf, pvf)`.
This is what the transversality condition on the variable needs (see
[Notation and conventions](@ref modelling-formulation-conventions)).

Take a harmonic oscillator whose pulsation $\omega$ is optimised, with the cost
$\omega^2 + \frac12\int u^2$, and solve it with the direct method first:

```@example main
using NLPModelsIpopt

ocp_ω = @def begin
    ω ∈ R, variable
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [1, 0], (start)
    q(1) == 0
    ẋ(t) == [v(t), -ω^2 * q(t) + u(t)]
    ω^2 + 0.5∫(u(t)^2) → min
end

sol_ω = solve(ocp_ω; grid_size=500, display=false)
ω_opt = variable(sol_ω)
p0_ω = dual(sol_ω, ocp_ω, :start)   # the initial costate (see the Solution page)
ω_opt, p0_ω
```

Then integrate the flow from this initial costate, with the costate of $\omega$:

```@example main
fω = Flow(ocp_ω, (x, p, ω) -> p[2])
xf_ω, pf_ω, pω = fω(0, [1, 0], p0_ω, 1; variable=ω_opt, variable_costate=true)
pω, -2ω_opt
```

With the Mayer term $\omega^2$ and $p^0 = -1$, transversality requires
$p_\omega(t_f) = -2\omega$: the direct solution satisfies it. The flow also reaches
$q(1) = 0$, and $p_v(1) = 0$ since $v(1)$ is free.

```@example main
@assert isapprox(pω, -2ω_opt; atol=1e-4)   # hide
@assert abs(xf_ω[1]) < 1e-4 && abs(pf_ω[2]) < 1e-4   # hide
nothing                                    # hide
```

`variable_costate=true` works on the point call only. On a trajectory call
`fω((0, 1), …)`, it raises a `MethodError` that does not say so yet
([CTFlows#437](https://github.com/control-toolbox/CTFlows.jl/issues/437)).

## Control-free problems

`Flow(ocp)`, with no law, builds the flow of a problem without a control: see
[Control-free problems](@ref modelling-without-control). On a problem with a control, it
raises an error that asks for a law:

```@repl main
try # hide
Flow(ocp)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Total or partial Hamiltonian

The keyword `hamiltonian_type` chooses how the flow is built from $H$ and the law
$u(x, p)$:

- `:total`, the default, integrates the Hamiltonian system of
  $\bar H(x, p) = H(x, p, u(x, p))$, differentiating through the law:
  $\dot x = \nabla_p H + (\partial_p u)^\top \nabla_u H$ and
  $\dot p = -\nabla_x H - (\partial_x u)^\top \nabla_u H$;
- `:partial` takes the partial derivatives of $H$ with the control frozen at the value of the
  law: $\dot x = \nabla_p H$, $\dot p = -\nabla_x H$, at $u = u(x, p)$.

The two differ by the terms in $\nabla_u H$. These vanish when $\nabla_u H = 0$ along the
law, as for a control that maximises $H$ inside the control set, and also where the law is
locally constant, as for bang–bang or saturated controls. So for an optimal control law the
two give the same flow. For another law, they do not, and the state of `:partial` is the one
the law actually drives, $\dot x = f(x, u(x, p))$: use `:partial` to simulate a given
feedback.

Take the law $u = p_2 + 1$, which does not maximise $H$:

```@example main
law(x, p) = p[2] + 1

xf_total, _ = Flow(ocp, law; hamiltonian_type=:total)(t0, x0, p0, tf)
xf_partial, _ = Flow(ocp, law; hamiltonian_type=:partial)(t0, x0, p0, tf)
xf_total, xf_partial
```

With `:partial`, the state is driven by $u = p_2 + 1 = 7 - 12t$, which overshoots the target.
With `:total`, the flow is the one of
$\bar H = p_1 v + p_2 (p_2 + 1) - (p_2 + 1)^2/2 = p_1 v + p_2^2/2 - 1/2$. It differs from the
optimal $\mathbf{H} = p_1 v + p_2^2/2$ by a constant, so it has the same Hamiltonian vector
field, and it reaches the target as the optimal law does. This is a property of this
example, not of `:total`.

```@example main
@assert isapprox(xf_total, xf; atol=1e-8)            # hide
@assert isapprox(xf_partial, [0.5, 1]; atol=1e-8)    # hide
nothing                                              # hide
```

## What comes back

The point call `f(t0, x0, p0, tf)` returns `(xf, pf)`, or `(xf, pf, pvf)` with
`variable_costate=true`. The trajectory call `f((t0, tf), x0, p0)` returns a
[`Solution`](@ref results-solution), as `solve` does: `state`, `costate`, `control`,
`objective` and `plot` work on it, but it has no multipliers (see
[Solutions from a flow](@ref results-solution-flows)).

```@example main
sol = f((t0, tf), x0, p0)
objective(sol)
```

```@example main
@assert sol isa OptimalControl.Solution && isapprox(objective(sol), 6; atol=1e-8)   # hide
nothing                                                                             # hide
```

This is specific to flows built from a problem. A flow built from a Hamiltonian or a vector
field returns its own trajectory type: see [Simulation](@ref flows-simulation).

## See also

- [Accessors](@ref flows-accessors): the Hamiltonian, its vector field and the law, read back
  from a flow.
- [Shooting](@ref flows-shooting): turn a flow into equations for the initial costate.
- [Control-free problems](@ref modelling-without-control): `Flow(ocp)` in full.

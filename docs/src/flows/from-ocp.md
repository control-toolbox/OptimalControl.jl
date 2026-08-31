# [From an OCP](@id flows-from-ocp)

```@meta
Draft = false
```

The main path: you've worked out the PMP's maximising control $u^*(t,x,p,v)$ by hand, and want
the Hamiltonian flow it defines.

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

For this problem, the pseudo-Hamiltonian is $\tilde H(x,p,u) = p_1 v + p_2 u + p^0 u^2/2$
(with $p^0 = -1$, the normal case). The maximisation condition gives $u^*(x,p) = p_2$, since
$\partial^2_{uu}\tilde H = p^0 < 0$.

## The simplest form

```@example main
f = Flow(ocp, (x, p) -> p[2])
p0 = [12, 6]
xf, pf = f(t0, x0, p0, tf)
xf
```

The costate $p_0 = [12, 6]$ above is the one the PMP predicts for this problem; the flow
reaches the target `[0, 0]` from it.

## Passing a typed law

`Flow(ocp, u)` above is a convenience overload — it wraps the bare function in
`DynClosedLoop`, the law kind that carries a costate. Writing it explicitly is equivalent and
sometimes clearer:

```@example main
f_typed = Flow(ocp, DynClosedLoop((x, p) -> p[2]))
f_typed(t0, x0, p0, tf)[1] ≈ xf
```

Two other law kinds exist — `ClosedLoop(x -> ...)` and `OpenLoop(t -> ...)` — but they build a
*state* flow with no costate, appropriate for simulation rather than indirect solving; see
[Simulation](@ref flows-simulation).

## Non-autonomous problems

When the dynamics depend on $t$ explicitly, the control law does too — `u(t, x, p)`:

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

## Problems with a variable

An extra optimisation variable extends the law's arity — `u(x, p, v)` (or `u(t, x, p, v)` if
also non-autonomous):

```@example main
t0c = 0
x0c = 0

ocp_v = @def begin
    tf ∈ R, variable
    t ∈ [t0c, tf], time
    x ∈ R, state
    u ∈ R, control
    x(t0c) == x0c
    x(tf) == 1
    ẋ(t) == tf * u(t)
    tf + 0.5∫(u(t)^2) → min
end

fc = Flow(ocp_v, (x, p, v) -> v * p)
nothing # hide
```

**`variable=` is mandatory at call time** — there is no positional slot for it any more:

```@example main
tf_val = (3 / 2)^(1 / 4)
p0c = 2 * tf_val / 3
xf_v, pf_v = fc(t0c, x0c, p0c, tf_val; variable=tf_val)
xf_v
```

```@repl main
try # hide
fc(t0c, x0c, p0c, tf_val)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

The mirror image is also enforced: passing `variable=` to a flow built from a `Fixed` problem
(no `variable` in the `@def`) is rejected the same way, not silently ignored.

## Free final time and the augmented costate

`variable_costate=true` integrates the extra adjoint $\dot p_v = -\partial H/\partial v$
alongside $(x,p)$ and returns a 3-tuple `(xf, pf, pvf)` instead of 2 — useful for the
transversality condition on a free variable:

```@example main
q0 = 1
v0 = 0
t0d = 0
tfd = 1

ocp_aug = @def begin
    ω ∈ R, variable
    t ∈ [t0d, tfd], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    q(t0d) == q0
    v(t0d) == v0
    q(tfd) == 0.0
    ẋ(t) == [v(t), -ω^2 * q(t) + u(t)]
    ω^2 + 0.5∫(u(t)^2) → min
end

f_aug = Flow(ocp_aug, (x, p, ω) -> p[2])
ω_val = π / 2
p0_val = [1.0, 0.5]

xf_aug, pf_aug, pω = f_aug(t0d, [q0, v0], p0_val, tfd; variable=ω_val, variable_costate=true)
pω
```

`variable_costate=true` replaced the old `augment=true` keyword — same idea, new name.

## Control-free problems

`Flow(ocp)` — no law argument — works when the problem has no control at all: see
[No control](@ref modelling-without-control) for how to declare one and what
it means.

## Total or partial Hamiltonian

`hamiltonian_type=` (default `:total`) chooses how the Hamiltonian flow is built from the
pseudo-Hamiltonian and the law:

- `:total` composes a `ComposedHamiltonian` — substitutes the law into $\tilde H$ and
  differentiates *through* it: $\dot x = \partial\tilde H/\partial p +
  (\partial\tilde H/\partial u)(\partial u/\partial p)$.
- `:partial` builds a `PseudoHamiltonianSystem` and takes partials of $\tilde H$ at the frozen
  feedback value: $\dot x = \partial\tilde H/\partial p\big|_{u=u^*(x,p)}$.

They agree **iff the law is stationary for $\tilde H$** ($\partial\tilde H/\partial u = 0$) —
true of every genuine PMP-optimal law, which is why the two are easy to mistake for redundant.
They are not. On this problem's $\tilde H = p_1 v + p_2 u - \tfrac12 u^2$, the minimiser is
$u^*=p_2$; feed it $u = p_2 + 1$ instead — not stationary — and the two modes give different
dynamics:

```@example main
law(x, p) = p[2] + 1.0   # not the PMP minimiser

f_total = Flow(ocp, law; hamiltonian_type=:total)
f_partial = Flow(ocp, law; hamiltonian_type=:partial)

xf_total, _ = f_total(t0, x0, p0, tf)
xf_partial, _ = f_partial(t0, x0, p0, tf)
xf_total ≈ xf_partial
```

```@example main
# :total reproduces the stationary law's trajectory exactly — the perturbation cancels
xf_stationary, _ = Flow(ocp, (x, p) -> p[2])(t0, x0, p0, tf)
xf_total ≈ xf_stationary
```

Both are correct for what they compute; picking the wrong one on a non-stationary law silently
integrates different dynamics, no error — which is why it's worth knowing this exists rather
than assuming the two are interchangeable.

## What comes back

A point call (`f(t0, x0, p0, tf)`) returns `(xf, pf)` (or `(xf, pf, pvf)` with
`variable_costate=true`). A trajectory call — `f((t0, tf), x0, p0)` — returns a real
[`Solution`](@ref results-solution), exactly the same type `solve` returns:

```@example main
sol = f((t0, tf), x0, p0)
typeof(sol) <: OptimalControl.Solution
```

Everything in [Solution object](@ref results-solution) and [Plot](@ref results-plot) applies
verbatim — `state(sol)`, `control(sol)`, `objective(sol)`, `plot(sol)`. This is specific to
flows built **from an OCP**; a flow built without one (a bare `Hamiltonian`, a
`ControlledVectorField`, ...) returns its own trajectory wrapper instead — see
[Simulation](@ref flows-simulation) for that distinction.

## See also

- [Accessors](@ref flows-accessors) — the Hamiltonian, its vector
  field, and the law you passed in, pulled back out.
- [Shooting](@ref flows-shooting) — the payoff: turn this into a root-finding
  problem for $p_0$.
- [No control](@ref modelling-without-control) — the `Flow(ocp)` case in full.

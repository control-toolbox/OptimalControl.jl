# [Overview](@id flows-overview)

```@meta
Draft = false
```

`Flow` is one constructor that does three distinct jobs: **indirect optimal control** (build
the Hamiltonian flow of the Pontryagin Maximum Principle, write a shooting function, solve it),
**simulation** (integrate a controlled system under an open-loop or feedback control), and
**inspection** (pull the Hamiltonian, the Hamiltonian vector field, or the control law back out
of a flow you built). This page maps the section and recaps just enough PMP to make the rest
make sense.

## Why flows

The direct methods ([Solve](@ref solve-overview)) discretize the whole problem into one large
nonlinear program. Flows integrate instead: you supply a control law — from the PMP, from a
feedback design, from anywhere — and get back an ODE solution. Direct methods win when you
don't yet have a control law and want the solver to find one; flows win once you do, whether
that law came from solving the PMP by hand, from a direct solve's costate, or from a controller
you designed independently of any optimization.

## The Pontryagin Maximum Principle, briefly

For an OCP with dynamics $\dot x = f(t,x,u,v)$ and Lagrange cost $f^0$, the pseudo-Hamiltonian
is

```math
\tilde H(t, x, p, u, v) = p \cdot f(t,x,u,v) + p^0 f^0(t,x,u,v).
```

The maximisation condition picks, at each $(t,x,p,v)$, the control that extremises
$\tilde H$ — a **control law** $u^*(t,x,p,v)$. Substituting it back gives the true Hamiltonian
$H(t,x,p,v) = \tilde H(t,x,p,u^*(t,x,p,v),v)$, whose Hamiltonian system

```math
\dot x = \partial H/\partial p, \qquad \dot p = -\partial H/\partial x
```

is the **Hamiltonian flow** this whole section builds and integrates. Boundary conditions on
$(x,p)$ at $t_0$/$t_f$ (transversality) turn "integrate the flow" into "find the missing
$p_0$" — [shooting](@ref flows-shooting).

## From the PMP to a flow

You supply $u^*$ — worked out by hand, or read off a `@def` problem via
[`Flow(ocp, ...)`](@ref flows-from-ocp) — and `Flow` gives you $\exp(t\vec H)$: an object
callable at a point (endpoint only) or over a trajectory (the full path), integrated
numerically.

## Three things this section does

1. **Indirect solving** — [From an OCP](@ref flows-from-ocp),
   [Constrained arcs](@ref flows-constrained-arcs), [Multi-phase flows](@ref flows-multi-phase),
   [Shooting](@ref flows-shooting).
2. **Simulation** — [Simulation](@ref flows-simulation): integrate under a
   given control, no optimization involved.
3. **Inspection** — [Accessors](@ref flows-accessors): the Hamiltonian,
   its vector field, the pseudo-Hamiltonian, the control law you passed in.

[From Hamiltonians](@ref flows-from-hamiltonians) covers the lower-level
constructors these three jobs are all built from.

## Before you start

Every flow needs an ODE integrator, and none is a hard dependency — load one, most commonly
`OrdinaryDiffEqTsit5`, before building any flow:

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using NLPModelsIpopt

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

f = Flow(ocp, (x, p) -> p[2])
nothing # hide
```

Every page in this section opens with `using OrdinaryDiffEqTsit5` — no exceptions. Forget it
and `Flow` says so at construction time, naming the `using` to add:

```julia
julia> f = Flow(ocp, (x, p) -> p[2])
ERROR: ExtensionError → top-level scope, REPL[6]:1
│
│  missing dependencies to access SciML options metadata
│
│  Missing  OrdinaryDiffEqTsit5
│
│  Context  Load OrdinaryDiffEqTsit5, OrdinaryDiffEq, or DifferentialEquations to activate the CTSolversSciMLIntegrator extension.
│  Hint     Run: using OrdinaryDiffEqTsit5
└─
```

!!! note "Why that block is not executed"

    The documentation build loads `OrdinaryDiffEq` once, for the whole site, and a Julia
    extension stays armed for the rest of the session — so no page here can demonstrate this
    failure live. The transcript above comes from a session loading `OptimalControl` and
    `NLPModelsIpopt` and nothing else.

## Choosing an integrator and its options

`describe` covers the indirect side too, not just the direct-solve strategies from
[Choosing a method](@ref solve-choosing-a-method): `:sciml` for the integrator family,
`:di` for the automatic-differentiation backend that builds a Hamiltonian's vector field.

```@example main
describe(:sciml)
```

Real option names worth knowing: `alg` (the ODE algorithm, default `Tsit5()`), `reltol`/
`abstol` (default `1e-8` each), `saveat` (explicit save times), `dense` (dense output,
`:auto` by default — resolves to `false` for a point call, `true` for a trajectory call).
Pass any of them as keywords when constructing a flow, e.g.
`Flow(ocp, law; reltol=1e-10, alg=Tsit5())`.

```@example main
describe(:di)
```

`OptimalControl.get_full_strategy_registry()` — internal, not re-exported — is what `describe`
and the constructor completion machinery actually query for the indirect side: it merges the
direct-solve registry with `CTFlows.Flows.flow_registry()`, so `:sciml`/`:di` show up alongside
`:collocation`/`:adnlp`/`:ipopt` in the same introspection tools.

## CPU and GPU

`method=:cpu`/`:gpu` — the same tokens as [`solve`](@ref solve-overview) — are passed **when
constructing** a flow, not on the call:

```julia
f = Flow(ocp, law; method=:gpu)   # correct — a constructor keyword
f(t0, x0, p0, tf; method=:gpu)    # wrong — no such call-time keyword
```

## Where to go

- [From an OCP](@ref flows-from-ocp) — the main path for indirect optimal control.
- [From Hamiltonians](@ref flows-from-hamiltonians) — building blocks below
  the OCP layer.
- [Simulation](@ref flows-simulation) — no optimization, just integration.
- [Accessors](@ref flows-accessors) — inspection.
- [Multi-phase flows](@ref flows-multi-phase) and [Constrained arcs](@ref flows-constrained-arcs)
  — assembling several arcs into one trajectory.
- [Shooting](@ref flows-shooting) — the payoff.
- [Solve overview](@ref solve-overview) — the direct-method counterpart to everything here.
- [Geometry](@ref geometry-overview) — the Lie-theoretic tools some of these constructors build on.

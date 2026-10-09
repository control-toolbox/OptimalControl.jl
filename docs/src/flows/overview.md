# [Flows overview](@id flows-overview)

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

The notation is the one of [Notation and conventions](@ref modelling-formulation-conventions).
For a problem with dynamics $\dot x = f(t,x,u,v)$ and Lagrange cost $f^0$, the
pseudo-Hamiltonian is

```math
H(t, x, p, u, v) = p \cdot f(t,x,u,v) + p^0 f^0(t,x,u,v),
```

with $p^0 = -1$ in the normal case. Along an optimal trajectory, the control **maximises**
$H$. When this maximisation gives the control in feedback form, a **control law**
$u(t,x,p,v)$, substituting it gives the maximised Hamiltonian
$\mathbf{H}(t,x,p,v) = H(t,x,p,u(t,x,p,v),v)$, whose Hamiltonian system

```math
\dot x = \nabla_p \mathbf{H}, \qquad \dot p = -\nabla_x \mathbf{H}
```

gives the extremals. Its flow, $t \mapsto (x(t), p(t))$ from $(x_0, p_0)$, is what `Flow`
computes. The boundary and transversality conditions then turn "integrate the flow" into
"find the missing $p_0$": that is [shooting](@ref flows-shooting).

## From the PMP to a flow

You supply the control law, worked out by hand, and `Flow` builds the Hamiltonian flow. For
the energy-minimal double integrator below, $H = p_q v + p_v u - u^2/2$ is maximised by
$u = p_v$, the second costate component: the control law is `(x, p) -> p[2]`.
[From an OCP](@ref flows-from-ocp) explains how `Flow(ocp, law)` reads the dynamics and the
cost from the problem.

## Three things this section does

- **Indirect solving** — [From an OCP](@ref flows-from-ocp),
  [Constrained arcs](@ref flows-constrained-arcs), [Multi-phase flows](@ref flows-multi-phase),
  [Shooting](@ref flows-shooting).
- **Simulation** — [Simulation](@ref flows-simulation): integrate under a
  given control, no optimization involved.
- **Inspection** — [Accessors](@ref flows-accessors): the Hamiltonian,
  its vector field, the pseudo-Hamiltonian, the control law you passed in.

[From Hamiltonians](@ref flows-from-hamiltonians) covers the lower-level
constructors these three jobs are all built from.

## Before you start

Every flow needs an ODE integrator, and none is a hard dependency — load one, most commonly
`OrdinaryDiffEqTsit5`, before building any flow:

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

f = Flow(ocp, (x, p) -> p[2])
nothing # hide
```

A flow is called in two ways. At a point, it returns the state and the costate at the final
time. From the exact initial costate $p(0) = (12, 6)$, it reaches the target $x(1) = (0, 0)$,
with $p(1) = (12, -6)$:

```@example main
xf, pf = f(t0, x0, [12, 6], tf)
```

On a time span, it returns the whole trajectory, as a [`Solution`](@ref results-solution)
that can be read and plotted like the solution of a direct solve:

```@example main
sol = f((t0, tf), x0, [12, 6])
objective(sol)
```

```@example main
@assert isapprox(xf, [0, 0]; atol=1e-8) && isapprox(pf, [12, -6]; atol=1e-8)   # hide
@assert isapprox(objective(sol), 6; atol=1e-8)                                 # hide
nothing                                                                        # hide
```

Every page in this section opens with `using OrdinaryDiffEqTsit5`. Without it, `Flow` raises
an error at construction, naming the package to load:

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

## Choosing an integrator and its options

`describe` covers the indirect side too, not just the direct-solve strategies from
[Choosing a method](@ref solve-choosing-a-method): `:sciml` for the integrator family,
`:di` for the automatic-differentiation backend that builds a Hamiltonian's vector field.

::: details `describe(:sciml)`

```@example main
describe(:sciml)
```

:::

The options used most are `alg` (the ODE algorithm, `Tsit5()` by default), `reltol` and
`abstol` (`1e-8` each by default), `saveat` (the times at which to save the trajectory) and
`dense` (dense output, `:auto` by default: `false` for a point call, `true` for a trajectory
call). Pass them as keywords when you build a flow, for example
`Flow(ocp, law; reltol=1e-10, alg=Tsit5())`. With `saveat`, also pass `dense=false`
([CTFlows#434](https://github.com/control-toolbox/CTFlows.jl/issues/434)), see
[Plot](@ref results-plot-flow).

::: details `describe(:di)`

```@example main
describe(:di)
```

:::

## CPU and GPU

The parameters `:cpu` and `:gpu`, the same as for [`solve`](@ref solve-gpu), are passed with
the `method` keyword **when you build** a flow. The call has no such keyword:

```julia
f = Flow(ocp, law; method=:gpu)   # a keyword of the constructor
f(t0, x0, p0, tf; method=:gpu)    # MethodError: not a keyword of the call
```

`method=:gpu` selects the GPU variants of the integrator and of the automatic
differentiation backend (Mooncake); the initial state and costate must then be device
arrays (`CuArray`). See the
[GPU flows page of CTFlows](https://control-toolbox.org/CTFlows.jl/stable/flows/gpu) for what
it supports. On a machine without a GPU, or without Mooncake loaded, the error comes at the
first call and does not name the cause yet
([CTFlows#436](https://github.com/control-toolbox/CTFlows.jl/issues/436)).

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
- [Notation and conventions](@ref modelling-formulation-conventions) — the signs and symbols
  used throughout this section.

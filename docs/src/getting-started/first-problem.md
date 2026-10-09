# [Your first problem](@id getting-started-first-problem)

The shortest complete story: define a problem, solve it, look at the result, and check it
against the exact answer. No options, no theory: every line is explained, and the other pages
go deeper.

## The problem

A wagon moves along a rail. Its position is $q$, its velocity $v$, and we push it with a force
$u$ (unit mass, no friction).

```@raw html
<img src="../assets/chariot_q.svg" alt="" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

Starting at rest at $q = -1$, we want it at rest at $q = 0$ one unit of time later, while
spending as little energy as possible:

```math
\min\ \frac{1}{2}\int_0^1 u(t)^2\,\mathrm dt
\quad\text{s.t.}\quad
\dot q(t) = v(t),\quad \dot v(t) = u(t),\quad
x(0) = (-1, 0),\quad x(1) = (0, 0),
```

where $x = (q, v)$ is the state. This is the double integrator, the "hello world" of optimal
control.

## Define it

We load `OptimalControl` to write the problem and `NLPModelsIpopt` to solve it (see
[Installation](@ref getting-started-installation)), then transcribe the formulation with
[`@def`](@ref modelling-abstract-syntax):

```@example main
using OptimalControl
using NLPModelsIpopt

ocp = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end
nothing # hide
```

Each line mirrors the mathematics:

| Line | Meaning |
| --- | --- |
| `t ∈ [0, 1], time` | the time variable and its fixed interval |
| `x = (q, v) ∈ R², state` | a two-dimensional state, whose components are named `q` and `v` |
| `u ∈ R, control` | a scalar control |
| `x(0) == [-1, 0]`, `x(1) == [0, 0]` | the initial and final conditions |
| `ẋ(t) == [v(t), u(t)]` | the dynamics |
| `0.5∫(u(t)^2) → min` | the cost to minimise |

See [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) for every form these lines can
take.

## Solve it

`solve` discretises the problem in time and hands the resulting finite-dimensional problem to
Ipopt:

```@example main
sol = solve(ocp)
nothing # hide
```

The first box names the method that ran: `solve(ocp)` was called without any method, so it
used the default `(:collocation, :adnlp, :ipopt, :cpu)`. The rest is Ipopt's log. `EXIT:
Optimal Solution Found` is the line to look for. Ipopt needs a single iteration here because
the dynamics are linear and the cost is quadratic.

## Look at it

`Plots` draws the solution:

```@example main
using Plots
plot(sol)
```

The figure shows the state $(q, v)$, the costate $(p_q, p_v)$ and the control $u$. The wagon
accelerates, then brakes: the velocity peaks at mid-time and the control decreases linearly
from about $6$ to about $-6$. The costate comes from the multipliers of the discretised
problem: $p_q$ is constant and $p_v$ coincides with the control, as the maximum principle
predicts (see the energy example below).

The solution also carries the cost and a few solver diagnostics:

```@example main
objective(sol), iterations(sol), successful(sol)
```

The state and the control are functions of time. Because the control is scalar, `control(sol)`
returns a `Number`, not a length-1 vector (see the
[note on dimension one](@ref modelling-abstract-syntax-control)):

```@example main
state(sol)(0.5), control(sol)(0.25)
```

See [Solution](@ref results-solution) for everything else a solution carries, and
[Plot](@ref results-plot) for what else `plot` can show.

## Check it

This problem can be solved by hand: the optimal control is $u(t) = 6 - 12t$, the state at
mid-time is $x(1/2) = (-1/2, 3/2)$, and the minimal cost is $6$. The numerical solution
matches, up to the discretisation error of the default grid (250 steps):

```@example main
objective(sol) - 6
```

```@example main
@assert successful(sol)                                                       # hide
@assert isapprox(objective(sol), 6; rtol=1e-3)                                # hide
@assert isapprox(state(sol)(0.5), [-0.5, 1.5]; atol=1e-3)                     # hide
@assert maximum(abs(control(sol)(t) - (6 - 12t)) for t in 0:0.01:1) < 5e-2    # hide
nothing                                                                       # hide
```

The [energy minimisation example](@ref examples-double-integrator-energy) derives this exact
solution with the maximum principle and recovers it by indirect shooting.

## Next

- [Choosing a method](@ref solve-choosing-a-method) — pick a different solver, modeler, or grid.
- [Guided tour](@ref getting-started-guided-tour) — the same problem in more depth, plus the
  indirect (Pontryagin) method and a second, harder problem.
- [Example gallery](@ref examples-gallery) — worked problems covering singular arcs, state
  constraints, free variables, and more.

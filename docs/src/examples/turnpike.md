# [Turnpike (bang–singular–bang)](@id examples-turnpike)

A scalar system, $\dot x = u$ with $u \in [-1,1]$, driven between two states over a fixed
horizon while minimising $\int x^2$. Because the cost is linear in $u$, the optimal control is
bang — $u = \pm 1$ — except on an interval where the switching function vanishes: a **singular
arc**. This is the smallest problem that shows one, and unlike
[Singular control](@ref examples-singular-control) the singular feedback falls straight out of
the optimality conditions, with no Poisson brackets.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## The problem

State $x$, control $u \in [-1,1]$, dynamics $\dot x = u$, fixed horizon $t_f = 2$, transfer
from $x(0) = 1$ to $x(t_f) = 1/2$ minimising $\int_0^{2} x(t)^2\,dt$. One dimension, so the
state and the control are scalars, not length-1 vectors.

## Definition

```@example main
t0, tf = 0.0, 2.0
x0, xf = 1.0, 0.5

ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    x(t0) == x0
    x(tf) == xf
    ẋ(t) == u(t)
    ∫(x(t)^2) → min
end
```

## Direct solution

```@example main
direct_sol = solve(ocp; grid_size=100, display=false)
plt = plot(direct_sol, :state, :control; label="Direct")
```

The state slides down to the origin, holds there, then climbs to the target. The flat middle
stretch — the *turnpike* — is the singular arc, where $u$ leaves the bounds and sits at $0$.

## The singular control

The pseudo-Hamiltonian $H(x,p,u) = p\,u - x^2$ is linear in $u$, so the maximising control is
bang, $u = \operatorname{sign}(p)$, driven by the sign of the costate. Where $p$ vanishes on a
whole interval rather than at an isolated instant, that rule says nothing and the control is
*singular*. Differentiate $p \equiv 0$: the adjoint equation is $\dot p = -\partial_x H = 2x$,
so $p \equiv 0$ forces $x \equiv 0$, and then $\dot x = u$ forces

$$u_{\text{sing}} = 0.$$

The whole extremal is therefore bang–singular–bang:

| arc | interval | $u$ | $x$ |
| --- | --- | --- | --- |
| bang down | $[0,\,t_1]$ | $-1$ | $1 \to 0$ |
| singular | $[t_1,\,t_2]$ | $0$ | $0$ |
| bang up | $[t_2,\,2]$ | $+1$ | $0 \to 1/2$ |

with $t_1 = 1$, $t_2 = 3/2$ and $p_0 = -1$, all read off by integrating each arc by hand: $x$
falls at unit rate from $1$, reaching $0$ at $t_1 = 1$; it rises at unit rate to $1/2$, so it
must leave the arc at $t_2 = 3/2$.

## Indirect solution

Three constant-control flows, one per arc:

```@example main
f_minus = Flow(ocp, (x, p) -> -1.0)
f_sing  = Flow(ocp, (x, p) ->  0.0)
f_plus  = Flow(ocp, (x, p) -> +1.0)
```

The unknowns are the initial costate $p_0$ and the two switching times $t_1 < t_2$; the horizon
is fixed. Three conditions close the system — the trajectory enters the singular arc at $x = 0$
with the switching function already vanishing there ($p = 0$), and it hits the target at $t_f$:

```@example main
function shoot!(s, ξ)
    p0, t1, t2 = ξ[1], ξ[2], ξ[3]
    x1, p1 = f_minus(t0, x0, p0, t1)
    x2, p2 = f_sing(t1, x1, p1, t2)
    xf_, _ = f_plus(t2, x2, p2, tf)
    s[1] = x1        # enter the singular arc at x = 0
    s[2] = p1        # switching function vanishes there
    s[3] = xf_ - xf  # hit the target
    return nothing
end
```

For a starting point, solve the same problem directly first, then read the singular arc off
that solution. The switching function here is just the costate ($\partial_u H = p$), so the arc
is where $|p|$ stays near zero — the same recipe as the
[Goddard tutorial](https://control-toolbox.org/Tutorials.jl/stable/tutorial-goddard.html#Initial-guess):

```@example main
t = time_grid(direct_sol)
p = costate(direct_sol)

φ(τ) = p(τ)                     # switching function ≡ costate
η = 1e-3
t12 = t[abs.(φ.(t)) .≤ η]       # grid points on the singular arc

p0_guess = p(t0)
t1_guess = minimum(t12)
t2_guess = maximum(t12)
(p0_guess, t1_guess, t2_guess)
```

```@example main
nle!(s, ξ, _) = shoot!(s, ξ)
prob = NonlinearProblem(nle!, [p0_guess, t1_guess, t2_guess])
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol, t1_sol, t2_sol = shooting_sol.u
```

```@example main
s = zeros(3)
shoot!(s, shooting_sol.u)
s
```

The solver lands on $p_0 = -1$, $t_1 = 1$, $t_2 = 3/2$ — the hand computation above.

## Comparison

Concatenating the three constant-control flows at the solved switching times rebuilds the whole
trajectory:

```@example main
φ_bsb = f_minus * (t1_sol, f_sing) * (t2_sol, f_plus)
indirect_sol = φ_bsb((t0, tf), x0, p0_sol)
plot!(plt, indirect_sol, :state, :control;
    label="Indirect", linestyle=:dash)
```

The two curves overlap, and the objective is the expected $3/8$:

```@example main
objective(direct_sol)
```

## See also

- [Singular control](@ref examples-singular-control) — a 2-D drift system where the singular
  control does need the `Lift`/`@Lie` Poisson-bracket chain.
- [Shooting](@ref flows-shooting) — the shooting method in general; this page is a worked case
  of *switching times as unknowns*.
- [Time minimisation (bang–bang)](@ref examples-double-integrator-time) — the bang arcs on their
  own, with no singular arc between them.
- [Multi-phase flows](@ref flows-multi-phase) — concatenating arc flows with `*`.
- [Goddard problem](https://control-toolbox.org/Tutorials.jl/stable/tutorial-goddard.html) —
  the same direct-then-indirect workflow on a harder instance: a singular arc *and* a
  state-constraint boundary arc.
```

# [Writing a shooting function](@id flows-shooting)

```@meta
Draft = false
```

The payoff of everything else in this section: turn a flow into a root-finding problem for the
unknown initial costate (and switching times, and free final time), and solve it.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using NonlinearSolve
nothing # hide
```

## The shooting equation

The PMP gives necessary conditions but not $p_0$ directly. Shooting turns "integrate the flow
and check the boundary/transversality conditions" into a root-finding problem: guess the
unknowns (initial costate, switching times, free final time), integrate, measure how far the
result is from satisfying the conditions, and let a nonlinear solver close the gap.

Worked example throughout: minimise the final time for $\ddot q = u$, $u \in [-1,1]$, from
$(q,v)=(-1,0)$ to $(0,0)$ — bang-bang, one switch, free $t_f$. The reference solution is
$p_0=(1,1)$, one switch at $t=1$, $t_f=2$.

```@example main
t0 = 0.0
x0 = [-1.0, 0.0]
xf = [0.0, 0.0]
u_max = 1.0
u_min = -1.0

ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    q(0) == -1
    v(0) == 0
    q(tf) == 0
    v(tf) == 0
    ẋ(t) == [v(t), u(t)]
    tf → min
end

f_max = Flow(ocp, (x, p, v) -> u_max)
f_min = Flow(ocp, (x, p, v) -> u_min)
nothing # hide
```

## A simple shooting function

The simplest case has no switching — a single arc, fixed time. Out-of-place, the residual is
just the target-state gap:

```@example main
function shoot_simple(p0)
    xf_, _ = f_max(t0, x0, p0, 1.0; variable=2.0)   # arbitrary tf here — illustration only
    return xf_ - xf
end
nothing # hide
```

## In-place, for the solver

The real problem has 4 unknowns — $p_0$ (2), the switching time $t_1$, and $t_f$ — and 4
residuals: the target state (2), the switching condition ($p_2=0$ where the bang-bang control
switches, since $H_u=0$ there), and the free-time transversality $H(t_f)=-1$ (the Mayer cost is
$t_f\to\min$, normal case):

```@example main
H(x, p, u) = p[1] * x[2] + p[2] * u - 1

function shoot!(s, ξ)
    p0 = ξ[1:2]
    t1, tfv = ξ[3], ξ[4]
    x1, p1 = f_max(t0, x0, p0, t1; variable=tfv)
    xf_, pf = f_min(t1, x1, p1, tfv; variable=tfv)
    s[1:2] = xf_ - xf
    s[3] = p1[2]
    s[4] = H(xf_, pf, u_min)
    return nothing
end

s = zeros(4)
shoot!(s, [1.0, 1.0, 1.0, 2.0])   # residual at the reference solution
sqrt(sum(abs2, s))
```

## Solving it

`NonlinearSolve` closes the gap from a perturbed guess:

```@example main
ξ_guess = [1.0, 1.0, 1.0, 2.0] .* 1.1
prob = NonlinearProblem((s, ξ, _) -> shoot!(s, ξ), ξ_guess)
sol = solve(prob, SimpleNewtonRaphson(); abstol=1e-10, reltol=1e-10)
sol.u, sol.retcode
```

## `unsafe=true` inside the loop

A nonlinear solver explores guesses that don't correspond to a real solution — some of them
can make the flow's integration blow up. The default behaviour is to throw, which would abort
the whole solve on the first bad guess:

```@example main
f_blowup = Flow(VectorField(x -> x^2))   # ẋ = x², genuinely diverges before t=1
try
    f_blowup(0.0, 10.0, 1.0)
catch e
    println(e)
end
```

`unsafe=true` returns whatever the integrator produced instead of throwing — garbage, but a
*value*, letting the shooting residual carry the failure forward as "very wrong" rather than
crashing the solve:

```@example main
f_blowup(0.0, 10.0, 1.0; unsafe=true)
```

Inside a `shoot!`, wrap the flow calls with `unsafe=true` so an intermediate failure shows up as
a large residual for the solver to step away from, not an exception that stops the search.

## Free final time

The transversality residual `H(xf_, pf, u_min) = -1` above **is** the free-final-time
condition — no separate machinery needed beyond adding it as a residual. For a smooth
(non-switching) free-final-time problem, `variable_costate=true` gives the extra adjoint
directly if the transversality condition is stated in terms of $p_v(t_f)$ instead:

```@example main
xf_v, pf_v, pvf = f_max(t0, x0, [1.0, 1.0], 1.0; variable=2.0, variable_costate=true)
pvf
```

## Multiple shooting and switching times

The example above already has one: $t_1$ is an unknown alongside $p_0$ and $t_f$. Each
additional switch adds one more unknown time and one more switching-condition residual — see
[Multi-phase flows](@ref flows-multi-phase) for concatenating the corresponding flows once the
times are known (or being solved for).

## Getting a starting point from a direct solve

Manufacturing a shooting guess by hand doesn't scale — the standard workflow is to solve the
same problem directly first, then read `costate(sol)(t0)` off as the initial guess:

```@example main
using NLPModelsIpopt
direct_sol = solve(ocp; display=false)
p0_guess = costate(direct_sol)(0.0)
p0_guess
```

## Checking against the direct solution

```@example main
objective(direct_sol)
```

```@example main
indirect_sol = f_max((t0, sol.u[3]), x0, sol.u[1:2]; variable=sol.u[4])
nothing # hide
```

Compare `state(indirect_sol)`/`objective`-derived quantities against the direct solve the same
way [Solution object](@ref results-solution) already teaches — both describe the same optimal
trajectory, found by two different methods.

## See also

- [From an OCP](@ref flows-from-ocp) — building the flows a shooting function is made of.
- [Multi-phase flows](@ref flows-multi-phase) — concatenating the arcs once switching times are
  known.
- [Solve overview](@ref solve-overview) — the direct-method starting point used above.

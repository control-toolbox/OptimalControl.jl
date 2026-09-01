# [Singular control](@id examples-singular-control)

```@meta
Draft = false
```

A vehicle in the plane with drift, time-optimal, whose extremal control is neither $+1$ nor
$-1$ on part of the trajectory — a **singular arc**. This is the problem the whole
[Geometry](@ref geometry-overview) section exists to support: computing that arc's control
needs Poisson brackets.

For the minimal case, where the singular control drops out of the optimality conditions with no
brackets at all, see [Turnpike (bang–singular–bang)](@ref examples-turnpike) first.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## The problem

State $q=(x,y,\theta)$, dynamics $\dot x=\cos\theta,\ \dot y=\sin\theta+x,\ \dot\theta=u$,
control $u\in[-1,1]$, time-optimal transfer from the origin (free orientation) to $(1,0)$ (free
final orientation too).

## Definition

```@example main
ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    q = (x, y, θ) ∈ R³, state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1
    -π / 2 ≤ θ(t) ≤ π / 2   # helps direct convergence

    x(0) == 0
    y(0) == 0
    x(tf) == 1
    y(tf) == 0

    ∂(q)(t) == [cos(θ(t)), sin(θ(t)) + x(t), u(t)]

    tf → min
end
```

The $-\pi/2 \le \theta(t) \le \pi/2$ box only keeps the *direct* solver away from a spurious
branch where the vehicle turns the long way round; the optimal orientation stays well inside
it, so the bound is never active at the solution. The *indirect* solution below is built from
the PMP flow alone and never sees this bound — the two still agree because it is slack.

## Direct solution

```@example main
direct_sol = solve(ocp; grid_size=50, display=false)
plt = plot(direct_sol, :state, :control; label="Direct")
```

## Computing the singular control

The pseudo-Hamiltonian $H = p_x\cos\theta + p_y(\sin\theta+x) + p_\theta u$ is **linear in
$u$** — its sign is driven entirely by $p_\theta$, exactly as in the bang–bang example, except
that here $p_\theta$ vanishes on part of the trajectory instead of only at isolated switching
instants. On that arc the control is *singular*: found from the vanishing switching function's
own derivatives, not from $\operatorname{sign}(p_\theta)$.

Splitting the dynamics into a drift and a control vector field, $F_0(q) = (\cos\theta,
\sin\theta+x, 0)$ and $F_1(q)=(0,0,1)$:

```@example main
F0(q) = [cos(q[3]), sin(q[3]) + q[1], 0]
F1(q) = [0, 0, 1]
```

```@example main
H0 = Lift(F0)
H1 = Lift(F1)

H01 = @Lie {H0, H1}
H001 = @Lie {H0, H01}
H101 = @Lie {H1, H01}

us_bracket(q, p) = -H001(q, p) / H101(q, p)
```

The classical singular-control formula $u_s = -H_{001}/H_{101}$ (see
[Poisson bracket](@ref geometry-poisson)) simplifies, for this particular drift/control pair,
to a function of the state alone:

```@example main
u_indirect(x) = sin(x[3])^2
```

This is exact on the singular surface $\{H_1 = 0,\ H_{01} = 0\}$ — here $p_\theta = 0$ and
$p_y = p_x\tan\theta$. Check it against the bracket formula at an arbitrary point of that
surface:

```@example main
q_s = [0.3, -0.1, 0.5]
p_s = [1.7, 1.7 * tan(q_s[3]), 0.0]      # a point of {H₁ = 0, H₀₁ = 0}

us_bracket(q_s, p_s), u_indirect(q_s)    # equal
```

## Indirect solution

```@example main
f = Flow(ocp, (x, p, v) -> u_indirect(x))
```

Unknowns: the initial costate $p_0\in\mathbb R^3$, the free initial angle $\theta_0$, and the
free final time $t_f$ — five conditions (two boundary, two transversality on $\theta$, and the
free-final-time condition $H(t_f)=1$):

```@example main
t0 = 0

function shoot!(s, ξ)
    p0, θ0, tf = ξ[1:3], ξ[4], ξ[5]

    q_t0 = [0, 0, θ0]
    q_tf, p_tf = f(t0, q_t0, p0, tf; variable=tf)

    s[1] = q_tf[1] - 1
    s[2] = q_tf[2]
    s[3] = p0[3]
    s[4] = p_tf[3]

    px_tf, py_tf, θf = p_tf[1], p_tf[2], q_tf[3]
    s[5] = px_tf * cos(θf) + py_tf * (sin(θf) + 1) - 1
    return nothing
end
```

```@example main
nle!(s, ξ, _) = shoot!(s, ξ)

p0_guess = costate(direct_sol)(t0)
θ0_guess = state(direct_sol)(t0)[3]
tf_guess = variable(direct_sol)

ξ_guess = [p0_guess..., θ0_guess, tf_guess]

prob = NonlinearProblem(nle!, ξ_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol, θ0_sol, tf_sol =
    shooting_sol.u[1:3], shooting_sol.u[4], shooting_sol.u[5]
```

```@example main
s = zeros(5)
shoot!(s, shooting_sol.u)
s
```

## Comparison

```@example main
indirect_sol = f((t0, tf_sol), [0, 0, θ0_sol], p0_sol; variable=tf_sol)
plot!(
    plt, indirect_sol, :state, :control;
    label="Indirect", linestyle=:dash,
)
```

The indirect and direct solutions match closely, confirming the singular-control computation
above is correct — and, since `Lift`/`@Lie` needed no change from the pre-rewrite version, that
the flow half was migrated correctly too.

The same equality, now along the computed extremal rather than a hand-picked surface point:

```@example main
xs = state(indirect_sol)
ps = costate(indirect_sol)
[us_bracket(xs(t), ps(t)) - u_indirect(xs(t))
 for t in range(t0, tf_sol, 5)]
```

## See also

- [Poisson bracket](@ref geometry-poisson) — the $H_{01}$/$H_{001}$/$H_{101}$ chain, in general.
- [The `@Lie` macro](@ref geometry-lie-macro) — the `{}` bracket notation used above.
- [Lifting a vector field](@ref geometry-lift) — `Lift`, in general.
- [Shooting](@ref flows-shooting) — the shooting method in general.

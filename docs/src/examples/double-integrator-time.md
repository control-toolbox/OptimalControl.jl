# [Time minimisation (bang–bang)](@id examples-double-integrator-time)

```@meta
Draft = false
```

Same wagon as [Energy minimisation](@ref examples-double-integrator-energy), but transferred
**as fast as possible** instead of at minimal energy — a bounded control gives a bang–bang
optimal law with a single switch.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## The problem

Same dynamics, $\dot q = v,\ \dot v = u$, now with $u \in [-1,1]$ and the final time $t_f$ free
— minimise $t_f$ instead of the control energy.

## Definition

```@example main
t0 = 0
x0 = [-1, 0]
xf = [0, 0]

ocp = @def begin
    tf ∈ R, variable
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    tf → min
end
```

## Direct solution

```@example main
direct_sol = solve(ocp; grid_size=20, display=false)
plt = plot(direct_sol, :state, :control; label="Direct")
```

## Indirect solution

The pseudo-Hamiltonian $H(x,p,u) = p_1v + p_2u - 1$ is linear in $u$, so the maximising control
is **bang–bang**: $u(t) = \operatorname{sign}(p_2(t))$, with one switch from $u=+1$ to $u=-1$ at
a time $t_1$.

```@example main
H(x, p, u) = p[1] * x[2] + p[2] * u - 1

u_max = 1.0
u_min = -1.0

f_max = Flow(ocp, (x, p, v) -> u_max)
f_min = Flow(ocp, (x, p, v) -> u_min)
```

The free final time makes this a `NonFixed` flow: every call needs `variable=`.

```@example main
function shoot!(s, ξ)
    p0 = ξ[1:2]
    t1, tf = ξ[3], ξ[4]

    x1, p1 = f_max(t0, x0, p0, t1; variable=tf)
    xf_, pf = f_min(t1, x1, p1, tf; variable=tf)

    s[1:2] = xf_ - xf     # target reached
    s[3] = p1[2]          # switching condition
    s[4] = H(xf_, pf, u_min)  # free final time transversality
    return nothing
end
```

```@example main
nle!(s, ξ, _) = shoot!(s, ξ)

p0_guess = costate(direct_sol)(t0)
t1_guess = 0.9 * variable(direct_sol)
tf_guess = variable(direct_sol)

ξ_guess = [p0_guess..., t1_guess, tf_guess]

prob = NonlinearProblem(nle!, ξ_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol, t1_sol, tf_sol =
    shooting_sol.u[1:2], shooting_sol.u[3], shooting_sol.u[4]
```

```@example main
s = zeros(4)
shoot!(s, shooting_sol.u)
s
```

## Comparison

Concatenating the two constant-control flows at the switching time reconstructs the whole
trajectory:

```@example main
φ = f_max * (t1_sol, f_min)
indirect_sol = φ((t0, tf_sol), x0, p0_sol; variable=tf_sol)
plot!(plt, indirect_sol, :state, :control; label="Indirect")
```

## See also

- [Multi-phase flows](@ref flows-multi-phase) — flow concatenation `*`, in general.
- [Shooting](@ref flows-shooting) — bang–bang shooting, worked in full detail from this exact
  problem.
- [Energy minimisation](@ref examples-double-integrator-energy) — the same wagon, unbounded
  control.

# [Energy minimisation](@id examples-double-integrator-energy)

```@meta
Draft = false
```

The double integrator — a unit mass sliding frictionlessly on a rail, acceleration as the
control — transferred between two rest states at minimal energy. The simplest problem on this
site, and the same one used to introduce the package on the home page.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## The problem

State $x=(q,v)$ — position and velocity — dynamics $\dot q = v,\ \dot v = u$, transfer from
$x(0)=(-1,0)$ to $x(1)=(0,0)$ minimising the control energy $\int_0^1 \tfrac12u(t)^2\,dt$.

## Definition

Character-identical to the problem on the home page — this is the same instance, so the two
should recognisably be the same problem:

```@example main
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫( 0.5u(t)^2 ) → min
end
```

```@example main
t0, tf = 0, 1
x0, xf = [-1, 0], [0, 0]
nothing # hide
```

## Direct solution

```@example main
direct_sol = solve(ocp; grid_size=20, display=false)
plt = plot(direct_sol, :state, :control; label="Direct")
```

## Indirect solution

The pseudo-Hamiltonian is $H(x,p,u) = p_1v + p_2u - \tfrac12u^2$; maximising over $u$ gives the
feedback law $u(x,p) = p_2$.

```@example main
u(x, p) = p[2]
f = Flow(ocp, u; saveat=range(t0, tf, 100), dense=false)
```

The shooting function drives the flow's endpoint to the target:

```@example main
π_x((x, p)) = x
S(p0) = π_x(f(t0, x0, p0, tf)) - xf
```

```@example main
nle!(s, p0, _) = (s .= S(p0))

t = time_grid(direct_sol)
p0_guess = costate(direct_sol)(t0)

prob = NonlinearProblem(nle!, p0_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol = shooting_sol.u
```

```@example main
S(p0_sol)
```

## Comparison

```@example main
indirect_sol = f((t0, tf), x0, p0_sol)
plot!(plt, indirect_sol, :state, :control; label="Indirect")
```

The two solutions overlap: the shooting function's residual at `p0_sol` is numerically zero,
confirming the indirect solve reproduces the direct one.

## See also

- [From an OCP](@ref flows-from-ocp) — the Hamiltonian-flow construction used above, in full.
- [Shooting](@ref flows-shooting) — the shooting method in general.
- [Time minimisation (bang–bang)](@ref examples-double-integrator-time) — the same wagon, a
  harder control constraint.

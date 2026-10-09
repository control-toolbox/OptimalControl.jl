# [Constrained arcs](@id flows-constrained-arcs)

Along a **boundary arc**, a state constraint is active, and the flow needs more than a
control law: the constraint and its multiplier. This page builds such flows, and assembles
them with the unconstrained arcs, on two problems with known solutions.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using NLPModelsIpopt
using Plots
nothing # hide
```

## The setting

With the conventions of [Notation and conventions](@ref modelling-formulation-conventions), a
state constraint is written $c(x) \ge 0$, and along a boundary arc, where $c(x(t)) = 0$, the
pseudo-Hamiltonian gains the term $+\mu\, c(x)$, with $\mu \ge 0$:

```math
H(x, p, u, \mu) = p \cdot f(x, u) + p^0 f^0(x, u) + \mu\, c(x).
```

On the arc, differentiating $c(x(t)) = 0$ gives the control, and the maximisation condition
then gives the multiplier, both in feedback form. `Flow(ocp, law; constraint=c, multiplier=μ)`
integrates the corresponding Hamiltonian flow. The functions have the signatures

```julia
c([t, ]x, u[, v])    # the constraint, c ≥ 0
u([t, ]x, p[, v])    # the control law on the arc
μ([t, ]x, p[, v])    # the multiplier on the arc
```

with `t` for a non-autonomous problem and `v` for a problem with a variable.

## A constraint of order one

This example comes from the v2.0.4 manual, after Bonnard, Faubourg, Launay and
Trélat[^1]. Minimise $\int_0^2 x^2$ for $\dot x = u$, $|u| \le 1$, from $x(0) = 1$ to
$x(2) = 1/2$, under the constraint $x \ge l_b = 0.1$:

```@example main
t0, tf = 0, 2
x0, xf = 1, 1 / 2
lb = 0.1

ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    x(t0) == x0
    x(tf) == xf
    x(t) - lb ≥ 0, (x_con)
    ẋ(t) == u(t)
    ∫(x(t)^2) → min
end
nothing # hide
```

Here $c(x) = x - l_b$ and $H = p\,u - x^2 + \mu\,(x - l_b)$. Along a boundary arc,
$x = l_b$ is constant, so $u = 0$. The maximisation condition with $|u| < 1$ gives $p = 0$ on
the arc, and differentiating, $\dot p = 2x - \mu = 0$: the multiplier is $\mu = 2x$. The
solution has three arcs: $u = -1$, the boundary arc, then $u = +1$, with $t_1 = 0.9$,
$t_2 = 1.6$ and $p(0) \approx -0.982237546583301$.

```@example main
c(x, u) = x - lb         # the constraint, c ≥ 0
u_b(x, p) = 0            # the control on the boundary arc
μ(x, p) = 2x             # the multiplier on the boundary arc

f_minus = Flow(ocp, (x, p) -> -1)
f_boundary = Flow(ocp, u_b; constraint=c, multiplier=μ)
f_plus = Flow(ocp, (x, p) -> 1)

t1, t2 = 0.9, 1.6
f = f_minus * (t1, f_boundary) * (t2, f_plus)

p0 = -0.982237546583301
zf = f(t0, x0, p0, tf)
```

The concatenation reaches $x(2) = 1/2$ (its point call returns `[x; p]`, see
[Multi-phase flows](@ref flows-multi-phase)). The direct method finds the same boundary arc,
$[0.9, 1.6]$, and the same cost:

```@example main
sol_d = solve(ocp; grid_size=400, display=false)
sol_f = f((t0, tf), x0, p0)
objective(sol_d), objective(sol_f)
```

```@example main
@assert isapprox(zf[1], xf; atol=1e-8)                                  # hide
@assert isapprox(objective(sol_d), objective(sol_f); atol=1e-3)         # hide
tg = time_grid(sol_d)                                                   # hide
on_arc = [t for t in tg if state(sol_d)(t) < lb + 1e-3]                 # hide
@assert isapprox(first(on_arc), t1; atol=1e-2) && isapprox(last(on_arc), t2; atol=1e-2)   # hide
nothing                                                                 # hide
```

[^1]: B. Bonnard, L. Faubourg, G. Launay and E. Trélat, *Optimal control with state constraints and the space shuttle re-entry problem*, J. Dyn. Control Syst. 9 (2003), no. 2, 155–199.

`constraint` and `multiplier` go together: one without the other is rejected.

```@repl main
try # hide
Flow(ocp, u_b; constraint=c)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Other ways to give the constraint

The constraint can also be a typed `StateConstraint` (or `ControlConstraint`,
`MixedConstraint`, `PathConstraint` for constraints that involve the control), with the same
result:

```@example main
f_typed = Flow(ocp, u_b; constraint=StateConstraint(x -> x - lb), multiplier=μ)
f_typed(t1, lb, 0.0, t2), f_boundary(t1, lb, 0.0, t2)
```

Several constraints active on the same arc are given as tuples, one multiplier per
constraint:

```@example main
f_two = Flow(ocp, u_b;
    constraint=(c, (x, u) -> 10 - x),     # a second constraint, x ≤ 10, inactive
    multiplier=(μ, (x, p) -> 0))
f_two(t1, lb, 0.0, t2)
```

```@example main
@assert all(f_typed(t1, lb, 0.0, t2) .≈ (lb, 0)) && all(f_two(t1, lb, 0.0, t2) .≈ (lb, 0))   # hide
nothing                                                                                     # hide
```

Finally, `constraint=:x_con` names a path constraint of the problem by its label. It uses the
function stored in the model as it is, without its bound: the result is right only when the
constraint is written as here, `c(x) ≥ 0`. Written `x(t) ≥ lb` or `lb - x(t) ≤ 0`, the flow on
the arc is wrong, without an error
([CTFlows#440](https://github.com/control-toolbox/CTFlows.jl/issues/440)). The examples of
this documentation use the function form.

## A costate jump: a constraint of order two

This example also comes from the v2.0.4 manual. It is the Bryson–Denham problem: minimise
$\frac12\int_0^1 u^2$ for $\ddot x_1 = u$, from $x(0) = (0, 1)$ to $x(1) = (0, -1)$, with
$x_1 \le l = 1/9$:

```@example main
l = 1 / 9

ocp_bd = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [0, 1]
    x(1) == [0, -1]
    x₁(t) ≤ l, (x_con)
    ẋ(t) == [x₂(t), u(t)]
    0.5∫(u(t)^2) → min
end
nothing # hide
```

Here $c(x) = l - x_1 \ge 0$ and $H = p_1 x_2 + p_2 u - u^2/2 + \mu\,(l - x_1)$. Along a
boundary arc, $x_1 = l$, so $\dot x_1 = x_2 = 0$, and differentiating again, $u = 0$: the
constraint is of order two. The maximisation condition gives $p_2 = 0$ on the arc, then
$\dot p_2 = -p_1 = 0$ and $\dot p_1 = \mu = 0$. Off the arc, $u = p_2$. The solution has
three arcs, with $t_1 = 3l = 1/3$, $t_2 = 1 - 3l = 2/3$ and $p(0) = (-18, -6)$, and the
costate **jumps** at $t_1$ and $t_2$: $p_1$ increases by $18$. On a Hamiltonian flow, a vector
jump acts on the costate (see [Multi-phase flows](@ref flows-multi-phase)):

```@example main
f_free = Flow(ocp_bd, (x, p) -> p[2])
f_arc = Flow(ocp_bd, (x, p) -> 0; constraint=(x, u) -> l - x[1], multiplier=(x, p) -> 0)

ν = 18
f_bd = f_free * (3l, [ν, 0], f_arc) * (1 - 3l, [ν, 0], f_free)
zf_bd = f_bd(0, [0, 1], [-18, -6], 1)
```

The flow reaches the target $(0, -1)$. Its cost is $4/(9l) = 4$, the value the direct method
finds too:

```@example main
sol_bd = solve(ocp_bd; display=false)
sol_bd_flow = f_bd((0, 1), [0, 1], [-18, -6])
objective(sol_bd), objective(sol_bd_flow)
```

To plot the flow against the direct solution, the same flows are built with `saveat`, so
that the trajectory has enough points (see [Plotting a flow](@ref results-plot-flow)). Use
such flows for trajectories only: their point call returns the value at the last `saveat`
time, not at the final time
([CTFlows#441](https://github.com/control-toolbox/CTFlows.jl/issues/441)).

```@example main
fine = (saveat=range(0, 1, 101), dense=false)
f_bd_fine = Flow(ocp_bd, (x, p) -> p[2]; fine...) *
    (3l, [ν, 0], Flow(ocp_bd, (x, p) -> 0; constraint=(x, u) -> l - x[1], multiplier=(x, p) -> 0, fine...)) *
    (1 - 3l, [ν, 0], Flow(ocp_bd, (x, p) -> p[2]; fine...))
sol_bd_fine = f_bd_fine((0, 1), [0, 1], [-18, -6])
nothing # hide
```

```@example main
@assert isapprox(zf_bd[1:2], [0, -1]; atol=1e-8)                    # hide
@assert isapprox(objective(sol_bd_flow), 4 / (9l); atol=1e-5)       # hide
@assert isapprox(objective(sol_bd), 4 / (9l); atol=1e-3)            # hide
nothing                                                             # hide
```

```@example main
plt = plot(sol_bd; label="direct", size=(800, 600))
plot!(plt, sol_bd_fine; label="flow", linestyle=:dash)
```

## Partial Hamiltonian

`hamiltonian_type=:partial` (see
[Total or partial Hamiltonian](@ref flows-from-ocp-total-partial)) applies to a constrained
arc too. Along an optimal boundary arc, the law and the multiplier make both forms give the
same flow:

```@example main
f_partial = Flow(ocp, u_b; constraint=c, multiplier=μ, hamiltonian_type=:partial)
f_partial(t1, lb, 0.0, t2)
```

## Control-free problems

A problem without a control has no boundary arcs in this sense: its flow rejects
`constraint` and `multiplier`.

```@repl main
ocp_cf = @def begin
    t ∈ [0, 1], time
    x ∈ R, state
    x(0) == 1
    ẋ(t) == -x(t)
    ∫(x(t)^2) → min
end;
try # hide
Flow(ocp_cf; constraint=(x, u) -> 1, multiplier=(x, p) -> 1)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## See also

- [Multi-phase flows](@ref flows-multi-phase): concatenations and jumps.
- [Shooting](@ref flows-shooting): solve for the junction times and the initial costate.
- [State constraint](@ref examples-state-constraint): a speed constraint on the double
  integrator, from the direct solution to the shooting.

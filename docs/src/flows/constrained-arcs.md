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
then gives the multiplier, both in feedback form. `Flow(ocp, law; multipliers=:label => μ)`,
with the label of the constraint in the problem and its multiplier, integrates the
corresponding Hamiltonian flow: the same pair as for
[`hamiltonian(ocp, law; multipliers=…)`](@ref modelling-hamiltonians-feedback). The functions
have the signatures

```julia
u([t, ]x, p[, v])    # the control law on the arc
μ([t, ]x, p[, v])    # the multiplier on the arc
c([t, ]x, u[, v])    # the constraint, c ≥ 0, when it is given as a function
```

with `t` for a non-autonomous problem and `v` for a problem with a variable.

## A constraint of order one

This example follows Bonnard, Faubourg, Launay and Trélat[^1]. Minimise $\int_0^2 x^2$ for $\dot x = u$, $|u| \le 1$, from $x(0) = 1$ to
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
solution has three arcs: $u = -1$, the boundary arc, then $u = +1$. On the first arc,
$x = 1 - t$ reaches $l_b$ at $t_1 = 0.9$; on the last one, $x = l_b + t - t_2$ reaches $1/2$
at $t_f = 2$, so $t_2 = 1.6$. The costate is continuous at $t_1$, where it vanishes: with
$\dot p = 2x = 2(1 - t)$ on the first arc, $p(0) = -\int_0^{t_1} 2(1 - t)\,\mathrm{d}t = -0.99$,
and $p < 0$ before $t_1$, as $u = -1$ requires.

```@example main
u_b(x, p) = 0            # the control on the boundary arc
μ(x, p) = 2x             # the multiplier on the boundary arc

f_minus = Flow(ocp, (x, p) -> -1; label="u = -1")
f_boundary = Flow(ocp, u_b; multipliers=:x_con => μ, label="boundary")
f_plus = Flow(ocp, (x, p) -> 1; label="u = +1")

t1, t2 = 0.9, 1.6
f = f_minus * (t1, f_boundary) * (t2, f_plus)

p0 = -0.99
zf = f(t0, x0, p0, tf)
```

The concatenation reaches $x(2) = 1/2$ (its point call returns `(x, p)`, see
[Multi-phase flows](@ref flows-multi-phase)). The direct method finds the same boundary arc,
$[0.9, 1.6]$, and the same cost:

```@repl main
sol_d = solve(ocp; grid_size=400, display=false);
sol_f = f((t0, tf), x0, p0);
objective(sol_d)
objective(sol_f)
```

Given by its label, the constraint also gets its multiplier in the solution of the flow,
read with `dual` as for a direct solution (see [Solution](@ref results-solution)):
$\mu = 2x = 0.2$ on the boundary arc, and $0$ off it. The direct method finds the same:

```@repl main
μ_f = dual(sol_f, ocp, :x_con);
μ_d = dual(sol_d, ocp, :x_con);
ts = (0.5, 1.2, 1.8);
μ_f.(ts)
μ_d.(ts)
```

```@example main
@assert isapprox(zf[1], xf; atol=1e-8)                                  # hide
@assert abs(f_minus(t0, x0, p0, t1)[2]) < 1e-8                           # hide
@assert isapprox(objective(sol_d), objective(sol_f); atol=1e-3)         # hide
@assert μ_f(0.5) == 0 && isapprox(μ_f(1.2), 0.2; atol=1e-8) && μ_f(1.8) == 0   # hide
@assert isapprox(μ_d(1.2), 0.2; atol=1e-3)                              # hide
tg = time_grid(sol_d)                                                   # hide
on_arc = [t for t in tg if state(sol_d)(t) < lb + 1e-3]                 # hide
@assert isapprox(first(on_arc), t1; atol=1e-2) && isapprox(last(on_arc), t2; atol=1e-2)   # hide
nothing                                                                 # hide
```

[^1]: B. Bonnard, L. Faubourg, G. Launay and E. Trélat, *Optimal control with state constraints and the space shuttle re-entry problem*, J. Dyn. Control Syst. 9 (2003), no. 2, 155–199.

A constraint and its multiplier go together, as a pair: a label alone is rejected.

```@repl main
Flow(ocp, u_b; multipliers=:x_con)
```

## Other ways to give the constraint

The label takes the constraint from the problem, with its bound and its side: written
`x(t) - lb ≥ 0` as here, or `lb - x(t) ≤ 0`, it gives the same flow. The constraint can also
be given as a function `c(x, u) ≥ 0`, or as a typed `StateConstraint` (or `ControlConstraint`,
`MixedConstraint`, `PathConstraint` for constraints that involve the control), with the same
flow:

```@repl main
c(x, u) = x - lb;        # the constraint, c ≥ 0
f_fun = Flow(ocp, u_b; multipliers=c => μ);
f_typed = Flow(ocp, u_b; multipliers=StateConstraint(x -> x - lb) => μ);
f_fun(t1, lb, 0.0, t2)
f_typed(t1, lb, 0.0, t2)
f_boundary(t1, lb, 0.0, t2)
```

Several constraints active on the same arc are given as several pairs, in a tuple, or, for
labels, in a named tuple `(; a=μa, b=μb)`. An anonymous function in a pair is written in
parentheses:

```@repl main
f_two = Flow(ocp, u_b;
    multipliers=(c => μ, ((x, u) -> 10 - x) => ((x, p) -> 0)));   # x ≤ 10, inactive
f_two(t1, lb, 0.0, t2)
```

```@example main
@assert all(f_typed(t1, lb, 0.0, t2) .≈ (lb, 0)) && all(f_two(t1, lb, 0.0, t2) .≈ (lb, 0))   # hide
@assert all(f_fun(t1, lb, 0.0, t2) .≈ (lb, 0))                                              # hide
nothing                                                                                     # hide
```

!!! note "A label or a function"

    A constraint given as a function, or as a typed constraint, has no label: the flow is
    the same, but its solution carries no multiplier, and `dual(sol, ocp, :x_con)` throws an
    error that says so. When the problem has path constraints, building such a flow warns
    about it. In a multi-phase flow, one phase without a label is enough to lose the
    multipliers of the whole solution.

    A box on the state or on the control, such as `x(t) ≥ lb, (x_box)`, is given by its
    label too, and has its dual in the solution. The duals of the boundary conditions, of
    the boxes on the variable, and of the boxes that no phase adjoins are not rebuilt by a
    flow: `dual` throws an error for them. A function is still needed for a constraint that
    is not in the problem.

    The multiplier follows the sign convention of the duals, see
    [The sign of the multipliers](@ref modelling-hamiltonians-sign). See also
    [Constraint duals of a flow](https://control-toolbox.org/CTFlows.jl/stable/flows/constrained#Constraint-duals-of-a-flow)
    in the CTFlows documentation.

## A costate jump: a constraint of order two

This is the Bryson–Denham problem: minimise
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
f_free = Flow(ocp_bd, (x, p) -> p[2]; label="interior")
f_arc = Flow(ocp_bd, (x, p) -> 0; multipliers=:x_con => ((x, p) -> 0), label="boundary")

ν = 18
f_bd = f_free * (3l, [ν, 0], f_arc) * (1 - 3l, [ν, 0], f_free)
zf_bd = f_bd(0, [0, 1], [-18, -6], 1)
```

The flow reaches the target $(0, -1)$. Its cost is $4/(9l) = 4$, the value the direct method
finds too:

```@repl main
sol_bd = solve(ocp_bd; display=false);
sol_bd_flow = f_bd((0, 1), [0, 1], [-18, -6]);
objective(sol_bd)
objective(sol_bd_flow)
```

The flow can be plotted against the direct solution (see
[Plotting a flow](@ref results-plot-flow)):

```@example main
@assert isapprox(zf_bd[1], [0, -1]; atol=1e-8)                    # hide
@assert isapprox(objective(sol_bd_flow), 4 / (9l); atol=1e-5)       # hide
@assert isapprox(objective(sol_bd), 4 / (9l); atol=1e-3)            # hide
nothing                                                             # hide
```

```@example main
plt = plot(sol_bd; label="direct", size=(800, 920), legend=false)
plot!(plt, sol_bd_flow; label="flow", linestyle=:dash)
plot!(plt; subplot=1, legend=:best)   # one legend, on the first subplot
```

## Partial Hamiltonian

`hamiltonian_type=:partial` (see
[Total or partial Hamiltonian](@ref flows-from-ocp-total-partial)) applies to a constrained
arc too. Along an optimal boundary arc, the law and the multiplier make both forms give the
same flow:

```@repl main
f_partial = Flow(ocp, u_b; multipliers=:x_con => μ, hamiltonian_type=:partial);
f_partial(t1, lb, 0.0, t2)
```

## Control-free problems

A problem without a control has no boundary arcs in this sense: its flow rejects
`multipliers`.

```@repl main
ocp_cf = @def begin
    t ∈ [0, 1], time
    x ∈ R, state
    x(0) == 1
    ẋ(t) == -x(t)
    ∫(x(t)^2) → min
end;
Flow(ocp_cf; multipliers=((x, u) -> 1) => ((x, p) -> 1))
```

## See also

- [Multi-phase flows](@ref flows-multi-phase): concatenations and jumps.
- [Shooting](@ref flows-shooting): solve for the junction times and the initial costate.
- [State constraint](@ref examples-state-constraint): a speed constraint on the double
  integrator, from the direct solution to the shooting.

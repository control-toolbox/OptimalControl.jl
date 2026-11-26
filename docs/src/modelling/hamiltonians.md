# [Hamiltonians of a problem](@id modelling-hamiltonians)

The indirect method works with the Hamiltonians of the maximum principle. They depend only
on the problem, so they need not be written by hand: OptimalControl builds them from the
model, with the conventions of [Notation and conventions](@ref modelling-formulation-conventions).

| Object | By hand | From the problem |
| :--- | :--- | :--- |
| pseudo-Hamiltonian $H(x, p, u) = p \cdot f(x, u) + p^0 f^0(x, u)$ | `H(x, p, u) = …` | `pseudo_hamiltonian(ocp)` |
| Hamiltonian of a control law, $\mathbf{H}(x, p) = H(x, p, u(x, p))$ | `h(x, p) = …` | `hamiltonian(ocp, u)` |
| Hamiltonian of a control-free problem | `h(x, p) = …` | `hamiltonian(ocp)` |

Along an arc on which constraints are active, both take the constraints and their multipliers
with the keywords `constraints=` and `multipliers=`, see [Constraints](@ref modelling-hamiltonians-constraints).

They are also read back from a flow, see [Accessors](@ref flows-accessors). This page shows
how to get them, how to call them, and what to do with them: build a flow, write a shooting
function, or check the conditions of the maximum principle.

```@example main
using OptimalControl        # problems, Hamiltonians, flows
using OrdinaryDiffEqTsit5   # integrator of the flows
using ForwardDiff           # derivatives, to check the maximum principle
nothing # hide
```

## The pseudo-Hamiltonian

The problem of this page is the [energy minimisation](@ref examples-double-integrator-energy)
of the double integrator:

```@example main
t0, tf = 0, 1
x0, xf = [-1, 0], [0, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == xf
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end
nothing # hide
```

Its pseudo-Hamiltonian, in the normal case $p^0 = -1$, is

```math
H(x, p, u) = p_1 v + p_2 u - \frac{u^2}{2}.
```

`pseudo_hamiltonian` builds it from the model:

```@example main
H = pseudo_hamiltonian(ocp)
```

It is called with its **natural** signature, which follows the problem: here, an autonomous
problem without variable, `H(x, p, u)`:

```@example main
x, p, u = [1.0, 2.0], [3.0, 4.0], 0.5
H(x, p, u)      # p₁v + p₂u − u²/2 = 6 + 2 − 0.125
```

The **uniform** signature, `H(t, x, p, u, v)`, takes every argument whatever the problem,
with `nothing` for a missing variable:

```@example main
H(0.0, x, p, u, nothing)
```

| Problem | Natural call |
| :--- | :--- |
| autonomous, no variable | `H(x, p, u)` |
| autonomous, with a variable | `H(x, p, u, v)` |
| non-autonomous, no variable | `H(t, x, p, u)` |
| non-autonomous, with a variable | `H(t, x, p, u, v)` |

As everywhere in OptimalControl, a one-dimensional state, control or variable is a number.

### [The sign of $p^0$](@id modelling-hamiltonians-p0)

The pseudo-Hamiltonian is always **maximised**, for a minimisation and for a maximisation;
only $p^0$ depends on the criterion. The keyword `p0` gives it:

| Criterion | Normal case (default) | Abnormal case | Allowed |
| :--- | :--- | :--- | :--- |
| `min` | $p^0 = -1$ | $p^0 = 0$ | $p^0 \le 0$ |
| `max` | $p^0 = +1$ | $p^0 = 0$ | $p^0 \ge 0$ |

```@example main
pseudo_hamiltonian(ocp; p0=0)(x, p, u)   # abnormal case: p₁v + p₂u
```

A $p^0$ whose sign contradicts the criterion is rejected:

```@repl main
pseudo_hamiltonian(ocp; p0=1)
```

## The Hamiltonian of a control law

The maximisation of $H$ in $u$ gives the control in feedback form, $u(x, p) = p_2$. The
Hamiltonian of this law is

```math
\mathbf{H}(x, p) = H(x, p, u(x, p)) = p_1 v + \frac{p_2^2}{2},
```

and `hamiltonian(ocp, u)` builds it, here named `h` in the code:

```@example main
u_max(x, p) = p[2]
h = hamiltonian(ocp, u_max)
h(x, p)         # p₁v + p₂²/2 = 6 + 8
```

The law is a plain function with the natural arity of the problem (`u(x, p)`,
`u(t, x, p)`, `u(x, p, v)` or `u(t, x, p, v)`), or a typed law, see
[Passing a typed law](@ref flows-from-ocp). The keyword `p0` applies as for the
pseudo-Hamiltonian.

A [control-free problem](@ref modelling-without-control) has a Hamiltonian and no
pseudo-Hamiltonian: `hamiltonian(ocp)`, without a law, builds it.

```@example main
ocp_cf = @def begin
    t ∈ [0, 1], time
    x ∈ R, state
    x(0) == 1
    ẋ(t) == -x(t)
    ∫(x(t)^2) → min
end
hamiltonian(ocp_cf)(2.0, 3.0)   # p·(−x) − x² = −6 − 4
```

```@repl main
pseudo_hamiltonian(ocp_cf)
hamiltonian(ocp)
```

## What to do with them

### Build a flow

The flow of a problem and its law, `Flow(ocp, u)`, is the flow of the Hamiltonian of the
law. Building the flow from the Hamiltonian, as in [From Hamiltonians](@ref flows-from-hamiltonians),
gives the same extremal. From here on, `p0` is the initial costate, as in the calls of a flow,
not the keyword `p0` of the cost multiplier $p^0$ above (see
[The cost multiplier](@ref flows-from-ocp-p0)):

```@example main
p0 = [12.0, 6.0]
f = Flow(ocp, u_max)
g = Flow(h)
f(t0, x0, p0, tf), g(t0, x0, p0, tf)
```

Conversely, a flow gives back the Hamiltonian it integrates, the very same object:

```@example main
hamiltonian(f) === h
```

### Write a shooting function

A shooting function often needs a Hamiltonian, for instance for the transversality
condition of a free final time. It is safer to get it from the problem than to write it
again: the formula is written once, in the model. See [Shooting](@ref flows-shooting): for the
minimum-time problem, written with the Mayer cost $t_f \to \min$, the condition
$\mathbf{H}(t_f) = -p^0 = 1$ (see [Minimal time](@ref modelling-formulation-conventions)) is
evaluated with the pseudo-Hamiltonian of the problem, at the control of the last arc.

### Check the maximum principle

The maximisation condition says that $\partial H / \partial u = 0$ along the optimal law,
when the control is in the interior of the control set. With `ForwardDiff`:

```@example main
∂uH(x, p, u) = ForwardDiff.derivative(w -> H(x, p, w), u)
∂uH(x, p, u_max(x, p))
```

## [Partial and total derivatives](@id modelling-hamiltonians-partial-total)

The flow of a law can be built in two ways (keyword `hamiltonian_type` of `Flow`, see
[Total or partial Hamiltonian](@ref flows-from-ocp-total-partial)):

- `:total` differentiates $\mathbf{H}(x, p) = H(x, p, u(x, p))$, **through** the law:

  ```math
  \nabla_p \mathbf{H} = \frac{\partial H}{\partial p} + \Big(\frac{\partial u}{\partial p}\Big)^{\!\top}
  \frac{\partial H}{\partial u};
  ```

- `:partial` takes the partial derivatives of $H$, with the control **frozen** at the value
  of the law, $\partial H / \partial p$ at $u = u(x, p)$, as in the maximum principle.

The two differ by the terms in $\partial H / \partial u$. For the optimal law, this term
vanishes, so the two coincide:

```@example main
∇p_total = ForwardDiff.gradient(q -> h(x, q), p)
∇p_partial = ForwardDiff.gradient(q -> H(x, q, u_max(x, p)), p)
∇p_total, ∇p_partial
```

For a law that does not maximise $H$, such as $u = p_2 + 1$, it does not: $\partial H /
\partial u = -1$, and the two gradients differ. The second component of $\nabla_p$ is
$\dot v$: only the partial derivative gives $\dot v = u = p_2 + 1 = 5$, the dynamics that
the law actually drives.

```@example main
law(x, p) = p[2] + 1
h_law = hamiltonian(ocp, law)
∂uH(x, p, law(x, p)), ForwardDiff.gradient(q -> h_law(x, q), p), ForwardDiff.gradient(q -> H(x, q, law(x, p)), p)
```

The same holds for the [multipliers](@ref modelling-hamiltonians-feedback) of the
constraints, below: the total derivative goes through the multiplier in feedback form, the
partial one freezes it. Both coincide on an optimal arc, where the constraint is active.

```@example main
@assert H(x, p, u) ≈ 7.875                                  # hide
@assert h(x, p) ≈ 14.0                                      # hide
@assert ∂uH(x, p, u_max(x, p)) == 0                        # hide
@assert ∇p_total ≈ ∇p_partial ≈ [2.0, 4.0]                  # hide
@assert ForwardDiff.gradient(q -> h_law(x, q), p) ≈ [2.0, 4.0]                # hide
@assert ForwardDiff.gradient(q -> H(x, q, law(x, p)), p) ≈ [2.0, 5.0]       # hide
nothing                                                     # hide
```

## [Constraints](@id modelling-hamiltonians-constraints)

### Constraints by label

On an arc where constraints are active, the maximum principle adjoins them to the
pseudo-Hamiltonian, with their multipliers $\mu$. They are given by their **label**, and
the multiplier is an explicit argument, like the control:

```math
H(x, p, u, \mu) = p \cdot f(x, u) + p^0 f^0(x, u) + \mu \cdot c(x, u),
```

where $c \ge 0$ is the constraint on its active side, in the normalised form of
[State constraints](@ref modelling-formulation-conventions). The example is the
[speed limit](@ref examples-state-constraint-first-order): the velocity of the double
integrator is bounded by $v_{\max} = 1.2$.

```@example main
v_max = 1.2
ocp_c = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    v(t) ≤ v_max, (v_con)
    x(t0) == x0, (initial)
    x(tf) == xf
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end

Hc = pseudo_hamiltonian(ocp_c; constraints=:v_con)
μ = 2.0
Hc(x, p, u, μ) - H(x, p, u)     # μ (v_max − v) = 2 (1.2 − 2)
```

Several labels are given as a tuple, `constraints=(:a, :b)`: $\mu$ then stacks their
multipliers, in that order. The labels not given are inactive.

### [The sign of the multipliers](@id modelling-hamiltonians-sign)

The multipliers follow the sign convention of the **duals** of a solution, so that a dual
read in a solution of a direct method, `dual(sol, ocp, :label)`, has the sign the Hamiltonian
expects. Component by component:

| Bounds | Term adjoined | Multiplier $y$ |
| :--- | :--- | :--- |
| lower only, $l_b \le c$ | $y\,(c - l_b)$ | $y \ge 0$ |
| upper only, $c \le u_b$ | $y\,(u_b - c)$ | $y \ge 0$ |
| both, or $c = l_b = u_b$ | $-y\,(c - b)$, $b = u_b$ if $y > 0$, $l_b$ otherwise | signed |

For a constraint with two bounds, the active side is read on the sign of the multiplier:
$y > 0$ on the upper side, $y < 0$ on the lower side.

### Which constraints

| Kind | Adjoined | |
| :--- | :--- | :--- |
| path constraint (state, control or mixed) | yes | |
| state box, such as `v(t) ≤ v_max` | yes | the same term as the path constraint `v(t) - v_max ≤ 0` |
| control box | yes | inert in the flow, see below |
| boundary constraint | no | it gives the transversality conditions |
| variable box | no | it gives the transversality condition on the variable |

```@repl main
pseudo_hamiltonian(ocp_c; constraints=:initial)
```

A **control box** is inert in the flow: on an arc where the control is saturated,
$u = u_b$, the term $\mu\,(u_b - u)$ vanishes, and so do its derivatives in $x$ and $p$.
Its multiplier is given by the stationarity $\partial H / \partial u - \mu = 0$. This is
why it is usually left out; adjoining it gives its multiplier, to compare with the dual of
a direct method.

### [Multipliers in feedback form](@id modelling-hamiltonians-feedback)

With a control law, the multipliers of the active constraints are given in feedback form,
as `label => μ` pairs, and the Hamiltonian of the arc is

```math
\mathbf{H}(x, p) = H(x, p, u(x, p), \mu(x, p)).
```

On the boundary arc of the speed limit, $v = v_{\max}$, so $u = 0$; the maximisation
condition gives $p_2 = 0$, and the adjoint equation $\dot p_2 = -p_1 + \mu = 0$ gives
$\mu = p_1$:

```@example main
μ_b(x, p) = p[1]
h_b = hamiltonian(ocp_c, (x, p) -> 0; multipliers=:v_con => μ_b)
h_b([-0.8, v_max], [38.4, 0.0])   # p₁ v_max on the arc
```

The flow of the arc is `Flow(ocp_c, (x, p) -> 0; constraint=:v_con, multiplier=μ_b)`, see
[Constrained arcs](@ref flows-constrained-arcs). The
[speed limit example](@ref examples-state-constraint-first-order) solves the problem by
shooting, and compares the multiplier with the dual of a direct method.

```@example main
@assert Hc(x, p, u, μ) - H(x, p, u) ≈ 2 * (v_max - 2)   # hide
@assert h_b([-0.8, v_max], [38.4, 0.0]) ≈ 38.4 * v_max  # hide
nothing                                                 # hide
```

## See also

- [Notation and conventions](@ref modelling-formulation-conventions): $p^0$ and the signs.
- [From an OCP](@ref flows-from-ocp): the flows built on these Hamiltonians.
- [Accessors](@ref flows-accessors): the Hamiltonians read back from a flow.
- [Constrained arcs](@ref flows-constrained-arcs): the flows of boundary arcs.

# [Constrained arcs](@id flows-constrained-arcs)

```@meta
Draft = false
```

A flow along a boundary arc — where a state constraint is active — needs the constraint and
its multiplier, not just the control law.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
nothing # hide
```

## The setting

A state constraint active on a sub-interval turns the PMP into a three-piece story:
unconstrained arc, boundary arc (where the constraint is tight and pins down both the control
and the multiplier in feedback form), unconstrained arc again. The boundary arc's flow needs
that extra structure.

```@example main
t0 = 0.0
tf = 1.0
x0 = [-1.0, 0.0]
VMAX = 1.2

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    v(t) + 0.0 ≤ VMAX, (vmax)
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end
nothing # hide
```

## Building the constrained flow

```@example main
g(x) = VMAX - x[2]      # ≥ 0 while the constraint holds
μ(x, p) = p[1]           # multiplier in feedback form on the boundary
law(x, p) = 0.0           # control on the boundary arc

f_boundary = Flow(ocp, law; constraint=(x, u) -> g(x), multiplier=μ)
xf, pf = f_boundary(t0, x0, [12.0, 6.0], tf)
xf
```

`constraint=`/`multiplier=` must be given **as a pair** — one without the other is rejected:

```@repl main
try # hide
Flow(ocp, law; constraint=:vmax)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Three ways to give the constraint

**A plain `Function`** — the form above, `(x, u) -> g(x)` paired with `multiplier=μ`.

**A typed `Data.StateConstraint`** (or `ControlConstraint`/`MixedConstraint`/`PathConstraint`
for the other shapes) — equivalent, more explicit:

```@example main
f_typed = Flow(ocp, law; constraint=StateConstraint(g), multiplier=μ)
f_typed(t0, x0, [12.0, 6.0], tf)[1] ≈ xf
```

**A `Symbol` naming a `:path` constraint already declared in the OCP** — the standout
capability here, not just a rename:

```@example main
f_sym = Flow(ocp, law; constraint=:vmax, multiplier=μ)
typeof(f_sym)
```

An unknown label is rejected, not silently accepted:

```@repl main
try # hide
Flow(ocp, law; constraint=:nope, multiplier=μ)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

!!! warning "The `Symbol` form uses the model's own sign convention"

    `constraint=:vmax` pulls the constraint straight from the OCP — `v(t) ≤ V_{max}` as
    written there — rather than whatever hand-derived $g(x) \geq 0$ you might use in a
    shooting function. The two are **not guaranteed to agree numerically** unless you match
    conventions yourself; pick one style per problem and stay consistent, don't mix a
    hand-rolled `g`/`μ` pair with the model's own label expecting them to be interchangeable.

## Several constraints at once

Pass matched tuples of functions (or labels) and multipliers, one per active constraint on the
boundary arc, in place of the single values above.

## Assembling the arcs

A boundary arc is one phase in a larger [multi-phase flow](@ref flows-multi-phase):
unconstrained arc, then the constrained flow from `t1` (constraint activation), then
unconstrained again from `t2` (exit) — with a jump on the costate at each switch if the
constraint order requires one.

## Positional form is gone

```@repl main
try # hide
Flow(ocp, law, (x, u) -> g(x), μ)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Partial Hamiltonian on a constrained arc

`hamiltonian_type=:partial` (see [From an OCP](@ref flows-from-ocp)) is supported here too — the
boundary arc's law is stationary for the constrained pseudo-Hamiltonian at the optimum, same as
the unconstrained case, so `:total` and `:partial` still agree when the law is genuinely
optimal.

## Control-free flows reject constraints

```@repl main
ocp_cf = @def begin
    t ∈ [t0, tf], time
    x ∈ R, state
    x(t0) == 1.0
    ẋ(t) == -x(t)
    ∫(x(t)^2) → min
end;
try # hide
Flow(ocp_cf; constraint=(x, u) -> 1.0, multiplier=(x, p) -> 1.0)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## See also

- [Multi-phase flows](@ref flows-multi-phase) — assembling several arcs, constrained or not,
  into one callable flow.
- [Writing a shooting function](@ref flows-shooting) — solving for the switching times
  themselves rather than assuming them known.

# [Inspect a problem](@id modelling-inspect)

Once a problem is built — via [`@def`](@ref) or the [functional API](@ref modelling-functional-api) — every part of it can be read back: dimensions, names, dynamics, costs, constraints, traits. This page is about reading a model, not solving it: for that, see [Solve overview](@ref solve-overview); for the indirect/PMP route, see [Flows overview](@ref flows-overview).

```@example main
using OptimalControl
nothing # hide
```

A model prints as a readable summary:

```@example main
ocp = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t)  == [v(t), u(t)]
    0.5∫( u(t)^2 ) → min
end
ocp
```

To illustrate the accessors below, we use a richer problem: free final time, a variable, and several kinds of constraints.

```@raw html
<!--
dev note (not rendered): the executed block below is the single source of truth for the
problem shown in the highlighted blocks of this page. It is tagged by the comment just
under this note. A julia code block that contains only
@inspect-model richer "fragment" "fragment" ...
is rewritten when VitePress renders the page (docs/src/.vitepress/inspect-model.ts, hooked
in config.mts): it takes the problem tagged with that id and appends "# [!code warning]" to
the lines containing a fragment (plain substrings, whitespace collapsed). An unknown id
fails the build. To reuse this on another page, tag the executed problem the same way.
-->
```

```@raw html
<!-- model: richer -->
```

```@example main
ocp = @def begin
    v = (w, tf) ∈ R²,   variable
    s ∈ [0, tf],        time
    q = (x, y) ∈ R²,    state
    u ∈ R,              control
    0 ≤ tf ≤ 2,         (1)
    u(s) ≥ 0,           (cons_u)
    x(s) + u(s) ≤ 10,   (cons_mixed)
    0 ≤ y(s) ≤ 4,       (cons_state)
    w == 0
    x(0) == -1
    y(0) - tf == 0,     (cons_bound)
    q(tf) == [0, 0]
    q̇(s) == [y(s)+w, u(s)]
    0.5∫( u(s)^2 ) → min
end
nothing # hide
```

## Times

Everything in the time declaration can be read back: the interval, the time name, and whether each bound is fixed or comes from the variable.

```@raw html
<!-- dev note (not rendered): copy of the problem tagged "richer", built at render time; see the note before it. -->
```

```julia
@inspect-model richer "variable" "time"
```

### Times model

The times component of the model is a [`TimesModel`](@extref CTModels.Components.TimesModel): it holds the initial and the final time — each a [`FixedTimeModel`](@extref CTModels.Components.FixedTimeModel) or a [`FreeTimeModel`](@extref CTModels.Components.FreeTimeModel) — and the name of the time variable:

```@example main
tm = times(ocp)
```

You rarely need this object itself: the accessors below take the problem directly. They also accept the component, which is how they are defined in CTModels — see the documentation of [`TimesModel`](@extref CTModels.Components.TimesModel) and of [`initial_time`](@extref CTModels.Components.initial_time) / [`final_time`](@extref CTModels.Components.final_time):

```@repl main
initial_time(tm)
final_time(tm, [1, 2])   # w = 1, tf = 2
```

On a solution, `times(sol)` returns something else: the time grid, a vector (see
[Solution object](@ref results-solution)).

Initial and final times separately. The final time needs the variable value when it is free:

```@repl main
initial_time(ocp)
final_time(ocp, [1, 2])   # w = 1, tf = 2
```

Asking for a free final time without the variable raises an error, whose hint says to pass
the variable:

```@repl main
final_time(ocp)
```

### Time variable names

The same pieces as names — the time symbol, and the name or value of each bound:

```@repl main
time_name(ocp)           # "s"
initial_time_name(ocp)   # "0" — fixed
final_time_name(ocp)     # "tf" — a variable
```

### Free time index

When a bound is free, its [`FreeTimeModel`](@extref CTModels.Components.FreeTimeModel) records which component of the variable holds it. [`index`](@extref CTModels.Components.index) reads that position; it applies to the bound itself (the `initial` and `final` fields of the `TimesModel`), not to the problem:

```@repl main
index(tm.final)   # tf is the 2nd component of v = (w, tf)
```

### Time fixedness predicates

Whether each bound is fixed or read from the variable:

```@repl main
has_fixed_initial_time(ocp)
has_free_initial_time(ocp)
has_fixed_final_time(ocp)
has_free_final_time(ocp)
```

### Autonomy

Whether the problem depends explicitly on the time variable:

```@repl main
is_autonomous(ocp)
```

What counts as an explicit dependence, with examples, is in [Time dependence](@ref modelling-inspect-time-dependence) below.

## State

The state declaration gives back its name, dimension and component names; box constraints on state components have their own accessors.

```@raw html
<!-- dev note (not rendered): copy of the problem tagged "richer", built at render time; see the note before it. -->
```

```julia
@inspect-model richer "R², state" "(cons_state)"
```

### State component information

Name, dimension and per-component names:

```@repl main
state_name(ocp)
state_dimension(ocp)
state_components(ocp)
```

!!! note
    The component names are used when plotting the solution. See [Plot with Plots](@ref results-plot).

### State box constraints

The box constraints declared on state components, as a tuple:

```@repl main
state_constraints_box(ocp)
```

!!! note "Tuple structures"
    Box-constraint accessors (`state_constraints_box`, `control_constraints_box`,
    `variable_constraints_box`) return `(lb, indices, ub, labels, aliases)`:
    - `lb`, `ub` — vectors of lower / upper bounds
    - `indices` — component indices (1-based)
    - `labels` — constraint labels
    - `aliases` — for each component, every label that declared it

    The nonlinear-constraint accessors (`path_constraints_nl`, `boundary_constraints_nl`)
    return `(lb, f!, ub, labels)` instead, with `f!` in-place: `f!(val, t, x, u, v)` for path
    constraints, `f!(val, x0, xf, v)` for boundary constraints.

Just the count of state components under a box:

```@repl main
dim_state_constraints_box(ocp)
```

!!! note "By label"
    A declared constraint can also be read back by its label — e.g. `constraint(ocp, :cons_state)`. See
    [Constraints](@ref modelling-inspect-constraints).

## Control

Same for the control: name, dimension, components, its box constraint, and a presence predicate.

```@raw html
<!-- dev note (not rendered): copy of the problem tagged "richer", built at render time; see the note before it. -->
```

```julia
@inspect-model richer "u ∈ R, control" "(cons_u)"
```

### Control component information

Name, dimension and per-component names:

```@repl main
control_name(ocp)
control_dimension(ocp)
control_components(ocp)
```

### Control box constraints

The control box `cons_u`, same tuple structure, and its count:

```@repl main
control_constraints_box(ocp)
dim_control_constraints_box(ocp)
```

!!! note "By label"
    A declared constraint can also be read back by its label — e.g. `constraint(ocp, :cons_u)`. See
    [Constraints](@ref modelling-inspect-constraints).

### Control presence

Whether the problem declares a control at all:

```@repl main
has_control(ocp)  # true if the problem has a control input
```

`is_control_free(ocp) ≡ !has_control(ocp)`: see [Control-free problems](@ref modelling-without-control).

## Variable

The variable is inspected the same way — name, dimension, components and its box constraint.

```@raw html
<!-- dev note (not rendered): copy of the problem tagged "richer", built at render time; see the note before it. -->
```

```julia
@inspect-model richer "variable" "(1)" "w == 0"
```

### Variable component information

Name, dimension and per-component names:

```@repl main
variable_name(ocp)
variable_dimension(ocp)
variable_components(ocp)
```

### Variable box constraints

The tuple has two entries: the `(1)` box bounds `tf` (index 2), and the equality
`w == 0` is stored as a box with equal bounds on `w` (index 1). Same tuple structure,
and the count:

```@repl main
variable_constraints_box(ocp)
dim_variable_constraints_box(ocp)
```

!!! note "By label"
    A declared constraint can also be read back by its label — e.g. `constraint(ocp, :eq1)` for the `(1)` box. See
    [Constraints](@ref modelling-inspect-constraints). A constraint declared without a label gets an
    automatic one, `Symbol("label##…")` above: read it from the tuple to pass it to `constraint`.

### Variable presence

Whether the problem declares an optimisation variable:

```@repl main
has_variable(ocp)  # true if the problem has optimisation variables
```

## Dynamics

The dynamics are stored as an in-place function `f!(dx, t, x, u, v)` — `dx` is mutated, the other arguments are time, state, control, variable. The highlighted line is what [`dynamics`](@ref) returns:

```@raw html
<!-- dev note (not rendered): copy of the problem tagged "richer", built at render time; see the note before it. -->
```

```julia
@inspect-model richer "q̇(s) =="
```

Retrieve it and evaluate it at a point:

```@example main
s1 = 0.5; q1 = [0.0, 1.0]; u1 = 2.0; v1 = [1.0, 2.0]   # values at which to evaluate
dq = similar(q1)
nothing # hide
```

```@repl main
f! = dynamics(ocp)
f!(dq, s1, q1, u1, v1)
dq  # the state derivative q̇
```

## Objective

The objective reads as a criterion plus its cost functions — Mayer, Lagrange or both.

```@raw html
<!-- dev note (not rendered): copy of the problem tagged "richer", built at render time; see the note before it. -->
```

```julia
@inspect-model richer "→ min"
```

The sense of the optimisation:

```@repl main
criterion(ocp)  # :min or :max
```

The objective is in Mayer form $g(x(t_0), x(t_f), v)$, Lagrange form $\int_{t_0}^{t_f} f^0(t, x(t), u(t), v)\, \mathrm{d}t$, or Bolza form (both):

```@repl main
has_mayer_cost(ocp)
has_lagrange_cost(ocp)
```

Get the cost functions: `mayer` has signature `g(x0, xf, v)` and raises an error when there is no Mayer cost (check first with `has_mayer_cost`); `lagrange` has signature `f⁰(t, x, u, v)`:

```@repl main
mayer(ocp)
```

Evaluate the integrand at a point:

```@repl main
f⁰ = lagrange(ocp)
f⁰(s1, q1, u1, v1)  # the integrand value
```

## [Constraints](@id modelling-inspect-constraints)

Every declared constraint is retrievable by its label — type, function and bounds — and all of them in bulk.

```@raw html
<!-- dev note (not rendered): copy of the problem tagged "richer", built at render time; see the note before it. -->
```

```julia
@inspect-model richer "(1)" "(cons_u)" "(cons_mixed)" "(cons_state)" "w == 0" "x(0) == -1" "(cons_bound)" "q(tf) == [0, 0]"
```

### Individual constraints

`constraint(ocp, label)` returns `(type, f, lb, ub)`. The function signature is `f(x0, xf, v)` for `:boundary` and `:variable` constraints, `f(t, x, u, v)` for `:control`, `:state` and `:path` ones. The constraint `0 ≤ tf ≤ 2` was labelled `(1)`, which is stored as `:eq1` (see [Labels](@ref modelling-abstract-syntax-labels)):

```@example main
x0 = [0, 1]; xf = [2, 3]; v1 = [1, 4]        # boundary values and variable
s1 = 0.5; q1 = [1.0, 2.0]; u1 = 3.0          # time, state and control values
```

```@repl main
(type, f, lb, ub) = constraint(ocp, :eq1)
f(x0, xf, v1)
```

A boundary constraint:

```@repl main
(type, f, lb, ub) = constraint(ocp, :cons_bound)
f(x0, xf, v1)
```

A control constraint:

```@repl main
(type, f, lb, ub) = constraint(ocp, :cons_u)
f(s1, q1, u1, v1)
```

A path constraint — here a mixed one, on `x` and `u` together:

```@repl main
(type, f, lb, ub) = constraint(ocp, :cons_mixed)
f(s1, q1, u1, v1)
```

### All constraints, and nonlinear ones

The accessors above all read from one object, the constraints model, a
[`ConstraintsModel`](@extref CTModels.Components.ConstraintsModel). It groups the declared
constraints by kind into five parts: the nonlinear path and boundary constraints, and the box
constraints on the state, the control and the variable. Each part is the tuple described in
[State box constraints](@ref "State box constraints"). It is rarely used directly, since
`state_constraints_box(ocp)`, `path_constraints_nl(ocp)` and the others return its parts.

```@repl main
constraints(ocp)
```

The nonlinear groups, path and boundary, with their sizes. Here `f!` is the in-place function
that evaluates all the constraints of the group at once, see
[`path_constraints_nl`](@extref CTModels.Components.path_constraints_nl) and
[`boundary_constraints_nl`](@extref CTModels.Components.boundary_constraints_nl):

```@repl main
path_constraints_nl(ocp)
boundary_constraints_nl(ocp)
dim_path_constraints_nl(ocp)
dim_boundary_constraints_nl(ocp)
```

!!! note
    To get the dual variable (Lagrange multiplier) of a constraint, use [`dual`](@ref) on a
    solution — see [Solution object](@ref results-solution).

## Problem definition

The `@def` block is stored verbatim on the model: `definition` returns the recorded definition, `expression` the underlying `Expr`, and `has_abstract_definition` tells whether there is one.

```@repl main
definition(ocp)  # the definition recorded by @def
```

The raw `Expr` behind it:

```@repl main
expr = expression(ocp)  # the Expr from the definition
```

Whether a definition was recorded at all — false for a functional-API model:

```@repl main
has_abstract_definition(ocp)  # false for a functional-API model
```

## [Time dependence](@id modelling-inspect-time-dependence)

These examples use small problems of their own, so that the model above is left untouched. A problem is **autonomous** when neither the dynamics, nor the Lagrange cost, nor any path constraint depends explicitly on the time variable, and **non-autonomous** otherwise.

```@repl main
ocp_auto = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t)
    x(1) + 0.5∫( u(t)^2 ) → min
end;
is_autonomous(ocp_auto)
```

Adding an explicit `t` to the dynamics (or to the Lagrange integrand) makes it non-autonomous:

```@repl main
ocp_dyn = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t) + t                  # explicit dependence on t
    x(1) + 0.5∫( u(t)^2 ) → min
end;
is_autonomous(ocp_dyn)
```

A path constraint that depends on `t` has the same effect:

```@repl main
ocp_path = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    x(t) - t ≤ 1                       # explicit dependence on t
    ẋ(t)  == u(t)
    x(1) + 0.5∫( u(t)^2 ) → min
end;
is_autonomous(ocp_path)
```

The same question, negated:

```@repl main
is_nonautonomous(ocp_path)  # the negation of is_autonomous
```

## `times`, not `time`

The time accessor is `times(ocp)`, shown above. `time` is Julia's `Base.time` (the wall-clock
time): calling `time(ocp)` raises an error whose hint is `use times(ocp)`. Coming from v2.0?
See [Migrating from v2.0](@ref migration).

## Signatures and `is_*` aliases

Every accessor on this page is listed with its full signature and return type in the
[Problem API reference](@ref api-problem). Many predicates also have an `is_*` counterpart. Only the
`has_*` and `is_autonomous` forms are shown above.

| Predicate | Alias | Relation |
| :-- | :-- | :-- |
| `has_variable` | `is_variable` | equivalent |
| `has_variable` | `is_nonvariable` | negation |
| `has_control` | `is_control_free` | negation |
| `is_autonomous` | `is_nonautonomous` | negation |
| `has_fixed_initial_time` | `is_initial_time_fixed` | equivalent |
| `has_free_initial_time` | `is_initial_time_free` | equivalent |
| `has_fixed_final_time` | `is_final_time_fixed` | equivalent |
| `has_free_final_time` | `is_final_time_free` | equivalent |
| `has_mayer_cost` | `is_mayer_cost_defined` | equivalent |
| `has_lagrange_cost` | `is_lagrange_cost_defined` | equivalent |
| `has_abstract_definition` | `is_abstractly_defined` | equivalent |

## See also

- [Formulation](@ref modelling-formulation) — the mathematics behind these fields.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) · [Functional API](@ref modelling-functional-api) — building the model this page reads.
- [Solve overview](@ref solve-overview) — solving it.
- [Solution object](@ref results-solution) — the symmetric page for reading back a *solution* rather than a *problem*.

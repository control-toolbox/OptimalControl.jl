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

```@example main
ocp = @def begin
    v = (w, tf) ∈ R²,   variable
    s ∈ [0, tf],        time
    q = (x, y) ∈ R²,    state
    u ∈ R,              control
    0 ≤ tf ≤ 2,         (1)
    u(s) ≥ 0,           (cons_u)
    x(s) + u(s) ≤ 10,   (cons_mixed)
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

### Times model

```@example main
times(ocp)  # a struct describing the initial and final times
```

On a solution, `times(sol)` returns something else: the time grid, a vector (see
[Solution object](@ref results-solution)).

Initial and final times separately. The final time needs the variable value when it is free:

```@repl main
initial_time(ocp)
final_time(ocp, [1, 2])   # w = 1, tf = 2
```

Asking for a free final time without the variable errors (the hint is not explicit yet, see
[CTModels#431](https://github.com/control-toolbox/CTModels.jl/issues/431)):

```@repl main
final_time(ocp)
```

### Time variable names

```@repl main
time_name(ocp)           # "s"
initial_time_name(ocp)   # "0" — fixed
final_time_name(ocp)     # "tf" — a variable
```

### Time fixedness predicates

```@repl main
has_fixed_initial_time(ocp)
has_free_initial_time(ocp)
has_fixed_final_time(ocp)
has_free_final_time(ocp)
```

### Autonomy

```@example main
is_autonomous(ocp)  # false if the dynamics, the Lagrange cost or a path constraint depend on t
```

See [Time dependence](@ref modelling-inspect-time-dependence) below.

## State

### State component information

```@repl main
state_name(ocp)
state_dimension(ocp)
state_components(ocp)
```

!!! note
    The component names are used when plotting the solution. See [Plot](@ref results-plot).

### State box constraints

```@example main
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

```@example main
dim_state_constraints_box(ocp)
```

## Control

### Control component information

```@repl main
control_name(ocp)
control_dimension(ocp)
control_components(ocp)
```

### Control box constraints

```@repl main
control_constraints_box(ocp)
dim_control_constraints_box(ocp)
```

### Control presence

```@example main
has_control(ocp)  # true if the problem has a control input
```

`is_control_free(ocp) ≡ !has_control(ocp)`: see [Control-free problems](@ref modelling-without-control).

## Variable

### Variable component information

```@repl main
variable_name(ocp)
variable_dimension(ocp)
variable_components(ocp)
```

### Variable box constraints

```@repl main
variable_constraints_box(ocp)
dim_variable_constraints_box(ocp)
```

### Variable presence

```@example main
has_variable(ocp)  # true if the problem has optimisation variables
```

## Dynamics

The dynamics are stored as an in-place function `f!(dx, t, x, u, v)` — `dx` is mutated, the other arguments are time, state, control, variable:

```@example main
f! = dynamics(ocp)
s1 = 0.5; q1 = [0.0, 1.0]; u1 = 2.0; v1 = [1.0, 2.0]   # values at which to evaluate
dq = similar(q1)
f!(dq, s1, q1, u1, v1)
dq  # the state derivative q̇
```

## Objective

```@example main
criterion(ocp)  # :min or :max
```

The objective is in Mayer form $g(x(t_0), x(t_f), v)$, Lagrange form $\int_{t_0}^{t_f} f^0(t, x(t), u(t), v)\, \mathrm{d}t$, or Bolza form (both):

```@repl main
has_mayer_cost(ocp)
has_lagrange_cost(ocp)
```

Get the cost functions: `mayer` has signature `g(x0, xf, v)` and errors when there is no Mayer cost (with a hint that does not apply to a built model, see [CTModels#431](https://github.com/control-toolbox/CTModels.jl/issues/431)); `lagrange` has signature `f⁰(t, x, u, v)`:

```@repl main
mayer(ocp)
```

```@example main
f⁰ = lagrange(ocp)
f⁰(s1, q1, u1, v1)  # the integrand value
```

## Constraints

### Individual constraints

`constraint(ocp, label)` returns `(type, f, lb, ub)`. The function signature is `f(x0, xf, v)` for `:boundary` and `:variable` constraints, `f(t, x, u, v)` for `:control`, `:state` and `:mixed` ones. The constraint `0 ≤ tf ≤ 2` was labelled `(1)`, which is stored as `:eq1` (see [Labels](@ref modelling-abstract-syntax-labels)):

```@example main
x0 = [0, 1]; xf = [2, 3]; v1 = [1, 4]        # boundary values and variable
s1 = 0.5; q1 = [1.0, 2.0]; u1 = 3.0          # time, state and control values

(type, f, lb, ub) = constraint(ocp, :eq1)
(type, f(x0, xf, v1), lb, ub)
```

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_bound)   # a boundary constraint
(type, f(x0, xf, v1))
```

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_u)       # a control constraint
(type, f(s1, q1, u1, v1))
```

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_mixed)  # a mixed path constraint
(type, f(s1, q1, u1, v1))
```

### All constraints, and nonlinear ones

```@example main
constraints(ocp)
```

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

```@example main
definition(ocp)  # the definition recorded by @def
```

```@example main
expr = expression(ocp)  # the Expr from the definition
nothing # hide
```

```@example main
has_abstract_definition(ocp)  # false for a functional-API model
```

## [Time dependence](@id modelling-inspect-time-dependence)

A problem is **autonomous** when neither the dynamics, nor the Lagrange cost, nor any path constraint depends explicitly on the time variable, and **non-autonomous** otherwise.

```@example main
ocp = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t)
    x(1) + 0.5∫( u(t)^2 ) → min
end
is_autonomous(ocp)
```

Adding an explicit `t` to the dynamics (or to the Lagrange integrand) makes it non-autonomous:

```@example main
ocp = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t) + t                  # explicit dependence on t
    x(1) + 0.5∫( u(t)^2 ) → min
end
is_autonomous(ocp)
```

A path constraint that depends on `t` has the same effect:

```@example main
ocp = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    x(t) - t ≤ 1                       # explicit dependence on t
    ẋ(t)  == u(t)
    x(1) + 0.5∫( u(t)^2 ) → min
end
is_autonomous(ocp)
```

```@example main
is_nonautonomous(ocp)  # the negation of is_autonomous
```

## `times`, not `time`

The time accessor is `times(ocp)`, shown above. `time` is Julia's `Base.time` (the wall-clock
time): calling `time(ocp)` raises an error whose hint is `use times(ocp)`. Coming from v2.0?
See [Migration](@ref migration).

## Signatures and `is_*` aliases

Every accessor on this page is listed with its full signature and return type in the
[Problem API reference](@ref api-problem). Many predicates also have an `is_*` counterpart (equivalent, or its negation as for
`has_control` / `is_control_free`): `has_variable` / `is_variable` / `is_nonvariable`,
`is_autonomous` / `is_nonautonomous`, `has_fixed_final_time` / `is_final_time_fixed` (and the
three other time variants), `has_mayer_cost` / `is_mayer_cost_defined`,
`has_lagrange_cost` / `is_lagrange_cost_defined`, `has_abstract_definition` /
`is_abstractly_defined`. Only the `has_*` and `is_autonomous` forms are shown above.

## See also

- [Formulation](@ref modelling-formulation) — the mathematics behind these fields.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) · [Functional API](@ref modelling-functional-api) — building the model this page reads.
- [Solve overview](@ref solve-overview) — solving it.
- [Solution object](@ref results-solution) — the symmetric page for reading back a *solution* rather than a *problem*.

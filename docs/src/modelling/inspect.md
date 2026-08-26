# [Inspect a problem](@id modelling-inspect)

```@meta
Draft = false
```

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

To illustrate the accessors in the sections below, we use a richer problem: free final time, a variable, and several kinds of constraints.

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

The time component defines the temporal domain of the optimal control problem.

### Times model

Get the times model:

```@example main
times(ocp)  # returns the TimesModel struct containing time information
```

You can also access initial and final times separately:

```@example main
initial_time(ocp)  # returns the initial time value
```

For the final time, if it is free (part of the variable), you need to provide the variable value:

```@example main
v = [1, 2]  # example variable values: w=1, tf=2
final_time(ocp, v)  # returns tf value from variable
```

If you try to get the final time without providing the variable when it's free, an error occurs:

```@repl main
final_time(ocp)  # error: tf is free, need variable
```

### Time variable names

Get the names of the time variable and time bounds:

```@example main
time_name(ocp)  # returns "s" (the time variable name in this OCP)
```

```@example main
initial_time_name(ocp)  # returns "0" (initial time is fixed at 0)
```

```@example main
final_time_name(ocp)  # returns "tf" (final time is a variable)
```

### Time fixedness predicates

Check whether initial or final times are fixed or free:

```@example main
has_fixed_initial_time(ocp)  # true if t0 is fixed
```

```@example main
has_free_initial_time(ocp)  # true if t0 is free (part of variable)
```

!!! note "Variant methods"
    Alternative methods with `is_*` prefix are also available and equivalent:
    - `is_initial_time_fixed(ocp)` ≡ `has_fixed_initial_time(ocp)`
    - `is_initial_time_free(ocp)` ≡ `has_free_initial_time(ocp)`
    - `is_final_time_fixed(ocp)` ≡ `has_fixed_final_time(ocp)`
    - `is_final_time_free(ocp)` ≡ `has_free_final_time(ocp)`

Similarly for final time:

```@example main
has_fixed_final_time(ocp)  # false (tf is free in this OCP)
```

```@example main
has_free_final_time(ocp)  # true (tf is part of variable v)
```

### Autonomy

Check if the dynamics and Lagrange cost are autonomous (time-independent):

```@example main
is_autonomous(ocp)  # false if dynamics or cost depend on time
```

For more details on autonomy, see the [Time dependence](@ref modelling-inspect-time-dependence) section below.

### [Summary table](@id modelling-inspect-summary-time)

| Method | Returns | Description |
| -------- | --------- | --------- |
| `times(ocp)` | `(Float64, Any)` | Time interval (t0, tf) or (t0, tf_name) |
| `initial_time(ocp)` | `Float64` | Initial time t0 |
| `final_time(ocp)` | `Float64` | Final time tf (error if free) |
| `final_time(ocp, v)` | `Float64` | Final time tf from variable v |
| `time_name(ocp)` | `String` | Time variable name |
| `initial_time_name(ocp)` | `String` | Initial time name or value |
| `final_time_name(ocp)` | `String` | Final time name or value |
| `has_fixed_initial_time(ocp)` | `Bool` | True if t0 is fixed |
| `has_free_initial_time(ocp)` | `Bool` | True if t0 is free |
| `has_fixed_final_time(ocp)` | `Bool` | True if tf is fixed |
| `has_free_final_time(ocp)` | `Bool` | True if tf is free |
| `is_autonomous(ocp)` | `Bool` | True if time-independent |

## State

The state component represents the state variables of the optimal control problem.

### State component information

Get the name, dimension, and component names of the state:

```@example main
state_name(ocp)  # returns "q" (the state variable name)
```

```@example main
state_dimension(ocp)  # returns 2 (dimension of state)
```

```@example main
state_components(ocp)  # returns ["x", "y"] (component names)
```

!!! note

    The component names are used when plotting the solution. See [Plot](@ref results-plot).

### State box constraints

Get the box constraints on the state (lower and upper bounds):

```@example main
state_constraints_box(ocp)  # returns box constraints if any
```

!!! note "Tuple structure"
    The returned tuple has the structure `(lb, indices, ub, labels, aliases)` where:
    - `lb`: vector of lower bounds
    - `indices`: vector of component indices (1-based)
    - `ub`: vector of upper bounds
    - `labels`: vector of constraint labels
    - `aliases`: vector of vectors containing all labels that declared each component

Get the dimension of state box constraints:

```@example main
dim_state_constraints_box(ocp)  # returns number of box constraints on state
```

### [Summary table](@id modelling-inspect-summary-state)

| Method | Returns | Description |
| -------- | --------- | --------- |
| `state_name(ocp)` | `String` | State variable name |
| `state_dimension(ocp)` | `Int` | State dimension |
| `state_components(ocp)` | `Vector{String}` | State component names |
| `state_constraints_box(ocp)` | Box constraints | State box constraints |
| `dim_state_constraints_box(ocp)` | `Int` | Number of state box constraints |

## Control

The control component represents the control variables of the optimal control problem.

### Control component information

Get the name, dimension, and component names of the control:

```@example main
control_name(ocp)  # returns "u" (the control variable name)
```

```@example main
control_dimension(ocp)  # returns 1 (dimension of control)
```

```@example main
control_components(ocp)  # returns ["u"] (component names)
```

### Control box constraints

Get the box constraints on the control:

```@example main
control_constraints_box(ocp)  # returns box constraints if any
```

!!! note "Tuple structure"
    The returned tuple has the structure `(lb, indices, ub, labels, aliases)` where:
    - `lb`: vector of lower bounds
    - `indices`: vector of component indices (1-based)
    - `ub`: vector of upper bounds
    - `labels`: vector of constraint labels
    - `aliases`: vector of vectors containing all labels that declared each component

Get the dimension of control box constraints:

```@example main
dim_control_constraints_box(ocp)  # returns number of box constraints on control
```

### Control presence

Check whether the problem has a control input:

```@example main
has_control(ocp)  # true if problem has a control input
```

!!! note "Variant method"

    - `is_control_free(ocp)` ≡ `!has_control(ocp)`. See [Problems without a control](@ref modelling-without-control).

### [Summary table](@id modelling-inspect-summary-control)

| Method | Returns | Description |
| -------- | --------- | --------- |
| `control_name(ocp)` | `String` | Control variable name |
| `control_dimension(ocp)` | `Int` | Control dimension |
| `control_components(ocp)` | `Vector{String}` | Control component names |
| `control_constraints_box(ocp)` | Box constraints | Control box constraints |
| `dim_control_constraints_box(ocp)` | `Int` | Number of control box constraints |
| `has_control(ocp)` | `Bool` | True if problem has a control input |
| `is_control_free(ocp)` | `Bool` | True if problem has no control (`≡ !has_control`) |

## Variable

The variable component represents the optimization variables (parameters) of the optimal control problem.

### Variable component information

Get the name, dimension, and component names of the variable:

```@example main
variable_name(ocp)  # returns "v" (the variable name)
```

```@example main
variable_dimension(ocp)  # returns 2 (dimension of variable)
```

```@example main
variable_components(ocp)  # returns ["w", "tf"] (component names)
```

### Variable box constraints

Get the box constraints on the variable:

```@example main
variable_constraints_box(ocp)  # returns box constraints if any
```

!!! note "Tuple structure"
    The returned tuple has the structure `(lb, indices, ub, labels, aliases)` where:
    - `lb`: vector of lower bounds
    - `indices`: vector of component indices (1-based)
    - `ub`: vector of upper bounds
    - `labels`: vector of constraint labels
    - `aliases`: vector of vectors containing all labels that declared each component

Get the dimension of variable box constraints:

```@example main
dim_variable_constraints_box(ocp)  # returns number of box constraints on variable
```

### Variable presence

Check whether the problem has optimization variables:

```@example main
has_variable(ocp)  # true if problem has optimization variables
```

!!! note "Variant methods"

    - `is_variable(ocp)` ≡ `has_variable(ocp)`
    - `is_nonvariable(ocp)` ≡ `!has_variable(ocp)`

### [Summary table](@id modelling-inspect-summary-variable)

| Method | Returns | Description |
| -------- | --------- | --------- |
| `variable_name(ocp)` | `String` | Variable name |
| `variable_dimension(ocp)` | `Int` | Variable dimension |
| `variable_components(ocp)` | `Vector{String}` | Variable component names |
| `variable_constraints_box(ocp)` | Box constraints | Variable box constraints |
| `dim_variable_constraints_box(ocp)` | `Int` | Number of variable box constraints |
| `has_variable(ocp)` | `Bool` | True if problem has optimization variables |
| `is_variable(ocp)` | `Bool` | Alias for `has_variable` |
| `is_nonvariable(ocp)` | `Bool` | True if problem has no variables (`≡ !has_variable`) |

## Dynamics

The dynamics component defines the differential equations governing the state evolution.

### Dynamics function

The dynamics are stored as an in-place function of the form `f!(dx, t, x, u, v)`:

```@example main
f! = dynamics(ocp)
s = 0.5  # time
q = [0.0, 1.0]  # state
u = 2.0  # control (scalar: control_dimension(ocp) == 1)
v = [1.0, 2.0]  # variable
dq = similar(q)
f!(dq, s, q, u, v)
dq  # returns the derivative q̇
```

The first argument `dx` is mutated upon call and contains the state derivative. The other arguments are:

* `t`: time
* `x`: state
* `u`: control
* `v`: variable

### [Summary table](@id modelling-inspect-summary-dynamics)

| Method | Returns | Description |
| -------- | --------- | --------- |
| `dynamics(ocp)` | `Function` | In-place dynamics function f!(dx, t, x, u, v) |

## Objective

The objective component defines the cost function to minimize or maximize.

### Criterion

The criterion indicates whether the problem is a minimization or maximization:

```@example main
criterion(ocp)  # returns :min or :max
```

### Objective form

The objective function can be in Mayer form, Lagrange form, or Bolza form (combination of both):

* **Mayer**: $g(x(t_0), x(t_f), v) \to \min$
* **Lagrange**: $\int_{t_0}^{t_f} f^0(t, x(t), u(t), v)\, \mathrm{d}t \to \min$
* **Bolza**: $g(x(t_0), x(t_f), v) + \int_{t_0}^{t_f} f^0(t, x(t), u(t), v)\, \mathrm{d}t \to \min$

Check which form is present:

```@example main
has_mayer_cost(ocp)  # true if Mayer cost exists
```

```@example main
has_lagrange_cost(ocp)  # true if Lagrange cost exists
```

!!! note "Variant methods"
    Alternative methods are also available:
    - `is_mayer_cost_defined(ocp)` ≡ `has_mayer_cost(ocp)`
    - `is_lagrange_cost_defined(ocp)` ≡ `has_lagrange_cost(ocp)`

### Mayer cost

Get the Mayer cost function with signature `g(x0, xf, v)`:

```@repl main
g = mayer(ocp)  # error if no Mayer cost
```

### Lagrange cost

Get the Lagrange cost function with signature `f⁰(t, x, u, v)`:

```@example main
f⁰ = lagrange(ocp)
s = 0.5
q = [0.0, 1.0]
u = 2.0
v = [1.0, 2.0]
f⁰(s, q, u, v)  # returns the integrand value
```

### [Summary table](@id modelling-inspect-summary-objective)

| Method | Returns | Description |
| -------- | --------- | --------- |
| `criterion(ocp)` | `Symbol` | `:min` or `:max` |
| `has_mayer_cost(ocp)` | `Bool` | True if Mayer cost exists |
| `has_lagrange_cost(ocp)` | `Bool` | True if Lagrange cost exists |
| `mayer(ocp)` | `Function` | Mayer cost function g(x0, xf, v) |
| `lagrange(ocp)` | `Function` | Lagrange cost function f⁰(t, x, u, v) |

## Constraints

The constraints component defines the constraints on the optimal control problem.

### Individual constraints

Retrieve a specific constraint by its label using the `constraint` function. It returns a tuple `(type, f, lb, ub)`:

```@example main
(type, f, lb, ub) = constraint(ocp, :eq1)
println("type: ", type)
x0 = [0, 1]
xf = [2, 3]
v  = [1, 4]
println("val: ", f(x0, xf, v))
println("lb: ", lb)
println("ub: ", ub)
```

The function signature depends on the constraint type:

* For `:boundary` and `:variable` constraints: `f(x0, xf, v)`
* For other constraints (`:control`, `:state`, `:mixed`): `f(t, x, u, v)`

Examples of different constraint types:

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_bound)
println("type: ", type)
println("val: ", f(x0, xf, v))
```

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_u)
println("type: ", type)
s = 0.5
q = [1.0, 2.0]
u = 3.0
println("val: ", f(s, q, u, v))
```

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_mixed)
println("type: ", type)
println("val: ", f(s, q, u, v))
```

### All constraints

Get all constraints as a collection:

```@example main
constraints(ocp)  # returns all constraints
```

### Nonlinear constraints

Get nonlinear path and boundary constraints:

```@example main
path_constraints_nl(ocp)  # returns nonlinear path constraints
```

```@example main
boundary_constraints_nl(ocp)  # returns nonlinear boundary constraints
```

!!! note "Tuple structure"
    The returned tuples have the structure `(lb, f!, ub, labels)` where:
    - `lb`: vector of lower bounds
    - `f!`: constraint function (in-place)
    - `ub`: vector of upper bounds
    - `labels`: vector of constraint labels

    The constraint functions have the following signatures:
    - Path constraints: `f!(val, t, x, u, v)` where `val` is mutated
    - Boundary constraints: `f!(val, x0, xf, v)` where `val` is mutated

Get the dimensions of nonlinear constraints:

```@example main
dim_path_constraints_nl(ocp)  # number of nonlinear path constraints
```

```@example main
dim_boundary_constraints_nl(ocp)  # number of nonlinear boundary constraints
```

!!! note

    To get the dual variable (or Lagrange multiplier) associated to a constraint, use the [`dual`](@ref) method on a solution — see [Solution object](@ref results-solution).

### [Summary table](@id modelling-inspect-summary-constraints)

| Method | Returns | Description |
| -------- | --------- | --------- |
| `constraint(ocp, label)` | `(Symbol, Function, Real, Real)` | Get constraint by label |
| `constraints(ocp)` | Collection | All constraints |
| `path_constraints_nl(ocp)` | Constraints | Nonlinear path constraints |
| `boundary_constraints_nl(ocp)` | Constraints | Nonlinear boundary constraints |
| `dim_path_constraints_nl(ocp)` | `Int` | Number of nonlinear path constraints |
| `dim_boundary_constraints_nl(ocp)` | `Int` | Number of nonlinear boundary constraints |

## Problem definition

Get the problem definition as a string:

```@example main
definition(ocp)  # returns the OCP definition as AbstractDefinition
```

To extract the expression from the definition, use:

```@example main
expr = expression(ocp)  # returns the Expr from the definition
nothing # hide
```

!!! note

    The definition is optional and can be `EmptyDefinition` — this is what the [functional API](@ref modelling-functional-api) produces. Use `has_abstract_definition(ocp)` to check if a definition is present.

### Definition presence

Check whether the problem carries an abstract definition:

```@example main
has_abstract_definition(ocp)  # true if definition is present (not EmptyDefinition)
```

!!! note "Variant method"

    - `is_abstractly_defined(ocp)` ≡ `has_abstract_definition(ocp)`

## [Time dependence](@id modelling-inspect-time-dependence)

Optimal control problems can be **autonomous** or **non-autonomous**. In an autonomous problem, neither the dynamics nor the Lagrange cost explicitly depends on the time variable.

The following problem is autonomous.

```@example main
ocp = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t)                       # no explicit dependence on t
    x(1) + 0.5∫( u(t)^2 ) → min         # no explicit dependence on t
end
is_autonomous(ocp)
```

The following problem is non-autonomous since the dynamics depends on `t`.

```@example main
ocp = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t) + t                   # explicit dependence on t
    x(1) + 0.5∫( u(t)^2 ) → min
end
is_autonomous(ocp)
```

Finally, this last problem is non-autonomous because the Lagrange part of the cost depends on `t`.

```@example main
ocp = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t)
    x(1) + 0.5∫( t + u(t)^2 ) → min     # explicit dependence on t
end
is_autonomous(ocp)
```

The variant predicate `is_nonautonomous` is also available and returns the opposite of `is_autonomous`:

```@example main
is_nonautonomous(ocp)  # true if dynamics or cost depend on time
```

!!! note "Variant method"

    - `is_nonautonomous(ocp)` ≡ `!is_autonomous(ocp)`

## API trap: `time` is gone

`time(ocp)` is not the time accessor — `time` is `Base.time` (wall-clock time), extended but not exported. The accessor is `times(ocp)`, shown above. Calling `time(ocp)` throws a migration error pointing here — see [Migrating to v2.1](@ref migration).

## See also

- [Formulation](@ref modelling-formulation) — the mathematics behind these fields.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) · [Functional API](@ref modelling-functional-api) — building the model this page reads.
- [Solve overview](@ref solve-overview) — solving it.
- [Solution object](@ref results-solution) — the symmetric page for reading back a *solution* rather than a *problem*.

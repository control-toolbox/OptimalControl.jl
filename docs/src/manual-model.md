# [The optimal control problem object: structure and usage](@id manual-model)

```@meta
CollapsedDocStrings = false
```

In this manual, we'll first recall the **main functionalities** you can use when working with an optimal control problem (OCP). This includes essential operations like:

* **Solving an OCP**: How to find the optimal solution for your defined problem.
* **Computing flows from an OCP**: Understanding the dynamics and trajectories derived from the optimal solution.
* **Printing an OCP**: How to display a summary of your problem's definition.

After covering these core functionalities, we'll delve into the **structure of an OCP**. Since an OCP is structured as a [`Model`](@ref) struct, we'll first explain how to **access its underlying attributes**, such as the problem's dynamics, costs, and constraints. Following this, we'll shift our focus to the **simple properties** inherent to an OCP, learning how to determine aspects like whether the problem:

* **Is autonomous**: Does its dynamics depend explicitly on time?
* **Has a fixed or free initial/final time**: Is the duration of the control problem predetermined or not?

---

**Content**

- [Main functionalities](@ref manual-model-main-functionalities)
- [Model struct](@ref manual-model-struct)
- [Attributes and properties](@ref manual-model-attributes)

---

## [Main functionalities](@id manual-model-main-functionalities)

Let's define a basic optimal control problem.

```@example main
using OptimalControl

t0 = 0
tf = 1
x0 = [-1, 0]

ocp = @def begin
    t ∈ [ t0, tf ], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ẋ(t)  == [v(t), u(t)]
    0.5∫( u(t)^2 ) → min
end
nothing # hide
```

To print it, simply:

```@example main
ocp
```

We can now solve the problem (for more details, visit the [solve manual](@ref manual-solve)):

```@example main
using NLPModelsIpopt
solve(ocp)
nothing # hide
```

You can also compute flows (for more details, see the [flow manual](@ref manual-flow-ocp)) from the optimal control problem, providing a control law in feedback form. The **pseudo-Hamiltonian** of this problem is

```math
    H(x, p, u) = p_q\, q + p_v\, v + p^0 u^2 /2,
```

where $p^0 = -1$ since we are in the normal case. From the Pontryagin maximum principle, the maximising control is given in feedback form by

```math
u(x, p) = p_v
```

since $\partial^2_{uu} H = p^0 = - 1 < 0$. 

```@example main
u = (x, p) -> p[2]          # control law in feedback form

using OrdinaryDiffEq        # needed to import numerical integrators
f = Flow(ocp, u)            # compute the Hamiltonian flow function

p0 = [12, 6]                # initial covector solution
xf, pf = f(t0, x0, p0, tf)  # flow from (x0, p0) at time t0 to tf
xf                          # should be (0, 0)
```

!!! note

    A more advanced feature allows for the discretization of the optimal control problem. From the discretized version, you can obtain a Nonlinear Programming problem (or optimization problem) and solve it using any appropriate NLP solver. For more details, visit the [NLP manipulation tutorial](https://control-toolbox.org/Tutorials.jl/stable/tutorial-nlp.html).

## [Model struct](@id manual-model-struct)

The optimal control problem `ocp` is a [`Model`](@ref) struct. 

```@docs; canonical=false
Model
```

Each field can be accessed directly (`ocp.times`, etc) or by a getter:

- [`times`](@ref)
- [`state`](@ref)
- [`control`](@ref)
- [`variable`](@ref)
- [`dynamics`](@ref)
- [`objective`](@ref)
- [`constraints`](@ref)
- [`definition`](@ref)
- [`get_build_examodel`](@ref)

For instance, we can retrieve the `times` and `definition` values.

```@example main
times(ocp)
```

```@example main
definition(ocp)
```

!!! note

    We refer to [CTModels API](@extref CTModels Types) for more details about this struct and its fields.

## [Attributes and properties](@id manual-model-attributes)

Numerous attributes can be retrieved. To illustrate this, a more complex optimal control problem is defined.

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

### Control, state and variable

You can access the name of the control, state, and variable, along with the names of their components and their dimensions..

```@example main
using DataFrames
data = DataFrame(
    Data=Vector{Symbol}(),
    Name=Vector{String}(),
    Components=Vector{Vector{String}}(), 
    Dimension=Vector{Int}(),
)

# control
push!(data,(
    :control,
    control_name(ocp),
    control_components(ocp),
    control_dimension(ocp),
))

# state
push!(data,(
    :state,
    state_name(ocp),
    state_components(ocp),
    state_dimension(ocp),
))

# variable
push!(data,(
    :variable,
    variable_name(ocp),
    variable_components(ocp),
    variable_dimension(ocp),
))
```

!!! note

    The names of the components are used for instance when plotting the solution. See the [plot manual](@ref manual-plot).

### Constraints

You can retrieve labelled constraints with the [`constraint`](@ref) function. The `constraint(ocp, label)` method returns a tuple of the form `(type, f, lb, ub)`.
The signature of the function `f` depends on the symbol `type`. For `:boundary` and `:variable` constraints, the signature is `f(x0, xf, v)` where `x0` is the initial state, `xf` the final state and `v` the variable. For other constraints, the signature is `f(t, x, u, v)`. Here, `t` represents time, `x` the state, `u` the control, and `v` the variable.

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

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_bound)
println("type: ", type)
println("val: ", f(x0, xf, v))
println("lb: ", lb)
println("ub: ", ub)
```

```@example main
(type, f, lb, ub) = constraint(ocp, :cons_u)
println("type: ", type)
t = 0
x = [1, 2]
u = 3
println("val: ", f(t, x, u, v))
println("lb: ", lb)
println("ub: ", ub)
```
 
```@example main
(type, f, lb, ub) = constraint(ocp, :cons_mixed)
println("type: ", type)
println("val: ", f(t, x, u, v))
println("lb: ", lb)
println("ub: ", ub)
```

!!! note

    To get the dual variable (or Lagrange multiplier) associated to the constraint, use the [`dual`](@ref) method.

### Dynamics

The dynamics stored in `ocp` are an [in-place function](https://docs.julialang.org/en/v1/manual/functions/#man-argument-passing) (the first argument is mutated upon call) of the form `f!(dx, t, x, u, v)`. Here, `t` represents time, `x` the state, `u` the control, and `v` the variable, with `dx` being the output value.

```@example main
f! = dynamics(ocp)
t = 0
x = [0., 1]
u = 2
v = [1, 4]
dx = similar(x)
f!(dx, t, x, u, v)
dx
```

### Criterion and objective

The criterion can be `:min` or `:max`.

```@example main
criterion(ocp)
```

The objective function is either in Mayer, Lagrange or Bolza form. 

- Mayer:
```math
g(x(t_0), x(t_f), v) \to \min
```
- Lagrange:
```math
\int_{t_0}^{t_f} f^0(t, x(t), u(t), v)\, \mathrm{d}t \to \min
```
- Bolza:
```math
g(x(t_0), x(t_f), v) + \int_{t_0}^{t_f} f^0(t, x(t), u(t), v)\, \mathrm{d}t \to \min
```

The objective of problem `ocp` is `0.5∫( u(t)^2 ) → min`, hence, in Lagrange form. The signature of the Mayer part of the objective is `g(x0, xf, v)` but in our case, the method `mayer` will return an error.

```@repl main
g = mayer(ocp)
```

The signature of the Lagrange part of the objective is `f⁰(t, x, u, v)`.

```@example main
f⁰ = lagrange(ocp)
f⁰(t, x, u, v)
```

To avoid having to capture exceptions, you can check the form of the objective:

```@example main
println("Mayer: ", has_mayer_cost(ocp))
println("Lagrange: ", has_lagrange_cost(ocp))
```

### Times

The time variable is not named `t` but `s` in `ocp`.

```@example main
time_name(ocp)
```

The initial time is `0`.

```@example main
initial_time(ocp)
```

Since the initial time has the value `0`, its name is `string(0)`. 

```@example main
initial_time_name(ocp)
```

In contrast, the final time is `tf`, since in `ocp` we have `s ∈ [0, tf]`.

```@example main
final_time_name(ocp)
```

To get the value of the final time, since it is part of the variable `v = (w, tf)` of `ocp`, we need to provide a variable to the function `final_time`. 

```@example main
v = [1, 2]
tf = final_time(ocp, v)
```

```@repl main
final_time(ocp)
```

To check whether the initial or final time is fixed or free (i.e., part of the variable), you can use the following functions:

```@example main
println("Fixed initial time: ", has_fixed_initial_time(ocp))
println("Fixed final time: ", has_fixed_final_time(ocp))
```

Or, similarly:

```@example main
println("Free initial time: ", has_free_initial_time(ocp))
println("Free final time: ", has_free_final_time(ocp))
```

### [Time dependence](@id manual-model-time-dependence)

Optimal control problems can be **autonomous** or **non-autonomous**. In an autonomous problem, neither the dynamics nor the Lagrange cost explicitly depends on the time variable.

The following problem is autonomous.

```@example main
ocp = @def begin
    t ∈ [ 0, 1 ], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t)  == u(t)                       # no explicit dependence on t
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
    ẋ(t)  == u(t) + t                   # explicit dependence on t
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
    ẋ(t)  == u(t)
    x(1) + 0.5∫( t + u(t)^2 ) → min     # explicit dependence on t
end
is_autonomous(ocp)
```

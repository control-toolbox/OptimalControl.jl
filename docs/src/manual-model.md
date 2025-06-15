# [Understanding optimal control problems: functionalities and properties](@id manual-model)

```@meta
CollapsedDocStrings = false
Draft = false
```

In this manual, we'll first recall the **main functionalities** you can use when working with an optimal control problem (OCP). This includes essential operations like:

* **Solving an OCP**: How to find the optimal solution for your defined problem.
* **Computing flows from an OCP**: Understanding the dynamics and trajectories derived from the optimal solution.
* **Printing an OCP**: How to display a summary of your problem's definition.

After covering these core functionalities, we'll delve into the **structure of an OCP**. Since an OCP is structured as a [`Model`](@ref) struct, we'll first explain how to **access its underlying attributes**, such as the problem's dynamics, costs, and constraints. Following this, we'll shift our focus to the **simple properties** inherent to an OCP, learning how to determine aspects like whether the problem:

* **Is autonomous**: Does its dynamics depend explicitly on time?
* **Has a fixed final time**: Is the duration of the control problem predetermined?

This structured approach will give you a comprehensive understanding of both what you can *do* with an OCP and what an OCP *is*.

---

**Content**

- [Main functionalities](@ref manual-model-main-functionalities)
- [Model struct](@ref manual-model-struct)
- [Attributes](@ref manual-model-attributes)
- [Properties](@ref manual-model-properties)

---

## [Main functionalities](@id manual-model-main-functionalities)

Let us define a basic optimal control problem.

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
    ∫( 0.5u(t)^2 ) → min
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
#solve(ocp)
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
u = (x, p) -> p[2]              # control law in feedback form

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

Each field can be access directly (`ocp.times`, etc) or by a getter:

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

The dynamics stored in `ocp` is an inplace function of the form `f!(dx, t, x, u, v)` where `t` is the time, `x` the state, `u` the control and `v` the variable, and where `dx` is the output value.

```@example main
f! = dynamics(ocp)
t = 0
x = [0., 1]
u = 2
v = []
dx = similar(x)
f!(dx, t, x, u, v)
dx
```

We refer to [CTModels API](@extref CTModels Types) for more details about this struct and its fields.

## [Attributes](@id manual-model-attributes)

More attributes can be retrived. To illustrate this, we define a more complex optimal control problem.

```@example main
ocp = @def begin
    tf ∈ R,   variable
    t ∈ [0, tf],        time
    q = (x, y) ∈ R²,    state
    u ∈ R,              control
    0 ≤ tf ≤ 2,         (1)
    u(t) ≥ 0,           (cons_u)
    x(t) + u(t) ≤ 10,   (cons_mixed)
    x(0) == -1
    y(0) - tf == 0,     (cons_bound)
    q(tf) == [0, 0]
    q̇(t) == [y(t), u(t)]
    0.5∫( u(t)^2 ) → min
end
nothing # hide
```

### Control, state and variable

You can get access to the name of the control, the names of the components, its dimension and the box constraints `lb ≤ u(t) ≤ ub`, where `lb` stands for lower bound and `ub` for upper bound.

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

### Constraints

The labelled constraints may be retrieved with the [`constraint`](@ref) function. The method `constraint(ocp, label)` returns a tuple of the form `(type, f, lb, ub)`.
The signature of the function `f` depends on the type. For boundary constraints (that is at initial and/or final time) and variable constraints, the signature is `f(x0, xf, v)` where `x0` stands for the initial state, `xf` the final state and `v` the variable. For other constraints, the signature is `f(t, x, u, v)`.

```@example main
(type, f, lb, ub) = constraint(ocp, :eq1)
println("type: ", type)
x0 = [0, 1]
xf = [2, 3]
v  = 4
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
u = [3, 4]
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

### Dynamics


### Objective


### Times



## [Properties](@id manual-model-properties)


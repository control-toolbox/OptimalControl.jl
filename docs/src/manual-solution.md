# [The optimal control solution object: structure and usage](@id manual-solution)

```@meta
CollapsedDocStrings = false
Draft = false
```

In this manual, we'll first recall the **main functionalities** you can use when working with a solution of an optimal control problem (SOL). This includes essential operations like:

* **Plotting a SOL**: How to plot the optimal solution for your defined problem.
* **Printing a SOL**: How to display a summary of your solution.

After covering these core functionalities, we'll delve into the **structure of a SOL**. Since a SOL is structured as a [`Solution`](@ref) struct, we'll first explain how to **access its underlying attributes**. Following this, we'll shift our focus to the **simple properties** inherent to a SOL.

---

**Content**

- [Main functionalities](@ref manual-solution-main-functionalities)
- [Solution struct](@ref manual-solution-struct)
- [Attributes and properties](@ref manual-solution-attributes)

---

## [Main functionalities](@id manual-solution-main-functionalities)

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

We can now solve the problem (for more details, visit the [solve manual](@ref manual-solve)):

```@example main
using NLPModelsIpopt
sol = solve(ocp)
nothing # hide
```

!!! note

    You can export (or save) the solution in a Julia `.jld2` data file and reload it later, and also export a discretised version of the solution in a more portable [JSON](https://en.wikipedia.org/wiki/JSON) format. Note that the optimal control problem is needed when loading a solution.

    See the two functions:

    - [`import_ocp_solution`](@ref),
    - [`export_ocp_solution`](@ref).

To print `sol`, simply:

```@example main
sol
```

For complementary information, you can plot the solution:

```@example main
using Plots
plot(sol)
```

!!! note

    For more details about plotting a solution, visit the [plot manual](@ref manual-plot).

## [Solution struct](@id manual-solution-struct)

The solution `sol` is a [`Solution`](@ref) struct.

```@docs; canonical=false
Solution
```

Each field can be accessed directly (`ocp.times`, etc) but we recommend to use the sophisticated getters we proveide: the `state(sol::Solution)` method does not return `sol.state` but a function of time that can be called at any time, not only on the grid `time_grid`.

```@example main
0.25 ∈ time_grid(sol)
```

```@example main
x = state(sol)
x(0.25)
```

## [Attributes and properties](@id manual-solution-attributes)

### State, costate, control, variable and objective value

You can access the values of the state, costate, control and variable by eponymous functions. The returned values are functions of time for the state, costate and control and a scalar or a vector for the variable.

```@example main
t = 0.25
x = state(sol)
p = costate(sol)
u = control(sol)
nothing # hide
```

Since the state is of dimension 2, evaluating `x(t)` returns a vector:
```@example main
x(t)
```

It is the same for the costate:
```@example main
p(t)
```

But the control is one-dimensional:
```@example main
u(t)
```

There is no variable, hence, an empty vector is returned:
```@example main
v = variable(sol)
```

The objective value is accessed by:
```@example main
objective(sol)
```

### Infos from the solver

The problem `ocp` is solved via a direct method (see [solve manual](@ref manual-solve) for details). The solver stores data in `sol`, including the success of the optimization, the iteration count, the time grid used for **discretisation**, and other specific details within the `solver_infos` field.

```@example main
time_grid(sol)
```

```@example main
constraints_violation(sol)
```

```@example main
infos(sol)
```

```@example main
iterations(sol)
```

```@example main
message(sol)
```

```@example main
status(sol)
```

```@example main
successful(sol)
```

### Dual variables

You can retrieved dual variables (or Lagrange multipliers) associated to labelled constraint. To illustrate this, we define a problem with constraints:

```@example main
ocp = @def begin

    tf ∈ R,             variable
    t ∈ [0, tf],        time
    x = (q, v) ∈ R²,    state
    u ∈ R,              control

    tf ≥ 0,             (eq_tf)
    -1 ≤ u(t) ≤ 1,      (eq_u)
    v(t) ≤ 0.75,        (eq_v)

    x(0)  == [-1, 0],   (eq_x0)
    q(tf) == 0
    v(tf) == 0

    ẋ(t) == [v(t), u(t)]

    tf → min

end
sol = solve(ocp; display=false)
nothing # hide
```

Dual variables corresponding to variable and boundary constraints are given as scalar or vectors.

```@example main
dual(sol, ocp, :eq_tf)
```

```@example main
dual(sol, ocp, :eq_x0)
```

The other type of constraints are associated to dual variables given as functions of time.

```@example main
μ_u = dual(sol, ocp, :eq_u)
plot(time_grid(sol), μ_u)
```

```@example main
μ_v = dual(sol, ocp, :eq_v)
plot(time_grid(sol), μ_v)
```

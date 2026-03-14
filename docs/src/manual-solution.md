# [The optimal control solution object: structure and usage](@id manual-solution)

In this manual, we'll first recall the **main functionalities** you can use when working with a solution of an optimal control problem (SOL). This includes essential operations like:

* **Plotting a SOL**: How to plot the optimal solution for your defined problem.
* **Printing a SOL**: How to display a summary of your solution.

After covering these core functionalities, we'll delve into the **structure of a SOL**. Since a SOL is structured as a [`OptimalControl.Solution`](@ref) struct, we'll first explain how to **access its underlying attributes**. Following this, we'll shift our focus to the **simple properties** inherent to a SOL.

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

The solution `sol` is a [`OptimalControl.Solution`](@ref) struct.

```@docs; canonical=false
OptimalControl.Solution
```

Each field can be accessed directly (`ocp.times`, etc) but we recommend to use the sophisticated getters we provide: the `state(sol::Solution)` method does not return `sol.state` but a function of time that can be called at any time, not only on the grid `time_grid`.

```@example main
0.25 ∈ time_grid(sol)
```

```@example main
x = state(sol)
x(0.25)
```

## [API Reference by Component](@id manual-solution-api)

This section provides a comprehensive reference of all methods available for inspecting and querying optimal control solutions. Methods are organized by component for easy navigation.

### Trajectories

The trajectory component provides access to the state, control, variable, and costate trajectories.

#### State trajectory

Get the state trajectory as a function of time:

```@example main
x = state(sol)  # returns a function of time
```

Evaluate the state at any time (not just grid points):

```@example main
t = 0.25
x(t)  # returns state vector at t=0.25
```

The state function can be evaluated at any time within the problem horizon, even if it's not a discretization grid point:

```@example main
0.25 ∈ time_grid(sol)  # false: not a grid point
```

```@example main
x(0.25)  # still works: interpolated value
```

#### Control trajectory

Get the control trajectory as a function of time:

```@example main
u = control(sol)  # returns a function of time
```

```@example main
u(t)  # returns control value at t
```

#### Variable values

Get the optimization variable values:

```@example main
v = variable(sol)  # returns vector or empty if no variable
```

#### Costate trajectory

Get the costate (adjoint) trajectory as a function of time:

```@example main
p = costate(sol)  # returns a function of time
```

```@example main
p(t)  # returns costate vector at t
```

#### Time information

Get time-related information from the solution:

```@example main
time_grid(sol)  # returns the discretization time grid
```

```@example main
times(sol)  # returns the time interval (t0, tf)
```

The `time` function returns a function that can be used to get time values:

```@example main
time_func = time(sol)
time_func(0.5)  # returns time at normalized parameter 0.5
```

#### Summary table

| Method | Returns | Description |
|--------|---------|-------------|
| `state(sol)` | `Function` | State trajectory x(t) |
| `control(sol)` | `Function` | Control trajectory u(t) |
| `variable(sol)` | `Vector` | Variable values |
| `costate(sol)` | `Function` | Costate trajectory p(t) |
| `time(sol)` | `Function` | Time function |
| `time_grid(sol)` | `Vector{Float64}` | Discretization time grid |
| `times(sol)` | `(Float64, Float64)` | Time interval (t0, tf) |

### Objective

The objective component provides access to the objective value and criterion.

#### Objective value

Get the optimal objective value:

```@example main
objective(sol)  # returns the objective value
```

#### Criterion

Get the optimization criterion:

```@example main
criterion(sol)  # returns :min or :max
```

#### Summary table

| Method | Returns | Description |
|--------|---------|-------------|
| `objective(sol)` | `Float64` | Objective value |
| `criterion(sol)` | `Symbol` | `:min` or `:max` |

### Dual variables

The dual variables (Lagrange multipliers) provide sensitivity information about constraints.

To illustrate dual variables, we define a problem with various constraints:

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
    ẋ(t) == [v(t), u(t)]
    tf → min
end
sol = solve(ocp; display=false)
nothing # hide
```

#### Dual of labeled constraints

Get the dual variable for a specific labeled constraint:

```@example main
dual(sol, ocp, :eq_tf)  # dual for variable constraint
```

```@example main
dual(sol, ocp, :eq_x0)  # dual for boundary constraint
```

For path constraints, the dual is a function of time:

```@example main
μ_u = dual(sol, ocp, :eq_u)
plot(time_grid(sol), μ_u)
```

```@example main
μ_v = dual(sol, ocp, :eq_v)
plot(time_grid(sol), μ_v)
```

#### Box constraint duals

Get dual variables for box constraints on state, control, and variable:

```@example main
state_constraints_lb_dual(sol)  # lower bound duals for state
```

```@example main
state_constraints_ub_dual(sol)  # upper bound duals for state
```

```@example main
control_constraints_lb_dual(sol)  # lower bound duals for control
```

```@example main
control_constraints_ub_dual(sol)  # upper bound duals for control
```

```@example main
variable_constraints_lb_dual(sol)  # lower bound duals for variable
```

```@example main
variable_constraints_ub_dual(sol)  # upper bound duals for variable
```

#### Nonlinear constraint duals

Get dual variables for nonlinear path and boundary constraints:

```@example main
path_constraints_dual(sol)  # duals for nonlinear path constraints
```

```@example main
boundary_constraints_dual(sol)  # duals for nonlinear boundary constraints
```

#### Summary table

| Method | Returns | Description |
|--------|---------|-------------|
| `dual(sol, ocp, label)` | `Real` or `Function` | Dual for labeled constraint |
| `state_constraints_lb_dual(sol)` | Dual values | State lower bound duals |
| `state_constraints_ub_dual(sol)` | Dual values | State upper bound duals |
| `control_constraints_lb_dual(sol)` | Dual values | Control lower bound duals |
| `control_constraints_ub_dual(sol)` | Dual values | Control upper bound duals |
| `variable_constraints_lb_dual(sol)` | Dual values | Variable lower bound duals |
| `variable_constraints_ub_dual(sol)` | Dual values | Variable upper bound duals |
| `path_constraints_dual(sol)` | Dual values | Nonlinear path constraint duals |
| `boundary_constraints_dual(sol)` | Dual values | Nonlinear boundary constraint duals |

### Solution metadata

The solution metadata provides information about the solver performance and status.

#### Solver status

Check if the solution was successful:

```@example main
successful(sol)  # returns true if solver succeeded
```

!!! note "Variant method"
    The method `success(sol)` is equivalent to `successful(sol)`.

Get the solver status symbol:

```@example main
status(sol)  # returns solver status (e.g., :first_order)
```

Get the solver message:

```@example main
message(sol)  # returns solver message string
```

#### Iteration count

Get the number of solver iterations:

```@example main
iterations(sol)  # returns iteration count
```

#### Constraints violation

Get the maximum constraint violation:

```@example main
constraints_violation(sol)  # returns max violation
```

#### Additional solver information

Get additional solver-specific information:

```@example main
infos(sol)  # returns dictionary of solver info
```

#### Summary table

| Method | Returns | Description |
|--------|---------|-------------|
| `successful(sol)` | `Bool` | True if solver succeeded |
| `status(sol)` | `Symbol` | Solver status |
| `message(sol)` | `String` | Solver message |
| `iterations(sol)` | `Int` | Number of iterations |
| `constraints_violation(sol)` | `Float64` | Maximum constraint violation |
| `infos(sol)` | `Dict` | Additional solver information |

### Other accessors

Additional methods for accessing solution information.

#### Original OCP model

Get the original optimal control problem:

```@example main
model(sol)  # returns the OCP model
```

#### Index information

Get index information from the solution:

```@example main
index(sol)  # returns index information
```

#### Summary table

| Method | Returns | Description |
|--------|---------|-------------|
| `model(sol)` | `Model` | Original OCP model |
| `index(sol)` | Index info | Index information |

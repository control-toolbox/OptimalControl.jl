# [Initial guess (or iterate) for the resolution](@id manual-initial-guess)

We present the different possibilities to provide an initial guess to solve an
optimal control problem with the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package.

First, we need to import OptimalControl.jl to define the
optimal control problem and [NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl) to solve it.
We also need to import [Plots.jl](https://docs.juliaplots.org) to plot solutions.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

For the illustrations, we define two optimal control problems to showcase the different ways to specify initial guesses.

The first problem uses default component labels (`x₁`, `x₂` for the state):

```@example main
t0 = 0; tf = 10; α = 5

ocp1 = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == [ -1, 0 ]
    x₁(tf) == 0
    ẋ(t) == [ x₂(t), x₁(t) + α*x₁(t)^2 + u(t) ]
    x₂(tf)^2 + ∫( 0.5u(t)^2 ) → min
end
nothing # hide
```

The second problem uses custom component labels (`q`, `v` for the state, `tf` for the variable) and a different time variable name (`s` instead of `t`):

```@example main
ocp2 = @def begin
    tf ∈ R, variable
    s ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    -1 ≤ u(s) ≤ 1
    tf ≥ 0
    q(0) == -1
    v(0) == 0
    q(tf) == 0
    v(tf) == 0
    ẋ(s) == [v(s), u(s)]
    tf → min
end
nothing # hide
```

!!! note "Component labels and time variable in `@init`"

    - The `@init` macro uses the **labels** declared in the `@def` block. For `ocp1`, you can use `x`, `x₁`, `x₂`, and `u`. For `ocp2`, you can use `x`, `q`, `v`, `u`, and `tf`.
    - The `@init` macro uses the **time variable name** from the `@def` block. For `ocp1`, use `t` (e.g., `x(t) := ...`). For `ocp2`, use `s` (e.g., `q(s) := ...`).
    - This allows for more readable initial guess specifications that match your problem definition.

## Default initial guess

We first solve the problem without giving an initial guess.
This will default to initialize all variables to 0.1.

To visualize the default initial guess before solving, we can run the solver with `max_iter=0`:

```@example main
# visualize the default initial guess (no iterations)
sol_init = solve(ocp1; init=nothing, max_iter=0, display=false)
plot(sol_init; size=(600, 450))
```

!!! tip "Visualizing any initial guess"

    This technique works with any initial guess specification. By setting `max_iter=0`, the solver stops immediately after initialization, allowing you to visualize the initial guess before the optimization process begins.

Now let us solve the problem completely:

```@example main
# solve the optimal control problem without initial guess
sol = solve(ocp1; display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

Let us plot the solution of the optimal control problem.

```@example main
plot(sol; size=(600, 450))
```

Note that the following formulations are equivalent to not giving an initial guess.

```@example main
sol = solve(ocp1; init=nothing, display=false)
println("Number of iterations: ", iterations(sol))

sol = solve(ocp1; init=(), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

!!! tip "Interactions with an optimal control solution"

    To get the number of iterations of the solver, check the [`iterations`](@ref) function.

To reduce the number of iterations and improve the convergence, we can give an initial guess to the solver.
The recommended way is to use the `@init` macro, which provides a clean syntax for specifying initial values.

## Initial guess with `@init`

The `@init` macro allows you to specify initial values for state and control using the syntax `label(t) := expression`.
For optimization variables (like `tf`), use `label := value` since they are not functions of time.

### `@init` at a Glance

**Complete syntax:**

```julia
ig = @init ocp begin
    # initial guess specifications
end
```

The `ocp` argument is required for label validation and context checking.

**Core syntax:** `label(time_var) := expression`

| Component | Has `(t)`? | Uses `:=`? | Example |
| ----------- | ----------- | ----------- | --------- |
| State/Control | ✅ Yes | ✅ Yes | `u(t) := 2` |
| Variable | ❌ No | ✅ Yes | `tf := 2.0` |
| Alias | ❌ No | ❌ No (use `=`) | `a = 0.5` |

**Dimensions:**

- **1D** → scalar: `u(t) := 2`
- **2D** → vector: `u(t) := [1, 2]`

**Initialization types:**

| Type | 1D Example | 2D Example |
| ------ | ------------ | ------------ |
| **Constant** | `u(t) := 2` or `u := 2` | `x(t) := [1, 2]` or `x := [1, 2]` |
| **Function** | `u(t) := sin(t)` | `x(t) := [sin(t), cos(t)]` |
| **Grid** | `u(T) := [0, 1, 2]` | `x(T) := [[0,0], [1,1], [2,2]]` |
| **Grid (matrix)** | — | `x(T) := [0 0; 1 1; 2 2]` |

where `T = [0.0, 0.5, 1.0]` is the time grid.

!!! tip "Key rules"
    - Use the **same time variable** as in your `@def` block (`t`, `s`, etc.)
    - **1D**: scalar values (not `[value]`)
    - **2D**: vectors `[v1, v2]` or vector of vectors `[[v1, v2], ...]` or matrix
    - **Variables** and **aliases**: no time argument
    - **Constant functions**: use either `u(t) := 2` or the simplified `u := 2`

### Constant initial guess

To initialize with constant values, use constant expressions in the function syntax:

!!! note "Alternative syntax for constant functions"
    For constant functions, you can also use the simplified syntax without the time argument:
    - `u(t) := 2` is equivalent to `u := 2`
    - `x(t) := [1, 2]` is equivalent to `x := [1, 2]`

    This shorter syntax is only available for constant expressions.

```@example main
# initialize with constant functions
ig = @init ocp1 begin
    x(t) := [-0.2, 0.1]  # constant vector function
    u(t) := -0.2         # constant scalar function
end

sol = solve(ocp1; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

Using custom labels makes the initialization more readable:

```@example main
# initialize individual components with constant values
# note: use 's' as the time variable (matching ocp2 definition)
ig = @init ocp2 begin
    q(s) := -0.2   # constant function for q
    v(s) := 0.0    # constant function for v
    u(s) := 0.1    # constant function for u
    tf := 2.0      # variable (not a function)
end

sol = solve(ocp2; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

### Partial initialization

You can initialize only some components; missing components will default to 0.1:

```@example main
# initialize only the control
ig = @init ocp1 begin
    u(t) := -0.2
end

sol = solve(ocp1; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

```@example main
# initialize only state components and variable
ig = @init ocp2 begin
    q(s) := -0.5
    v(s) := 0.2
    tf := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

### Time-dependent functions

For non-constant functions, use any expression involving `t`:

```@example main
# initialize with time-dependent functions
ig = @init ocp1 begin
    x(t) := [-0.2t, 0.1t]  # time-dependent vector
    u(t) := -0.2t          # time-dependent scalar
end

sol = solve(ocp1; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

```@example main
# initialize individual components with time-dependent functions
ig = @init ocp2 begin
    q(s) := sin(s)   # time-dependent
    v(s) := cos(s)   # time-dependent
    u(s) := s        # time-dependent
    tf := 2.0        # variable (constant)
end

sol = solve(ocp2; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

### Using aliases

You can define Julia aliases within the `@init` block using `=` (single equals, without time argument):

```@example main
# use aliases for constants and expressions
ig = @init ocp2 begin
    amplitude = 0.5
    phase = sin(amplitude)
    φ = 2π * s
    q(s) := amplitude * sin(φ)
    v(s) := amplitude * cos(φ)
    u(s) := phase      # constant function using alias
    tf := 2.0          # variable
end

sol = solve(ocp2; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

## Vector initial guess (interpolated)

You can provide initial values on a time grid using the syntax `label(T) := data`, where `T` is a time vector and `data` contains the corresponding values.

### Full block initialization on a grid

```@example main
# define time grid and data
T = [0.0, 5.0, 10.0]
X = [[-1.0, 0.0], [-0.5, 0.5], [0.0, 0.0]]
U = [0.0, -0.5, 0.0]

ig = @init ocp1 begin
    x(T) := X
    u(T) := U
end

sol = solve(ocp1; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

### Per-component grids

Different components can use different time grids:

```@example main
# different grids for different components
Sq = [0.0, 1.0, 2.0]
Dq = [-1.0, -0.5, 0.0]
Sv = [0.0, 2.0]
Dv = [0.0, 0.0]
Su = [0.0, 1.0, 2.0]
Du = [0.0, 0.5, 0.0]

ig = @init ocp2 begin
    q(Sq) := Dq
    v(Sv) := Dv
    u(Su) := Du
    tf := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

### Matrix format

For state initialization, you can also use a matrix where each row corresponds to a time point:

```@example main
# matrix format for state data
T = [0.0, 5.0, 10.0]
Xmat = [
    -1.0  0.0;
    -0.5  0.5;
     0.0  0.0
]
U = [0.0, -0.5, 0.0]

ig = @init ocp1 begin
    x(T) := Xmat
    u(T) := U
end

sol = solve(ocp1; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

## Mixed initial guess

You can freely mix constant functions, time-dependent functions, and grid-based initializations in a single `@init` block:

```@example main
# mix different initialization types
T = [0.0, 5.0, 10.0]
X = [[-1.0, 0.0], [-0.5, 0.5], [0.0, 0.0]]

ig = @init ocp1 begin
    x(T) := X              # grid-based for state
    u(t) := -0.2 * sin(t)  # time-dependent function for control
end

sol = solve(ocp1; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

```@example main
# another mix: constant and time-dependent functions
ig = @init ocp2 begin
    q(s) := -1.0 + s/2.0  # time-dependent function
    v(s) := 0.0           # constant function
    u(s) := 0.1 * s       # time-dependent function
    tf := 2.0             # variable
end

sol = solve(ocp2; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

## Solution as initial guess (warm start)

You can use an existing solution directly as an initial guess.
The dimensions of the state, control and optimization variable must coincide.
This particular feature allows an easy implementation of discrete continuations.

```@example main
# generate an initial solution
sol_init = solve(ocp1; display=false)

# solve the problem using solution as initial guess
sol = solve(ocp1; init=sol_init, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

You can also manually extract data from a solution and use it within an `@init` block:

```@example main
# extract functions from solution
x_fun = state(sol_init)
u_fun = control(sol_init)

# use them in @init
ig = @init ocp1 begin
    x(t) := x_fun(t)
    u(t) := u_fun(t)
end

sol = solve(ocp1; init=ig, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

!!! tip "Interactions with an optimal control solution"

    Please check [`state`](@ref), [`costate`](@ref), [`control`](@ref) and [`variable`](@ref variable(::Solution)) to get data from the solution. The functions `state`, `costate` and `control` return functions of time and `variable` returns a vector.

## Costate / multipliers

For the moment there is no option to provide an initial guess for the costate / multipliers.

## Legacy: NamedTuple construction

While the `@init` macro is the recommended approach, you can still construct initial guesses using direct `NamedTuple` syntax for backward compatibility.

### Basic tuple syntax

```@example main
# direct tuple construction with constants
sol = solve(ocp1; init=(state=[-0.2, 0.1], control=-0.2), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

### Using component labels

The tuple syntax now supports using component labels as keys:

```@example main
# use component labels in the tuple
sol = solve(ocp2; init=(q=-1.0, v=0.0, u=0.1, tf=2.0), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

### Grid-based initialization with tuples

For grid-based initialization, the syntax uses `(time_vector, data)` pairs:

```@example main
# grid-based with tuple syntax
T = [0.0, 5.0, 10.0]
X = [[-1.0, 0.0], [-0.5, 0.5], [0.0, 0.0]]
U = [0.0, -0.5, 0.0]

sol = solve(ocp1; init=(state=(T, X), control=(T, U)), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

You can also mix component labels with grid syntax:

```@example main
# per-component grids with tuple syntax
Tq = [0.0, 1.0, 2.0]
Dq = [-1.0, -0.5, 0.0]

sol = solve(ocp2; init=(q=(Tq, Dq), v=0.0, u=0.1, tf=2.0), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

!!! note "Recommendation"

    While the direct tuple syntax is still supported, we recommend using the `@init` macro for better readability and maintainability, especially for complex initial guess specifications.

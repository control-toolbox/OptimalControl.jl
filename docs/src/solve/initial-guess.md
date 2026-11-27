# [Initial guess](@id solve-initial-guess)

The direct methods of `solve` hand a nonlinear program (NLP) to a solver, which iterates from a starting point: values of the state, the control and the variable on the grid. This starting point is the **initial guess**. This page shows why it matters, then every way to give it with the `init` keyword: constants, functions of time, data on a time grid, a previous solution, or nothing at all, the default. It ends with how to inspect a guess and check it against the problem before solving.

The examples use Ipopt as NLP solver, loaded with `NLPModelsIpopt`, and `Plots` for the figures:

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## [Why the guess matters](@id solve-initial-guess-why)

The solver of the direct method finds a **local** solution, near where it starts. When the problem has several, the initial guess chooses which one it returns. Take a point that moves from $(-1, 0)$ to $(1, 0)$ with the least energy, around a disc of radius $1/2$ centred at $(0, 0.1)$: it can pass below the disc, or above it, a little longer.

```@repl main
obstacle = @def begin
    t ∈ [0, 1], time
    x = (x₁, x₂) ∈ R², state
    u ∈ R², control
    x(0) == [-1, 0]
    x(1) == [1, 0]
    ẋ(t) == u(t)
    x₁(t)^2 + (x₂(t) - 0.1)^2 ≥ 0.25
    ∫(u₁(t)^2 + u₂(t)^2) → min
end;

above = @init obstacle begin
    x₁(t) := -1 + 2t
    x₂(t) := sin(π * t)
end;
below = @init obstacle begin
    x₁(t) := -1 + 2t
    x₂(t) := -sin(π * t)
end;

sol_above = solve(obstacle; init=above, display=false);
sol_below = solve(obstacle; init=below, display=false);
(objective(sol_above), objective(sol_below))
```

Both solves succeed, on two different solutions. The one below the disc costs less: started above, the solver stays on the other side.

::: details Code of the figure

```@example main
ts = range(0, 1; length=200)
path(sol) = (t -> state(sol)(t)[1]).(ts), (t -> state(sol)(t)[2]).(ts)
θ = range(0, 2π; length=200)
plt = plot(0.5cos.(θ), 0.1 .+ 0.5sin.(θ); seriestype=:shape, fillalpha=0.2, label="obstacle",
           aspect_ratio=1, size=(600, 400))
plot!(plt, path(sol_above)...; label="started above")
plot!(plt, path(sol_below)...; label="started below")
nothing # hide
```

:::

```@example main
@assert successful(sol_above) && successful(sol_below)                          # hide
@assert objective(sol_below) < objective(sol_above) - 0.5                       # hide
@assert state(sol_above)(0.5)[2] > 0.5 && state(sol_below)(0.5)[2] < -0.3       # hide
sol_default = solve(obstacle; display=false)                                    # hide
@assert isapprox(objective(sol_default), objective(sol_below); rtol=1e-6)       # hide
plt                                                                             # hide
```

The default guess, `0.1` everywhere, gives the better solution here too, in more iterations; on another problem it may not. A guess built from what you know of the solution, its shape or a solution of a nearby problem, is how you choose.

## Two running examples

The rest of the page shows every way to write a guess on two problems: `ocp1` has default component labels, `ocp2` custom ones, a free final time and another name for time.

:::tabs key:initial-guess-problems

== ocp1 — default labels

```@example main
t0 = 0; tf = 10; α = 5

ocp1 = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == [-1, 0]
    x₁(tf) == 0
    ẋ(t) == [x₂(t), x₁(t) + α * x₁(t)^2 + u(t)]
    x₂(tf)^2 + 0.5∫(u(t)^2) → min
end
nothing # hide
```

== ocp2 — custom labels, free final time

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

:::

!!! note "Component labels and time variable in `@init`"

    - `@init` uses the **labels** declared in `@def`: `x`, `x₁`, `x₂` and `u` for `ocp1`; `x`, `q`, `v`, `u` and `tf` for `ocp2`.
    - Components not named in `@def`, as in `ocp1` with `x ∈ R²`, receive **default labels** with subscripted indices, `x₁`, `x₂`, usable like custom ones.
    - `@init` uses the **time variable name** of `@def`: `t` for `ocp1` (`x(t) := …`), `s` for `ocp2` (`q(s) := …`).

## The default guess

With no initial guess, every component defaults to `0.1`. To see it without solving, run with `max_iter=0`:

```@example main
sol_default = solve(ocp1; max_iter=0, display=false)
plot(sol_default, :state, :control; size=(800, 600))
```

Solving with no guess at all, `init=nothing`, and `init=()` are all equivalent — all three skip straight to the default:

```@repl main
iterations(solve(ocp1; display=false))
iterations(solve(ocp1; init=nothing, display=false))
iterations(solve(ocp1; init=(), display=false))
```

## The `@init` macro

`@init` builds an initial guess with the syntax `label(t) := expression` (a function of time) or `label := value` (a constant, or the value of a variable):

```julia
ig = @init ocp begin
    # specifications
end
```

| Component | Form | Example |
| :--- | :--- | :--- |
| State / control, function of time | `label(t) := expression` | `u(t) := -0.2t` |
| State / control, constant | `label(t) := value` or `label := value` | `u := 2` |
| State / control, on a grid | `label(T) := data`, `T` a time vector | `u(T) := U` |
| Variable | `label := value` | `tf := 2.0` |
| Alias (local name) | `name = expression` | `a = 0.5` |

1-D components take a scalar (`u(t) := 2`), following the [1-D is a scalar](@ref modelling-abstract-syntax-control) rule; multi-D components take a vector (`x(t) := [1, 2]`).

!!! warning "No indexed syntax"

    `x[1](t) := …` raises a `ParsingError`: `@init` works at the level of declared labels, not array positions. Write `x₁(t) := …`, or use the component's own name.

### Constant

```@repl main
ig = @init ocp1 begin
    x(t) := [-0.2, 0.1]
    u(t) := -0.2
end;

sol = solve(ocp1; init=ig, display=false);
iterations(sol)
```

Constants also accept the shorter form without the time argument (`u := 2` instead of `u(t) := 2`):

```@repl main
ig = @init ocp2 begin
    q := -0.2
    v := 0.0
    u := 0.1
    tf := 2.0
end;

sol = solve(ocp2; init=ig, display=false);
iterations(sol)
```

### Partial

Uninitialised components fall back to `0.1`:

```@repl main
ig = @init ocp1 begin
    u(t) := -0.2
end;

sol = solve(ocp1; init=ig, display=false);
iterations(sol)
```

### Time-dependent functions

```@repl main
ig = @init ocp1 begin
    x(t) := [-0.2t, 0.1t]
    u(t) := -0.2t
end;

sol = solve(ocp1; init=ig, display=false);
iterations(sol)
```

### Aliases

`=` (no time argument) defines a local alias, not a problem label:

```@repl main
ig = @init ocp2 begin
    amplitude = 0.5
    φ = 2π * s
    q(s) := amplitude * sin(φ)
    v(s) := amplitude * cos(φ)
    u(s) := sin(amplitude)
    tf := 2.0
end;

sol = solve(ocp2; init=ig, display=false);
iterations(sol)
```

### [Cross-spec references](@id solve-initial-guess-cross-spec)

Specifications inside one `@init` block can **reference each other**, from top to bottom:

- a reference only resolves to a label (or alias) defined **earlier** in the block;
- substitution happens by name: the referenced label is replaced by its definition when the later expression is evaluated;
- grid specs are not substituted (see the note below).

**Temporal → temporal, and chains.** `v` references `q`, and `u` references `v`, hence `q`:

```@repl main
ig = @init ocp2 begin
    q(s) := sin(s)
    v(s) := 1.0 + q(s)      # references q
    u(s) := s + v(s)^2      # transitively references q via v
    tf := 2.0
end;

sol = solve(ocp2; init=ig, display=false);
iterations(sol)
```

**Constant → temporal.** A function of time can use a constant defined earlier:

```@repl main
ig = @init ocp2 begin
    q    := -1.0
    v(s) := q + sin(s)      # uses the constant value of q
    u(s) := 0.0
    tf   := 2.0
end;

sol = solve(ocp2; init=ig, display=false);
iterations(sol)
```

**Constant → constant.** A constant can use another one, including between the components of a variable. Here the variable has two components, `(tf, a)`, and the guess is read back with `variable`:

```@repl main
ocp_var2 = @def begin
    w = (tf, a) ∈ R², variable
    t ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control
    x(0) == 0
    x(1) - a == 0
    ẋ(t) == u(t)
    0.5∫(u(t)^2) → min
end;

ig = @init ocp_var2 begin
    tf := 1.0
    a  := tf + 0.5
end;

variable(ig)
```

**With aliases.** Aliases (`=`) and references (`:=`) combine freely:

```@repl main
ig = @init ocp2 begin
    A    = 2.0              # alias
    q(s) := A * sin(s)      # uses the alias
    v(s) := q(s) + 1.0      # references q
    u(s) := 0.0
    tf   := 2.0
end;

sol = solve(ocp2; init=ig, display=false);
iterations(sol)
```

!!! note "No substitution across grid specs"

    A grid spec (`label(T) := data`, see below) lives in a different evaluation context: it is not substituted into a spec written with the time variable, or vice versa — the reference is then undefined (`UndefVarError`). Keep one style per chain of references.

## On a time grid

`label(T) := data`, with `T` a time vector, interpolates `data` linearly between the points of `T`, and holds the first and last values outside it:

```@repl main
T = [0.0, 5.0, 10.0];
X = [[-1.0, 0.0], [-0.5, 0.5], [0.0, 0.0]];
U = [0.0, -0.5, 0.0];

ig = @init ocp1 begin
    x(T) := X
    u(T) := U
end;

sol = solve(ocp1; init=ig, display=false);
iterations(sol)
```

Different components can use different grids:

```@repl main
Sq = [0.0, 1.0, 2.0]; Dq = [-1.0, -0.5, 0.0];
Sv = [0.0, 2.0];      Dv = [0.0, 0.0];
Su = [0.0, 1.0, 2.0]; Du = [0.0, 0.5, 0.0];

ig = @init ocp2 begin
    q(Sq) := Dq
    v(Sv) := Dv
    u(Su) := Du
    tf := 2.0
end;

sol = solve(ocp2; init=ig, display=false);
iterations(sol)
```

For the state, a matrix (one row per time point) works too:

```@repl main
Xmat = [-1.0 0.0; -0.5 0.5; 0.0 0.0];

ig = @init ocp1 begin
    x(T) := Xmat
    u(T) := U
end;

sol = solve(ocp1; init=ig, display=false);
iterations(sol)
```

## Mixing the forms

Constants, functions, and grids combine freely in one `@init` block:

```@repl main
ig = @init ocp1 begin
    x(T) := X               # grid
    u(t) := -0.2 * sin(t)   # function
end;

sol = solve(ocp1; init=ig, display=false);
iterations(sol)
```

## Warm start from a solution

Pass a [`Solution`](@ref results-solution) directly: dimensions of state, control, and variable must match, but not the grids — the solution is interpolated onto the grid of the new solve. This is the basis of discrete continuation, on the grid (see the [guided tour](@ref getting-started-guided-tour)) or on a parameter of the problem (see [Discrete continuation](@extref Tutorials tutorial-continuation)):

```@repl main
sol_init = solve(ocp1; display=false);
sol = solve(ocp1; init=sol_init, display=false);
iterations(sol)
```

Or extract functions from a solution and feed them through `@init`: `state` and `control` on a solution return functions of time, and `variable` its value.

```@repl main
x_fun = state(sol_init);
u_fun = control(sol_init);

ig = @init ocp1 begin
    x(t) := x_fun(t)
    u(t) := u_fun(t)
end;

sol = solve(ocp1; init=ig, display=false);
iterations(sol)
```

## Without `@init`: a named tuple

`init` also accepts a named tuple with the fields `state`, `control` and `variable`, each a constant or a function of time (any subset of them):

```@repl main
sol = solve(
    ocp2; 
    init=(state=s -> [-1 + s, 0.0], control=0.1, variable=2.0), 
    display=false
);
iterations(sol)
```

The fields can also be the labels of the components, and a grid is passed as a `(T, data)` pair:

```@repl main
sol = solve(
    ocp2; 
    init=(q=(Sq, Dq), v=0.0, u=0.1, tf=2.0), 
    display=false
);
iterations(sol)
```

## Inspect or check a guess

Whatever you pass as `init`, `solve` turns it into an initial guess with [`build_initial_guess`](@ref)`(ocp, init)`. `@init` returns one already. Read it back with `state`, `control` and `variable`, as on a solution; components that are not specified take the default value `0.1`:

```@repl main
ig = @init ocp2 begin
    q(s) := sin(s)
    tf := 2.0
end;

state(ig)(0.5)
control(ig)(0.5)
variable(ig)
```

Both check the guess against the problem, before any solve: a component of the wrong dimension raises an `IncorrectArgument`.

```@repl main
build_initial_guess(ocp2, (state=[-1.0, 0.0, 0.0],))   # ocp2 has a 2-D state
```

```@example main
err = try                                                   # hide
    build_initial_guess(ocp2, (state=[-1.0, 0.0, 0.0],))    # hide
catch e                                                     # hide
    e                                                       # hide
end                                                         # hide
@assert err isa OptimalControl.IncorrectArgument            # hide
nothing                                                     # hide
```

## Costate and multipliers

There is currently no way to seed the costate or the multipliers — only state, control, and variable accept an initial guess. How the costate and the constraint multipliers start is then left to the solver, and depends on which one you use.

## `init` or `initial_guess`

`init` is an alias for `initial_guess`; use whichever reads better, but not both in the same
call, in descriptive and explicit mode alike:

```@repl main
solve(ocp1; init=nothing, initial_guess=nothing, display=false)
```

## See also

- [Solve overview](@ref solve-overview) — the rest of what `solve` accepts.
- [Solution object](@ref results-solution) — `state`, `costate`, `control`, `variable` on a returned solution.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — where the labels `@init` uses come from.
- [Discrete continuation](@extref Tutorials tutorial-continuation) — warm starts along a family of problems.

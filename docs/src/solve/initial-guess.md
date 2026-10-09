# [Initial guess](@id solve-initial-guess)

Every way to hand `solve` a starting point: constants, functions, grids, a previous solution,
or nothing at all.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

Two running examples, to show both default and custom component labels:

```@example main
t0 = 0; tf = 10; α = 5

ocp1 = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == [-1, 0]
    x₁(tf) == 0
    ẋ(t) == [x₂(t), x₁(t) + α * x₁(t)^2 + u(t)]
    x₂(tf)^2 + ∫(0.5u(t)^2) → min
end
nothing # hide
```

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

    - `@init` uses the **labels** declared in `@def`. For `ocp1`, you can use `x`, `x₁`, `x₂`
      and `u`; for `ocp2`, `x`, `q`, `v`, `u` and `tf`.
    - When components are not named in `@def` (as in `ocp1` with `x ∈ R²`), they receive
      **default labels** with subscripted indices, `x₁`, `x₂`, usable in `@init` like custom
      labels.
    - `@init` uses the **time variable name** of `@def`: `t` for `ocp1` (`x(t) := …`), `s` for
      `ocp2` (`q(s) := …`).

## The default guess

With no initial guess, every component defaults to `0.1`. To see it without solving, run with
`max_iter=0`:

```@example main
sol_init = solve(ocp1; init=nothing, max_iter=0, display=false)
plot(sol_init, :state, :control; size=(600, 450))
```

Solving with no guess at all, `init=nothing`, and `init=()` are all equivalent — all three skip
straight to the default:

```@example main
sol = solve(ocp1; display=false)
println("no init:         ", iterations(sol), " iterations")

sol = solve(ocp1; init=nothing, display=false)
println("init=nothing:     ", iterations(sol), " iterations")

sol = solve(ocp1; init=(), display=false)
println("init=():          ", iterations(sol), " iterations")
```

## The `@init` macro

`@init` builds an initial guess with the syntax `label(t) := expression` (functions of time) or
`label := value` (for variables and aliases, which aren't functions of time):

```julia
ig = @init ocp begin
    # specifications
end
```

| Component | Form | Example |
| --- | --- | --- |
| State / control, function of time | `label(t) := expression` | `u(t) := -0.2t` |
| State / control, constant | `label(t) := value` or `label := value` | `u := 2` |
| State / control, on a grid | `label(T) := data`, `T` a time vector | `u(T) := U` |
| Variable | `label := value` | `tf := 2.0` |
| Alias (local name) | `name = expression` | `a = 0.5` |

1-D components take a scalar (`u(t) := 2`), following the
[1-D is a scalar](@ref modelling-abstract-syntax-control) rule; multi-D components take a
vector (`x(t) := [1, 2]`).

The indexed syntax `x[1](t) := ...` is **not supported** — `@init` works at the level of
declared labels, not array positions; use `x₁(t) := ...` or a component's own name instead.

### Constant

```@example main
ig = @init ocp1 begin
    x(t) := [-0.2, 0.1]
    u(t) := -0.2
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

Constants also accept the shorter form without the time argument (`u := 2` instead of
`u(t) := 2`):

```@example main
ig = @init ocp2 begin
    q := -0.2
    v := 0.0
    u := 0.1
    tf := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println(iterations(sol), " iterations")
```

### Partial

Uninitialized components fall back to `0.1`:

```@example main
ig = @init ocp1 begin
    u(t) := -0.2
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

### Time-dependent functions

```@example main
ig = @init ocp1 begin
    x(t) := [-0.2t, 0.1t]
    u(t) := -0.2t
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

### Aliases

`=` (no time argument) defines a local alias, not a problem label:

```@example main
ig = @init ocp2 begin
    amplitude = 0.5
    φ = 2π * s
    q(s) := amplitude * sin(φ)
    v(s) := amplitude * cos(φ)
    u(s) := sin(amplitude)
    tf := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println(iterations(sol), " iterations")
```

### [Cross-spec references](@id solve-initial-guess-cross-spec)

Specifications inside one `@init` block can **reference each other**, from top to bottom:

- a reference only resolves to a label (or alias) defined **earlier** in the block;
- substitution happens by name: the referenced label is replaced by its definition when the
  later expression is evaluated;
- grid specs are not substituted (see the note below).

**Temporal → temporal, and chains.** `v` references `q`, and `u` references `v`, hence `q`:

```@example main
ig = @init ocp2 begin
    q(s) := sin(s)
    v(s) := 1.0 + q(s)      # references q
    u(s) := s + v(s)^2      # transitively references q via v
    tf := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println(iterations(sol), " iterations")
```

**Constant → temporal.** A function of time can use a constant defined earlier:

```@example main
ig = @init ocp2 begin
    q    := -1.0
    v(s) := q + sin(s)      # uses the constant value of q
    u(s) := 0.0
    tf   := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println(iterations(sol), " iterations")
```

**Constant → constant.** A constant can use another one, including between the components of
a variable. Here the variable has two components, `(tf, a)`, and the guess is read back with
`variable`:

```@example main
ocp_var2 = @def begin
    w = (tf, a) ∈ R², variable
    t ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control
    x(0) == 0
    x(1) - a == 0
    ẋ(t) == u(t)
    ∫(0.5u(t)^2) → min
end

ig = @init ocp_var2 begin
    tf := 1.0
    a  := tf + 0.5
end

variable(ig)
```

**With aliases.** Aliases (`=`) and references (`:=`) combine freely:

```@example main
ig = @init ocp2 begin
    A    = 2.0              # alias
    q(s) := A * sin(s)      # uses the alias
    v(s) := q(s) + 1.0      # references q
    u(s) := 0.0
    tf   := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println(iterations(sol), " iterations")
```

!!! note "No substitution across grid specs"

    A grid spec (`label(T) := data`, see below) lives in a different evaluation context: it is
    not substituted into a spec written with the time variable, or vice versa. Keep one style
    per chain of references.

## Vector initial guess (interpolated)

`label(T) := data`, with `T` a time vector, interpolates `data` onto the solve grid:

```@example main
T = [0.0, 5.0, 10.0]
X = [[-1.0, 0.0], [-0.5, 0.5], [0.0, 0.0]]
U = [0.0, -0.5, 0.0]

ig = @init ocp1 begin
    x(T) := X
    u(T) := U
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

Different components can use different grids:

```@example main
Sq = [0.0, 1.0, 2.0]; Dq = [-1.0, -0.5, 0.0]
Sv = [0.0, 2.0];      Dv = [0.0, 0.0]
Su = [0.0, 1.0, 2.0]; Du = [0.0, 0.5, 0.0]

ig = @init ocp2 begin
    q(Sq) := Dq
    v(Sv) := Dv
    u(Su) := Du
    tf := 2.0
end

sol = solve(ocp2; init=ig, display=false)
println(iterations(sol), " iterations")
```

For state, a matrix (one row per time point) works too:

```@example main
T = [0.0, 5.0, 10.0]
Xmat = [-1.0 0.0; -0.5 0.5; 0.0 0.0]
U = [0.0, -0.5, 0.0]

ig = @init ocp1 begin
    x(T) := Xmat
    u(T) := U
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

## Mixing them

Constants, functions, and grids combine freely in one `@init` block:

```@example main
T = [0.0, 5.0, 10.0]
X = [[-1.0, 0.0], [-0.5, 0.5], [0.0, 0.0]]

ig = @init ocp1 begin
    x(T) := X               # grid
    u(t) := -0.2 * sin(t)   # function
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

## Warm start from a solution

Pass a [`Solution`](@ref results-solution) directly — dimensions of state, control, and variable must match. This
is the basis for discrete continuation:

```@example main
sol_init = solve(ocp1; display=false)
sol = solve(ocp1; init=sol_init, display=false)
println(iterations(sol), " iterations")
```

Or extract functions from a solution and feed them through `@init`:

```@example main
x_fun = state(sol_init)
u_fun = control(sol_init)

ig = @init ocp1 begin
    x(t) := x_fun(t)
    u(t) := u_fun(t)
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

`state`, `costate` and `control` on a solution return functions of time; `variable` returns the
value of the variable (a scalar for a 1-D variable, a vector otherwise).

## Without `@init`: a named tuple

`init` also accepts a named tuple with the fields `state`, `control` and `variable`, each a
constant or a function of time (any subset of them):

```@example main
sol = solve(ocp2; init=(state=s -> [-1 + s, 0.0], control=0.1, variable=2.0), display=false)
println(iterations(sol), " iterations")
```

## Inspect a guess

Whatever you pass as `init`, `solve` turns it into an initial guess with
[`build_initial_guess`](@ref)`(ocp, init)`. You can call it yourself, and read the result back
with `state`, `control` and `variable`, as on a solution. Components that are not specified
take the default value `0.1`:

```@example main
ig = build_initial_guess(ocp2, @init(ocp2, begin
    q(s) := sin(s)
    tf := 2.0
end))
state(ig)(0.5), control(ig)(0.5), variable(ig)
```

The same holds for the output of `@init` itself, which is an initial guess already.

## Costate and multipliers

There is currently no way to seed the costate or the multipliers — only state, control, and
variable accept an initial guess.

## `init` or `initial_guess`

`init` is an alias for `initial_guess`; use whichever reads better, but not both in the same
call. In descriptive mode, passing both is reported as an unknown option `:init` rather than
as a conflict ([OptimalControl#964](https://github.com/control-toolbox/OptimalControl.jl/issues/964)).

## See also

- [Solve overview](@ref solve-overview) — the rest of what `solve` accepts.
- [Solution object](@ref results-solution) — `state`, `costate`, `control`, `variable` on a
  returned solution.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — where the labels `@init` uses come from.

# [Initial guess](@id solve-initial-guess)

```@meta
Draft = false
```

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

`@init` uses the **labels declared in `@def`**: for `ocp1` that's `x`, `x₁`, `x₂`, `u` (default
subscripted names, since `x ∈ R²` doesn't name its components); for `ocp2` it's `x`, `q`, `v`,
`u`, `tf`. It also uses the **time variable name** from `@def`: `t` for `ocp1`, `s` for `ocp2`.

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

| Component | Has `(t)`? | Uses `:=`? | Example |
| --- | --- | --- | --- |
| State / control | yes | yes | `u(t) := 2` |
| Variable | no | yes | `tf := 2.0` |
| Alias | no | no (use `=`) | `a = 0.5` |

1-D components take a scalar (`u(t) := 2`); multi-D components take a vector
(`x(t) := [1, 2]`). The right-hand side of `:=` can be a constant, a function of the time
variable, or a grid `label(T) := data` for a time vector `T`.

The indexed syntax `x[1](t) := ...` is **not supported** — `@init` works at the level of
declared labels, not array positions; use `x₁(t) := ...` or a component's own name instead.

Whatever you pass as `init=`/`initial_guess=` — `@init` output, `nothing`, a `Solution`, a
constant — `solve` normalizes it the same way internally, via `build_initial_guess(ocp, ...)`.
Calling it yourself is occasionally useful to inspect what got built:

```@example main
ig = @init ocp1 begin
    u(t) := -0.2
end
built = build_initial_guess(ocp1, ig)
typeof(built)
```

### Constant

```@example main
ig = @init ocp1 begin
    x(t) := [-0.2, 0.1]
    u(t) := -0.2
end

sol = solve(ocp1; init=ig, display=false)
println(iterations(sol), " iterations")
```

Constant functions also accept the shorter form without the time argument
(`u := 2` instead of `u(t) := 2`):

```@example main
ig = @init ocp2 begin
    q(s) := -0.2
    v(s) := 0.0
    u(s) := 0.1
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

### Cross-spec references

A spec can reference a label defined earlier in the same block, and references chain:

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

A grid-based spec (`label(T) := data`, see below) lives in a different evaluation context and
is not substituted into a spec written with the plain time variable, or vice versa — keep one
style per chain of references.

## Constants, vectors, functions

State and control 1-D reads through `@init` follow the "1-D is a scalar" rule, same as
everywhere else — no special case to remember here beyond what's already true on
[functional-API callbacks](@ref modelling-functional-api-shapes) and solutions.

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

`state`, `costate`, and `control` on a solution return functions of time; `variable` returns a
vector.

## Costate and multipliers

There is currently no way to seed the costate or the multipliers — only state, control, and
variable accept an initial guess.

## `init` or `initial_guess`

`init` is an alias for `initial_guess`; use whichever reads better. **In explicit mode**,
supplying both at once is rejected cleanly:

```@repl main
try # hide
solve(
    ocp1;
    discretizer=OptimalControl.Collocation(),
    init=1, initial_guess=2,
    display=false,
)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

!!! warning "Same conflict, worse message in descriptive mode"

    In descriptive mode (the common case — no `discretizer=`/`modeler=`/`solver=`), supplying
    both aliases does **not** raise this same clear error. `initial_guess` is consumed first,
    and the leftover `init` falls through to strategy-option routing, where it's rejected as an
    *unrecognized solver option* rather than as a conflicting alias — a much more confusing
    message for the same mistake:

    ```@repl main
    try # hide
    solve(ocp1; init=1, initial_guess=2, display=false)
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

    This is a real inconsistency between the two code paths, not intentional behavior — don't
    rely on either message, just don't pass both.

## Not (yet) part of the public API

`CTModels.jl` has more initial-guess machinery than OptimalControl exposes:
`initial_guess`, `pre_initial_guess`, `validate_initial_guess`, `initial_state`,
`initial_control`, `initial_variable`, and `PreInitialGuess` all exist there but are not
re-exported here — only [`build_initial_guess`](@ref) is. Whether some of these should surface
under `using OptimalControl` is an open question, not a decision this page makes.

## See also

- [Overview](@ref solve-overview) — the rest of what `solve` accepts.
- [Solution object](@ref results-solution) — `state`, `costate`, `control`, `variable` on a
  returned solution.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — where the labels `@init` uses come from.

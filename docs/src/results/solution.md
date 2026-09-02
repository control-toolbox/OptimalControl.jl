# [Solution object](@id results-solution)

Everything you do after something has been computed: read the trajectories, check whether it
converged, read the sensitivities. This page mirrors [Inspect a problem](@ref modelling-inspect)
— that page reads a *model* back, this one reads a *solution* back — and the two sections link
to each other throughout.

## What you get back

`solve` returns a [`Solution`](@ref results-solution); a `Flow` call returns a trajectory. Both
are read with the **same generics** — `state`, `control`, `costate`, `objective`, `time_grid`,
`plot` — so everything on this page also applies to a flow's output (see
[Flows](@ref flows-overview)).

```@example main
using OptimalControl
using NLPModelsIpopt

t0 = 0
tf = 1
x0 = [-1, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end

sol = solve(ocp; display=false)
nothing # hide
```

`Solution` and `AbstractSolution` are imported, not exported — they exist for dispatch, not for
writing type annotations in your own code, so a signature like `f(sol::Solution) = ...` won't
work as written; you'd need `f(sol::OptimalControl.Solution) = ...` or just not annotate.

## Trajectories

`state`, `control`, `variable`, and `costate` return **functions of time** (except `variable`,
which is a single vector — variables don't vary with time):

```@example main
x = state(sol)
u = control(sol)
p = costate(sol)
x(0.25), u(0.25), p(0.25)
```

These functions interpolate — they can be called anywhere in the time horizon, not just at grid
points:

```@example main
0.25 ∈ time_grid(sol)
```

```@example main
x(0.25)  # still works
```

`time_grid(sol)` returns the discretization nodes, and `times(sol)` is an alias for it.

## The time horizon

`initial_time` and `final_time` read the endpoints back. On a fixed-time problem they give you
what you wrote in the `@def`:

```@example main
initial_time(sol), final_time(sol)
```

The case worth knowing is the **free** one. When a time is an optimisation variable, its value
is not in the model — the model only records *which* component of the variable holds it. The
accessor resolves that against the solution's variable for you:

```@example main
ocp_free = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1
    x(0) == [-1, 0]
    q(tf) == 0
    v(tf) == 0
    ẋ(t) == [v(t), u(t)]
    tf → min
end
sol_free = solve(ocp_free; display=false)

initial_time(sol_free), final_time(sol_free)
```

Here `t0` is fixed and `tf` is free, so the second value is the optimal final time. It is the
number the solver put in the optimisation variable, reached through the accessor rather than by
indexing:

```@example main
final_time(sol_free), variable(sol_free)
```

!!! warning "Requires CTModels ≥ 0.18"

    Before that release, `final_time(sol)` threw a `MethodError` on any problem with a free
    final time: the solution-level accessor called `final_time(sol.times)` without passing the
    variable through, and no method matched a `FreeTimeModel` alone. `initial_time(sol)` hit
    the same wall whenever `t0` was the free one.

    The example above is the regression guard — no page in this site read the horizon back from
    a solution, which is how the bug shipped. See
    [CTModels#402](https://github.com/control-toolbox/CTModels.jl/pull/402).

**1-D is a scalar here too**: with a 1-D control, `u(t)` is a `Number`, not a length-1 vector —
same rule as everywhere else on the site ([functional-API callbacks](@ref modelling-functional-api-shapes),
[abstract syntax](@ref modelling-abstract-syntax-control)):

```@example main
typeof(u(0.25))
```

## The objective

```@example main
objective(sol)
```

## Did it work

```@example main
successful(sol), status(sol), message(sol)
```

```@example main
iterations(sol), constraints_violation(sol)
```

`infos(sol)` returns a `Dict` of anything else the solver reported.

!!! warning "`success` is not `successful`"

    `success(sol)` looks like it should work but doesn't — it isn't and never was a CTModels
    method (it resolves to `Base.success`, a process-exit-status function). Calling it on a
    `Solution` now throws a migration-pointing error:

    ```@repl main
    try # hide
    success(sol)
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

    See [Migration](@ref migration) for the full list of renamed spellings.

## Dual variables

Dual variables (Lagrange multipliers) give sensitivity information. A richer problem to show
them on:

```@example main
ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0, (eq_tf)
    -1 ≤ u(t) ≤ 1, (eq_u)
    v(t) ≤ 0.75, (eq_v)
    x(0) == [-1, 0], (eq_x0)
    q(tf) == 0
    v(tf) == 0
    ẋ(t) == [v(t), u(t)]
    tf → min
end
sol = solve(ocp; display=false)
nothing # hide
```

`dual(sol, ocp, :label)` returns the signed multiplier for a labeled constraint — a scalar for
a variable or boundary constraint, a function of time for a path constraint:

```@example main
dual(sol, ocp, :eq_tf)   # variable constraint
```

```@example main
dual(sol, ocp, :eq_x0)   # boundary constraint
```

```@example main
μ_u = dual(sol, ocp, :eq_u)   # path constraint — a function of time
μ_u(0.5)
```

!!! note "Sign convention"

    `μ > 0` means the lower-side constraint is active, `μ < 0` the upper-side, `μ = 0`
    inactive. For box constraints the solver reports separate non-negative lower/upper
    multipliers internally; `dual` combines them as `μ = μ_lb − μ_ub` per component. The raw,
    unsigned, non-negative versions are available separately — see below.

The box-constraint duals, without going through a label — one accessor per group, no per-label
lookup needed:

```@example main
state_constraints_lb_dual(sol), state_constraints_ub_dual(sol)
```

```@example main
control_constraints_lb_dual(sol), control_constraints_ub_dual(sol)
```

```@example main
variable_constraints_lb_dual(sol), variable_constraints_ub_dual(sol)
```

with matching dimension accessors:

```@example main
dim_dual_state_constraints_box(sol),
dim_dual_control_constraints_box(sol),
dim_dual_variable_constraints_box(sol)
```

And the nonlinear (path/boundary) duals as a whole, plus their counts:

```@example main
path_constraints_dual(sol), boundary_constraints_dual(sol)
```

```@example main
dim_path_constraints_nl(sol), dim_boundary_constraints_nl(sol)
```

## Back to the model

```@example main
model(sol) === ocp
```

`model(sol)` gives back the exact OCP the solution was computed from — everything on
[Inspect a problem](@ref modelling-inspect) works on it.

## Empty solutions

```@example main
is_empty_time_grid(sol)
```

`false` for anything a normal `solve` produced — it's a defensive check for the placeholder
case (an uninitialized or degenerate solution object carrying no time grid at all), not
something a real solve leaves you needing to handle.

## See also

- [Inspect a problem](@ref modelling-inspect) — the model-side mirror of this page.
- [Plot a solution](@ref results-plot) — draw everything read here.
- [Save and load](@ref results-save-load) — persist a solution to disk and reload it.
- [Migration](@ref migration) — every renamed accessor, `success` → `successful` included.

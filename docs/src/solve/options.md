# [Options](@id solve-options)

```@meta
Draft = false
```

Every keyword argument passed to `solve` ends up on exactly one strategy: the discretizer,
the modeler, or the solver. This page covers how that routing works, the two escape hatches
for the cases it does not handle automatically, and how to inspect where a value came from.

The examples swing a pendulum up, from rest at the bottom to rest at the top, with the least
effort. The dynamics are nonlinear, so the solver iterates, and its options change what it
returns.

::: details The problem used on this page

```@example advanced
using OptimalControl
using NLPModelsIpopt

ocp = @def begin
    t ∈ [0, 2], time
    x = (θ, ω) ∈ R², state
    u ∈ R, control
    x(0) == [0, 0]
    x(2) == [π, 0]
    ẋ(t) == [ω(t), -sin(θ(t)) + u(t)]
    ∫(u(t)^2) → min
end
nothing # hide
```

:::

## Option routing

`solve` runs in **strict** mode: every keyword you pass must be recognised by exactly one of
the three strategies in play, or it's an error — never a silent no-op.

```@example advanced
sol = solve(ocp;
    grid_size=100,     # → Collocation (discretizer)
    backend=:default,  # → ADNLP (modeler)
    max_iter=500,      # → Ipopt (solver)
    print_level=0,     # → Ipopt (solver)
)
nothing # hide
```

An option nobody recognises is rejected with a "did you mean" suggestion:

```@repl advanced
solve(ocp, :ipopt; max_iter=100, mumps_print_level=1, display=false)
```

## Options change the result

The options of the solver decide when it stops. With the defaults, Ipopt stops at a tolerance
of `1e-8`. A looser tolerance stops sooner, on a less accurate cost; a too small `max_iter`
stops before convergence, and the solution says so:

```@example advanced
sol = solve(ocp; display=false)
sol_tol = solve(ocp; tol=1e-2, display=false)
sol_iter = solve(ocp; max_iter=2, display=false)

for (name, s) in (("default", sol), ("tol=1e-2", sol_tol), ("max_iter=2", sol_iter))
    println(rpad(name, 12), rpad(successful(s), 7), rpad(status(s), 13),
            iterations(s), " iterations, cost ", objective(s))
end
```

```@example advanced
@assert successful(sol) && successful(sol_tol) && !successful(sol_iter)              # hide
@assert iterations(sol_tol) < iterations(sol)                                        # hide
@assert abs(objective(sol_tol) - objective(sol)) > 1e-3                               # hide
nothing                                                                              # hide
```

Always check `successful(sol)` before using a solution (see
[Solution object](@ref results-solution)).

## Explicit routing with `route_to`

If two strategies of a method declared the same option name, using it bare would be
ambiguous, and `solve` would not guess which one you meant. With the built-in strategies,
this does not happen today: no two strategies of a method share an option name. `route_to`
names the target strategy explicitly. It is required for an ambiguous name, and allowed
everywhere, for instance to be explicit:

```@example advanced
using MadNLP
sol = solve(ocp, :madnlp;
    grid_size=50,                     # auto-routed to the discretizer
    max_iter=route_to(:madnlp, 1000), # explicitly routed
    print_level=MadNLP.ERROR,         # auto-routed to the solver
)
nothing # hide
```

`route_to` takes a strategy id and a value, or the same as a keyword argument,
`route_to(madnlp=1000)`. It also accepts several id/value pairs, to send the same option name
to several strategies with different values at once: `route_to(:id1, value1, :id2, value2)`.

```@example advanced
sol = solve(ocp, :madnlp; max_iter=route_to(madnlp=1000), display=false) # keyword form
@assert successful(sol)  # hide
nothing # hide
```

## Undeclared solver options

The three strategies here declare their own options, but not every option the underlying
solver accepts is declared — Ipopt's `mumps_print_level`, for instance, isn't in the strategy
metadata, so it's rejected by strict validation (shown above). Combine `route_to` with
`bypass` to force it through, unvalidated:

```@example advanced
sol = solve(ocp, :ipopt;
    max_iter=100,
    mumps_print_level=route_to(:ipopt, bypass(1)),
)
nothing # hide
```

`bypass` is needed in addition to `route_to` because `route_to` alone still validates against
the strategy's declared options — `bypass` is what skips that check. `force` is a plain alias
for `bypass` (`force === bypass`); use whichever name reads better:
`route_to(:ipopt, force(1))`.

!!! warning "Use `bypass` sparingly"

    It skips type checking and validation entirely. Reach for it only when you're certain the
    option name and value are correct and the strategy genuinely doesn't declare it.

## What a strategy accepts

`describe` prints the options of a strategy (see [Choosing a method](@ref solve-choosing-a-method)).
The same information can be read in code, on the type, before building an instance:

```@example advanced
:max_iter in option_names(OptimalControl.Ipopt)
```

```@example advanced
option_default(OptimalControl.Ipopt, :max_iter), option_type(OptimalControl.Ipopt, :max_iter)
```

```@example advanced
option_description(OptimalControl.Ipopt, :max_iter)
```

`option_defaults(OptimalControl.Ipopt)` gives all the defaults at once, as a named tuple. An
option whose default is `NotProvided` is not passed to the solver, which then uses its own.

```@example advanced
@assert :max_iter in option_names(OptimalControl.Ipopt)                  # hide
@assert option_default(OptimalControl.Ipopt, :max_iter) == 1000          # hide
@assert option_type(OptimalControl.Ipopt, :max_iter) == Integer          # hide
@assert option_defaults(OptimalControl.Ipopt).max_iter == 1000           # hide
nothing                                                                  # hide
```

## Where a value came from

Every option on a built strategy instance knows whether it was set by you (`:user`), left at
its default (`:default`), or computed from the `:cpu`/`:gpu` parameter (`:computed`):

```@example advanced
s = OptimalControl.Ipopt(max_iter=200)
println(has_option(s, :max_iter))      # true — Ipopt declares this option
println(has_option(s, :not_an_option)) # false
println(option_value(s, :max_iter))    # 200 — what will actually be used
println(option_value(s, :tol))         # 1.0e-8 — strategy default

opts = options(s)
println(is_user(opts, :max_iter))      # true
println(is_default(opts, :tol))        # true
println(is_computed(opts, :max_iter))  # false
```

`option_source` returns which of the three it was, as a `Symbol`. MadNLP's linear solver is a
computed option: its default depends on the parameter (MUMPS on CPU, cuDSS on GPU):

```@example advanced
println(option_source(s, :max_iter))
println(option_source(s, :tol))
println(option_source(OptimalControl.MadNLP(), :linear_solver))
```

```@example advanced
@assert option_source(s, :max_iter) == :user                                   # hide
@assert option_source(s, :tol) == :default                                     # hide
@assert option_source(OptimalControl.MadNLP(), :linear_solver) == :computed    # hide
nothing                                                                        # hide
```

The display of `solve` (see [Solve overview](@ref solve-overview)) shows the `:user` and
`:computed` options of each strategy, the latter tagged `[cpu-dependent]` or
`[gpu-dependent]`; the `:default` ones are not shown.

## Action options vs strategy options

Two keywords — `init`/`initial_guess` and `display`/`show_trace` — are handled *before*
routing even starts; they're never sent to a strategy. In each pair the two names are
aliases: use either, but not both in the same call (an `IncorrectArgument`). If a strategy happens to declare an option with the
same name, the action option wins by default. `route_to` is the way around that, if you ever
need to target the strategy's own option of that name explicitly instead.

## See also

- [Choosing a method](@ref solve-choosing-a-method) — the strategies these options are routed to.
- [Explicit mode](@ref solve-explicit-mode) — configure a strategy by passing options directly
  to its constructor instead of routing them through `solve`.

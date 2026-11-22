# [Options](@id solve-options)

Every keyword argument passed to `solve` does one of two things. Two **action options**
control `solve` itself; they are handled before any strategy sees them:

| Option | Alias | Role |
| :--- | :--- | :--- |
| `initial_guess` | `init` | the starting point of the solve (see [Initial guess](@ref solve-initial-guess)) |
| `display` | `show_trace` | the configuration box and the solver's log |

Every other keyword is a **strategy option**, routed to exactly one of the three strategies
of the method — the discretizer, the modeler, or the solver (see
[Choosing a method](@ref solve-choosing-a-method)). This page covers how that routing works,
and the two escape hatches for the cases it does not handle automatically:
[`route_to`](@ref solve-options-route-to), to name the target strategy explicitly, and
[`bypass`](@ref solve-options-undeclared), to pass an option the strategy does not declare.

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

```@repl advanced
sol = solve(ocp;
    grid_size=100,     # → Collocation (discretizer)
    backend=:default,  # → ADNLP (modeler)
    max_iter=500,      # → Ipopt (solver)
    print_level=0,     # → Ipopt (solver)
);
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

println(
    rpad("options", 12), 
    rpad("successful", 11), 
    rpad("status", 13), 
    rpad("iterations", 11), 
    "cost\n"
)
for (name, s) in (("default", sol), ("tol=1e-2", sol_tol), ("max_iter=2", sol_iter))
    println(
        rpad(name, 12),
        rpad(successful(s), 11),
        rpad(status(s), 13),
        rpad(iterations(s), 11),
        objective(s)
    )
end
```

```@example advanced
@assert successful(sol) && successful(sol_tol) && !successful(sol_iter)              # hide
@assert iterations(sol_tol) < iterations(sol)                                        # hide
@assert abs(objective(sol_tol) - objective(sol)) > 1e-3                              # hide
nothing                                                                              # hide
```

Always check `successful(sol)` before using a solution (see
[Solution object](@ref results-solution)).

## [Explicit routing with `route_to`](@id solve-options-route-to)

Routing can be made explicit: `route_to(:strategy, value)` wraps a value and names the
strategy it goes to. It is what you reach for when a bare option name would be ambiguous —
two strategies declaring the same name — and it is allowed everywhere else too, for instance
simply to make the target visible in the call:

```@repl advanced
using MadNLP
sol = solve(ocp, :madnlp;
    grid_size=50,                     # auto-routed to the discretizer
    max_iter=route_to(:madnlp, 1000), # explicitly routed
    print_level=MadNLP.ERROR,         # auto-routed to the solver
);
```

!!! info "What the strategies declare — and what they don't"

    Each strategy declares a curated set of options: the ones most users need, not the
    package's full list. Today no two strategies of a method share an option name, so the
    ambiguous case `route_to` is built for does not occur with the built-in strategies.
    `describe` lists what a strategy declares (see
    [Choosing a method](@ref solve-choosing-a-method)); for what it does not, see
    [Undeclared solver options](@ref solve-options-undeclared) below.

`route_to` takes a strategy id and a value, or the same as a keyword argument,
`route_to(madnlp=1000)`. It also accepts several id/value pairs, to send the same option name
to several strategies with different values at once: `route_to(:id1, value1, :id2, value2)`.

```@example advanced
sol = solve(ocp, :madnlp; max_iter=route_to(madnlp=1000), display=false) # keyword form
@assert successful(sol)  # hide
nothing # hide
```

## [Undeclared solver options](@id solve-options-undeclared)

The three strategies here declare their own options, but not every option the underlying
solver accepts is declared — Ipopt's `mumps_print_level`, for instance, isn't in the strategy
metadata, so it's rejected by strict validation (shown above). Combine `route_to` with
`bypass` to force it through, unvalidated:

```@repl advanced
sol = solve(ocp, :ipopt;
    max_iter=100,
    print_level=0,
    mumps_print_level=route_to(:ipopt, bypass(1)), # undeclared — bypass skips validation
);
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

```@repl advanced
:max_iter in option_names(OptimalControl.Ipopt)
option_default(OptimalControl.Ipopt, :max_iter)
option_type(OptimalControl.Ipopt, :max_iter)
option_description(OptimalControl.Ipopt, :max_iter)
```

`option_defaults(OptimalControl.Ipopt)` gives all the defaults at once, as a named tuple.

!!! note "`NotProvided` vs OptimalControl defaults"

    The defaults shown by `describe` and `option_defaults` are the ones **OptimalControl**
    sets. An option with an explicit value is always passed to the solver, overriding its
    own default: `max_iter` is `1000` here, though Ipopt's own default is `3000`;
    `mu_strategy` is `"adaptive"`, though Ipopt's is `"monotone"`. An option marked
    `NotProvided` is *not passed at all* — the solver keeps its own default.
    `hessian_approximation`, for instance, is `NotProvided`, so Ipopt uses `"exact"`.

    The same holds for the modelers: `backend = :optimized` is OptimalControl's choice of AD
    backend, while `jacobian_backend` is `NotProvided`, so ADNLPModels uses its own.

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

```@repl advanced
s = OptimalControl.Ipopt(max_iter=200)
has_option(s, :max_iter)       # Ipopt declares this option
has_option(s, :not_an_option)
option_value(s, :max_iter)     # what will actually be used
option_value(s, :tol)          # a strategy default

opts = options(s)
is_user(opts, :max_iter)
is_default(opts, :tol)
is_computed(opts, :max_iter)
nothing # hide
```

`option_source` returns which of the three it was, as a `Symbol`. MadNLP's linear solver is a
computed option: its default depends on the parameter (MUMPS on CPU, cuDSS on GPU):

```@repl advanced
option_source(s, :max_iter)
option_source(s, :tol)
option_source(OptimalControl.MadNLP(), :linear_solver)
nothing # hide
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

The two action options of the introduction — `initial_guess`/`init` and
`display`/`show_trace` — are never sent to a strategy. In each pair the two names are
aliases: use either, but not both in the same call (an `IncorrectArgument`). If a strategy
happens to declare an option with the same name, the action option wins by default.
`route_to` is the way around that, if you ever need to target the strategy's own option of
that name explicitly instead.

## See also

- [Choosing a method](@ref solve-choosing-a-method) — the strategies these options are routed to.
- [Explicit mode](@ref solve-explicit-mode) — configure a strategy by passing options directly
  to its constructor instead of routing them through `solve`.

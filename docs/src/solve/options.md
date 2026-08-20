# [Options](@id solve-options)

```@meta
Draft = false
```

Every keyword argument passed to `solve` ends up on exactly one strategy — the discretizer,
the modeler, or the solver. This page covers how that routing works, the two escape hatches
for the cases it doesn't handle automatically, and how to inspect where a value came from.

```@example advanced
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
nothing # hide
```

## Option routing

`solve` runs in **strict** mode: every keyword you pass must be recognized by exactly one of
the three strategies in play, or it's an error — never a silent no-op.

```@example advanced
sol = solve(ocp;
    grid_size=100,   # → Collocation (discretizer)
    show_time=true,  # → ADNLP (modeler)
    max_iter=500,    # → Ipopt (solver)
    print_level=0,   # → Ipopt (solver)
)
nothing # hide
```

An option nobody recognizes is rejected with a "did you mean" suggestion:

```@example advanced
try
    solve(ocp, :ipopt; max_iter=100, mumps_print_level=1, display=false)
catch e
    println(e)
end
```

## Ambiguous options

If two strategies from *different* families declare the same option name, using it bare is
ambiguous — `solve` won't guess which one you meant. Disambiguate with `route_to`, which takes
a strategy id and a value:

```julia
sol = solve(ocp, :exa, :madnlp;
    common_option_name=route_to(:exa, 12),
    max_iter=500,
)
```

`route_to` also accepts alternating id/value pairs, to send the same option name to several
strategies with different values at once:

```julia
sol = solve(ocp, :exa, :madnlp;
    common_option_name=route_to(:exa, 12, :madnlp, true),
)
```

`route_to` works even when there's no ambiguity to resolve — it's fine to use it just to be
explicit:

```@example advanced
using MadNLP
sol = solve(ocp, :madnlp;
    grid_size=50,                     # auto-routed to the discretizer
    max_iter=route_to(:madnlp, 1000), # explicitly routed
    print_level=MadNLP.ERROR,         # auto-routed to the solver
)
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

Both `bypass` and `route_to` return values of internal types (`BypassValue`, `RoutedOption`) —
these types are imported but not exported, so only the functions ever appear in your code, not
the type names.

!!! warning "Use `bypass` sparingly"

    It skips type checking and validation entirely. Reach for it only when you're certain the
    option name and value are correct and the strategy genuinely doesn't declare it.

## Where a value came from

Every option on a built strategy instance knows whether it was set by you, left at its
default, or computed from the problem:

```@example advanced
s = OptimalControl.Ipopt(max_iter=200)
println(option_value(s, :max_iter))    # 200 — what will actually be used
println(option_value(s, :tol))         # 1.0e-8 — the strategy's own default

opts = options(s)
println(is_user(opts, :max_iter))      # true
println(is_default(opts, :tol))        # true
println(is_computed(opts, :max_iter))  # false
```

`option_source` returns which of the three it was, as a `Symbol`:

```@example advanced
println(option_source(s, :max_iter))
println(option_source(s, :tol))
```

This is the same provenance information the `📦 Configuration` table shows when `solve` prints
its display (see [Overview](@ref solve-overview)) — these functions let you query it
programmatically instead of reading it off the printout.

## Action options vs strategy options

Two keywords — `init`/`initial_guess` and `display` — are handled *before* routing even
starts; they're never sent to a strategy. If a strategy happens to declare an option with the
same name, the action option wins by default. `route_to` is the way around that, if you ever
need to target the strategy's own option of that name explicitly instead.

## See also

- [Choosing a method](@ref solve-choosing-a-method) — the strategies these options are routed to.
- [Explicit mode](@ref solve-explicit-mode) — configure a strategy by passing options directly
  to its constructor instead of routing them through `solve`.

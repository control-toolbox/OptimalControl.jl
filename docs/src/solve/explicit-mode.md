# [Explicit mode](@id solve-explicit-mode)

```@meta
Draft = false
```

Instead of symbolic tokens, pass `solve` typed strategy instances — full control over each
component's configuration, no completion-order guessing.

## When you want this

- building the strategy configuration programmatically (from a data structure, a search over
  hyperparameters, etc.),
- reusing one carefully-configured strategy instance across several `solve` calls,
- avoiding any ambiguity about which options went where.

## Basic usage

```@example explicit
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

disc = OptimalControl.Collocation(grid_size=100, scheme=:trapeze)
mod = OptimalControl.ADNLP(backend=:optimized)
sol = OptimalControl.Ipopt(max_iter=1000, print_level=0)

result = solve(ocp; discretizer=disc, modeler=mod, solver=sol)
nothing # hide
```

`discretizer`, `modeler`, and `solver` are just three of many keyword names — mode detection
never looks at names, only at whether a keyword's *value* is a typed component (see
[Overview](@ref solve-overview)). Any keyword holding a typed instance triggers explicit mode.

The component types are `import`ed but not `@reexport`ed by `OptimalControl`, which is why
every constructor above is written `OptimalControl.Collocation(...)` rather than bare
`Collocation(...)` — writing `using CTDirect: Collocation` yourself would also work, but the
qualified spelling needs nothing extra loaded beyond `using OptimalControl`.

## Partial components

Give one component, and the other two are completed the same way descriptive mode completes a
partial token list — first match, top to bottom in [`methods`](@ref)`()`:

```@example explicit
methods()[1]  # (:collocation, :adnlp, :ipopt, :cpu) — what a bare solve(ocp) completes to
```

```@example explicit
result = solve(ocp; solver=OptimalControl.Ipopt(max_iter=2000, print_level=0), display=true)
nothing # hide
```

`solver=Ipopt(...)` alone completes to `Collocation()` (first discretizer) and `ADNLP()` (first
modeler compatible with Ipopt) — visible in the printed configuration above. Mixing a custom
component with defaults works the same way for any subset:

```@example explicit
result = solve(ocp;
    discretizer=OptimalControl.Collocation(grid_size=200, scheme=:trapeze),
    solver=OptimalControl.Ipopt(max_iter=100, print_level=0),
    display=false,
)
nothing # hide
```

## Per-component options

Every option a strategy accepts is set when it's constructed — never routed in from `solve`
afterward, unlike descriptive mode:

```@example explicit
disc = OptimalControl.Collocation(grid_size=150, scheme=:gauss_legendre_2)
mod = OptimalControl.ADNLP(backend=:optimized, show_time=true)
sol = OptimalControl.Ipopt(max_iter=1000, tol=1e-8, print_level=5, acceptable_tol=1e-6)
nothing # hide
```

Undeclared options still need `bypass` (or its alias `force`), same reasoning as in descriptive
mode — but here it's passed straight into the constructor, not through `route_to`:

```@example explicit
solver = OptimalControl.Ipopt(max_iter=500, print_level=0, mumps_print_level=bypass(1))
nothing # hide
```

A flat option keyword handed to `solve` itself, rather than to the component constructor, is
rejected — even one a completed default component would otherwise recognize:

```@repl explicit
try # hide
solve(
    ocp;
    discretizer=OptimalControl.Collocation(),
    backend=:generic,
    display=false,
)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

The error names the strategy that owns the option and tells you exactly how to fix it:
construct that strategy with the option set, and pass the configured instance in. `route_to`
plays no role here — it only makes sense in descriptive mode, where options don't yet belong to
a concrete instance.

## Mixing modes is forbidden

Symbolic tokens and typed components can't appear in the same call:

```@repl explicit
try # hide
solve(
    ocp, :adnlp, :ipopt;
    discretizer=OptimalControl.Collocation(),
    display=false,
)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

Pick one: `solve(ocp, :collocation, :adnlp, :ipopt; options...)` or
`solve(ocp; discretizer=..., modeler=..., solver=...)`.

## Inspecting the components you built

```@example explicit
solver = OptimalControl.Ipopt(max_iter=1000, tol=1e-6, print_level=0)
opts = options(solver)

is_user(opts, :max_iter)
```

```@example explicit
is_default(opts, :mu_strategy)
```

```@example explicit
opts[:max_iter]
```

```@example explicit
collect(keys(opts))
```

## See also

- [Overview](@ref solve-overview) — how mode detection decides between the two styles.
- [Options and routing](@ref solve-options) — the descriptive-mode counterpart (`route_to`,
  automatic routing) to per-component construction here.
- [Choosing a method](@ref solve-choosing-a-method) — the full strategy catalogue these
  constructors build from.

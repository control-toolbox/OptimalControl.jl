# [Explicit mode](@id solve-explicit-mode)

Instead of symbolic tokens, pass `solve` typed strategy instances: full control over each
component's configuration, no completion to guess.

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

discretizer = OptimalControl.Collocation(grid_size=100, scheme=:trapeze)
modeler = OptimalControl.ADNLP(backend=:optimized)
solver = OptimalControl.Ipopt(max_iter=1000, print_level=0)

sol = solve(ocp; discretizer=discretizer, modeler=modeler, solver=solver)
nothing # hide
```

Each component goes with its keyword: `discretizer`, `modeler`, `solver`. The component types
are not exported, so they are written with the module name: `OptimalControl.Collocation(...)`,
`OptimalControl.Ipopt(...)`. This needs nothing loaded beyond `using OptimalControl` (and the
solver package, as always).

## Partial components

Give one component, and the other two are completed the same way descriptive mode completes a
partial token list — first match, top to bottom in [`methods`](@ref)`()`:

```@example explicit
methods()[1]  # what a bare solve(ocp) completes to
```

```@example explicit
sol = solve(
    ocp;
    solver=OptimalControl.Ipopt(max_iter=2000, print_level=0),
    display=true,
)
nothing # hide
```

`solver=Ipopt(...)` alone completes to `Collocation()` (first discretizer) and `ADNLP()` (first
modeler compatible with Ipopt) — visible in the printed configuration above. Mixing a custom
component with defaults works the same way for any subset:

```@example explicit
sol = solve(ocp;
    discretizer=OptimalControl.Collocation(grid_size=200, scheme=:trapeze),
    solver=OptimalControl.Ipopt(max_iter=100, print_level=0),
    display=false,
)
nothing # hide
```

## Per-component options

Every option a strategy accepts is set when it is constructed, never routed in from `solve`
afterwards, unlike descriptive mode. Here, a fourth-order scheme on a coarser grid, and tighter
Ipopt tolerances:

```@example explicit
discretizer = OptimalControl.Collocation(grid_size=50, scheme=:gauss_legendre_2)
modeler = OptimalControl.ADNLP(backend=:optimized)
solver = OptimalControl.Ipopt(max_iter=1000, tol=1e-10, acceptable_tol=1e-8, print_level=0)

sol = solve(ocp; discretizer=discretizer, modeler=modeler, solver=solver)
println("objective = ", objective(sol))   # the exact value is 6
```

```@example explicit
@assert isapprox(objective(sol), 6; rtol=1e-6)   # hide
nothing                                          # hide
```

On 50 steps, the fourth-order scheme recovers the exact cost to about machine precision, where
the default second-order scheme on 250 steps is off by about `1e-4`.

Undeclared options still need `bypass` (or its alias `force`), same reasoning as in descriptive
mode — but here it's passed straight into the constructor, not through `route_to`:

```@example explicit
solver = OptimalControl.Ipopt(
    max_iter=500, print_level=0, mumps_print_level=bypass(1)
)
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

The error names the strategy that owns the option and tells you how to fix it: construct that
strategy with the option set, and pass the configured instance in. `route_to` plays no role
here: it only makes sense in descriptive mode, where options do not yet belong to a concrete
instance.

## Mixing modes is forbidden

Symbolic tokens and typed components cannot appear in the same call:

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

- [Solve overview](@ref solve-overview) — the two styles side by side.
- [Options](@ref solve-options) — the descriptive-mode counterpart (`route_to`, automatic
  routing) to per-component construction here.
- [Choosing a method](@ref solve-choosing-a-method) — the full strategy catalogue these
  constructors build from.

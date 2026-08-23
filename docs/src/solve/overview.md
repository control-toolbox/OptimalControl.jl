# [Overview](@id solve-overview)

```@meta
Draft = false
```

`solve` is the entry point for the direct methods: transcribe the problem, hand it to an NLP
solver, get a [`Solution`](@ref results-solution) back. This page shows the quickest way to call it, how to read
what it printed, and the two ways to steer it away from its defaults.

## Quick start

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

sol = solve(ocp)
nothing # hide
```

A solver package must be loaded before calling `solve` — here `using NLPModelsIpopt` provides
the default `:ipopt`. Without it, `solve` raises an `ExtensionError` naming the missing
package and the exact `using` statement that fixes it.

## Reading the display

By default `solve` prints a configuration table before running: which discretizer, modeler,
and solver were selected, and every option that ends up applied to each — tagged by where the
value came from:

- `:user` — you passed it explicitly,
- `:default` — the strategy's own default,
- `:computed` — derived from the problem (e.g. a grid size picked from the time span).

This is the fastest way to answer "what did `solve` actually do with the call I just wrote?"
without reading source.

## Turning the display off

```@example main
sol = solve(ocp; display=false)
nothing # hide
```

Useful once you trust a configuration and are solving in a loop, a test, or a script.

## The defaults

Calling `solve(ocp)` with no strategy tokens is equivalent to:

```julia
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)
```

This particular quadruplet isn't special-cased — it's simply the first entry of [`methods`](@ref)`()`,
and completion always takes the first match, top to bottom (see
[Choosing a method](@ref solve-choosing-a-method) for the full list and how partial
descriptions are completed).

## Two ways to steer it

`solve` can be pointed at a different strategy in two styles:

- **descriptive** — symbolic tokens, e.g. `solve(ocp, :madnlp)` (see
  [Choosing a method](@ref solve-choosing-a-method)),
- **explicit** — typed component instances, e.g. `solve(ocp; solver=OptimalControl.MadNLP())`
  (see [Explicit mode](@ref solve-explicit-mode)).

**The one thing worth knowing before either of those pages**: which mode you're in is decided
by the *type* of a keyword's *value*, never by the keyword's *name*. Any keyword argument whose
value `isa` `AbstractDiscretizer`, `AbstractNLPModeler`, or `AbstractNLPSolver` switches `solve`
into explicit mode, no matter what that keyword is called. Mixing a typed component with a
non-empty symbolic description is rejected outright:

```@repl main
using MadNLP
try # hide
solve(ocp, :collocation; solver=OptimalControl.MadNLP())
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## When it fails

A solve that doesn't converge still returns a [`Solution`](@ref results-solution) — inspect it rather than
assuming success:

```@example main
println(successful(sol))   # true/false — did the solver report success?
println(status(sol))       # a Symbol, e.g. :first_order, :max_iter
println(message(sol))      # the solver's own message
println(constraints_violation(sol))
```

## See also

- [Choosing a method](@ref solve-choosing-a-method) — the full list of strategies and how
  partial descriptions are completed.
- [Explicit mode](@ref solve-explicit-mode) — build and pass typed components directly.
- [Set an initial guess](@ref solve-initial-guess) — every way to hand `solve` a starting point.

# [Solve overview](@id solve-overview)

`solve` is the entry point for the direct methods: transcribe the problem, hand it to an NLP
solver, get a [`Solution`](@ref results-solution) back. This page shows the quickest way to
call it, how to read what it prints, and the two ways to steer it away from its defaults.

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

A solver package must be loaded before calling `solve`: here `using NLPModelsIpopt` provides
the default `:ipopt`. Without it, `solve` raises an `ExtensionError` naming the missing
package and the `using` statement that fixes it (see [Installation](@ref getting-started-installation)).

## Reading the display

Before running, `solve` prints the method it is about to use, then a **Configuration** box
with one line per strategy: the discretizer, the modeler and the solver. Each line lists the
options that differ from the strategy's defaults. Above, no option was passed, so the box only
names the strategies. Pass some options, and they appear on the line of the strategy that
receives them:

```@example main
sol = solve(ocp; grid_size=50, scheme=:trapeze, max_iter=100, print_level=0)
nothing # hide
```

The box now shows:

- **Discretizer**: `collocation`, with `grid_size = 50` and `scheme = trapeze`;
- **Modeler**: `adnlp`, with no option of its own;
- **Solver**: `ipopt`, with `max_iter = 100` and `print_level = 0`.

Each option was sent to the strategy that declares it: this is the automatic routing described
in [Options](@ref solve-options). Some defaults depend on the `:cpu`/`:gpu` parameter; they are
shown too, tagged `[cpu-dependent]` (or `[gpu-dependent]`). For instance, MadNLP's linear solver:

```@example main
using MadNLP
sol = solve(ocp, :madnlp; print_level=MadNLP.ERROR)
nothing # hide
```

Default values are not shown. To list every option of a strategy with its default, use
`describe`, for instance `describe(:ipopt)` (see [Options](@ref solve-options)).

## Turning the display off

```@example main
sol = solve(ocp; display=false)
nothing # hide
```

It silences both the configuration box and the solver's own log. Useful once you trust a
configuration and are solving in a loop, a test, or a script.

## The defaults

Calling `solve(ocp)` with no strategy tokens is equivalent to:

```julia
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)
```

This quadruplet is the first entry of [`methods`](@ref)`()`, and completion always takes the
first match, top to bottom (see [Choosing a method](@ref solve-choosing-a-method) for the full
list and how partial descriptions are completed).

## Two ways to steer it

`solve` can be pointed at a different strategy in two styles:

- **descriptive**: symbolic tokens, e.g. `solve(ocp, :madnlp)` (see
  [Choosing a method](@ref solve-choosing-a-method)),
- **explicit**: typed components, e.g. `solve(ocp; solver=OptimalControl.MadNLP())`
  (see [Explicit mode](@ref solve-explicit-mode)).

Use one style or the other in a call, not both: a typed component together with symbolic
tokens is rejected.

```@repl main
try # hide
solve(ocp, :collocation; solver=OptimalControl.MadNLP())
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## When it fails

A solve that does not converge still returns a [`Solution`](@ref results-solution). Check it
rather than assuming success. Here we stop Ipopt before its first iteration:

```@example main
sol = solve(ocp; max_iter=0, display=false, print_level=0)
println("successful: ", successful(sol))    # did the solver report success?
println("status:     ", status(sol))        # a Symbol, e.g. :first_order, :max_iter
println("violation:  ", constraints_violation(sol))
```

```@example main
@assert !successful(sol)            # hide
@assert status(sol) == :max_iter    # hide
nothing                             # hide
```

The solution holds the initial guess, which violates the boundary conditions. A converged
solve reports `successful(sol) == true`, the status `:first_order` and a negligible violation:

```@example main
sol = solve(ocp; display=false, print_level=0)
println("successful: ", successful(sol))
println("status:     ", status(sol))
println("violation:  ", constraints_violation(sol))
```

```@example main
@assert successful(sol)                       # hide
@assert isapprox(objective(sol), 6; rtol=1e-3)  # hide
nothing                                       # hide
```

## See also

- [Choosing a method](@ref solve-choosing-a-method) — the full list of strategies and how
  partial descriptions are completed.
- [Options](@ref solve-options) — routing, inspection with `describe`, disambiguation.
- [Explicit mode](@ref solve-explicit-mode) — build and pass typed components directly.
- [Initial guess](@ref solve-initial-guess) — every way to hand `solve` a starting point.

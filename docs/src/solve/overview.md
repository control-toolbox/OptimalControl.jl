# [Solve overview](@id solve-overview)

`solve` is the entry point for the direct methods: transcribe the problem, hand it to an NLP
solver, get a [`Solution`](@ref results-solution) back. This page shows the quickest way to
call it, how to read what it prints, and the two ways to steer it away from its defaults.

## The direct method, briefly

The notation is the one of [Notation and conventions](@ref modelling-formulation-conventions).
A direct method replaces the optimal control problem by a finite-dimensional one:

- the time interval is cut by a grid $t_0 < t_1 < \dots < t_N = t_f$, with $N$ steps
  (`grid_size`, 250 by default);
- the unknowns are the values of the state and of the control on this grid, and the
  variable if there is one;
- the dynamics $\dot x = f(t, x, u, v)$ becomes, on each step, the equation of an integration
  scheme, for instance $x_{i+1} = x_i + h_i\, f(t_i, x_i, u_i, v)$ with $h_i = t_{i+1} - t_i$
  for the explicit Euler scheme (the default is the midpoint scheme, see
  [Choosing a method](@ref solve-choosing-a-method) for the others);
- the cost is computed with the same scheme, and the other constraints are written at the
  points of the grid.

This gives a nonlinear program (NLP) on the vector $X$ of all the unknowns,

```math
\min_X\ F(X) \quad \text{subject to} \quad LB \le C(X) \le UB,
```

solved by an NLP solver, Ipopt by default. Its multipliers give the dual variables of the
solution: those of the discretised dynamics approximate the costate $p$ of the maximum
principle (see [Solution object](@ref results-solution-trajectories)).

`solve` carries out these steps with three components: a **discretizer** (the grid and the
scheme), a **modeler** that builds the NLP, and a **solver**. The rest of this section shows
how to choose and configure them; the [Explicit mode](@ref solve-explicit-mode-stages) runs
the steps one by one. The equations of each scheme are in the
[CTDirect documentation](https://control-toolbox.org/CTDirect.jl/stable/).

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
solve(ocp, :collocation; solver=OptimalControl.MadNLP())
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

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
rejected — even one a completed default component would otherwise recognise:

```@repl explicit
solve(
    ocp;
    discretizer=OptimalControl.Collocation(),
    backend=:generic,
    display=false,
)
```

The error names the strategy that owns the option and tells you how to fix it: construct that
strategy with the option set, and pass the configured instance in. `route_to` plays no role
here: it only makes sense in descriptive mode, where options do not yet belong to a concrete
instance.

## Mixing modes is forbidden

Symbolic tokens and typed components cannot appear in the same call:

```@repl explicit
solve(
    ocp, :adnlp, :ipopt;
    discretizer=OptimalControl.Collocation(),
    display=false,
)
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

## [The stages behind `solve`](@id solve-explicit-mode-stages)

`solve` chains three stages, one per component: the discretizer turns the problem into a
discretised problem, the modeler builds from it a nonlinear program (NLP) for an initial
guess, and the solver solves the NLP. The first two stages can be run on their own, to look
at the NLP or to pass it to another tool:

```@example explicit
discretizer = OptimalControl.Collocation(grid_size=100, scheme=:trapeze)
modeler = OptimalControl.ADNLP()

docp = discretize(ocp, discretizer)
init = build_initial_guess(ocp, nothing)   # the default initial guess
nlp = nlp_model(docp, init, modeler)
nlp.meta.nvar, nlp.meta.ncon
```

The NLP has 303 unknowns, the state and the control at the 101 points of the grid, and 204
constraints, the 200 equations of the dynamics and the 4 boundary conditions. `solve` also
takes the discretised problem, with the initial guess and the two other components:

```@example explicit
sol = solve(docp, init, modeler, solver; display=false)
objective(sol)
```

To solve the NLP with a solver of your own and get a solution back, build it with
`OptimalControl.build_model`: it returns the NLP, `built.nlp`, together with what the modeler
needs to read its solution, and `ocp_solution` turns the output of the solver into a
solution of the problem. Here with Ipopt, called directly:

```@example explicit
built = OptimalControl.build_model(docp, init, modeler)
stats = NLPModelsIpopt.ipopt(built.nlp; print_level=0)
sol_nlp = ocp_solution(built, stats, modeler)
objective(sol_nlp)
```

```@example explicit
@assert (nlp.meta.nvar, nlp.meta.ncon) == (303, 204)            # hide
@assert isapprox(objective(sol), 6; rtol=1e-2)                  # hide
@assert isapprox(objective(sol_nlp), objective(sol); rtol=1e-6) # hide
nothing                                                         # hide
```

!!! warning "`discretize` and `OrdinaryDiffEqTsit5`"

    `OrdinaryDiffEqTsit5`, needed for [flows](@ref flows-overview), also exports a function
    named `discretize`. After `using OptimalControl` and `using OrdinaryDiffEqTsit5`, the
    name is ambiguous, and calling `discretize` throws an `UndefVarError`. Write
    `OptimalControl.discretize`, or load only the integrator from the package:
    `using OrdinaryDiffEqTsit5: Tsit5`.

## See also

- [Solve overview](@ref solve-overview) — the two styles side by side.
- [Options](@ref solve-options) — the descriptive-mode counterpart (`route_to`, automatic
  routing) to per-component construction here.
- [Choosing a method](@ref solve-choosing-a-method) — the full strategy catalogue these
  constructors build from.

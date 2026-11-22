# [Discretisation](@id modelling-discretisation)

A problem defined with [`@def`](@ref) or the [functional API](@ref modelling-functional-api)
is continuous: its state and control are functions of time. The direct methods of
[`solve`](@ref solve-overview) work on a finite-dimensional approximation of it, which `solve`
builds and throws away. This page builds it by hand, in two steps: first the **discretised
problem**, then the **nonlinear program** (NLP) a solver works on. Both can be kept, inspected,
reused, and handed to other tools.

## [The direct method](@id modelling-discretisation-direct-method)

The notation is the one of [Notation and conventions](@ref modelling-formulation-conventions).
A direct method replaces the optimal control problem by a finite-dimensional one:

- the time interval is cut by a grid $t_0 < t_1 < \dots < t_N = t_f$, with $N$ steps
  (`grid_size`, 250 by default);
- the unknowns are the values of the state and of the control on this grid, and the
  variable if there is one;
- the dynamics $\dot x = f(t, x, u, v)$ becomes, on each step, the equation of an integration
  scheme, for instance $x_{i+1} = x_i + h_i\, f(t_i, x_i, u_i, v)$ with $h_i = t_{i+1} - t_i$
  for the explicit Euler scheme (the default is the midpoint scheme, see
  [Discretisation schemes](@ref solve-choosing-a-method-schemes) for the others);
- the cost is computed with the same scheme, and the other constraints are written at the
  points of the grid.

This gives a nonlinear program on the vector $X$ of all the unknowns,

```math
\min_X\ F(X) \quad \text{subject to} \quad LB \le C(X) \le UB,
```

solved by an NLP solver, Ipopt by default. Its multipliers give the dual variables of the
solution: those of the discretised dynamics approximate the costate $p$ of the maximum
principle (see [Solution object](@ref results-solution-trajectories)). The equations of each
scheme are in the [CTDirect documentation](https://control-toolbox.org/CTDirect.jl/stable/).

## The four steps

`solve(ocp)` runs four steps, and each of them can be run on its own:

| Step | Call | Result |
| :--- | :--- | :--- |
| discretise | [`discretize`](@ref)`(ocp, discretizer)` | the discretised problem |
| model | [`nlp_model`](@ref)`(docp, init, modeler)` | the NLP: an `ADNLPModel` or an `ExaModel` |
| solve | an NLP solver, called on the NLP | the statistics of the solver |
| read back | [`ocp_solution`](@ref)`(built, stats, modeler)` | a [`Solution`](@ref results-solution) |

The discretizer, the modeler and the solver are the typed components of
[Explicit mode](@ref solve-explicit-mode), configured the same way. The examples use the
energy-minimal double integrator of [Your first problem](@ref getting-started-first-problem).

::: details The problem used on this page

```@example main
using OptimalControl
using NLPModelsIpopt   # the Ipopt solver
using MadNLP           # the MadNLP solver

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

:::

## [The discretised problem](@id modelling-discretisation-docp)

`discretize` takes the problem and a discretizer, here a collocation on 100 steps with the
trapezoidal scheme:

```@example main
discretizer = OptimalControl.Collocation(grid_size=100, scheme=:trapeze)
docp = discretize(ocp, discretizer)
nothing # hide
```

The result is a discretised optimal control problem, or DOCP, of type
`OptimalControl.DiscretizedModel`. It fixes the grid, the unknowns and the equations of the
scheme, but not yet how they are evaluated and differentiated: that is the job of the modeler,
at the next step. It keeps the problem it comes from:

```@example main
ocp_model(docp) === ocp
```

A DOCP is built once and serves as many times as needed. It gives NLPs, for any modeler and
any initial guess (next section), and `solve` takes it in place of the problem, with an
initial guess and the three other components:

```@example main
init = build_initial_guess(ocp, nothing)   # the default initial guess

sol_ipopt = solve(docp, init, OptimalControl.ADNLP(), OptimalControl.Ipopt(print_level=0);
                  display=false)
sol_madnlp = solve(docp, init, OptimalControl.Exa(), OptimalControl.MadNLP(print_level=MadNLP.ERROR);
                   display=false)
objective(sol_ipopt), objective(sol_madnlp)
```

The two solvers solve the same discretised problem, and find the same value, up to their
tolerances. A solution is also a good initial guess for a nearby problem on the same grid, the
start of a continuation (see [Initial guess](@ref solve-initial-guess)):

```@example main
warm = build_initial_guess(ocp, sol_ipopt)
sol = solve(docp, warm, OptimalControl.ADNLP(), OptimalControl.Ipopt(print_level=0);
            display=false)
iterations(sol)
```

```@example main
@assert ocp_model(docp) === ocp                                          # hide
@assert isapprox(objective(sol_ipopt), 6; rtol=1e-2)                     # hide
@assert isapprox(objective(sol_madnlp), objective(sol_ipopt); rtol=1e-6) # hide
@assert iterations(sol) == 0                                             # hide
nothing                                                                  # hide
```

Started from the solution, Ipopt has nothing left to do.

## [The NLP models](@id modelling-discretisation-nlp)

`nlp_model` builds the NLP of a DOCP, for an initial guess and a modeler. The modeler
`OptimalControl.ADNLP()` builds an `ADNLPModel`, from
[ADNLPModels.jl](https://jso.dev/ADNLPModels.jl/stable/), with derivatives computed by
automatic differentiation:

```@example main
nlp = nlp_model(docp, init, OptimalControl.ADNLP())
nlp.meta.nvar, nlp.meta.ncon
```

The NLP has 303 unknowns, the state and the control at the 101 points of the grid, and 204
constraints, the 200 equations of the dynamics and the 4 boundary conditions. Its starting
point `nlp.meta.x0` is the initial guess, written in the unknowns of the NLP.

The modeler `OptimalControl.Exa()` builds an `ExaModel`, from
[ExaModels.jl](https://madsuite-org.github.io/ExaModels.jl/stable/), which evaluates the
equations of the scheme in parallel, on CPU or on GPU (see [GPU](@ref solve-gpu)). Same
unknowns, same constraints:

```@example main
nlp_exa = nlp_model(docp, init, OptimalControl.Exa())
nlp_exa.meta.nvar, nlp_exa.meta.ncon
```

Not every scheme is available with `Exa`: see the table of
[Discretisation schemes](@ref solve-choosing-a-method-schemes).

Both are models of [NLPModels.jl](https://jso.dev/NLPModels.jl/stable/), the common interface
of the JuliaSmoothOptimizers ecosystem: its functions evaluate the objective, the
constraints and their derivatives at any point $X$. At the starting point, where the control is
$0.1$ everywhere, both give the cost $\frac12 \int u^2 = 0.005$:

```@example main
using NLPModels: obj, grad, cons, jac

X = nlp.meta.x0
obj(nlp, X), obj(nlp_exa, X)
```

```@example main
size(jac(nlp, X))   # 204 constraints, 303 unknowns
```

```@example main
@assert (nlp.meta.nvar, nlp.meta.ncon) == (303, 204)            # hide
@assert (nlp_exa.meta.nvar, nlp_exa.meta.ncon) == (303, 204)    # hide
@assert isapprox(obj(nlp, X), obj(nlp_exa, X); rtol=1e-12)      # hide
@assert isapprox(obj(nlp, X), 0.005; rtol=1e-8)                 # hide
@assert size(jac(nlp, X)) == (204, 303)                         # hide
@assert length(grad(nlp, X)) == 303 && length(cons(nlp, X)) == 204  # hide
nothing                                                         # hide
```

The NLP is the place to study the discretised problem as an optimisation problem: its
sparsity, its conditioning, its derivatives, or to test an optimisation method on it.

## [Solving the NLP yourself](@id modelling-discretisation-solve-nlp)

An NLP model is accepted by any solver of the NLPModels interface, not only by the ones
`solve` knows. Here Ipopt, through `NLPModelsIpopt.ipopt`:

```@example main
stats = ipopt(nlp; print_level=0)
stats.status, stats.objective
```

What comes back is the output of the solver, not a solution of the control problem:
`stats.solution` is the vector of the 303 unknowns, in an order internal to the discretizer,
and `stats.multipliers` the vector of the 204 multipliers. To get the trajectories back, build
the NLP with `OptimalControl.build_model` instead of `nlp_model`: it returns the NLP,
`built.nlp`, together with what the modeler needs to read its solution. Then `ocp_solution`
turns the output of the solver into a [`Solution`](@ref results-solution):

```@example main
modeler = OptimalControl.ADNLP()
built = OptimalControl.build_model(docp, init, modeler)
stats = ipopt(built.nlp; print_level=0)
sol = ocp_solution(built, stats, modeler)
objective(sol), successful(sol)
```

The same with the `Exa` modeler and MadNLP, called through `MadNLP.madnlp`:

```@example main
modeler = OptimalControl.Exa()
built = OptimalControl.build_model(docp, init, modeler)
stats = madnlp(built.nlp; print_level=MadNLP.ERROR)
sol_exa = ocp_solution(built, stats, modeler)
objective(sol_exa), successful(sol_exa)
```

```@example main
@assert successful(sol) && successful(sol_exa)                     # hide
@assert isapprox(objective(sol), objective(sol_ipopt); rtol=1e-6)  # hide
@assert isapprox(objective(sol_exa), objective(sol); rtol=1e-6)    # hide
nothing                                                            # hide
```

`sol` and `sol_exa` are solutions of the optimal control problem, like the ones `solve`
returns: the state, the control and the costate as functions of time, the multipliers of the
constraints, the plots, the export to a file (see [Solution object](@ref results-solution)).
`solve` runs these very steps, with the solver chosen among its components, and adds the
completion of a partial description, the routing of the options and the display of the
configuration ([Explicit mode](@ref solve-explicit-mode)). Calling a solver yourself is for
the solvers `solve` does not wrap, for a solver option it does not route, or to read the
statistics of the solver in full.

!!! warning "`discretize` and `OrdinaryDiffEqTsit5`"

    `OrdinaryDiffEqTsit5`, needed for [flows](@ref flows-overview), also exports a function
    named `discretize`. After `using OptimalControl` and `using OrdinaryDiffEqTsit5`, the
    name is ambiguous, and calling `discretize` throws an `UndefVarError`. Write
    `OptimalControl.discretize`, or load only the integrator from the package:

    ```julia
    using OrdinaryDiffEqTsit5          # [!code --]
    using OrdinaryDiffEqTsit5: Tsit5   # [!code ++]
    ```

## See also

- [Solve overview](@ref solve-overview) — `solve` with its defaults, and how to read its display.
- [Explicit mode](@ref solve-explicit-mode) — the typed components and their options.
- [Discretisation schemes](@ref solve-choosing-a-method-schemes) — the schemes and their order.
- [Initial guess](@ref solve-initial-guess) — every way to build `init`.
- [Solution object](@ref results-solution) — what a solution holds.

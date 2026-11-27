# [Choosing a method](@id solve-choosing-a-method)

A **method** is a quadruplet `(discretizer, modeler, solver, parameter)`. This page maps out
what can be combined with what, how a partial description gets completed, and how to inspect
any one piece before you commit to it.

## The four families

- **Discretizer**: how the continuous problem is transcribed into a finite-dimensional one.
  Only `:collocation` exists today.
- **Modeler**: how the resulting NLP is built: `:adnlp`
  ([ADNLPModels](https://jso.dev/ADNLPModels.jl/stable/), automatic differentiation) or
  `:exa` ([ExaModels](https://madsuite-org.github.io/ExaModels.jl/stable/), SIMD-friendly
  and GPU-capable). `:exa` needs a problem written with [`@def`](@ref modelling-abstract-syntax),
  not with the [functional API](@ref modelling-functional-api).
- **Solver**: which NLP solver runs: `:ipopt`, `:madnlp`, `:uno`, `:madncl`, `:knitro`.
- **Parameter**: the execution backend, `:cpu` or `:gpu`.

## What is available

```@repl main
using OptimalControl
methods()
```

There are 12 methods: every `{adnlp, exa} × {ipopt, madnlp, uno, madncl, knitro}` pair on
`:cpu` (10), plus the two GPU-capable combinations `:exa × {:madnlp, :madncl}` on `:gpu` (2).

```@example main
@assert length(methods()) == 12                                    # hide
@assert first(methods()) == (:collocation, :adnlp, :ipopt, :cpu)   # hide
nothing                                                            # hide
```

## A problem to try them on

Every `solve` call on this page uses the same problem, the double integrator. Both modelers
accept it as written:

::: details The problem used on this page

```@example main
ocp = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end
nothing # hide
```

:::

## Partial descriptions

`solve(ocp, :madnlp)` does not need the other three tokens: they are completed for you.
Completion walks `methods()` from top to bottom and returns the first entry containing every
token you gave:

```julia
solve(ocp, :madnlp)   # → (:collocation, :adnlp, :madnlp, :cpu)
solve(ocp, :exa)      # → (:collocation, :exa,   :ipopt,  :cpu)
solve(ocp, :gpu)      # → (:collocation, :exa,   :madnlp, :gpu)
```

The first line of the display shows the completed method. For instance, with `:exa`:

```@repl main
using NLPModelsIpopt
sol = solve(ocp, :exa; print_level=0)
nothing # hide
```

!!! tip "`methods()` is read top to bottom — the first match wins"

    Completion walks `methods()` from the top and returns the **first** entry containing
    every token you gave; nothing below it is ever reached. The default of a bare
    `solve(ocp)` is the same rule with no tokens: the very first entry.

    ```@repl main
    first(methods())
    ```

All of these are equivalent:

```julia
solve(ocp)                       # empty description → first(methods())
solve(ocp, :collocation)
solve(ocp, :adnlp)
solve(ocp, :ipopt)
solve(ocp, :cpu)
solve(ocp, :collocation, :adnlp)
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)  # the complete description
```

## Incompatible tokens

Completion fails whenever no method contains *every* token you gave. Two tokens of the same
family can never match — `:adnlp` and `:exa` cannot describe one quadruplet — but neither can
tokens of different families: `:adnlp` with `:gpu` has no match, since every `:gpu` method
requires `:exa`. `solve` raises an error rather than silently picking one. It lists the
available methods and the closest matches:

```@repl main
solve(ocp, :adnlp, :exa; display=false)
```

```@repl main
solve(ocp, :adnlp, :gpu; display=false)
```

## What each solver needs installed

| Solver | Load |
| :--- | :--- |
| `:ipopt` | `using NLPModelsIpopt` |
| `:madnlp` | `using MadNLP` |
| `:uno` | `using UnoSolver` |
| `:madncl` | `using MadNCL` and `using MadNLP` (both) |
| `:knitro` | `using NLPModelsKnitro` (commercial licence required) |
| either on `:gpu` | `using MadNLPGPU`, `using CUDA` **and** `using CUDSS`, all three |

Solving without the matching package loaded raises an `ExtensionError` naming the `using`
statement to add; see [Installation](@ref getting-started-installation) and
[GPU](@ref solve-gpu).

## [Inspecting a strategy](@id solve-choosing-a-method-inspect)

`describe` prints a strategy: its family, the parameters it supports, and every option with
its type, its aliases and its default value:

```@repl main
describe(:collocation)
```

!!! note "Understanding default values"

    `(default: NotProvided)` means that OptimalControl does not set the option, so the
    solver or modeler uses its **own** default. For instance, an Ipopt option shown with
    `(default: NotProvided)` takes Ipopt's default value. Only the options with an explicit
    default, such as `(default: 1000)` for Ipopt's `max_iter`, are set by OptimalControl.

The modelers and solvers are described the same way. The solver packages must be loaded
first, as for solving:

::: details `describe(:adnlp)` and `describe(:exa)`

```@repl main
describe(:adnlp)
```

```@repl main
describe(:exa)
```

:::

::: details `describe(:ipopt)`

```@repl main
describe(:ipopt)
```

:::

::: details `describe(:madnlp)` and `describe(:madncl)`

```@repl main
using MadNLP
describe(:madnlp)
```

```@repl main
using MadNCL
describe(:madncl)
```

:::

::: details `describe(:uno)`

```@repl main
using UnoSolver
describe(:uno)
```

:::

`describe` also accepts parameters, listing the strategies that support each one:

```@repl main
describe(:cpu)
describe(:gpu)
```

It covers the strategies of the indirect method too: `describe(:sciml)` for the ODE
integrator of [flows](@ref flows-overview), and `describe(:di)` for the automatic
differentiation backend ([DifferentiationInterface](https://juliadiff.org/DifferentiationInterface.jl/DifferentiationInterface/stable/)).

## Package documentation

For the complete list of each package's options, see:

- **ADNLPModels**: [documentation](https://jso.dev/ADNLPModels.jl/stable/)
- **ExaModels**: [documentation](https://madsuite-org.github.io/ExaModels.jl/stable/)
- **Ipopt**: [options](https://coin-or.github.io/Ipopt/OPTIONS.html)
- **MadNLP**: [options](https://madsuite-org.github.io/MadNLP.jl/stable/options/)
- **Uno**: [documentation](https://unosolver.readthedocs.io)
- **MadNCL**: [repository](https://github.com/MadNLP/MadNCL.jl)
- **Knitro**: [options](https://www.artelys.com/docs/knitro/3_referenceManual/userOptions.html)

## [Discretisation schemes](@id solve-choosing-a-method-schemes)

`:collocation` accepts a `scheme` option (alias `disc_method`):

| Value | Order | Notes | `:adnlp` | `:exa` |
| :--- | :-: | :--- | :-: | :-: |
| `:trapeze` | 2 | trapezoidal rule | ✅ | ✅ |
| `:midpoint` | 2 | midpoint rule, **default** | ✅ | ✅ |
| `:euler` | 1 | explicit Euler | ✅ | ✅ |
| `:euler_implicit` | 1 | implicit Euler, more stable for stiff problems | ✅ | ✅ |
| `:euler_explicit`, `:euler_forward` | 1 | aliases of `:euler` | ✅ | ✅ |
| `:euler_backward` | 1 | alias of `:euler_implicit` | ✅ | ✅ |
| `:gauss_legendre_2` | 4 | 2-point Gauss–Legendre collocation | ✅ | ✗ |
| `:gauss_legendre_3` | 6 | 3-point Gauss–Legendre collocation | ✅ | ✗ |

These orders are theoretical, on a smooth solution. They can be checked on a problem whose
solution is known:

::: details Measuring the order on the LQ problem

For $\dot x = u$, $x(0) = 1$, and the cost $\int_0^1 (x^2 + u^2)\,\mathrm{d}t$, the Riccati
equation gives the optimal cost $J^* = \tanh(1)$. Each scheme solves the problem twice, on a
grid of $N = 10$ steps and again on $N = 20$: halving the step divides the error of a scheme
of order $k$ by $2^k$, so $\log_2(e_{10}/e_{20})$ recovers the order.

```@example main
lq = @def begin
    t ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control
    x(0) == 1
    ẋ(t) == u(t)
    ∫(x(t)^2 + u(t)^2) → min
end

error_of(scheme, N) = abs(objective(solve(lq; scheme=scheme, grid_size=N, display=false)) - tanh(1))

for scheme in (:euler, :euler_implicit, :trapeze, :midpoint, :gauss_legendre_2, :gauss_legendre_3)
    e10, e20 = error_of(scheme, 10), error_of(scheme, 20)
    println(
        rpad(scheme, 18),
        "error N=10 ",
        rpad(round(e10; sigdigits=2), 9),
        "N=20 ",
        rpad(round(e20; sigdigits=2), 9),
        "observed order ",
        round(log2(e10 / e20); digits=1)
    )
end
```

Each line prints the scheme, its error on the two grids, and the observed order — matching
the table above up to discretisation noise.

```@example main
for (scheme, k) in ((:euler, 1), (:trapeze, 2), (:midpoint, 2), (:gauss_legendre_2, 4))   # hide
    @assert abs(log2(error_of(scheme, 10) / error_of(scheme, 20)) - k) < 0.2           # hide
end                                                                                    # hide
nothing                                                                                # hide
```

:::

The higher-order schemes reach a given accuracy with far fewer steps, at a higher cost per
step: a Gauss–Legendre scheme adds unknowns at the stages inside each step. The order is
reached on a smooth solution. On a bang–bang control, the error is limited by the switching
times, which fall between the points of the grid.

The grid is set by `grid_size`, the number of uniform steps (default `250`), or by an
explicit `time_grid`: the increasing times of the grid, from the initial to the final time,
possibly non-uniform, to put more points where the solution varies fast. Here a grid twice
as fine on the second half of the interval:

```@example main
grid = [range(0, 0.5, 21);          # 20 steps on the first half
        range(0.5, 1, 41)[2:end]]   # 40 steps on the second half — drop the duplicate t=0.5
sol_grid = solve(ocp; time_grid=grid, display=false)
length(time_grid(sol_grid)), objective(sol_grid)   # 61 points, objective ≈ 6
```

```@example main
@assert isapprox(time_grid(sol_grid), grid) && isapprox(objective(sol_grid), 6; rtol=1e-2)   # hide
nothing                                                                              # hide
```

!!! warning "Under `:exa`, no custom `time_grid`"

    `time_grid` works with `:adnlp` only: with `:exa`, it is not supported yet and currently
    fails with a `DimensionMismatch`
    ([CTDirect#638](https://github.com/control-toolbox/CTDirect.jl/issues/638)).

!!! warning "Under `:exa`, no Gauss–Legendre scheme"

    `:exa` takes `:trapeze`, `:midpoint`, `:euler` and `:euler_implicit`, and the aliases of
    the last two (`:euler_forward`, `:euler_backward`, …). Both
    Gauss–Legendre schemes are available with `:adnlp` only:

    ```@repl main
    solve(ocp, :exa; scheme=:gauss_legendre_2, display=false)
    ```

    ```@example main
    @assert successful(solve(ocp, :exa; scheme=:euler_forward, display=false))   # hide
    nothing                                                                      # hide
    ```

## See also

- [Options](@ref solve-options): how keyword arguments reach the right strategy.
- [GPU](@ref solve-gpu): the `:gpu` parameter in full.
- [API reference: Options and strategies](@ref api-options): every symbol on this page, with
  full signatures.

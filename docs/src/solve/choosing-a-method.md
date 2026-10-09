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

```@example main
using OptimalControl
methods()
```

There are 12 methods: every `{adnlp, exa} × {ipopt, madnlp, uno, madncl, knitro}` pair on
`:cpu` (10), plus the two GPU-capable combinations `:exa × {:madnlp, :madncl}` on `:gpu` (2).

```@example main
@assert length(methods()) == 12                                    # hide
@assert methods()[1] == (:collocation, :adnlp, :ipopt, :cpu)       # hide
nothing                                                            # hide
```

## A problem to try them on

Every `solve` call on this page uses the same problem, the double integrator. Both modelers
accept it as written, with the dynamics in vector form:

```@example main
ocp = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    ∫(0.5u(t)^2) → min
end
nothing # hide
```

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

```@example main
using NLPModelsIpopt
sol = solve(ocp, :exa; print_level=0)
nothing # hide
```

This first-match rule is also why the plain `solve(ocp)` default is
`(:collocation, :adnlp, :ipopt, :cpu)`: it is `methods()[1]`. All of these are equivalent:

```julia
solve(ocp)                       # empty description → methods()[1]
solve(ocp, :collocation)
solve(ocp, :adnlp)
solve(ocp, :ipopt)
solve(ocp, :cpu)
solve(ocp, :collocation, :adnlp)
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)  # the complete description
```

## Incompatible tokens

Two tokens of the *same* family never fit one method: `:adnlp` and `:exa` cannot both describe
one quadruplet. No method contains both, so `solve` raises an error rather than silently
picking one. It lists the available methods and the closest matches:

```@repl main
try # hide
solve(ocp, :adnlp, :exa; display=false)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## What each solver needs installed

| Solver | Load |
| --- | --- |
| `:ipopt` | `using NLPModelsIpopt` |
| `:madnlp` | `using MadNLP` (CPU) |
| `:uno` | `using UnoSolver` |
| `:madncl` | `using MadNCL` and `using MadNLP` (both) |
| `:knitro` | `using NLPModelsKnitro` (commercial licence required) |
| either on `:gpu` | `using MadNLPGPU`, `using CUDA` **and** `using CUDSS`, all three |

Solving without the matching package loaded raises an `ExtensionError` naming the `using`
statement to add; see [Installation](@ref getting-started-installation) and
[GPU](@ref solve-gpu).

## Inspecting a strategy

`describe` prints a strategy: its family, the parameters it supports, and every option with
its type, its aliases and its default value:

```@example main
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

```@example main
describe(:adnlp)
```

```@example main
describe(:exa)
```

:::

::: details `describe(:ipopt)`

```@example main
describe(:ipopt)
```

:::

::: details `describe(:madnlp)` and `describe(:madncl)`

```@example main
using MadNLP
describe(:madnlp)
```

```@example main
using MadNCL
describe(:madncl)
```

:::

::: details `describe(:uno)`

```@example main
using UnoSolver
describe(:uno)
```

:::

`describe` also accepts the parameters, which lists the strategies that support them:

```@example main
describe(:cpu)
```

```@example main
describe(:gpu)
```

It covers the strategies of the indirect method too: `describe(:sciml)` for the ODE
integrator of [flows](@ref flows-overview), and `describe(:di)` for the automatic
differentiation backend ([DifferentiationInterface](https://juliadiff.org/DifferentiationInterface.jl/DifferentiationInterface/stable/)).

### Official documentation

For the complete list of each package's options, see:

- **ADNLPModels**: [documentation](https://jso.dev/ADNLPModels.jl/stable/)
- **ExaModels**: [documentation](https://madsuite-org.github.io/ExaModels.jl/stable/)
- **Ipopt**: [options](https://coin-or.github.io/Ipopt/OPTIONS.html)
- **MadNLP**: [options](https://madsuite-org.github.io/MadNLP.jl/stable/options/)
- **Uno**: [documentation](https://unosolver.readthedocs.io)
- **MadNCL**: [repository](https://github.com/MadNLP/MadNCL.jl)
- **Knitro**: [options](https://www.artelys.com/docs/knitro/3_referenceManual/userOptions.html)

## Discretization schemes

`:collocation` accepts a `scheme` option (alias `disc_method`):

| Value | Notes | `:adnlp` | `:exa` |
| --- | --- | :-: | :-: |
| `:trapeze` | trapezoidal rule, second-order | ✅ | ✅ |
| `:midpoint` | midpoint rule, second-order, **default** | ✅ | ✅ |
| `:euler` | explicit Euler, first-order | ✅ | ✅ |
| `:euler_implicit` | implicit Euler, first-order, more stable for stiff problems | ✅ | ✅ |
| `:euler_explicit`, `:euler_forward` | aliases of `:euler` | ✅ | ✗ |
| `:euler_backward` | alias of `:euler_implicit` | ✅ | ✗ |
| `:gauss_legendre_2` | 2-point Gauss–Legendre collocation, fourth-order | ✅ | ✗ |
| `:gauss_legendre_3` | 3-point Gauss–Legendre collocation, sixth-order | ✅ | ✗ |

The higher-order Gauss–Legendre schemes are more accurate, at a higher cost per grid step.
The grid is set by `grid_size` (default `250`), or, with `:adnlp`, by an explicit, possibly
non-uniform, `time_grid` (with `:exa`, `time_grid` is not supported yet:
[CTDirect#638](https://github.com/control-toolbox/CTDirect.jl/issues/638)).

!!! warning "Under `:exa`, only the four canonical names work"

    `:exa` takes `:trapeze`, `:midpoint`, `:euler` and `:euler_implicit`, and nothing else.
    Both Gauss–Legendre schemes are out, and so are the aliases: `:euler_forward` is rejected
    where `:euler` is accepted, though under `:adnlp` the two name the same scheme
    ([CTParser#355](https://github.com/control-toolbox/CTParser.jl/issues/355)):

    ```@repl main
    try # hide
    solve(ocp, :exa; scheme=:euler_forward, display=false)
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

## See also

- [Options](@ref solve-options): how keyword arguments reach the right strategy.
- [GPU](@ref solve-gpu): the `:gpu` parameter in full.
- [API reference: Options and strategies](@ref api-options): every symbol on this page, with
  full signatures.

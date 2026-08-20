# [Choosing a method](@id solve-choosing-a-method)

```@meta
Draft = false
```

A **method** is a quadruplet `(discretizer, modeler, solver, parameter)`. This page maps out
what can be combined with what, how a partial description gets completed, and how to inspect
any one piece before you commit to it.

## The four families

- **Discretizer** — how the continuous problem is transcribed into a finite-dimensional one.
  Only `:collocation` exists today.
- **Modeler** — how the resulting NLP is built: `:adnlp` (automatic differentiation via
  ADNLPModels) or `:exa` (SIMD-friendly, GPU-capable, via ExaModels — only for problems whose
  dynamics are written coordinatewise, see [Abstract syntax](@ref modelling-abstract-syntax)).
- **Solver** — which NLP solver runs: `:ipopt`, `:madnlp`, `:uno`, `:madncl`, `:knitro`.
- **Parameter** — execution backend: `:cpu` or `:gpu`.

## What is available

```@example main
using OptimalControl
methods()
```

There are 12 methods: every `{adnlp, exa} × {ipopt, madnlp, uno, madncl, knitro}` pair on
`:cpu` (10), plus the two GPU-capable combinations `:exa × {:madnlp, :madncl}` on `:gpu` (2).
This list is not fixed prose to memorize — it is exactly what `methods()` returns, so it's
printed live rather than quoted as a number anywhere on this page.

## Partial descriptions

`solve(ocp, :madnlp)` doesn't need the other three tokens — they're completed for you.
Completion walks `methods()` from top to bottom and returns the first entry containing every
token you gave:

```julia
solve(ocp, :madnlp)   # → (:collocation, :adnlp, :madnlp, :cpu)  — first entry with :madnlp
solve(ocp, :exa)      # → (:collocation, :exa,   :ipopt,  :cpu)  — first entry with :exa
solve(ocp, :gpu)      # → (:collocation, :exa,   :madnlp, :gpu)  — first GPU entry
```

This first-match-top-to-bottom rule is also why the plain `solve(ocp)` default is
`(:collocation, :adnlp, :ipopt, :cpu)`: it's simply `methods()[1]`. All of these are
equivalent:

```julia
solve(ocp)                                      # empty description → methods()[1]
solve(ocp, :collocation)
solve(ocp, :adnlp)
solve(ocp, :ipopt)
solve(ocp, :cpu)
solve(ocp, :collocation, :adnlp)
solve(ocp, :collocation, :adnlp, :ipopt, :cpu)  # the complete description
```

## Ambiguity

Two tokens from the *same* family never both fit one method — `:adnlp` and `:exa` can't both
be true of one quadruplet — so this raises `AmbiguousDescription` rather than silently picking
one:

```@example main
try
    solve(ocp, :adnlp, :exa; display=false)
catch e
    println(e)
end
```

The exception lists every candidate whose tokens are a superset of what matched, so you can see
what's close.

## What each solver needs installed

| Solver | Load |
| --- | --- |
| `:ipopt` | `using NLPModelsIpopt` |
| `:madnlp` | `using MadNLP` (CPU) or `using MadNLPGPU` (GPU) |
| `:uno` | `using UnoSolver` |
| `:madncl` | `using MadNCL` and `using MadNLP` (both) |
| `:knitro` | `using NLPModelsKnitro` (commercial licence required) |

Solving without the matching package loaded raises an `ExtensionError` naming exactly which
`using` statement to add.

## Inspecting a strategy

`describe` works on any strategy id, and covers more than the direct-solve side: it also
describes the indirect-method families (`:di`, `:sciml`) and the two parameters themselves.

```@example main
describe(:collocation)
```

```@example main
describe(:adnlp)
```

```@example main
using NLPModelsIpopt
describe(:ipopt)
```

```@example main
describe(:cpu)
```

## Discretization schemes

`:collocation` accepts a `scheme` option (alias `disc_method`):

| Value | Notes |
| --- | --- |
| `:trapeze` | second-order |
| `:midpoint` | second-order, **default** |
| `:euler`, `:euler_explicit`, `:euler_forward` | first-order, explicit |
| `:euler_implicit`, `:euler_backward` | first-order, implicit |
| `:gauss_legendre_2` | fourth-order, **`:adnlp` modeler only** |
| `:gauss_legendre_3` | sixth-order, **`:adnlp` modeler only** |
| `:variable` | variable-step ODE-based discretization |

plus `grid_size` (default `250`) or an explicit, possibly non-uniform, `time_grid`.

!!! warning "Gauss-Legendre schemes are `:adnlp`-only"

    `:gauss_legendre_2`/`:gauss_legendre_3` are rejected under `:exa` — confirmed live:

    ```@example main
    try
        solve(ocp, :exa; scheme=:gauss_legendre_2, display=false)
    catch e
        println(e)
    end
    ```

## Advanced: the strategy registry

`strategy_ids`, `type_from_id`, and `available_parameters` (and the [`create_registry`](@ref)
used to build one) all operate on a populated `StrategyRegistry`. The one that already knows
about every built-in strategy is internal (`OptimalControl.get_strategy_registry()`, not
re-exported) — these functions are orchestration/extension-authoring tools, not something a
typical solve caller reaches for. For everyday inspection, `methods()` and `describe` (above)
cover the same ground and need nothing extra.

## See also

- [Options and routing](@ref solve-options) — how keyword arguments reach the right strategy.
- [Solving on GPU](@ref solve-gpu) — the `:gpu` parameter in full.
- [API reference: Options and strategies](@ref api-options) — every symbol on this page, with full signatures.

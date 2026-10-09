# [Installation](@id getting-started-installation)

## Install

Open Julia's [interactive session (REPL)](https://docs.julialang.org/en/v1/manual/getting-started) and use the package manager:

```julia
using Pkg
Pkg.add("OptimalControl")
```

!!! tip

    If you are new to Julia, read [New to Julia: how to use OptimalControl](https://github.com/orgs/control-toolbox/discussions/64).

`OptimalControl` alone is enough to define a problem with [`@def`](@ref modelling-abstract-syntax) and describe [solve strategies](@ref solve-choosing-a-method). The features below are optional: each requires an additional package, which you only need to load when you use that feature.

## You will also need a solver

`solve` requires an NLP solver backend to be loaded. `NLPModelsIpopt` is the default solver and is used throughout this documentation:

```julia
using NLPModelsIpopt
```

Other solvers are available through their respective packages:

| Solver | Load |
| --- | --- |
| `:ipopt` (default) | `using NLPModelsIpopt` |
| `:madnlp` | `using MadNLP` (on GPU, see [below](@ref getting-started-installation-gpu)) |
| `:uno` | `using UnoSolver` |
| `:madncl` | `using MadNCL` **and** `using MadNLP` (both) |
| `:knitro` | `using NLPModelsKnitro` (commercial licence required) |

See [Choosing a method](@ref solve-choosing-a-method) to learn how these packages combine with a discretizer, a modeler, and a `:cpu`/`:gpu` parameter.

If you call `solve` before loading the appropriate package, it raises an `ExtensionError` that names the missing package and the `using` statement to add:

```julia
julia> solve(ocp)
ERROR: ExtensionError → _route_descriptive_options, descriptive_routing.jl:259
│
│  missing dependencies to access Ipopt{CPU} options metadata
│
│  Missing  NLPModelsIpopt
│
│  Context  Load NLPModelsIpopt extension first: using NLPModelsIpopt
│  Hint     Run: using NLPModelsIpopt
└─
```

The same mechanism covers every optional feature described on this page.

## Optional: plotting

```julia
using Plots
```

Loading this package enables `plot(sol)`. Without it, `plot(sol)` raises an `ExtensionError` that asks for `using Plots`. See [Plot](@ref results-plot).

[Makie](https://docs.makie.org) is supported too. Load `CairoMakie` for static figures or `GLMakie` for an interactive window, then call `Makie.plot(sol)`. See [Plot with Makie](@ref results-plot-makie).

## Optional: flows

Creating a [`Flow`](@ref flows-overview)—for indirect shooting, simulation, or inspecting a Hamiltonian vector field—requires an ODE integrator:

```julia
using OrdinaryDiffEqTsit5
```

Loading this package enables the creation of a `Flow`. Without it, `Flow` raises an `ExtensionError` that asks for `using OrdinaryDiffEqTsit5`.

!!! tip "Other integrators"

    `Tsit5` is the default integrator. To use another method from the [SciML ODE solvers](https://docs.sciml.ai/DiffEqDocs/stable/solvers/ode_solve/), load its package and pass the algorithm when you build the flow, for example `Flow(ocp, law; alg=Vern9())` after `using OrdinaryDiffEqVerner`. `OrdinaryDiffEqTsit5` is then not needed; without it, a flow built without `alg` raises an error that shows how to pass one. The umbrella packages `OrdinaryDiffEq` and `DifferentialEquations` include `Tsit5` and work too.

## Optional: saving solutions

```julia
using JLD2   # format=:JLD (default)
using JSON3  # format=:JSON
```

Loading either of these packages enables `export_ocp_solution` and `import_ocp_solution` in the matching format. Without it, these functions raise an `ExtensionError` that names the package to load. See [Save & load](@ref results-save-load).

## [Optional: GPU](@id getting-started-installation-gpu)

Only NVIDIA GPUs are supported. Load these three packages together:

```julia
using MadNLPGPU
using CUDA
using CUDSS
```

`CUDSS` is the one people forget: `using MadNLPGPU` does not load it, and the GPU solvers do not work without it. If one of the three is missing, the `ExtensionError` names it. One exception: when `MadNLPGPU` is the missing one, the error first asks for `MadNLP`, and names `MadNLPGPU` only once `MadNLP` is loaded ([CTSolvers#234](https://github.com/control-toolbox/CTSolvers.jl/issues/234)).

`ExaModels`, the GPU-capable modeler, needs no `using`: it comes with `OptimalControl`, so `:exa` works out of the box.

Before relying on a `:gpu` solve, check that `CUDA.functional()` returns `true`. See [GPU](@ref solve-gpu) for the details and for a complete example.

## See also

- [Your first problem](@ref getting-started-first-problem) — model, solve and plot one, end to end.
- [Choosing a method](@ref solve-choosing-a-method) — the full discretizer/modeler/solver/parameter picture.

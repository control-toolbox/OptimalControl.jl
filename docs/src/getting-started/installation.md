# [Installation](@id getting-started-installation)

```@meta
Draft = false
```

## Install

Open Julia's [interactive session (REPL)](https://docs.julialang.org/en/v1/manual/getting-started) and use the package manager:

```julia
using Pkg
Pkg.add("OptimalControl")
```

!!! tip

    If you are new to Julia, follow [this guideline](https://github.com/orgs/control-toolbox/discussions/64).

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
| `:madnlp` | `using MadNLP` (CPU) or `using MadNLPGPU` (GPU) |
| `:uno` | `using UnoSolver` |
| `:madncl` | `using MadNCL` **and** `using MadNLP` (both) |
| `:knitro` | `using NLPModelsKnitro` (commercial licence required) |

See [Choosing a method](@ref solve-choosing-a-method) to learn how these packages combine with a discretizer, a modeler, and a `:cpu`/`:gpu` parameter. If you call `solve` before loading the appropriate package, it raises an `ExtensionError` that identifies the exact `using` statement you need to add. The same mechanism covers every optional feature described on this page.

## Optional: plotting

```julia
using Plots
```

Loading this package enables `plot(sol)`. If it is not loaded, the package raises an `ExtensionError`.

See [Plotting](@ref results-plot).

## Optional: flows

Creating a [`Flow`](@ref flows-overview)—for indirect shooting, simulation, or inspecting a Hamiltonian vector field—requires an ODE integrator:

```julia
using OrdinaryDiffEqTsit5
```

Loading this package enables the creation of a `Flow`. If it is not loaded, the package raises an `ExtensionError`.

!!! warning "The `DifferentialEquations` ecosystem"

    You can use any ODE solver from the `DifferentialEquations` ecosystem. For example, you can load `OrdinaryDiffEqTsit5` or `OrdinaryDiffEqVern9`. You can also load the ecosystem's umbrella packages directly, such as with `using DifferentialEquations` or `using OrdinaryDiffEq`.

## Optional: saving solutions

```julia
using JLD2   # format=:JLD (default)
using JSON3  # format=:JSON
```

Loading either of these packages enables `export_ocp_solution` and `import_ocp_solution`. If neither package is loaded, these functions are not available.

See [Save & load](@ref results-save-load).

## Optional: GPU

```julia
using MadNLPGPU
using CUDA
using CUDSS
```

Only NVIDIA GPUs are supported.

All three packages must be loaded together to activate the `CTSolversMadNLPGPU` extension. Older guides list only the first two because, up to MadNLPGPU 0.8, `CUDSS` was a regular dependency. Since version 0.9, it is a weak dependency and must be loaded explicitly.

As with the other optional features above, a missing package is reported precisely: the `ExtensionError` identifies which of the three packages is absent. Thus, if the error asks you to load `CUDSS`, that is the package you need to add.

`ExaModels` is intentionally not listed: it is a dependency of `OptimalControl`, so `:exa` works without importing it explicitly. See [GPU](@ref solve-gpu) for the constraints, and check `CUDA.functional()` before assuming that a `:gpu` solve will actually run on the GPU.

## See also

- [Your first problem](@ref getting-started-first-problem) — model, solve and plot one, end to end.
- [Choosing a method](@ref solve-choosing-a-method) — the full discretizer/modeler/solver/parameter picture.

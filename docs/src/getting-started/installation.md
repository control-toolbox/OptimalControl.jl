# [Installation](@id getting-started-installation)

## Install

Open Julia's [interactive session (REPL)](https://docs.julialang.org/en/v1/manual/getting-started)
and use the package manager:

```julia
using Pkg
Pkg.add("OptimalControl")
```

!!! tip

    If you are new to Julia, follow [this guideline](https://github.com/orgs/control-toolbox/discussions/64).

`OptimalControl` alone is enough to define a problem with [`@def`](@ref modelling-abstract-syntax)
and describe [solve strategies](@ref solve-choosing-a-method). Everything below is optional —
loaded only when the feature it backs is actually used.

## You will also need a solver

`solve` needs an NLP solver backend loaded. `NLPModelsIpopt` is the default and the one used
throughout this documentation:

```julia
using NLPModelsIpopt
```

Alternatives exist, each behind its own package:

| Solver | Load |
| --- | --- |
| `:ipopt` (default) | `using NLPModelsIpopt` |
| `:madnlp` | `using MadNLP` (CPU) or `using MadNLPGPU` (GPU) |
| `:uno` | `using UnoSolver` |
| `:madncl` | `using MadNCL` **and** `using MadNLP` (both) |
| `:knitro` | `using NLPModelsKnitro` (commercial licence required) |

See [Choosing a method](@ref solve-choosing-a-method) for how these combine with a discretizer,
a modeler and a `:cpu`/`:gpu` parameter. Calling `solve` before the matching package is loaded
raises an `ExtensionError` naming exactly which `using` statement to add — the same mechanism
covers every optional piece on this page.

## Optional: plotting

```julia
using Plots
```

unlocks `plot(sol)`. Without it:

```julia
julia> using OptimalControl
julia> plot(sol)
ERROR: ExtensionError: missing dependencies to plot solutions
Missing  Plots
Hint     Run: using Plots
```

See [Plotting](@ref results-plot).

## Optional: flows

Building a [`Flow`](@ref flows-overview) — indirect shooting, simulation, or inspecting a
Hamiltonian vector field — needs an ODE integrator:

```julia
using OrdinaryDiffEqTsit5
```

!!! warning "The most common first failure"

    Every page in the [Flows](@ref flows-overview) section opens with
    `using OrdinaryDiffEqTsit5` for this reason: building a `Flow` before it is loaded is the
    single most common trap for newcomers to this part of the package. It fails cleanly rather
    than silently:

    ```julia
    julia> using OptimalControl
    julia> φ = Flow(ocp, u)
    ERROR: ExtensionError: missing dependencies to access SciML options metadata
    Missing  OrdinaryDiffEqTsit5
    Hint     Run: using OrdinaryDiffEqTsit5
    ```

## Optional: saving solutions

```julia
using JLD2   # format=:JLD (default)
using JSON3  # format=:JSON
```

unlock `export_ocp_solution`/`import_ocp_solution`. Without the matching one:

```julia
julia> export_ocp_solution(sol; format=:JLD)
ERROR: ExtensionError: missing dependencies to export solutions to JLD2 format
Missing  JLD2
Hint     Run: using JLD2
```

See [Save & load](@ref results-save-load).

## Optional: GPU

```julia
using MadNLPGPU
using CUDA
using CUDSS
```

NVIDIA GPUs only; the problem's dynamics must be written coordinatewise.

All three are required together — they are what arms the `CTSolversMadNLPGPU` extension. Older
guides list only the first two, because up to MadNLPGPU 0.8 `CUDSS` came in as a hard
dependency; from 0.9 it is weak and has to be loaded explicitly.

Like the optional pieces above, a missing one is reported accurately: the `ExtensionError`
names exactly which of the three is absent, so if you're told to load `CUDSS`, that's the one
you forgot.

`ExaModels` is not in the list on purpose: it ships as a dependency of OptimalControl, so
`:exa` works without importing it. See [GPU](@ref solve-gpu) for the constraints, and check
`CUDA.functional()` before assuming a `:gpu` solve will actually run on the device.

## Checking your setup

Loading everything and calling `methods()` is a quick way to confirm the install is sound —
if this runs without error, `OptimalControl` and every optional piece above are wired in:

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
using OrdinaryDiffEqTsit5
using JLD2
using JSON3

methods()
```

## See also

- [Your first problem](@ref getting-started-first-problem) — model, solve and plot one, end to end.
- [Choosing a method](@ref solve-choosing-a-method) — the full discretizer/modeler/solver/parameter picture.

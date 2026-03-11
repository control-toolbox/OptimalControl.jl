"""
    OptimalControl

High-level interface for solving optimal control problems.

This package provides a unified, user-friendly API for defining and solving optimal control
problems using various discretization methods, NLP modelers, and solvers. It orchestrates
the complete workflow from problem definition to solution.

# Main Features

- **Flexible solve interface**: Descriptive (symbolic) or explicit (typed components) modes
- **Multiple discretization methods**: Collocation and other schemes via CTDirect
- **Multiple NLP modelers**: ADNLP, ExaModels with CPU/GPU support
- **Multiple solvers**: Ipopt, MadNLP, MadNCL, Knitro with CPU/GPU support
- **Automatic component completion**: Partial specifications are completed intelligently
- **Option routing**: Strategy-specific options are routed to the appropriate components

# Usage

```julia
using OptimalControl

# Define your optimal control problem
ocp = Model(...)
# ... problem definition ...

# Solve using descriptive mode (symbolic description)
sol = solve(ocp, :collocation, :adnlp, :ipopt)

# Or solve using explicit mode (typed components)
sol = solve(ocp; 
    discretizer=CTDirect.Collocation(),
    modeler=CTSolvers.ADNLP(),
    solver=CTSolvers.Ipopt()
)
```

# Exported Names

$(EXPORTS)

# See Also

- [`solve`](@ref): Main entry point for solving optimal control problems
- [`methods`](@ref): List available solving methods
- [CTBase](https://control-toolbox.org/CTBase.jl): Core types and abstractions
- [CTDirect](https://control-toolbox.org/CTDirect.jl): Direct methods for discretization
- [CTSolvers](https://control-toolbox.org/CTSolvers.jl): NLP solvers and orchestration
"""
module OptimalControl

using DocStringExtensions
using Reexport

import CommonSolve
@reexport import CommonSolve: solve
import CTBase
import CTModels
import CTDirect
import CTSolvers

# Imports
include(joinpath(@__DIR__, "imports", "ctbase.jl"))
include(joinpath(@__DIR__, "imports", "ctdirect.jl"))
include(joinpath(@__DIR__, "imports", "ctflows.jl"))
include(joinpath(@__DIR__, "imports", "ctmodels.jl"))
include(joinpath(@__DIR__, "imports", "ctparser.jl"))
include(joinpath(@__DIR__, "imports", "ctsolvers.jl"))
include(joinpath(@__DIR__, "imports", "examodels.jl"))
# include(joinpath(@__DIR__, "imports", "redefine.jl"))

# helpers
include(joinpath(@__DIR__, "helpers", "kwarg_extraction.jl"))
include(joinpath(@__DIR__, "helpers", "print.jl"))
include(joinpath(@__DIR__, "helpers", "methods.jl"))
include(joinpath(@__DIR__, "helpers", "registry.jl"))
include(joinpath(@__DIR__, "helpers", "component_checks.jl"))
include(joinpath(@__DIR__, "helpers", "strategy_builders.jl"))
include(joinpath(@__DIR__, "helpers", "component_completion.jl"))
include(joinpath(@__DIR__, "helpers", "descriptive_routing.jl"))

# solve
include(joinpath(@__DIR__, "solve", "mode.jl"))
include(joinpath(@__DIR__, "solve", "mode_detection.jl"))
include(joinpath(@__DIR__, "solve", "dispatch.jl"))
include(joinpath(@__DIR__, "solve", "canonical.jl"))
include(joinpath(@__DIR__, "solve", "explicit.jl"))
include(joinpath(@__DIR__, "solve", "descriptive.jl"))

export methods # non useful since it is already in Base

end
"""
OptimalControl module.

List of all the exported names:

$(EXPORTS)
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
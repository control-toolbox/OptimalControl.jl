"""
OptimalControl module.

List of all the exported names:

$(EXPORTS)
"""
module OptimalControl

using DocStringExtensions
using Reexport

# Imports
include(joinpath(@__DIR__, "imports", "ctbase.jl"))
include(joinpath(@__DIR__, "imports", "ctdirect.jl"))
include(joinpath(@__DIR__, "imports", "ctflows.jl"))
include(joinpath(@__DIR__, "imports", "ctmodels.jl"))
include(joinpath(@__DIR__, "imports", "ctparser.jl"))
include(joinpath(@__DIR__, "imports", "ctsolvers.jl"))
include(joinpath(@__DIR__, "imports", "examodels.jl"))
include(joinpath(@__DIR__, "helpers", "print.jl"))

# solve
include(joinpath(@__DIR__, "solve", "solve_canonical.jl"))
include(joinpath(@__DIR__, "solve", "helpers", "available_methods.jl"))
include(joinpath(@__DIR__, "solve", "helpers", "registry.jl"))
export available_methods
export get_strategy_registry

end
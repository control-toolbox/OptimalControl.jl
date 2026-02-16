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
# export available_methods

end
"""
OptimalControl module.

List of all the exported names:

$(EXPORTS)
"""
module OptimalControl

using DocStringExtensions

# Imports
include(joinpath(@__DIR__, "imports", "ctbase.jl"))
include(joinpath(@__DIR__, "imports", "ctparser.jl"))
include(joinpath(@__DIR__, "imports", "plots.jl"))
include(joinpath(@__DIR__, "imports", "ctmodels.jl"))
include(joinpath(@__DIR__, "imports", "ctdirect.jl"))
include(joinpath(@__DIR__, "imports", "ctflows.jl"))
include(joinpath(@__DIR__, "imports", "ctsolvers.jl"))
include(joinpath(@__DIR__, "imports", "modelers.jl"))
include(joinpath(@__DIR__, "imports", "commonsolve.jl"))

# solve
include(joinpath(@__DIR__, "solve.jl"))
export solve
export available_methods

end

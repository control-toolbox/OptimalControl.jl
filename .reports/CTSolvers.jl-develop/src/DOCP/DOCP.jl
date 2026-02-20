# DOCP Module
#
# This module provides the DiscretizedModel type and implements
# the AbstractOptimizationProblem contract.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

module DOCP

# Importing to avoid namespace pollution
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import NLPModels
import SolverCore
import CTModels

# Using CTSolvers modules to get access to the api
using ..CTSolvers.Optimization
using ..CTSolvers.Modelers

# Include submodules
include(joinpath(@__DIR__, "types.jl"))
include(joinpath(@__DIR__, "contract_impl.jl"))
include(joinpath(@__DIR__, "accessors.jl"))
include(joinpath(@__DIR__, "building.jl"))

# Public API
export DiscretizedModel
export ocp_model
export nlp_model, ocp_solution

end # module DOCP

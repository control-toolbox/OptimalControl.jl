# Modelers Module
# 
# This module provides strategy-based modelers for converting discretized optimal 
# control problems to NLP backend models using the new AbstractStrategy contract.
#
# Author: CTSolvers Development Team
# Date: 2026-01-25

module Modelers

# Importing to avoid namespace pollution
import CTBase.Exceptions
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import SolverCore
import ADNLPModels
import ExaModels
import KernelAbstractions

# Using CTSolvers modules to get access to the api
using ..Options
using ..Strategies
using ..Optimization

# Include submodules
include(joinpath(@__DIR__, "abstract_modeler.jl"))
include(joinpath(@__DIR__, "validation.jl"))
include(joinpath(@__DIR__, "adnlp.jl"))
include(joinpath(@__DIR__, "exa.jl"))

# Public API
export AbstractNLPModeler
export ADNLP, Exa

end # module Modelers

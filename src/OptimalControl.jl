"""
[`OptimalControl`](@ref) module.

Lists all the imported modules and packages:

$(IMPORTS)

List of all the exported names:

$(EXPORTS)
"""
module OptimalControl

# using
using DocStringExtensions

# include core modules
using CTBase
using CTDirect
#using CTFlows
using CTModels
using CTParser

# extend
import CommonSolve: solve, CommonSolve

#
include("solve.jl")

# export functions only for user
export solve
export available_methods

# CTBase
export ParsingError

# CTFlows
#export VectorField
#export Hamiltonian
#export HamiltonianLift
#export HamiltonianVectorField
#export Flow
#export *

# CTDirect
export direct_transcription
export set_initial_guess

# CTModels: warning, the functions below are not exported by CTModels
export export_ocp_solution
export import_ocp_solution
export Model, PreModel
export constraint
export time_grid, control, state, variable, costate, objective
export iterations, stopping, message, infos

# CTParser
export @def

end

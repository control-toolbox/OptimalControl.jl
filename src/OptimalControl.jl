"""
[`OptimalControl`](@ref) module.

Lists all the imported modules and packages:

$(IMPORTS)

List of all the exported names:

$(EXPORTS)
"""
module OptimalControl

using DocStringExtensions

# CTBase
import CTBase: CTBase, ParsingError
export ParsingError

# CTModels
import CTModels: CTModels,
    # setters
    variable!, time!, state!, control!, dynamics!, constraint!, objective!, definition!,
    # model
    build_model, Model, PreModel,
    # getters
    initial_time, final_time, time_name, variable_dimension, variable_components, variable_name, state_dimension, state_components, state_name, control_dimension, control_components, control_name, constraint, dynamics, mayer, lagrange, criterion, export_ocp_solution, import_ocp_solution, constraint, time_grid, control, state, variable, costate, objective, iterations, stopping, message, infos
export Model
export initial_time, final_time, time_name, variable_dimension, variable_components, variable_name, state_dimension, state_components, state_name, control_dimension, control_components, control_name, constraint, dynamics, mayer, lagrange, criterion, export_ocp_solution, import_ocp_solution, constraint, time_grid, control, state, variable, costate, objective, iterations, stopping, message, infos

# CTParser
import CTParser: CTParser, @def
export @def

# CTDirect
import CTDirect: CTDirect, direct_transcription, set_initial_guess, build_OCP_solution # debug: complete?
export direct_transcription, set_initial_guess, build_OCP_solution

# CTFlows
import CTFlows: CTFlows, VectorField, Hamiltonian, HamiltonianLift, HamiltonianVectorField, Flow, ⋅, Lie, Poisson, @Lie # debug: complete?
export VectorField, Hamiltonian, HamiltonianLift, HamiltonianVectorField, Flow, ⋅, Lie, Poisson, @Lie

# CommonSolve
import CommonSolve: CommonSolve, solve
export solve
export available_methods
include("solve.jl")

end
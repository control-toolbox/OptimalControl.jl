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
using CTFlows

# declarations
const __display  = CTBase.__display
const __ocp_init = CTBase.__ocp_init

include("solve.jl")

# export functions only for user
export solve
export available_methods

# export from other modules

# CTFlows
export VectorField
export Hamiltonian
export HamiltonianLift
export HamiltonianVectorField
export Flow
export plot, plot!
export *

# CTDirect
export direct_transcription
export set_initial_guess
export build_solution
export save
export load
export export_ocp_solution
export import_ocp_solution

# CTBase
export Index
export Autonomous, NonAutonomous
export NonFixed, Fixed
export ControlLaw, FeedbackControl, Multiplier
export StateConstraint, ControlConstraint, MixedConstraint
export Model, __OCPModel
export variable!, time!, constraint!, dynamics!, objective!, state!, control!, remove_constraint!, constraint
export is_time_independent, is_time_dependent, is_min, is_max, is_variable_dependent, is_variable_independent
export Lie, @Lie, Poisson, Lift, ⋅, ∂ₜ
export @def
export ct_repl, ct_repl_update_model
export ParsingError

# repl
function __init__()
    isdefined(Base, :active_repl) && ct_repl()
    nothing
end

end

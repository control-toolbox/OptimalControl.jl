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
const __display = CTBase.__display
__ocp_init() = ()

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
export directTranscription
export getNLP
export setInitialGuess
export OCPSolutionFromDOCP
export save_OCP_solution
export load_OCP_solution
export export_OCP_solution
export read_OCP_solution


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
export ct_repl
export ParsingError

# repl
function __init__()
    isdefined(Base, :active_repl) && ct_repl()
    nothing
end

end

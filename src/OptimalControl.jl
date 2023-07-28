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
using CTProblems

# declarations
const __display = CTBase.__display

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

# CTBase
export Index
export Autonomous, NonAutonomous
export NonFixed, Fixed
export ControlLaw, FeedbackControl, Multiplier
export StateConstraint, ControlConstraint, MixedConstraint
export Model
export variable!, time!, constraint!, dynamics!, objective!, state!, control!, remove_constraint!, constraint
export is_time_independent, is_time_dependent, is_min, is_max, is_variable_dependent, is_variable_independent
export Lie, @Lie, Poisson, Lift, ⋅, ∂ₜ
export @def
export ct_repl

# CTProblems
export ProblemsDescriptions, Problem, Problems, @ProblemsDescriptions, @Problems

# repl
isdefined(Base, :active_repl) && ct_repl()

end

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
const ctrepl = CTBase.__init_repl

# resources
include("solve.jl")

# export functions only for user
export solve

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
export Lie, @Lie, Poisson, @Poisson, Lift, ⋅, ∂ₜ
export @def
export ctrepl

# repl
isdefined(Base, :active_repl) && ctrepl()

end

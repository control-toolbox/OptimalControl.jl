module OptimalControl

# using
using Reexport

# include modules
@reexport using CTBase
using CTDirect
using CTDirectShooting

# tools: callbacks, exceptions, functions and more
@reexport using ControlToolboxTools

# flows
@reexport using HamiltonianFlows
import HamiltonianFlows: Flow

# Types
const MyNumber, MyVector, Time, Times, TimesDisc, States, Adjoints, Controls, State, Adjoint, Dimension = CTBase.types()

# Other declarations
const __display = CTBase.__display

# resources
include("flows.jl")
include("solve.jl")

# export functions only for user
export solve
export plot, plot!
export Flow

end

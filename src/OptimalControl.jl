module OptimalControl

# using
using Reexport

# include modules
include("./CTBase/CTBase.jl"); 
include("CTDirect/CTDirect.jl"); 
include("CTDirectShooting/CTDirectShooting.jl"); 
# 
@reexport using .CTBase
using .CTDirect
using .CTDirectShooting

# tools: callbacks, exceptions, functions and more
@reexport using ControlToolboxTools
const ControlToolboxCallbacks = Tuple{Vararg{ControlToolboxCallback}}

# flows
@reexport using HamiltonianFlows
import HamiltonianFlows: Flow

# Types
const MyNumber, MyVector, Time, Times, TimesDisc, States, Adjoints, Controls, State, Adjoint, Dimension = CTBase.types()

# Other declarations
const __display = CTBase.__display

# resources
include("resources/flows.jl")
include("resources/solve.jl")

# export functions only for user
export solve
export plot, plot!
export Flow

end

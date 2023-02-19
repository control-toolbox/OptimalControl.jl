module OptimalControl

# using
using Reexport

# include modules
@reexport using CTBase
using CTDirect
using CTDirectShooting

# flows
@reexport using HamiltonianFlows
import HamiltonianFlows: Flow

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

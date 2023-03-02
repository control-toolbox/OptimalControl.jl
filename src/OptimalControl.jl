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

# ----------------------------------------
# to remove when put in the right package
include("CTBase.jl")
# ----------------------------------------

# export functions only for user
export solve
export Flow

end

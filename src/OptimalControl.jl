module OptimalControl

# using
using Reexport

# include modules
@reexport using CTBase
using CTDirect
using CTDirectShooting

# flows
@reexport using CTFlows

# Other declarations
const __display = CTBase.__display

# resources
include("solve.jl")

# export functions only for user
export solve

end

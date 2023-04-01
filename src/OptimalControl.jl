"""
[`OptimalControl`](@ref) module.

Lists all the imported modules and packages:

$(IMPORTS)

List of all the exported names:

$(EXPORTS)
"""
module OptimalControl

# using
using Reexport
using DocStringExtensions

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

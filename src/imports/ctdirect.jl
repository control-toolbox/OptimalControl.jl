# CTDirect reexports
#
# `AbstractDiscretizer` and the `discretize` generic moved to
# `CTSolvers.DOCP` (imports/ctsolvers.jl); CTDirect implements them.
# What is left here is the concrete discretizers.

# For internal use
using CTDirect: CTDirect

# Types
import CTDirect: Collocation

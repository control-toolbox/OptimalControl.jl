# DOCP Constructors
#
# This module provides essential accessor functions for DiscretizedModel.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDSIGNATURES)

Extract the original optimal control problem from a discretized problem.

# Arguments
- `docp::DiscretizedModel`: The discretized optimal control problem

# Returns
- The original optimal control problem

# Example
```julia-repl
julia> ocp = ocp_model(docp)
OptimalControlProblem(...)
```
"""
ocp_model(docp::DiscretizedModel) = docp.optimal_control_problem

# DOCP Model API
#
# Specific API for building NLP models and solutions from DiscretizedModel.
# These functions provide convenient wrappers for DOCP-specific operations.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDSIGNATURES)

Build an NLP model from a discretized optimal control problem.

This is a convenience wrapper around `build_model` that provides explicit
typing for `DiscretizedModel`.

# Arguments
- `prob::DiscretizedModel`: The discretized OCP
- `initial_guess`: Initial guess for the NLP solver
- `modeler`: The modeler to use (e.g., Modelers.ADNLP, Modelers.Exa)

# Returns
- `NLPModels.AbstractNLPModel`: The NLP model

# Example
```julia-repl
julia> nlp = nlp_model(docp, initial_guess, modeler)
ADNLPModel(...)
```
"""
function nlp_model(
    prob::DiscretizedModel,
    initial_guess,
    modeler::Modelers.AbstractNLPModeler
)::NLPModels.AbstractNLPModel
    return build_model(prob, initial_guess, modeler)
end

"""
$(TYPEDSIGNATURES)

Build an optimal control solution from NLP execution statistics.

This is a convenience wrapper around `build_solution` that provides explicit
typing for `DiscretizedModel` and ensures the return type
is an optimal control solution.

# Arguments
- `docp::DiscretizedModel`: The discretized OCP
- `model_solution::SolverCore.AbstractExecutionStats`: NLP solver output
- `modeler`: The modeler used for building

# Returns
- `AbstractSolution`: The OCP solution

# Example
```julia-repl
julia> solution = ocp_solution(docp, nlp_stats, modeler)
OptimalControlSolution(...)
```
"""
function ocp_solution(
    docp::DiscretizedModel,
    model_solution::SolverCore.AbstractExecutionStats,
    modeler::Modelers.AbstractNLPModeler
)
    return build_solution(docp, model_solution, modeler)
end

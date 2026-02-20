# Optimization Model API
#
# General API for building NLP models and solutions from optimization problems.
# These functions work with any AbstractOptimizationProblem.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDSIGNATURES)

Build an NLP model from an optimization problem using the specified modeler.

This is a general function that works with any `AbstractOptimizationProblem`.
The modeler handles the conversion to the specific NLP backend.

# Arguments
- `prob::AbstractOptimizationProblem`: The optimization problem
- `initial_guess`: Initial guess for the NLP solver
- `modeler`: The modeler strategy (e.g., Modelers.ADNLP, Modelers.Exa)

# Returns
- An NLP model suitable for the chosen backend

# Example
```julia-repl
julia> modeler = Modelers.ADNLP(show_time=false)
Modelers.ADNLP(...)

julia> nlp = build_model(prob, initial_guess, modeler)
ADNLPModel(...)
```
"""
function build_model(prob, initial_guess, modeler)
    return modeler(prob, initial_guess)
end

"""
$(TYPEDSIGNATURES)

Build a solution from NLP execution statistics using the specified modeler.

This is a general function that works with any `AbstractOptimizationProblem`.
The modeler handles the conversion from NLP solution to problem-specific solution.

# Arguments
- `prob::AbstractOptimizationProblem`: The optimization problem
- `model_solution`: NLP solver output (execution statistics)
- `modeler`: The modeler strategy used for building

# Returns
- A solution object appropriate for the problem type

# Example
```julia-repl
julia> solution = build_solution(prob, nlp_stats, modeler)
OptimalControlSolution(...)
```
"""
function build_solution(prob, model_solution, modeler)
    return modeler(prob, model_solution)
end

# AbstractOptimizationProblem Contract
#
# Defines the interface that all optimization problems must implement
# to work with the Modelers system.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDSIGNATURES)

Get the ADNLPModels model builder for an optimization problem.

This is part of the `AbstractOptimizationProblem` contract. Concrete problem types
must implement this method to provide a builder that constructs ADNLPModels from
the problem.

# Arguments
- `prob::AbstractOptimizationProblem`: The optimization problem

# Returns
- `AbstractModelBuilder`: A callable builder that constructs ADNLPModels

# Throws

- `Exceptions.NotImplemented`: If the problem type does not support ADNLPModels backend

# Example
```julia-repl
julia> builder = get_adnlp_model_builder(prob)
ADNLPModelBuilder(...)

julia> nlp_model = builder(initial_guess; show_time=false, backend=:optimized)
ADNLPModel(...)
```
"""
function get_adnlp_model_builder(prob::AbstractOptimizationProblem)
    throw(Exceptions.NotImplemented(
        "ADNLP model builder not implemented",
        required_method="get_adnlp_model_builder(prob::$(typeof(prob)))",
        suggestion="Implement get_adnlp_model_builder for $(typeof(prob)) to support ADNLPModels backend",
        context="AbstractOptimizationProblem.get_adnlp_model_builder - required method implementation"
    ))
end

"""
$(TYPEDSIGNATURES)

Get the ExaModels model builder for an optimization problem.

This is part of the `AbstractOptimizationProblem` contract. Concrete problem types
must implement this method to provide a builder that constructs ExaModels from
the problem.

# Arguments
- `prob::AbstractOptimizationProblem`: The optimization problem

# Returns
- `AbstractModelBuilder`: A callable builder that constructs ExaModels

# Throws

- `Exceptions.NotImplemented`: If the problem type does not support ExaModels backend

# Example
```julia-repl
julia> builder = get_exa_model_builder(prob)
ExaModelBuilder(...)

julia> nlp_model = builder(Float64, initial_guess; backend=nothing, minimize=true)
ExaModel{Float64}(...)
```
"""
function get_exa_model_builder(prob::AbstractOptimizationProblem)
    throw(Exceptions.NotImplemented(
        "ExaModel builder not implemented",
        required_method="get_exa_model_builder(prob::$(typeof(prob)))",
        suggestion="Implement get_exa_model_builder for $(typeof(prob)) to support ExaModels backend",
        context="AbstractOptimizationProblem.get_exa_model_builder - required method implementation"
    ))
end

"""
$(TYPEDSIGNATURES)

Get the ADNLPModels solution builder for an optimization problem.

This is part of the `AbstractOptimizationProblem` contract. Concrete problem types
must implement this method to provide a builder that converts NLP solver results
into problem-specific solutions.

# Arguments
- `prob::AbstractOptimizationProblem`: The optimization problem

# Returns
- `AbstractSolutionBuilder`: A callable builder that constructs solutions from NLP results

# Throws

- `Exceptions.NotImplemented`: If the problem type does not support ADNLPModels backend

# Example
```julia-repl
julia> builder = get_adnlp_solution_builder(prob)
ADNLPSolutionBuilder(...)

julia> solution = builder(nlp_stats)
OptimalControlSolution(...)
```
"""
function get_adnlp_solution_builder(prob::AbstractOptimizationProblem)
    throw(Exceptions.NotImplemented(
        "ADNLP solution builder not implemented",
        required_method="get_adnlp_solution_builder(prob::$(typeof(prob)))",
        suggestion="Implement get_adnlp_solution_builder for $(typeof(prob)) to support ADNLPModels backend",
        context="AbstractOptimizationProblem.get_adnlp_solution_builder - required method implementation"
    ))
end

"""
$(TYPEDSIGNATURES)

Get the ExaModels solution builder for an optimization problem.

This is part of the `AbstractOptimizationProblem` contract. Concrete problem types
must implement this method to provide a builder that converts NLP solver results
into problem-specific solutions.

# Arguments
- `prob::AbstractOptimizationProblem`: The optimization problem

# Returns
- `AbstractSolutionBuilder`: A callable builder that constructs solutions from NLP results

# Throws

- `Exceptions.NotImplemented`: If the problem type does not support ExaModels backend

# Example
```julia-repl
julia> builder = get_exa_solution_builder(prob)
ExaSolutionBuilder(...)

julia> solution = builder(nlp_stats)
OptimalControlSolution(...)
```
"""
function get_exa_solution_builder(prob::AbstractOptimizationProblem)
    throw(Exceptions.NotImplemented(
        "ExaSolution builder not implemented",
        required_method="get_exa_solution_builder(prob::$(typeof(prob)))",
        suggestion="Implement get_exa_solution_builder for $(typeof(prob)) to support ExaModels backend",
        context="AbstractOptimizationProblem.get_exa_solution_builder - required method implementation"
    ))
end

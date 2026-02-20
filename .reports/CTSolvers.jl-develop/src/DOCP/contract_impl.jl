# DOCP Contract Implementation
#
# Implementation of the AbstractOptimizationProblem contract for
# DiscretizedModel.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDSIGNATURES)

Get the ADNLPModels model builder from a DiscretizedModel.

This implements the `AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractModelBuilder`: The ADNLP model builder

# Example
```julia-repl
julia> builder = get_adnlp_model_builder(docp)
ADNLPModelBuilder(...)

julia> nlp_model = builder(initial_guess; show_time=false)
ADNLPModel(...)
```
"""
function Optimization.get_adnlp_model_builder(prob::DiscretizedModel)
    return prob.adnlp_model_builder
end

"""
$(TYPEDSIGNATURES)

Get the ExaModels model builder from a DiscretizedModel.

This implements the `AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractModelBuilder`: The ExaModel builder

# Example
```julia-repl
julia> builder = get_exa_model_builder(docp)
ExaModelBuilder(...)

julia> nlp_model = builder(Float64, initial_guess; backend=nothing)
ExaModel{Float64}(...)
```
"""
function Optimization.get_exa_model_builder(prob::DiscretizedModel)
    return prob.exa_model_builder
end

"""
$(TYPEDSIGNATURES)

Get the ADNLPModels solution builder from a DiscretizedModel.

This implements the `AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractSolutionBuilder`: The ADNLP solution builder

# Example
```julia-repl
julia> builder = get_adnlp_solution_builder(docp)
ADNLPSolutionBuilder(...)

julia> solution = builder(nlp_stats)
OptimalControlSolution(...)
```
"""
function Optimization.get_adnlp_solution_builder(prob::DiscretizedModel)
    return prob.adnlp_solution_builder
end

"""
$(TYPEDSIGNATURES)

Get the ExaModels solution builder from a DiscretizedModel.

This implements the `AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractSolutionBuilder`: The ExaModel solution builder

# Example
```julia-repl
julia> builder = get_exa_solution_builder(docp)
ExaSolutionBuilder(...)

julia> solution = builder(nlp_stats)
OptimalControlSolution(...)
```
"""
function Optimization.get_exa_solution_builder(prob::DiscretizedModel)
    return prob.exa_solution_builder
end

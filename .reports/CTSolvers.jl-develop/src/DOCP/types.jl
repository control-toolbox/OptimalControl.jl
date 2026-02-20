# DOCP Types
#
# This module defines the DiscretizedModel type.
# All builder types are now in the Optimization module.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDEF)

Discretized optimal control problem ready for NLP solving.

Wraps an optimal control problem together with builders for ADNLPModels and ExaModels backends.
This type implements the `AbstractOptimizationProblem` contract.

# Fields
- `optimal_control_problem::TO`: The original optimal control problem
- `adnlp_model_builder::TAMB`: Builder for ADNLPModels
- `exa_model_builder::TEMB`: Builder for ExaModels
- `adnlp_solution_builder::TASB`: Builder for ADNLP solutions
- `exa_solution_builder::TESB`: Builder for ExaModel solutions

# Example
```julia-repl
julia> docp = DiscretizedModel(
           ocp,
           ADNLPModelBuilder(build_adnlp_model),
           ExaModelBuilder(build_exa_model),
           ADNLPSolutionBuilder(build_adnlp_solution),
           ExaSolutionBuilder(build_exa_solution)
       )
DiscretizedModel{...}(...)
```
"""
struct DiscretizedModel{
    TO<:CTModels.AbstractModel,
    TAMB<:AbstractModelBuilder,
    TEMB<:AbstractModelBuilder,
    TASB<:AbstractSolutionBuilder,
    TESB<:AbstractSolutionBuilder
} <: AbstractOptimizationProblem
    optimal_control_problem::TO
    adnlp_model_builder::TAMB
    exa_model_builder::TEMB
    adnlp_solution_builder::TASB
    exa_solution_builder::TESB
end

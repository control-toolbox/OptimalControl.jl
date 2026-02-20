# Abstract Builders
#
# General abstract builder types and concrete implementations for optimization problems.
# Builders are callable objects that construct NLP models and solutions.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDEF)

Abstract base type for all builders in the optimization system.

This provides a common interface for model builders and solution builders
that work with optimization problems.
"""
abstract type AbstractBuilder end

"""
$(TYPEDEF)

Abstract base type for builders that construct NLP back-end models from
an AbstractOptimizationProblem.

Concrete subtypes are callable objects that encapsulate the logic for building
a model for a specific NLP back-end.
"""
abstract type AbstractModelBuilder <: AbstractBuilder end

"""
$(TYPEDEF)

Abstract base type for builders that transform NLP solutions into other
representations (for example, solutions of an optimal control problem).

Subtypes are callable objects that convert NLP solver results into
problem-specific solution formats.
"""
abstract type AbstractSolutionBuilder <: AbstractBuilder end

"""
$(TYPEDEF)

Abstract base type for builders that transform NLP solutions into OCP solutions.

Concrete implementations should define the exact call signature and behavior
for specific solution types.
"""
abstract type AbstractOCPSolutionBuilder <: AbstractSolutionBuilder end

# ============================================================================ #
# Concrete Builder Implementations
# ============================================================================ #

"""
$(TYPEDEF)

Builder for constructing ADNLPModels-based NLP models.

This is a callable object that wraps a function for building ADNLPModels.
The wrapped function should accept an initial guess and keyword arguments.

# Fields
- `f::T`: A callable that builds the ADNLPModel when invoked

# Example
```julia-repl
julia> builder = ADNLPModelBuilder(build_adnlp_model)
ADNLPModelBuilder(...)

julia> nlp_model = builder(initial_guess; show_time=false, backend=:optimized)
ADNLPModel(...)
```
"""
struct ADNLPModelBuilder{T<:Function} <: AbstractModelBuilder
    f::T
end

"""
$(TYPEDSIGNATURES)

Invoke the ADNLPModels model builder to construct an NLP model from an initial guess.

# Arguments
- `builder::ADNLPModelBuilder`: The builder instance
- `initial_guess`: Initial guess for optimization variables
- `kwargs...`: Additional options passed to the builder function

# Returns
- `ADNLPModels.ADNLPModel`: The constructed NLP model
"""
function (builder::ADNLPModelBuilder)(initial_guess; kwargs...)
    return builder.f(initial_guess; kwargs...)
end

"""
$(TYPEDEF)

Builder for constructing ExaModels-based NLP models.

This is a callable object that wraps a function for building ExaModels.
The wrapped function should accept a base type, initial guess, and keyword arguments.

# Fields
- `f::T`: A callable that builds the ExaModel when invoked

# Example
```julia-repl
julia> builder = ExaModelBuilder(build_exa_model)
ExaModelBuilder(...)

julia> nlp_model = builder(Float64, initial_guess; backend=nothing, minimize=true)
ExaModel{Float64}(...)
```
"""
struct ExaModelBuilder{T<:Function} <: AbstractModelBuilder
    f::T
end

"""
$(TYPEDSIGNATURES)

Invoke the ExaModels model builder to construct an NLP model from an initial guess.

The `BaseType` parameter specifies the floating-point type for the model.

# Arguments
- `builder::ExaModelBuilder`: The builder instance
- `BaseType::Type{<:AbstractFloat}`: Floating-point type for the model
- `initial_guess`: Initial guess for optimization variables
- `kwargs...`: Additional options passed to the builder function

# Returns
- `ExaModels.ExaModel{BaseType}`: The constructed NLP model
"""
function (builder::ExaModelBuilder)(
    ::Type{BaseType}, initial_guess; kwargs...
) where {BaseType<:AbstractFloat}
    return builder.f(BaseType, initial_guess; kwargs...)
end

"""
$(TYPEDEF)

Builder for constructing OCP solutions from ADNLP solver results.

This is a callable object that wraps a function for converting NLP solver
statistics into optimal control solutions.

# Fields
- `f::T`: A callable that builds the solution when invoked

# Example
```julia-repl
julia> builder = ADNLPSolutionBuilder(build_adnlp_solution)
ADNLPSolutionBuilder(...)

julia> solution = builder(nlp_stats)
OptimalControlSolution(...)
```
"""
struct ADNLPSolutionBuilder{T<:Function} <: AbstractOCPSolutionBuilder
    f::T
end

"""
$(TYPEDSIGNATURES)

Invoke the ADNLPModels solution builder to convert NLP execution statistics
into an optimal control solution.

# Arguments
- `builder::ADNLPSolutionBuilder`: The builder instance
- `nlp_solution`: NLP solver execution statistics

# Returns
- Optimal control solution (type depends on the wrapped function)
"""
function (builder::ADNLPSolutionBuilder)(nlp_solution)
    return builder.f(nlp_solution)
end

"""
$(TYPEDEF)

Builder for constructing OCP solutions from ExaModels solver results.

This is a callable object that wraps a function for converting NLP solver
statistics into optimal control solutions.

# Fields
- `f::T`: A callable that builds the solution when invoked

# Example
```julia-repl
julia> builder = ExaSolutionBuilder(build_exa_solution)
ExaSolutionBuilder(...)

julia> solution = builder(nlp_stats)
OptimalControlSolution(...)
```
"""
struct ExaSolutionBuilder{T<:Function} <: AbstractOCPSolutionBuilder
    f::T
end

"""
$(TYPEDSIGNATURES)

Invoke the ExaModels solution builder to convert NLP execution statistics
into an optimal control solution.

# Arguments
- `builder::ExaSolutionBuilder`: The builder instance
- `nlp_solution`: NLP solver execution statistics

# Returns
- Optimal control solution (type depends on the wrapped function)
"""
function (builder::ExaSolutionBuilder)(nlp_solution)
    return builder.f(nlp_solution)
end

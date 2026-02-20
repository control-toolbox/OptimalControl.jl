# Abstract Optimization Types
#
# General abstract types for optimization problems.
# These types are independent of specific optimal control problem implementations.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

"""
$(TYPEDEF)

Abstract base type for optimization problems.

This is a general type that represents any optimization problem, not necessarily
tied to optimal control. Subtypes can represent various problem formulations
including discretized optimal control problems, general NLP problems, etc.

Subtypes are typically paired with AbstractModelBuilder and AbstractSolutionBuilder
implementations that know how to construct and interpret NLP back-end models and solutions.

# Example
```julia-repl
julia> struct MyOptimizationProblem <: AbstractOptimizationProblem
           objective::Function
           constraints::Vector{Function}
       end
```
"""
abstract type AbstractOptimizationProblem end

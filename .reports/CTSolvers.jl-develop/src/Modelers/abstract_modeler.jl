# Abstract Optimization Modeler
#
# Defines the AbstractNLPModeler strategy contract for all modeler strategies.
# This extends the AbstractStrategy contract with modeler-specific interfaces.
#
# Author: CTSolvers Development Team
# Date: 2026-01-25

"""
$(TYPEDEF)

Abstract base type for all modeler strategies.

Modeler strategies are responsible for converting discretized optimal control
problems (AbstractOptimizationProblem) into NLP backend models. They implement 
the `AbstractStrategy` contract and provide modeler-specific interfaces for 
model and solution building.

# Implementation Requirements
All concrete modeler strategies must:
- Implement the `AbstractStrategy` contract (see Strategies module)
- Provide callable interfaces for model building from AbstractOptimizationProblem
- Provide callable interfaces for solution building
- Define strategy metadata with option specifications

# Example
```julia
struct MyModeler <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:MyModeler}) = :my_modeler

function (modeler::MyModeler)(
    prob::AbstractOptimizationProblem, 
    initial_guess
)
    # Build NLP model from problem and initial guess
    return nlp_model
end
```
"""
abstract type AbstractNLPModeler <: Strategies.AbstractStrategy end

"""
$(TYPEDSIGNATURES)

Build an NLP model from a discretized optimal control problem and initial guess.

# Arguments
- `modeler::AbstractNLPModeler`: The modeler strategy instance
- `prob::AbstractOptimizationProblem`: The discretized optimal control problem
- `initial_guess`: Initial guess for optimization variables

# Returns
- An NLP model compatible with the target backend (e.g., ADNLPModel, ExaModel)

# Throws
- `Strategies.Exceptions.NotImplemented`: If not implemented by concrete type
"""
function (modeler::AbstractNLPModeler)(
    ::AbstractOptimizationProblem, 
    initial_guess
)
    throw(Exceptions.NotImplemented(
        "Model building not implemented",
        required_method="(modeler::$(typeof(modeler)))(prob::AbstractOptimizationProblem, initial_guess)",
        suggestion="Implement the callable method for $(typeof(modeler)) to build NLP models",
        context="AbstractNLPModeler - required method implementation"
    ))
end

"""
$(TYPEDSIGNATURES)

Build a solution object from a discretized optimal control problem and NLP solution.

# Arguments
- `modeler::AbstractNLPModeler`: The modeler strategy instance
- `prob::AbstractOptimizationProblem`: The discretized optimal control problem
- `nlp_solution::SolverCore.AbstractExecutionStats`: Solution from NLP solver

# Returns
- A solution object appropriate for the problem type

# Throws
- `Strategies.Exceptions.NotImplemented`: If not implemented by concrete type
"""
function (modeler::AbstractNLPModeler)(
    ::AbstractOptimizationProblem,
    ::SolverCore.AbstractExecutionStats
)
    throw(Exceptions.NotImplemented(
        "Solution building not implemented",
        required_method="(modeler::$(typeof(modeler)))(prob::AbstractOptimizationProblem, nlp_solution::SolverCore.AbstractExecutionStats)",
        suggestion="Implement the callable method for $(typeof(modeler)) to build solution objects",
        context="AbstractNLPModeler - required method implementation"
    ))
end

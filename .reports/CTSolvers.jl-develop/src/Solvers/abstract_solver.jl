"""
$(TYPEDEF)

Abstract base type for optimization solvers in the Control Toolbox.

All concrete solver types must:
1. Be a subtype of `AbstractNLPSolver`
2. Implement the `AbstractStrategy` contract:
   - `Strategies.id(::Type{<:MySolver})` - Return unique Symbol identifier
   - `Strategies.metadata(::Type{<:MySolver})` - Return StrategyMetadata with options
   - Have an `options::Strategies.StrategyOptions` field
3. Implement the callable interface:
   - `(solver::MySolver)(nlp; display=Bool)` - Solve the NLP problem

# Solver Types
- `Solvers.Ipopt` - Interior point optimizer (Ipopt backend)
- `Solvers.MadNLP` - Matrix-free augmented Lagrangian (MadNLP backend)
- `Solvers.MadNCL` - NCL variant of MadNLP
- `Solvers.Knitro` - Commercial solver (Knitro backend)

# Example
```julia
# Create solver with options
solver = Solvers.Ipopt(max_iter=1000, tol=1e-8)

# Solve an NLP problem
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

See also: [`Solvers.Ipopt`](@ref), [`Solvers.MadNLP`](@ref), [`Solvers.MadNCL`](@ref), [`Solvers.Knitro`](@ref)
"""
abstract type AbstractNLPSolver <: Strategies.AbstractStrategy end

"""
$(TYPEDSIGNATURES)

Callable interface for optimization solvers.

Solves the given NLP problem and returns execution statistics.

# Arguments
- `nlp`: NLP problem to solve (typically `NLPModels.AbstractNLPModel`)
- `display::Bool`: Whether to display solver output (default: true)

# Returns
- `SolverCore.AbstractExecutionStats`: Solver execution statistics

# Throws
- `Strategies.Exceptions.NotImplemented`: If not implemented by concrete type

# Implementation
Concrete solver types must implement this method. The default implementation
throws a `NotImplemented` error with helpful guidance.

# Example
```julia
solver = Solvers.Ipopt(max_iter=100)
nlp = ADNLPModel(x -> sum(x.^2), zeros(5))
stats = solver(nlp, display=false)
```
"""
function (solver::AbstractNLPSolver)(nlp; display::Bool=true)
    throw(Exceptions.NotImplemented(
        "Solver callable not implemented",
        required_method="(solver::$(typeof(solver)))(nlp; display=Bool)",
        suggestion="Implement the callable method for $(typeof(solver))",
        context="AbstractNLPSolver - required method"
    ))
end

"""
$(TYPEDSIGNATURES)

Stub for descriptive mode resolution (Layer 2).

Raises [`CTBase.NotImplemented`](@ref) until descriptive mode is implemented.
This stub allows testing the orchestration layer (mode detection, dispatch routing)
before the descriptive mode handler exists.

# Arguments
- `ocp`: The optimal control problem to solve
- `description`: Symbolic description tokens (e.g., `:collocation`, `:adnlp`, `:ipopt`)
- `initial_guess`: Normalized initial guess (processed by Layer 1)
- `display`: Whether to display configuration information
- `registry`: Strategy registry
- `kwargs...`: Strategy-specific options

# Throws
- `CTBase.NotImplemented`: Always — descriptive mode is not yet implemented

# See Also
- [`CommonSolve.solve`](@ref): The entry point that dispatches here
"""
function solve_descriptive(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    initial_guess::CTModels.AbstractInitialGuess,
    display::Bool,
    registry::CTSolvers.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution

    throw(CTBase.NotImplemented(
        "Descriptive mode is not yet implemented",
        suggestion="Use explicit mode: solve(ocp; discretizer=..., modeler=..., solver=...)",
        context="_solve(::DescriptiveMode, ...)"
    ))
end

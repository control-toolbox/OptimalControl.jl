"""
$(TYPEDSIGNATURES)

Stub for descriptive mode resolution.

Raises [`CTBase.NotImplemented`](@ref) until `solve_descriptive` is implemented.
This stub allows testing the orchestration layer (mode detection, dispatch routing)
before the descriptive mode handler exists.

The `description` vararg will be forwarded to `solve_descriptive` when implemented.

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
- [`DescriptiveMode`](@ref): The dispatch sentinel type
- [`CommonSolve.solve`](@ref): The entry point that dispatches here
"""
function _solve(
    ::DescriptiveMode,
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    initial_guess::CTModels.AbstractInitialGuess,
    display::Bool,
    registry::CTSolvers.Strategies.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution

    throw(CTBase.NotImplemented(
        "Descriptive mode is not yet implemented",
        suggestion="Use explicit mode: solve(ocp; discretizer=..., modeler=..., solver=...)",
        context="_solve(::DescriptiveMode, ...)"
    ))
end

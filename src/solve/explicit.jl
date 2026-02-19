"""
$(TYPEDSIGNATURES)

Resolve an OCP in explicit mode (Layer 2).

Receives typed components (`discretizer`, `modeler`, `solver`) as named keyword arguments,
then completes missing components via the registry before calling Layer 3.

# Arguments
- `ocp`: The optimal control problem to solve
- `initial_guess`: Normalized initial guess (processed by Layer 1)
- `discretizer`: Discretization strategy, or `nothing` to complete via registry
- `modeler`: NLP modeling strategy, or `nothing` to complete via registry
- `solver`: NLP solver strategy, or `nothing` to complete via registry
- `display`: Whether to display configuration information
- `registry`: Strategy registry for completing partial components

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# See Also
- [`_has_complete_components`](@ref): Checks if all three components are provided
- [`_complete_components`](@ref): Completes missing components via registry
- [`_explicit_or_descriptive`](@ref): Mode detection that routes here
"""
function solve_explicit(
    ocp::CTModels.AbstractModel;
    initial_guess::CTModels.AbstractInitialGuess,
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing},
    display::Bool,
    registry::CTSolvers.StrategyRegistry
)::CTModels.AbstractSolution

    # Resolve components: use provided ones or complete via registry
    components = if _has_complete_components(discretizer, modeler, solver)
        (discretizer=discretizer, modeler=modeler, solver=solver)
    else
        _complete_components(discretizer, modeler, solver, registry)
    end

    # Single solve call with resolved components
    return CommonSolve.solve(
        ocp, initial_guess,
        components.discretizer,
        components.modeler,
        components.solver;
        display=display
    )
end
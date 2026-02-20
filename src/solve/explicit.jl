"""
$(TYPEDSIGNATURES)

Resolve an OCP in explicit mode (Layer 2).

Receives typed components (`discretizer`, `modeler`, `solver`) as named keyword arguments,
then completes missing components via the registry before calling Layer 3.

# Arguments
- `ocp`: The optimal control problem to solve
- `registry`: Strategy registry for completing partial components
- `kwargs...`: All keyword arguments. Action options extracted here:
  - `initial_guess` (aliases: `init`, `i`): Initial guess, default `nothing`
  - `display`: Whether to display configuration information, default `true`
  - Typed components: `discretizer`, `modeler`, `solver` (identified by abstract type)

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# See Also
- [`_has_complete_components`](@ref): Checks if all three components are provided
- [`_complete_components`](@ref): Completes missing components via registry
- [`_explicit_or_descriptive`](@ref): Mode detection that routes here
"""
function solve_explicit(
    ocp::CTModels.AbstractModel;
    registry::CTSolvers.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution

    # Extract action options with alias support
    init_raw, kwargs1 = _extract_action_kwarg(
        kwargs, (:initial_guess, :init, :i), _DEFAULT_INITIAL_GUESS
    )
    display_val, _ = _extract_action_kwarg(
        kwargs1, (:display,), _DEFAULT_DISPLAY
    )

    # Normalize initial guess
    normalized_init = CTModels.build_initial_guess(ocp, init_raw)

    # Extract typed components by abstract type
    discretizer = _extract_kwarg(kwargs, CTDirect.AbstractDiscretizer)
    modeler     = _extract_kwarg(kwargs, CTSolvers.AbstractNLPModeler)
    solver      = _extract_kwarg(kwargs, CTSolvers.AbstractNLPSolver)

    # Resolve components: use provided ones or complete via registry
    components = if _has_complete_components(discretizer, modeler, solver)
        (discretizer=discretizer, modeler=modeler, solver=solver)
    else
        _complete_components(discretizer, modeler, solver, registry)
    end

    # Single solve call with resolved components
    return CommonSolve.solve(
        ocp, normalized_init,
        components.discretizer,
        components.modeler,
        components.solver;
        display=display_val
    )
end
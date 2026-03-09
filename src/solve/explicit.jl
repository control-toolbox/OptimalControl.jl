"""
$(TYPEDSIGNATURES)

Resolve an OCP in explicit mode (Layer 2).

Receives typed components (`discretizer`, `modeler`, `solver`) as named keyword arguments,
then completes missing components via the registry before calling Layer 3.

# Arguments
- `ocp::CTModels.AbstractModel`: The optimal control problem to solve
- `registry::CTSolvers.StrategyRegistry`: Strategy registry for completing partial components
- `kwargs...`: All keyword arguments. Action options extracted here:
  - `initial_guess` (alias: `init`): Initial guess, default `nothing`
  - `display`: Whether to display configuration information, default `true`
  - Typed components: `discretizer`, `modeler`, `solver` (identified by abstract type)

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Notes
- This is Layer 2 of the solve architecture - handles explicit component mode
- The function performs: (1) action option extraction, (2) initial guess normalization, (3) component completion, (4) Layer 3 dispatch
- Missing components are completed using the first available strategy from the registry
- All three components must be either provided or completable via the registry
- This function is typically called by the main `solve` dispatcher in explicit mode

See also: [`CommonSolve.solve`](@extref), [`solve_descriptive`](@ref), [`_has_complete_components`](@ref), [`_complete_components`](@ref), [`_explicit_or_descriptive`](@ref)
"""
function solve_explicit(
    ocp::CTModels.AbstractModel;
    registry::CTSolvers.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution

    # Extract action options with alias support
    init_raw, kwargs1 = _extract_action_kwarg(
        kwargs, _INITIAL_GUESS_ALIASES, _DEFAULT_INITIAL_GUESS
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
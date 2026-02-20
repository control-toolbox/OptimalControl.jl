"""
$(TYPEDSIGNATURES)

Main entry point for optimal control problem resolution.

This function orchestrates the complete solve workflow by:
1. Detecting the resolution mode (explicit vs descriptive) from arguments
2. Normalizing the initial guess
3. Creating the strategy registry
4. Dispatching to the appropriate `_solve` method based on the detected mode

# Arguments
- `ocp`: The optimal control problem to solve
- `description`: Symbolic description tokens (e.g., `:collocation`, `:adnlp`, `:ipopt`)
- `initial_guess`: Initial guess or `nothing` for automatic generation
- `display`: Whether to display configuration information
- `kwargs...`: Additional keyword arguments (explicit components or strategy options)

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Examples
```julia
# Descriptive mode (symbolic description)
solution = solve(ocp, :collocation, :adnlp, :ipopt)

# Explicit mode (typed components)
solution = solve(ocp; discretizer=CTDirect.Collocation(), 
                     modeler=CTSolvers.ADNLP(), solver=CTSolvers.Ipopt())
```

# See Also
- [`_explicit_or_descriptive`](@ref): Mode detection and validation
- [`ExplicitMode`](@ref), [`DescriptiveMode`](@ref): Dispatch sentinel types
- [`_solve`](@ref): Mode-specific resolution methods
"""
function CommonSolve.solve(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    initial_guess=nothing,
    display::Bool=__display(),
    kwargs...
)::CTModels.AbstractSolution

    # 1. Detect mode and validate (raises on conflict)
    mode = _explicit_or_descriptive(description, kwargs)

    # 2. Normalize initial guess ONCE at the top level
    normalized_init = CTModels.build_initial_guess(ocp, initial_guess)

    # 3. Get registry for component completion
    registry = _extract_kwarg(kwargs, CTSolvers.StrategyRegistry)
    if isnothing(registry)
        registry = get_strategy_registry()
    end

    # 4. Dispatch — asymmetric signatures:
    #    ExplicitMode: extract typed components by type from kwargs (default nothing)
    #    DescriptiveMode: description forwarded as vararg positional arguments
    if mode isa ExplicitMode
        discretizer = _extract_kwarg(kwargs, CTDirect.AbstractDiscretizer)
        modeler     = _extract_kwarg(kwargs, CTSolvers.AbstractNLPModeler)
        solver      = _extract_kwarg(kwargs, CTSolvers.AbstractNLPSolver)
        return solve_explicit(
            ocp;
            initial_guess=normalized_init,
            display=display,
            registry=registry,
            discretizer=discretizer,
            modeler=modeler,
            solver=solver
        )
    else
        return solve_descriptive(
            ocp, description...;
            initial_guess=normalized_init,
            display=display,
            registry=registry,
            kwargs...
        )
    end
end

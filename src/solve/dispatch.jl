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
- `kwargs...`: All keyword arguments. Action options (`initial_guess`/`init`/`i`, `display`)
  are extracted by the appropriate Layer 2 function. Explicit components (`discretizer`,
  `modeler`, `solver`) are identified by abstract type.

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Examples
```julia
# Descriptive mode (symbolic description)
solve(ocp, :collocation, :adnlp, :ipopt)

# With initial guess aliases
solve(ocp, :collocation; init=x0, display=false)
solve(ocp, :collocation; i=x0)

# Explicit mode (typed components)
solve(ocp; discretizer=CTDirect.Collocation(),
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
    kwargs...
)::CTModels.AbstractSolution

    # 1. Detect mode and validate (raises on conflict)
    mode = _explicit_or_descriptive(description, kwargs)

    # 2. Get registry for component completion
    registry = _extract_kwarg(kwargs, CTSolvers.StrategyRegistry)
    if isnothing(registry)
        registry = get_strategy_registry()
    end

    # 3. Dispatch — action options (initial_guess, display) are extracted
    #    by the Layer 2 functions (solve_explicit / solve_descriptive)
    if mode isa ExplicitMode
        return solve_explicit(ocp; registry=registry, kwargs...)
    else
        return solve_descriptive(ocp, description...; registry=registry, kwargs...)
    end
end

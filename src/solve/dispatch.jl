"""
$(TYPEDSIGNATURES)

Main entry point for optimal control problem resolution.

This function orchestrates the complete solve workflow by:
1. Detecting the resolution mode (explicit vs descriptive) from arguments
2. Extracting or creating the strategy registry for component completion
3. Dispatching to the appropriate Layer 2 solver based on the detected mode

# Arguments
- `ocp::CTModels.AbstractModel`: The optimal control problem to solve
- `description::Symbol...`: Symbolic description tokens (e.g., `:collocation`, `:adnlp`, `:ipopt`)
- `kwargs...`: All keyword arguments. Action options (`initial_guess`/`init`, `display`)
  are extracted by the appropriate Layer 2 function. Explicit components (`discretizer`,
  `modeler`, `solver`) are identified by abstract type. A `registry` keyword can be
  provided to override the default strategy registry.

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Examples
```julia
# Descriptive mode (symbolic description)
solve(ocp, :collocation, :adnlp, :ipopt)

# With initial guess alias
solve(ocp, :collocation; init=x0, display=false)

# Explicit mode (typed components)
solve(ocp; discretizer=CTDirect.Collocation(),
           modeler=CTSolvers.ADNLP(), solver=CTSolvers.Ipopt())
```

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If explicit components and symbolic description are mixed

# Notes
- This is the main entry point (Layer 1) of the solve architecture
- Mode detection determines whether to use explicit or descriptive resolution path
- The registry can be injected for testing or customization purposes
- Action options and strategy-specific options are handled by Layer 2 functions

See also: [`_explicit_or_descriptive`](@ref), [`solve_explicit`](@ref), [`solve_descriptive`](@ref), [`get_strategy_registry`](@ref)
"""
function CommonSolve.solve(
    ocp::CTModels.AbstractModel, description::Symbol...; kwargs...
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

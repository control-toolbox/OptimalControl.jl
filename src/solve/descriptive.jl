"""
$(TYPEDSIGNATURES)

Resolve an OCP in descriptive mode (Layer 2).

Accepts a partial or complete symbolic method description and flat keyword options,
then completes the description, routes options to the appropriate strategies,
builds concrete components, and calls the canonical Layer 3 solver.

# Arguments
- `ocp::CTModels.AbstractModel`: The optimal control problem to solve
- `description::Symbol...`: Symbolic description tokens (e.g., `:collocation`, `:adnlp`, `:ipopt`).
  May be empty, partial, or complete — completed via [`_complete_description`](@ref).
- `registry::CTSolvers.StrategyRegistry`: Strategy registry for building strategies
- `kwargs...`: All keyword arguments, including action options (`initial_guess`/`init`,
  `display`) and strategy-specific options, optionally disambiguated with [`CTSolvers.Strategies.route_to`](@extref)

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If an option is unknown, ambiguous, or routed to the wrong strategy

# Examples
```julia
# Complete description with options
solve(ocp, :collocation, :adnlp, :ipopt; grid_size=100, display=false)

# Alias for initial_guess
solve(ocp, :collocation; init=x0, display=false)

# Disambiguation for ambiguous options
solve(ocp, :collocation, :adnlp, :ipopt;
    backend=route_to(adnlp=:sparse, ipopt=:cpu), display=false)
```

# Notes
- This is Layer 2 of the solve architecture - handles symbolic descriptions and option routing
- The function performs: (1) description completion, (2) option routing, (3) component building, (4) Layer 3 dispatch
- Action options (`initial_guess`/`init`, `display`) are extracted and normalized at this layer
- Strategy-specific options are routed to the appropriate component families
- This function is typically called by the main `solve` dispatcher in descriptive mode

See also: [`solve`](@ref), [`solve_explicit`](@ref), [`_complete_description`](@ref), [`_route_descriptive_options`](@ref), [`_build_components_from_routed`](@ref)
"""
function solve_descriptive(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    registry::CTSolvers.StrategyRegistry,
    kwargs...,
)::CTModels.AbstractSolution

    # 1. Complete partial description → full (discretizer_id, modeler_id, solver_id) triplet
    complete_description = _complete_description(description)

    # 2. Route all kwargs to the appropriate strategy families
    #    Action options (initial_guess/init, display) are extracted first
    routed = _route_descriptive_options(complete_description, registry, kwargs)

    # 3. Build concrete strategy instances + extract action options
    components = _build_components_from_routed(ocp, complete_description, registry, routed)

    # 4. Canonical solve (Layer 3)
    return CommonSolve.solve(
        ocp,
        components.initial_guess,
        components.discretizer,
        components.modeler,
        components.solver;
        display=components.display,
    )
end

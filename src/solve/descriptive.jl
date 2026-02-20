"""
$(TYPEDSIGNATURES)

Resolve an OCP in descriptive mode (Layer 2).

Accepts a partial or complete symbolic method description and flat keyword options,
then completes the description, routes options to the appropriate strategies,
builds concrete components, and calls the canonical Layer 3 solver.

# Arguments
- `ocp`: The optimal control problem to solve
- `description`: Symbolic description tokens (e.g., `:collocation`, `:adnlp`, `:ipopt`).
  May be empty, partial, or complete — completed via [`_complete_description`](@ref).
- `registry`: Strategy registry for building strategies
- `kwargs...`: All keyword arguments, including action options (`initial_guess`/`init`/`i`,
  `display`) and strategy-specific options, optionally disambiguated with [`route_to`](@ref)

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Throws
- `CTBase.IncorrectArgument`: If an option is unknown, ambiguous, or routed to the wrong strategy

# Example
```julia
# Complete description with options
solve(ocp, :collocation, :adnlp, :ipopt; grid_size=100, display=false)

# Aliases for initial_guess
solve(ocp, :collocation; init=x0, display=false)

# Disambiguation for ambiguous options
solve(ocp, :collocation, :adnlp, :ipopt;
    backend=route_to(adnlp=:sparse, ipopt=:cpu), display=false)
```

# See Also
- [`CommonSolve.solve`](@ref): The entry point that dispatches here
- [`_complete_description`](@ref): Completes partial symbolic descriptions
- [`_route_descriptive_options`](@ref): Routes kwargs to strategy families
- [`_build_components_from_routed`](@ref): Builds concrete strategy instances
"""
function solve_descriptive(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    registry::CTSolvers.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution

    # 1. Complete partial description → full (discretizer_id, modeler_id, solver_id) triplet
    complete_description = _complete_description(description)

    # 2. Route all kwargs to the appropriate strategy families
    #    Action options (initial_guess/init/i, display) are extracted first
    routed = _route_descriptive_options(complete_description, registry, kwargs)

    # 3. Build concrete strategy instances + extract action options
    components = _build_components_from_routed(ocp, complete_description, registry, routed)

    # 4. Canonical solve (Layer 3)
    return CommonSolve.solve(
        ocp, components.initial_guess,
        components.discretizer,
        components.modeler,
        components.solver;
        display=components.display,
    )
end

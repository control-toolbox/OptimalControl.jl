using DocStringExtensions

# ============================================================================
# Descriptive mode routing helpers
# ============================================================================
#
# These helpers encapsulate the option routing logic for solve_descriptive.
# They are kept separate from solve/descriptive.jl to allow direct unit testing
# without requiring a real OCP or solver.
#
# Call chain:
#   solve_descriptive
#     └─ _route_descriptive_options   (R2.1)
#          ├─ _descriptive_families   (R2.2)
#          └─ _descriptive_action_defs (R2.3)
#     └─ _build_components_from_routed (R2.4)

# ----------------------------------------------------------------------------
# R2.2 — Families
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the strategy families used for option routing in descriptive mode.

The returned `NamedTuple` maps family names to their abstract types, as expected
by [`CTSolvers.Orchestration.route_all_options`](@ref).

# Returns
- `NamedTuple`: `(discretizer, modeler, solver)` mapped to their abstract types

# Example
```julia
julia> fam = OptimalControl._descriptive_families()
(discretizer = CTDirect.AbstractDiscretizer, modeler = CTSolvers.AbstractNLPModeler, solver = CTSolvers.AbstractNLPSolver)
```

See also: [`_route_descriptive_options`](@ref)
"""
function _descriptive_families()
    return (
        discretizer = CTDirect.AbstractDiscretizer,
        modeler     = CTSolvers.AbstractNLPModeler,
        solver      = CTSolvers.AbstractNLPSolver,
    )
end

# ----------------------------------------------------------------------------
# R2.3 — Action option definitions
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the action-level option definitions for descriptive mode.

Action options are solve-level options (e.g., `display`, `initial_guess`) that
are consumed by Layer 1 before reaching `solve_descriptive`. They therefore do
**not** appear in the `kwargs` passed here, so this list is empty.

This helper exists for extensibility: future solve-level options that should be
separated from strategy options can be declared here.

# Returns
- `Vector{CTSolvers.Options.OptionDefinition}`: Empty vector (no action options at Layer 2)

# Example
```julia
julia> OptimalControl._descriptive_action_defs()
CTSolvers.Options.OptionDefinition[]
```

See also: [`_route_descriptive_options`](@ref)
"""
function _descriptive_action_defs()::Vector{CTSolvers.Options.OptionDefinition}
    return CTSolvers.Options.OptionDefinition[]
end

# ----------------------------------------------------------------------------
# R2.1 — Option routing
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Route all keyword options to the appropriate strategy families for descriptive mode.

This function wraps [`CTSolvers.Orchestration.route_all_options`](@ref) with the
families and action definitions specific to OptimalControl's descriptive mode.

Options are routed in `:strict` mode: any unknown option raises an
[`CTBase.IncorrectArgument`](@ref). Ambiguous options (belonging to multiple
strategies) must be disambiguated with [`route_to`](@ref).

# Arguments
- `complete_description`: Complete method triplet `(discretizer_id, modeler_id, solver_id)`
- `registry`: Strategy registry
- `kwargs`: Keyword arguments from the user's `solve` call (strategy options only)

# Returns
- `NamedTuple` with fields:
  - `action`: action-level options (empty in current implementation)
  - `strategies`: `NamedTuple` with `discretizer`, `modeler`, `solver` sub-tuples

# Throws
- `CTBase.IncorrectArgument`: If an option is unknown, ambiguous, or routed to the wrong strategy

# Example
```julia
julia> routed = OptimalControl._route_descriptive_options(
           (:collocation, :adnlp, :ipopt), registry,
           pairs((; grid_size=100, max_iter=500))
       )
julia> routed.strategies.discretizer
(grid_size = 100,)
julia> routed.strategies.solver
(max_iter = 500,)
```

See also: [`_descriptive_families`](@ref), [`_descriptive_action_defs`](@ref),
[`_build_components_from_routed`](@ref)
"""
function _route_descriptive_options(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    registry::CTSolvers.Strategies.StrategyRegistry,
    kwargs,
)
    families    = _descriptive_families()
    action_defs = _descriptive_action_defs()
    return CTSolvers.Orchestration.route_all_options(
        complete_description,
        families,
        action_defs,
        (; kwargs...),
        registry;
        source_mode = :description,
        mode        = :strict,
    )
end

# ----------------------------------------------------------------------------
# R2.4 — Component construction from routed options
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Build the three concrete strategy instances from a routed options result.

Each strategy is constructed via
[`CTSolvers.Strategies.build_strategy_from_method`](@ref) using the options
that were routed to its family by [`_route_descriptive_options`](@ref).

# Arguments
- `complete_description`: Complete method triplet `(discretizer_id, modeler_id, solver_id)`
- `registry`: Strategy registry
- `routed`: Result of [`_route_descriptive_options`](@ref)

# Returns
- `NamedTuple{(:discretizer, :modeler, :solver)}`: Concrete strategy instances

# Example
```julia
julia> components = OptimalControl._build_components_from_routed(
           (:collocation, :adnlp, :ipopt), registry, routed
       )
julia> components.discretizer isa CTDirect.AbstractDiscretizer
true
julia> components.modeler isa CTSolvers.AbstractNLPModeler
true
julia> components.solver isa CTSolvers.AbstractNLPSolver
true
```

See also: [`_route_descriptive_options`](@ref),
[`CTSolvers.Strategies.build_strategy_from_method`](@ref)
"""
function _build_components_from_routed(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    registry::CTSolvers.Strategies.StrategyRegistry,
    routed::NamedTuple,
)
    discretizer = CTSolvers.Strategies.build_strategy_from_method(
        complete_description,
        CTDirect.AbstractDiscretizer,
        registry;
        routed.strategies.discretizer...,
    )
    modeler = CTSolvers.Strategies.build_strategy_from_method(
        complete_description,
        CTSolvers.AbstractNLPModeler,
        registry;
        routed.strategies.modeler...,
    )
    solver = CTSolvers.Strategies.build_strategy_from_method(
        complete_description,
        CTSolvers.AbstractNLPSolver,
        registry;
        routed.strategies.solver...,
    )
    return (discretizer=discretizer, modeler=modeler, solver=solver)
end

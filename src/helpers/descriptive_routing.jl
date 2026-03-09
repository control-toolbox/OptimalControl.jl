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
#     └─ _build_components_from_routed (R2.4)  ← receives ocp for build_initial_guess

# ----------------------------------------------------------------------------
# Action option defaults (single source of truth)
# ----------------------------------------------------------------------------

"""
    _DEFAULT_DISPLAY::Bool

Default value for the `display` action option in solve functions.

When `true`, the solve configuration and method information will be displayed
to the user during the solving process.

# Value
- `true`: Display solve configuration (default)
- `false`: Suppress configuration display

See also: [`_route_descriptive_options`](@ref), [`solve`](@ref)
"""
const _DEFAULT_DISPLAY::Bool        = true

"""
    _DEFAULT_INITIAL_GUESS::Nothing

Default value for the `initial_guess` action option in solve functions.

When `nothing`, no initial guess is provided and the solver will use its
default initialization strategy.

# Value
- `nothing`: No initial guess provided (default)

See also: [`_route_descriptive_options`](@ref), [`solve`](@ref)
"""
const _DEFAULT_INITIAL_GUESS::Nothing = nothing

# Aliases for initial_guess (single source of truth)
# _INITIAL_GUESS_ALIASES_ONLY : used in OptionDefinition (name is separate)
# _INITIAL_GUESS_ALIASES      : used in _extract_action_kwarg (includes primary name)

"""
    _INITIAL_GUESS_ALIASES_ONLY::Tuple{Symbol}

Aliases for the `initial_guess` parameter, excluding the primary name.

Used in `CTSolvers.OptionDefinition` where the primary name is specified separately.

# Value
- `(:init,)`: Alias for `initial_guess`

See also: [`_INITIAL_GUESS_ALIASES`](@ref), [`_route_descriptive_options`](@ref)
"""
const _INITIAL_GUESS_ALIASES_ONLY::Tuple{Symbol}         = (:init,)

"""
    _INITIAL_GUESS_ALIASES::Tuple{Symbol, Symbol}

All valid names for the initial guess parameter, including the primary name and aliases.

Used in `_extract_action_kwarg` to extract the initial guess from keyword arguments.

# Value
- `(:initial_guess, :init)`: Primary name and alias

See also: [`_INITIAL_GUESS_ALIASES_ONLY`](@ref), [`_extract_action_kwarg`](@ref)
"""
const _INITIAL_GUESS_ALIASES::Tuple{Symbol, Symbol}      = (:initial_guess, :init)

# Unwrap an OptionValue (from route_all_options) to its raw value.
# Falls back to `fallback` if `opt` is not an OptionValue.

"""
    _unwrap_option(opt, fallback)

Unwrap an `CTSolvers.OptionValue` to its raw value, with fallback support.

If `opt` is an `OptionValue`, returns `opt.value`. Otherwise, returns `opt` if it's not `nothing`,
or `fallback` if `opt` is `nothing`.

# Arguments
- `opt`: Either an `CTSolvers.OptionValue` or a raw value
- `fallback`: Default value to use when `opt` is `nothing`

# Returns
- The unwrapped value or the fallback

# Example
```julia
julia> opt_val = CTSolvers.OptionValue(42, :user)
OptionValue(42, :user)

julia> _unwrap_option(opt_val, 0)
42

julia> _unwrap_option(nothing, 0)
0
```

See also: [`_route_descriptive_options`](@ref), [`CTSolvers.OptionValue`](@ref)
"""
_unwrap_option(opt::CTSolvers.OptionValue, fallback) = opt.value
_unwrap_option(opt,                        fallback) = opt === nothing ? fallback : opt

# ----------------------------------------------------------------------------
# R2.2 — Families
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the strategy families used for option routing in descriptive mode.

The returned `NamedTuple` maps family names to their abstract types, as expected
by [`CTSolvers.route_all_options`](@ref).

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

Action options are solve-level options consumed by the orchestrator before
strategy-specific options are routed. They are extracted from `kwargs` **first**
by [`CTSolvers.route_all_options`](@ref), so they never reach the strategy router.

Currently defined action options:
- `initial_guess` (aliases: `init`): Initial guess for the OCP solution.
  Defaults to `nothing` (automatic generation via [`CTModels.build_initial_guess`](@ref)).
- `display`: Whether to display solve configuration. Defaults to `true`.

# Priority rule

If a strategy also declares an option with the same name (e.g., `display`), the
action option takes priority when no [`route_to`](@ref) is used. To explicitly
target a strategy, use `route_to(strategy_id=value)`.

# Returns
- `Vector{CTSolvers.OptionDefinition}`: Action option definitions

# Example
```julia
julia> defs = OptimalControl._descriptive_action_defs()
julia> length(defs)
2
julia> defs[1].name
:initial_guess
julia> defs[1].aliases
(:init,)
```

See also: [`_route_descriptive_options`](@ref)
"""
function _descriptive_action_defs()::Vector{CTSolvers.OptionDefinition}
    return [
        CTSolvers.OptionDefinition(
            name        = :initial_guess,
            aliases     = _INITIAL_GUESS_ALIASES_ONLY,
            type        = Any,
            default     = _DEFAULT_INITIAL_GUESS,
            description = "Initial guess for the OCP solution",
        ),
        CTSolvers.OptionDefinition(
            name        = :display,
            aliases     = (),
            type        = Bool,
            default     = _DEFAULT_DISPLAY,
            description = "Display solve configuration",
        ),
    ]
end

# ----------------------------------------------------------------------------
# R2.1 — Option routing
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Route all keyword options to the appropriate strategy families for descriptive mode.

This function wraps [`CTSolvers.route_all_options`](@ref) with the
families and action definitions specific to OptimalControl's descriptive mode.

Options are routed in `:strict` mode: any unknown option raises an
[`CTBase.IncorrectArgument`](@ref). Ambiguous options (belonging to multiple
strategies) must be disambiguated with [`route_to`](@ref).

# Arguments
- `complete_description`: Complete method triplet `(discretizer_id, modeler_id, solver_id)`
- `registry`: Strategy registry
- `kwargs`: All keyword arguments from the user's `solve` call (action + strategy options)

# Returns
- `NamedTuple` with fields:
  - `action`: action-level options (`initial_guess`, `display`) as `OptionValue` wrappers
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
    complete_description::Tuple{Symbol, Symbol, Symbol, Symbol},
    registry::CTSolvers.StrategyRegistry,
    kwargs,
)
    families    = _descriptive_families()
    action_defs = _descriptive_action_defs()
    return CTSolvers.route_all_options(
        complete_description,
        families,
        action_defs,
        (; kwargs...),
        registry;
        source_mode = :description,
    )
end

# ----------------------------------------------------------------------------
# R2.4 — Component construction from routed options
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Build concrete strategy instances and extract action options from a routed options result.

Each strategy is constructed via
[`CTSolvers.build_strategy_from_resolved`](@ref) using the options
that were routed to its family by [`_route_descriptive_options`](@ref).

Action options (`initial_guess`, `display`) are extracted from `routed.action`
and unwrapped from their `OptionValue` wrappers. The initial guess is normalized
via [`CTModels.build_initial_guess`](@ref).

# Arguments
- `ocp`: The optimal control problem (needed to normalize the initial guess)
- `complete_description`: Complete method triplet `(discretizer_id, modeler_id, solver_id)`
- `registry`: Strategy registry
- `routed`: Result of [`_route_descriptive_options`](@ref)

# Returns
- `NamedTuple{(:discretizer, :modeler, :solver, :initial_guess, :display)}`

# Example
```julia
julia> components = OptimalControl._build_components_from_routed(
           ocp, (:collocation, :adnlp, :ipopt), registry, routed
       )
julia> components.discretizer isa CTDirect.AbstractDiscretizer
true
julia> components.initial_guess isa CTModels.AbstractInitialGuess
true
```

See also: [`_route_descriptive_options`](@ref),
[`CTSolvers.build_strategy_from_resolved`](@ref)
"""
function _build_components_from_routed(
    ocp::CTModels.AbstractModel,
    complete_description::Tuple{Symbol, Symbol, Symbol, Symbol},
    registry::CTSolvers.StrategyRegistry,
    routed::NamedTuple,
)
    # Resolve method with parameter information as early as possible
    families = _descriptive_families()
    resolved = CTSolvers.resolve_method(complete_description, families, registry)
    
    # Build strategies using resolved method
    discretizer = CTSolvers.build_strategy_from_resolved(
        resolved, :discretizer, families, registry; routed.strategies.discretizer...
    )
    modeler = CTSolvers.build_strategy_from_resolved(
        resolved, :modeler, families, registry; routed.strategies.modeler...
    )
    solver = CTSolvers.build_strategy_from_resolved(
        resolved, :solver, families, registry; routed.strategies.solver...
    )

    # Extract and unwrap action options (OptionValue → raw value)
    init_raw        = _unwrap_option(get(routed.action, :initial_guess, nothing), _DEFAULT_INITIAL_GUESS)
    normalized_init = CTModels.build_initial_guess(ocp, init_raw)

    display_val = _unwrap_option(get(routed.action, :display, nothing), _DEFAULT_DISPLAY)

    return (
        discretizer   = discretizer,
        modeler       = modeler,
        solver        = solver,
        initial_guess = normalized_init,
        display       = display_val,
    )
end

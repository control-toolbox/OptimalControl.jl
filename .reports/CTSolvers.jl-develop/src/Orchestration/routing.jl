# ============================================================================
# Option routing with strategy-aware disambiguation
# ============================================================================

# ----------------------------------------------------------------------------
# Main Routing Function
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Route all options with support for disambiguation and multi-strategy routing.

This is the main orchestration function that separates action options from
strategy options and routes each strategy option to the appropriate family.
It supports automatic routing for unambiguous options and explicit
disambiguation syntax for options that appear in multiple strategies.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Complete method tuple (e.g.,
  `(:collocation, :adnlp, :ipopt)`)
- `families::NamedTuple`: NamedTuple mapping family names to AbstractStrategy
  types
- `action_defs::Vector{Options.OptionDefinition}`: Definitions for
  action-specific options
- `kwargs::NamedTuple`: All keyword arguments (action + strategy options mixed)
- `registry::Strategies.StrategyRegistry`: Strategy registry
- `source_mode::Symbol=:description`: Controls error verbosity (`:description`
  for user-facing, `:explicit` for internal)

# Returns
NamedTuple with two fields:
- `action::NamedTuple`: NamedTuple of action options (with `OptionValue`
  wrappers)
- `strategies::NamedTuple`: NamedTuple of strategy options per family (raw
  values, may contain [`BypassValue`](@ref) wrappers for bypassed options)

# Disambiguation Syntax

**Auto-routing** (unambiguous):
```julia
solve(ocp, :collocation, :adnlp, :ipopt; grid_size=100)
# grid_size only belongs to discretizer => auto-route
```

**Single strategy** (disambiguate):
```julia
solve(ocp, :collocation, :adnlp, :ipopt; backend = route_to(adnlp=:sparse))
# backend belongs to both modeler and solver => disambiguate to :adnlp
```

**Multi-strategy** (set for multiple):
```julia
solve(ocp, :collocation, :adnlp, :ipopt; 
    backend = route_to(adnlp=:sparse, ipopt=:cpu)
)
# Set backend to :sparse for modeler AND :cpu for solver
```

**Bypass validation** (unknown backend option):
```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    custom_opt = route_to(ipopt=bypass(42))
)
# BypassValue(42) is routed to solver and accepted unconditionally
```

# Throws

- `Exceptions.IncorrectArgument`: If an option is unknown, ambiguous without
  disambiguation, or routed to the wrong strategy

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> families = (
           discretizer = AbstractOptimalControlDiscretizer,
           modeler = AbstractNLPModeler,
           solver = AbstractNLPSolver
       )

julia> action_defs = [
           OptionDefinition(name=:display, type=Bool, default=true,
                          description="Display progress")
       ]

julia> kwargs = (
           grid_size = 100,
           backend = (:sparse, :adnlp),
           max_iter = 1000,
           display = true
       )

julia> routed = route_all_options(method, families, action_defs, kwargs,
                                   registry)
(action = (display = true (user),),
 strategies = (discretizer = (grid_size = 100,),
              modeler = (backend = :sparse,),
              solver = (max_iter = 1000,)))
```

See also: [`extract_strategy_ids`](@ref),
[`build_strategy_to_family_map`](@ref), [`build_option_ownership_map`](@ref)
"""
function route_all_options(
    method::Tuple{Vararg{Symbol}},
    families::NamedTuple,
    action_defs::Vector{<:Options.OptionDefinition},
    kwargs::NamedTuple,
    registry::Strategies.StrategyRegistry;
    source_mode::Symbol = :description,
)
    # Step 1: Extract action options FIRST
    action_options, remaining_kwargs = Options.extract_options(
        kwargs, action_defs
    )

    # Step 2: Build strategy-to-family mapping
    strategy_to_family = build_strategy_to_family_map(
        method, families, registry
    )

    # Step 3: Build option ownership map
    option_owners = build_option_ownership_map(method, families, registry)

    # Step 4: Route each remaining option
    routed = Dict{Symbol, Vector{Pair{Symbol, Any}}}()
    for family_name in keys(families)
        routed[family_name] = Pair{Symbol, Any}[]
    end
    for (key, raw_val) in pairs(remaining_kwargs)
        # Try to extract disambiguation
        disambiguations = extract_strategy_ids(raw_val, method)

        if disambiguations !== nothing
            # Explicitly disambiguated (single or multiple strategies)
            for (value, strategy_id) in disambiguations
                family_name = strategy_to_family[strategy_id]
                owners = get(option_owners, key, Set{Symbol}())

                # Validate that this family owns this option, or bypass if BypassValue
                if family_name in owners || value isa Strategies.BypassValue
                    # Known option → route normally
                    # BypassValue → route without validation (build_strategy_options handles it)
                    push!(routed[family_name], key => value)
                elseif isempty(owners)
                    # Unknown option with explicit target but no bypass → error
                    _error_unknown_option(
                        key, method, families, strategy_to_family, registry
                    )
                else
                    # Option exists but in wrong family
                    valid_strategies = [
                        id for (id, fam) in strategy_to_family if fam in owners
                    ]
                    throw(Exceptions.IncorrectArgument(
                        "Invalid option routing",
                        got="option :$key to strategy :$strategy_id",
                        expected="option to be routed to one of: $valid_strategies",
                        suggestion="Check option ownership or use correct strategy identifier",
                        context="route_options - validating strategy-specific option routing"
                    ))
                end
            end
        else
            # Auto-route based on ownership
            value = raw_val
            owners = get(option_owners, key, Set{Symbol}())

            if isempty(owners)
                # Unknown option - provide helpful error
                _error_unknown_option(
                    key, method, families, strategy_to_family, registry
                )
            elseif length(owners) == 1
                # Unambiguous - auto-route
                family_name = first(owners)
                push!(routed[family_name], key => value)
            else
                # Ambiguous - need disambiguation
                _error_ambiguous_option(
                    key, value, owners, strategy_to_family, source_mode,
                    method, families, registry
                )
            end
        end
    end

    # Step 5: Convert to NamedTuples
    strategy_options = NamedTuple(
        family_name => NamedTuple(pairs)
        for (family_name, pairs) in routed
    )

    # Convert action options (Dict) to NamedTuple
    action_nt = (; (k => v for (k, v) in action_options)...)

    return (action=action_nt, strategies=strategy_options)
end

# ----------------------------------------------------------------------------
# Error Message Helpers (Private)
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Helper to throw an informative error when an option doesn't belong to any strategy.
Lists all available options for the active strategies to help the user.
"""
function _error_unknown_option(
    key::Symbol,
    method::Tuple,
    families::NamedTuple,
    strategy_to_family::Dict{Symbol, Symbol},
    registry::Strategies.StrategyRegistry
)
    # Build helpful error message showing all available options
    all_options = Dict{Symbol, Vector{Symbol}}()
    for (family_name, family_type) in pairs(families)
        id = Strategies.extract_id_from_method(method, family_type, registry)
        option_names = Strategies.option_names_from_method(
            method, family_type, registry
        )
        all_options[id] = collect(option_names)
    end

    msg = "Option :$key doesn't belong to any strategy in method $method.\n\n" *
          "Available options:\n"
    for (id, option_names) in all_options
        family = strategy_to_family[id]
        msg *= "  $family (:$id): $(join(option_names, ", "))\n"
    end

    # Suggest closest options across all strategies (using primary names + aliases)
    suggestion_parts = String[]
    
    # First, suggest similar options if any
    all_suggestions = _collect_suggestions_across_strategies(
        key, method, families, registry; max_suggestions=3
    )
    if !isempty(all_suggestions)
        push!(suggestion_parts, "Did you mean?\n" *
            join(["  - $(Strategies.format_suggestion(s))" for s in all_suggestions], "\n"))
    end
    
    # Then, suggest bypass if user is confident about the option
    if !isempty(all_suggestions)
        push!(suggestion_parts, "\n")
    end
    push!(suggestion_parts, "If you're confident this option exists for a specific strategy, " *
        "use bypass() to skip validation:\n" *
        "  custom_opt = route_to(<strategy_id>=bypass(<value>))")
    
    # Combine all suggestions
    suggestion = join(suggestion_parts, "")

    throw(Exceptions.IncorrectArgument(
        "Unknown option provided",
        got="option :$key in method $method",
        expected="valid option name for one of the strategies",
        suggestion=suggestion,
        context="route_options - unknown option validation"
    ))
end

"""
$(TYPEDSIGNATURES)

Collect option suggestions across all strategies in the method, deduplicated by primary name.
Returns the top `max_suggestions` results sorted by minimum Levenshtein distance.
"""
function _collect_suggestions_across_strategies(
    key::Symbol,
    method::Tuple,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry;
    max_suggestions::Int=3
)
    # Collect suggestions from all strategies, keeping best distance per primary name
    best = Dict{Symbol, @NamedTuple{primary::Symbol, aliases::Tuple{Vararg{Symbol}}, distance::Int}}()
    for (family_name, family_type) in pairs(families)
        id = Strategies.extract_id_from_method(method, family_type, registry)
        strategy_type = Strategies.type_from_id(id, family_type, registry)
        suggestions = Strategies.suggest_options(key, strategy_type; max_suggestions=typemax(Int))
        for s in suggestions
            if !haskey(best, s.primary) || s.distance < best[s.primary].distance
                best[s.primary] = s
            end
        end
    end

    # Sort by distance and take top suggestions
    results = sort(collect(values(best)), by=x -> x.distance)
    n = min(max_suggestions, length(results))
    return results[1:n]
end

"""
$(TYPEDSIGNATURES)

Helper to throw an informative error when an option belongs to multiple strategies and needs disambiguation.
Suggests using `route_to` syntax with specific examples for the conflicting strategies.
"""
function _error_ambiguous_option(
    key::Symbol,
    value::Any,
    owners::Set{Symbol},
    strategy_to_family::Dict{Symbol, Symbol},
    source_mode::Symbol,
    method::Tuple{Vararg{Symbol}},
    families::NamedTuple,
    registry::Strategies.StrategyRegistry
)
    # Find which strategies own this option
    strategies = [
        id for (id, fam) in strategy_to_family if fam in owners
    ]

    # Collect aliases for this option from each strategy's metadata
    alias_info = String[]
    for (family_name, family_type) in pairs(families)
        if family_name in owners
            try
                sid = Strategies.extract_id_from_method(method, family_type, registry)
                strategy_type = Strategies.type_from_id(sid, family_type, registry)
                meta = Strategies.metadata(strategy_type)
                if haskey(meta, key)
                    def = meta[key]
                    if !isempty(def.aliases)
                        push!(alias_info, "  :$sid aliases: $(join(def.aliases, ", "))")
                    end
                end
            catch
                # Skip if metadata lookup fails
            end
        end
    end

    if source_mode === :description
        # User-friendly error message with route_to() syntax
        msg = "Option :$key is ambiguous between strategies: " *
              "$(join(strategies, ", ")).\n\n" *
              "Disambiguate using route_to():\n"
        for id in strategies
            fam = strategy_to_family[id]
            msg *= "  $key = route_to($id=$value)    # Route to $fam\n"
        end
        msg *= "\nOr set for multiple strategies:\n" *
               "  $key = route_to(" *
               join(["$id=$value" for id in strategies], ", ") *
               ")"
        # Build suggestion with alias info
        suggestion = "Use route_to() like $key = route_to($(first(strategies))=$value) to specify target strategy"
        if !isempty(alias_info)
            suggestion *= ". Or use strategy-specific aliases to avoid ambiguity:\n" *
                         join(alias_info, "\n")
        end
        throw(Exceptions.IncorrectArgument(
            "Ambiguous option requires disambiguation",
            got="option :$key between strategies: $(join(strategies, ", "))",
            expected="strategy-specific routing using route_to()",
            suggestion=suggestion,
            context="route_options - ambiguous option resolution"
        ))
    else
        # Internal/developer error message
        throw(Exceptions.IncorrectArgument(
            "Ambiguous option in explicit mode",
            got="option :$key between families: $owners",
            expected="unambiguous option routing in explicit mode",
            suggestion="Use route_to() for disambiguation or switch to description mode",
            context="route_options - explicit mode ambiguity validation"
        ))
    end
end

"""
$(TYPEDSIGNATURES)

Helper to warn when an unknown option is routed in permissive mode.
"""
function _warn_unknown_option_permissive(
    key::Symbol,
    strategy_id::Symbol,
    family_name::Symbol
)
    @warn """
    Unknown option routed in permissive mode
    
    Option :$key is not defined in the metadata of strategy :$strategy_id ($family_name).
    
    This option will be passed directly to the strategy backend without validation.
    Ensure the option name and value are correct for the backend.
    """
end
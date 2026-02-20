# ============================================================================
# Strategy Builders and Construction Utilities
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a strategy instance from its ID and options.

This function creates a concrete strategy instance by:
1. Looking up the strategy type from its ID in the registry
2. Constructing the instance with the provided options

# Arguments
- `id::Symbol`: Strategy identifier (e.g., `:adnlp`, `:ipopt`)
- `family::Type{<:AbstractStrategy}`: Abstract family type to search within
- `registry::StrategyRegistry`: Registry containing strategy mappings
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete strategy instance of the appropriate type

# Throws
- `KeyError`: If the ID is not found in the registry for the given family

# Example
```julia-repl
julia> registry = create_registry(
           AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa)
       )

julia> modeler = build_strategy(:adnlp, AbstractNLPModeler, registry; backend=:sparse)
Modelers.ADNLP(options=StrategyOptions{...})

julia> modeler = build_strategy(:adnlp, AbstractNLPModeler, registry; 
           backend=:sparse, mode=:permissive)
Modelers.ADNLP(options=StrategyOptions{...})
```

See also: [`type_from_id`](@ref), [`build_strategy_from_method`](@ref)
"""
function build_strategy(
    id::Symbol,
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    mode::Symbol = :strict,
    kwargs...
)
    T = type_from_id(id, family, registry)
    return T(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Extract the strategy ID for a specific family from a method tuple.

A method tuple contains multiple strategy IDs (e.g., `(:collocation, :adnlp, :ipopt)`).
This function identifies which ID corresponds to the requested family.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy IDs
- `family::Type{<:AbstractStrategy}`: Abstract family type to search for
- `registry::StrategyRegistry`: Registry containing strategy mappings

# Returns
- `Symbol`: The ID corresponding to the requested family

# Throws
- `ErrorException`: If no ID or multiple IDs are found for the family

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> extract_id_from_method(method, AbstractNLPModeler, registry)
:adnlp

julia> extract_id_from_method(method, AbstractNLPSolver, registry)
:ipopt
```

See also: [`strategy_ids`](@ref), [`build_strategy_from_method`](@ref)
"""
function extract_id_from_method(
    method::Tuple{Vararg{Symbol}},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry
)
    allowed = strategy_ids(family, registry)
    hits = Symbol[]
    
    for s in method
        if s in allowed
            push!(hits, s)
        end
    end
    
    if length(hits) == 1
        return hits[1]
    elseif isempty(hits)
        throw(Exceptions.IncorrectArgument(
            "No strategy ID found for family in method",
            got="family $family in method $method",
            expected="family ID present in method tuple",
            suggestion="Add the family ID to your method tuple, e.g., (:$family, ...)",
            context="extract_id_from_method - validating method tuple contains family"
        ))
    else
        throw(Exceptions.IncorrectArgument(
            "Multiple strategy IDs found for family in method",
            got="family $family appears $length(hits) times in method $method",
            expected="exactly one ID per family in method tuple",
            suggestion="Remove duplicate family IDs from method tuple, keep only one",
            context="extract_id_from_method - validating unique family IDs"
        ))
    end
end

"""
$(TYPEDSIGNATURES)

Get option names for a strategy family from a method tuple.

This is a convenience function that combines ID extraction with option introspection.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy IDs
- `family::Type{<:AbstractStrategy}`: Abstract family type to search for
- `registry::StrategyRegistry`: Registry containing strategy mappings

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of option names for the identified strategy

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> option_names_from_method(method, AbstractNLPModeler, registry)
(:backend, :show_time)
```

See also: [`extract_id_from_method`](@ref), [`option_names`](@ref)
"""
function option_names_from_method(
    method::Tuple{Vararg{Symbol}},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry
)
    id = extract_id_from_method(method, family, registry)
    strategy_type = type_from_id(id, family, registry)
    return option_names(strategy_type)
end

"""
$(TYPEDSIGNATURES)

Build a strategy from a method tuple and options.

This is a high-level convenience function that:
1. Extracts the appropriate ID from the method tuple
2. Builds the strategy with the provided options

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy IDs
- `family::Type{<:AbstractStrategy}`: Abstract family type to search for
- `registry::StrategyRegistry`: Registry containing strategy mappings
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete strategy instance of the appropriate type

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> modeler = build_strategy_from_method(
           method, 
           AbstractNLPModeler, 
           registry; 
           backend=:sparse
       )
Modelers.ADNLP(options=StrategyOptions{...})

julia> modeler = build_strategy_from_method(
           method, 
           AbstractNLPModeler, 
           registry; 
           backend=:sparse,
           mode=:permissive
       )
Modelers.ADNLP(options=StrategyOptions{...})
```

See also: [`extract_id_from_method`](@ref), [`build_strategy`](@ref)
"""
function build_strategy_from_method(
    method::Tuple{Vararg{Symbol}},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    mode::Symbol = :strict,
    kwargs...
)
    id = extract_id_from_method(method, family, registry)
    return build_strategy(id, family, registry; mode=mode, kwargs...)
end

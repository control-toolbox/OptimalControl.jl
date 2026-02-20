# ============================================================================
# Strategy registry for explicit dependency management
# ============================================================================

"""
$(TYPEDEF)

Registry mapping strategy families to their concrete types.

This type provides an explicit, immutable registry for managing strategy types
organized by family. It enables:
- **Type lookup by ID**: Find concrete types from symbolic identifiers
- **Family introspection**: List all strategies in a family
- **Validation**: Ensure ID uniqueness and type hierarchy correctness

# Design Philosophy

The registry uses an **explicit passing pattern** rather than global mutable state:
- Created once via `create_registry`
- Passed explicitly to functions that need it
- Thread-safe (no shared mutable state)
- Testable (easy to create multiple registries)

# Fields
- `families::Dict{Type{<:AbstractStrategy}, Vector{Type}}`: Maps abstract family types to concrete strategy types

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> registry = create_registry(
           AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa),
           AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP)
       )
StrategyRegistry with 2 families

julia> strategy_ids(AbstractNLPModeler, registry)
(:adnlp, :exa)

julia> T = type_from_id(:adnlp, AbstractNLPModeler, registry)
Modelers.ADNLP
```

See also: [`create_registry`](@ref), [`strategy_ids`](@ref), [`type_from_id`](@ref)
"""
struct StrategyRegistry
    families::Dict{Type{<:AbstractStrategy}, Vector{Type}}
end

"""
$(TYPEDSIGNATURES)

Create a strategy registry from family-to-strategies mappings.

This function validates the registry structure and ensures:
- All strategy IDs are unique within each family
- All strategies are subtypes of their declared family
- No duplicate family definitions

# Arguments
- `pairs...`: Pairs of family type => tuple of strategy types

# Returns
- `StrategyRegistry`: Validated registry ready for use

# Validation Rules

1. **ID Uniqueness**: Within each family, all strategy `id()` values must be unique
2. **Type Hierarchy**: Each strategy must be a subtype of its family
3. **No Duplicates**: Each family can only appear once in the registry

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> registry = create_registry(
           AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa),
           AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP, Solvers.Knitro)
       )
StrategyRegistry with 2 families

julia> strategy_ids(AbstractNLPModeler, registry)
(:adnlp, :exa)
```

# Throws
- `ErrorException`: If duplicate IDs are found within a family
- `ErrorException`: If a strategy is not a subtype of its family
- `ErrorException`: If a family appears multiple times

See also: [`StrategyRegistry`](@ref), [`strategy_ids`](@ref), [`type_from_id`](@ref)
"""
function create_registry(pairs::Pair...)
    families = Dict{Type{<:AbstractStrategy}, Vector{Type}}()
    
    # Validate that all pairs have the correct structure
    for pair in pairs
        family, strategies = pair
        if !(family isa DataType && family <: AbstractStrategy)
            throw(Exceptions.IncorrectArgument(
                "Invalid strategy family type",
                got="family=$family of type $(typeof(family))",
                expected="DataType subtype of AbstractStrategy",
                suggestion="Use a valid AbstractStrategy subtype as the family type",
                context="StrategyRegistry constructor - validating family types"
            ))
        end
        if !(strategies isa Tuple)
            throw(Exceptions.IncorrectArgument(
                "Invalid strategies format",
                got="strategies of type $(typeof(strategies))",
                expected="Tuple of strategy types",
                suggestion="Provide strategies as a tuple, e.g., (Strategy1, Strategy2)",
                context="StrategyRegistry constructor - validating strategies format"
            ))
        end
    end
    
    for (family, strategies) in pairs
        # Check for duplicate family
        if haskey(families, family)
            throw(Exceptions.IncorrectArgument(
                "Duplicate family registration",
                got="family $family already registered",
                expected="unique family types in registry",
                suggestion="Remove duplicate family or use a different family type",
                context="StrategyRegistry constructor - checking family uniqueness"
            ))
        end
        
        # Validate uniqueness of IDs within this family
        ids = [id(T) for T in strategies]
        if length(ids) != length(unique(ids))
            duplicates = [i for i in ids if count(==(i), ids) > 1]
            throw(Exceptions.IncorrectArgument(
                "Duplicate strategy IDs detected",
                got="duplicate IDs: $(unique(duplicates)) in family $family",
                expected="unique strategy identifiers within each family",
                suggestion="Ensure each strategy has a unique id() return value within the family",
                context="StrategyRegistry constructor - validating ID uniqueness"
            ))
        end
        
        # Validate all strategies are subtypes of family
        for T in strategies
            if !(T <: family)
                throw(Exceptions.IncorrectArgument(
                    "Strategy type not compatible with family",
                    got="strategy type $T",
                    expected="subtype of family $family",
                    suggestion="Ensure strategy type $T is properly defined as <: $family",
                    context="StrategyRegistry constructor - validating strategy-family relationships"
                ))
            end
        end
        
        families[family] = collect(strategies)
    end
    
    return StrategyRegistry(families)
end

"""
$(TYPEDSIGNATURES)

Get all strategy IDs for a given family.

Returns a tuple of symbolic identifiers for all strategies registered under
the specified family type. The order matches the registration order.

# Arguments
- `family::Type{<:AbstractStrategy}`: The abstract family type
- `registry::StrategyRegistry`: The registry to query

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of strategy IDs in registration order

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> ids = strategy_ids(AbstractNLPModeler, registry)
(:adnlp, :exa)

julia> for strategy_id in ids
           println("Available: ", strategy_id)
       end
Available: adnlp
Available: exa
```

# Throws
- `ErrorException`: If the family is not found in the registry

See also: [`type_from_id`](@ref), [`create_registry`](@ref)
"""
function strategy_ids(family::Type{<:AbstractStrategy}, registry::StrategyRegistry)
    if !haskey(registry.families, family)
        available_families = collect(keys(registry.families))
        throw(Exceptions.IncorrectArgument(
            "Strategy family not found in registry",
            got="family $family",
            expected="one of registered families: $available_families",
            suggestion="Check available families or register the missing family first",
            context="strategy_ids - looking up family in registry"
        ))
    end
    strategies = registry.families[family]
    return Tuple(id(T) for T in strategies)
end

"""
$(TYPEDSIGNATURES)

Lookup a strategy type from its ID within a family.

Searches the registry for a strategy with the given symbolic identifier within
the specified family. This is the core lookup mechanism used by the builder
functions to convert symbolic descriptions to concrete types.

# Arguments
- `strategy_id::Symbol`: The symbolic identifier to look up
- `family::Type{<:AbstractStrategy}`: The family to search within
- `registry::StrategyRegistry`: The registry to query

# Returns
- `Type{<:AbstractStrategy}`: The concrete strategy type matching the ID

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> T = type_from_id(:adnlp, AbstractNLPModeler, registry)
Modelers.ADNLP

julia> id(T)
:adnlp
```

# Throws
- `ErrorException`: If the family is not found in the registry
- `ErrorException`: If the ID is not found within the family (includes suggestions)

See also: [`strategy_ids`](@ref), [`build_strategy`](@ref)
"""
function type_from_id(
    strategy_id::Symbol,
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry
)
    if !haskey(registry.families, family)
        available_families = collect(keys(registry.families))
        throw(Exceptions.IncorrectArgument(
            "Strategy family not found in registry",
            got="family $family",
            expected="one of registered families: $available_families",
            suggestion="Check available families or register the missing family first",
            context="type_from_id - looking up family in registry"
        ))
    end
    
    for T in registry.families[family]
        if id(T) === strategy_id
            return T
        end
    end
    
    # Not found - provide helpful error with available options
    available = strategy_ids(family, registry)
    throw(Exceptions.IncorrectArgument(
        "Unknown strategy ID",
        got=":$strategy_id for family $family",
        expected="one of available IDs: $available",
        suggestion="Check available strategy IDs or register the missing strategy",
        context="type_from_id - looking up strategy ID in family"
    ))
end

# Display
function Base.show(io::IO, registry::StrategyRegistry)
    n_families = length(registry.families)
    print(io, "StrategyRegistry with $n_families $(n_families == 1 ? "family" : "families")")
end

function Base.show(io::IO, ::MIME"text/plain", registry::StrategyRegistry)
    n_families = length(registry.families)
    println(io, "StrategyRegistry with $n_families $(n_families == 1 ? "family" : "families"):")
    
    items = collect(registry.families)
    for (i, (family, strategies)) in enumerate(items)
        is_last = i == length(items)
        prefix = is_last ? "└─ " : "├─ "
        ids = [id(T) for T in strategies]
        println(io, prefix, family, " => ", Tuple(ids))
    end
end

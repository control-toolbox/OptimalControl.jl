"""
$(TYPEDEF)

Metadata about a strategy type, wrapping option definitions.

This type serves as a container for `OptionDefinition` objects that define
the contract for a strategy's configuration options. It is returned by the
type-level `metadata(::Type{<:AbstractStrategy})` method and provides a
convenient interface for accessing and managing option definitions.

# Strategy Contract

Every concrete strategy type must implement the `metadata` method to return
a `StrategyMetadata` instance describing its configurable options:

```julia
function metadata(::Type{<:MyStrategy})
    return StrategyMetadata(
        OptionDefinition(...),
        OptionDefinition(...),
        # ... more option definitions
    )
end
```

This metadata is used by:
- **Validation**: Check option types and values before construction
- **Documentation**: Auto-generate option documentation
- **Introspection**: Query available options without instantiation
- **Construction**: Build `StrategyOptions` with `build_strategy_options`

# Fields
- `specs::NamedTuple`: NamedTuple mapping option names to their definitions (type-stable)

# Type Parameter
- `NT <: NamedTuple`: The concrete NamedTuple type holding the option definitions

# Constructor

The constructor accepts a variable number of `OptionDefinition` arguments and
automatically builds the internal NamedTuple, validating that all option names
are unique. The type parameter is inferred automatically.

# Collection Interface

`StrategyMetadata` implements standard Julia collection interfaces:
- `meta[:option_name]` - Access definition by name
- `keys(meta)` - Get all option names
- `values(meta)` - Get all definitions
- `pairs(meta)` - Iterate over name-definition pairs
- `length(meta)` - Number of options

# Example - Standalone Usage
```julia-repl
julia> using CTSolvers.Strategies

julia> meta = StrategyMetadata(
           OptionDefinition(
               name = :max_iter,
               type = Int,
               default = 100,
               description = "Maximum iterations",
               aliases = (:max, :maxiter),
               validator = x -> x > 0 || throw(ArgumentError("\$x must be positive"))
           ),
           OptionDefinition(
               name = :tol,
               type = Float64,
               default = 1e-6,
               description = "Convergence tolerance"
           )
       )
StrategyMetadata with 2 options:
  max_iter (max, maxiter) :: Int64
    default: 100
    description: Maximum iterations
  tol :: Float64
    default: 1.0e-6
    description: Convergence tolerance

julia> meta[:max_iter].name
:max_iter

julia> collect(keys(meta))
2-element Vector{Symbol}:
 :max_iter
 :tol
```

# Example - Strategy Implementation
```julia
# Define a concrete strategy type
struct MyOptimizer <: AbstractStrategy
    options::StrategyOptions
end

# Implement the metadata contract (type-level)
function metadata(::Type{<:MyOptimizer})
    return StrategyMetadata(
        OptionDefinition(
            name = :max_iter,
            type = Int,
            default = 100,
            description = "Maximum number of iterations",
            validator = x -> x > 0 || throw(ArgumentError("max_iter must be positive"))
        ),
        OptionDefinition(
            name = :tol,
            type = Float64,
            default = 1e-6,
            description = "Convergence tolerance",
            validator = x -> x > 0 || throw(ArgumentError("tol must be positive"))
        )
    )
end

# Implement the id contract (type-level)
id(::Type{<:MyOptimizer}) = :myoptimizer

# Implement constructor using build_strategy_options
function MyOptimizer(; kwargs...)
    options = build_strategy_options(MyOptimizer; kwargs...)
    return MyOptimizer(options)
end

# Now the strategy can be used with automatic validation
julia> strategy = MyOptimizer(max_iter=200, tol=1e-8)
julia> options(strategy)
StrategyOptions(max_iter=200, tol=1.0e-8)
```

# Throws
- `Exceptions.IncorrectArgument`: If duplicate option names are provided

See also: [`OptionDefinition`](@ref), [`AbstractStrategy`](@ref), [`build_strategy_options`](@ref)
"""
struct StrategyMetadata{NT <: NamedTuple}
    specs::NT
    
    function StrategyMetadata(defs::OptionDefinition...)
        # Check for duplicate names
        names = [Options.name(def) for def in defs]
        if length(names) != length(unique(names))
            duplicates = [n for n in names if count(==(n), names) > 1]
            throw(Exceptions.IncorrectArgument(
                "Duplicate option names detected",
                got="duplicate names: $(unique(duplicates))",
                expected="unique option names for each strategy",
                suggestion="Check your OptionDefinition definitions and ensure each name is unique",
                context="StrategyMetadata constructor - validating option name uniqueness"
            ))
        end
        
        # Convert to NamedTuple using names as keys
        names_tuple = Tuple(Options.name(def) for def in defs)
        specs_nt = NamedTuple{names_tuple}(defs)
        NT = typeof(specs_nt)
        
        new{NT}(specs_nt)
    end
end

# ============================================================================
# Collection Interface - Indexability and Iteration
# ============================================================================

"""
$(TYPEDSIGNATURES)

Access an option definition by name.

# Arguments
- `meta::StrategyMetadata`: Strategy metadata
- `key::Symbol`: Option name to retrieve

# Returns
- `OptionDefinition`: The option definition for the specified name

# Throws
- `FieldError`: If the option name is not defined

# Example
```julia-repl
julia> meta[:max_iter]
OptionDefinition{Int64}
  name: max_iter
  type: Int64
  default: 100
  description: Maximum iterations

julia> meta[:max_iter].default
100
```

See also: [`Base.keys`](@ref), [`Base.values`](@ref), [`Base.haskey`](@ref)
"""
Base.getindex(meta::StrategyMetadata, key::Symbol) = meta.specs[key]

"""
$(TYPEDSIGNATURES)

Get all option names defined in the metadata.

# Arguments
- `meta::StrategyMetadata`: Strategy metadata

# Returns
- Iterator of option names (Symbols)

# Example
```julia-repl
julia> collect(keys(meta))
2-element Vector{Symbol}:
 :max_iter
 :tol
```

See also: [`Base.values`](@ref), [`Base.pairs`](@ref)
"""
Base.keys(meta::StrategyMetadata) = keys(meta.specs)

"""
$(TYPEDSIGNATURES)

Get all option definitions.

# Arguments
- `meta::StrategyMetadata`: Strategy metadata

# Returns
- Iterator of `OptionDefinition` objects

# Example
```julia-repl
julia> for def in values(meta)
           println(def.name, ": ", def.description)
       end
max_iter: Maximum iterations
tol: Convergence tolerance
```

See also: [`Base.keys`](@ref), [`Base.pairs`](@ref)
"""
Base.values(meta::StrategyMetadata) = values(meta.specs)

"""
$(TYPEDSIGNATURES)

Iterate over (name, definition) pairs.

# Arguments
- `meta::StrategyMetadata`: Strategy metadata

# Returns
- Iterator of (Symbol, OptionDefinition) pairs

# Example
```julia-repl
julia> for (name, def) in pairs(meta)
           println(name, " => ", def.type)
       end
max_iter => Int64
tol => Float64
```

See also: [`Base.keys`](@ref), [`Base.values`](@ref)
"""
Base.pairs(meta::StrategyMetadata) = pairs(meta.specs)

"""
$(TYPEDSIGNATURES)

Iterate over (name, definition) pairs.

This enables using `StrategyMetadata` in for loops and other iteration contexts.

# Arguments
- `meta::StrategyMetadata`: Strategy metadata
- `state...`: Iteration state (internal)

# Returns
- Tuple of ((Symbol, OptionDefinition), state) or `nothing` when done

# Example
```julia-repl
julia> for (name, def) in meta
           println("\$name: \$(def.description)")
       end
max_iter: Maximum iterations
tol: Convergence tolerance
```

See also: [`Base.pairs`](@ref), [`Base.keys`](@ref)
"""
Base.iterate(meta::StrategyMetadata, state...) = iterate(pairs(meta.specs), state...)

"""
$(TYPEDSIGNATURES)

Get the number of option definitions.

# Arguments
- `meta::StrategyMetadata`: Strategy metadata

# Returns
- `Int`: Number of option definitions

# Example
```julia-repl
julia> length(meta)
2
```

See also: [`Base.isempty`](@ref), [`Base.haskey`](@ref)
"""
Base.length(meta::StrategyMetadata) = length(meta.specs)

"""
$(TYPEDSIGNATURES)

Check if an option definition exists.

# Arguments
- `meta::StrategyMetadata`: Strategy metadata
- `key::Symbol`: Option name to check

# Returns
- `Bool`: `true` if the option exists

# Example
```julia-repl
julia> haskey(meta, :max_iter)
true

julia> haskey(meta, :nonexistent)
false
```

See also: [`Base.getindex`](@ref), [`Base.keys`](@ref)
"""
Base.haskey(meta::StrategyMetadata, key::Symbol) = haskey(meta.specs, key)

# Display
function Base.show(io::IO, ::MIME"text/plain", meta::StrategyMetadata)
    n = length(meta)
    println(io, "StrategyMetadata with $n option$(n == 1 ? "" : "s"):")
    items = collect(pairs(meta))
    for (i, (key, def)) in enumerate(items)
        is_last = i == length(items)
        prefix = is_last ? "└─ " : "├─ "
        cont   = is_last ? "   " : "│  "
        println(io, prefix, def)
        println(io, cont, "description: ", Options.description(def))
    end
end

# ============================================================================
# Strategy utilities and helper functions
# ============================================================================

using DocStringExtensions

"""
$(TYPEDSIGNATURES)

Filter a NamedTuple by excluding specified keys.

# Arguments
- `nt::NamedTuple`: NamedTuple to filter
- `exclude::Symbol`: Single key to exclude

# Returns
- `NamedTuple`: New NamedTuple without the excluded key

# Example
```julia-repl
julia> opts = (max_iter=100, tol=1e-6, debug=true)
julia> filter_options(opts, :debug)
(max_iter = 100, tol = 1.0e-6)
```

See also: [`filter_options(::NamedTuple, ::Tuple)`](@ref)
"""
function filter_options(nt::NamedTuple, exclude::Symbol)
    return filter_options(nt, (exclude,))
end

"""
$(TYPEDSIGNATURES)

Filter a NamedTuple by excluding specified keys.

# Arguments
- `nt::NamedTuple`: NamedTuple to filter
- `exclude::Tuple{Vararg{Symbol}}`: Tuple of keys to exclude

# Returns
- `NamedTuple`: New NamedTuple without the excluded keys

# Example
```julia-repl
julia> opts = (max_iter=100, tol=1e-6, debug=true)
julia> filter_options(opts, (:debug, :tol))
(max_iter = 100,)
```

See also: [`filter_options(::NamedTuple, ::Symbol)`](@ref)
"""
function filter_options(nt::NamedTuple, exclude::Tuple{Vararg{Symbol}})
    exclude_set = Set(exclude)
    filtered_pairs = [
        key => value
        for (key, value) in pairs(nt)
        if key ∉ exclude_set
    ]
    return NamedTuple(filtered_pairs)
end

"""
$(TYPEDSIGNATURES)

Extract strategy options as a mutable Dict, ready for modification.

This is a convenience method that combines three steps into one:
1. Getting `StrategyOptions` from the strategy
2. Extracting raw values (unwrapping `OptionValue`)
3. Converting to `Dict` for modification

# Arguments
- `strategy::AbstractStrategy`: Strategy instance (solver, modeler, etc.)

# Returns
- `Dict{Symbol, Any}`: Mutable dictionary of option values

# Example
```julia-repl
julia> using CTSolvers

julia> solver = Solvers.Ipopt(max_iter=1000, tol=1e-8)

julia> options = Strategies.options_dict(solver)
Dict{Symbol, Any} with 6 entries:
  :max_iter => 1000
  :tol => 1.0e-8
  ...

julia> options[:print_level] = 0  # Modify as needed
0

julia> solve_with_ipopt(nlp; options...)
```

# Notes
This function is particularly useful in solver extensions and modelers where
you need to extract options and potentially modify them before passing to
backend solvers or model builders.

See also: [`options`](@ref), [`Options.extract_raw_options`](@ref)
"""
function options_dict(strategy::AbstractStrategy)
    opts = options(strategy)
    raw_opts = Options.extract_raw_options(_raw_options(opts))
    return Dict{Symbol, Any}(pairs(raw_opts))
end

"""
$(TYPEDSIGNATURES)

Suggest similar option names for an unknown key using Levenshtein distance.

For each option, the distance is the minimum over the primary name and all its aliases.
Results are grouped by primary option name and sorted by this minimum distance.

# Arguments
- `key::Symbol`: Unknown key to find suggestions for
- `strategy_type::Type{<:AbstractStrategy}`: Strategy type to search in
- `max_suggestions::Int=3`: Maximum number of suggestions to return

# Returns
- `Vector{@NamedTuple{primary::Symbol, aliases::Tuple{Vararg{Symbol}}, distance::Int}}`:
  Suggested options sorted by distance (closest first), each with primary name, aliases, and distance.

# Example
```julia-repl
julia> suggest_options(:max_it, MyStrategy)
1-element Vector{...}:
 (primary = :max_iter, aliases = (), distance = 2)

julia> suggest_options(:adnlp_backen, MyStrategy)
1-element Vector{...}:
 (primary = :backend, aliases = (:adnlp_backend,), distance = 1)
```

# Note
The distance of an option to the key is `min(dist(key, primary), dist(key, alias1), ...)`.
This ensures that options with a close alias are suggested even if the primary name is far.

See also: [`resolve_alias`](@ref), [`levenshtein_distance`](@ref)
"""
function suggest_options(
    key::Symbol,
    strategy_type::Type{<:AbstractStrategy};
    max_suggestions::Int=3
)
    meta = metadata(strategy_type)
    return suggest_options(key, meta; max_suggestions=max_suggestions)
end

"""
$(TYPEDSIGNATURES)

Suggest similar option names from a `StrategyMetadata` using Levenshtein distance.

See [`suggest_options(::Symbol, ::Type{<:AbstractStrategy})`](@ref) for details.
"""
function suggest_options(
    key::Symbol,
    meta::StrategyMetadata;
    max_suggestions::Int=3
)
    key_str = string(key)
    
    # For each option, compute min distance over primary name + aliases
    results = NamedTuple{(:primary, :aliases, :distance), Tuple{Symbol, Tuple{Vararg{Symbol}}, Int}}[]
    for (primary_name, def) in pairs(meta)
        # Distance to primary name
        min_dist = levenshtein_distance(key_str, string(primary_name))
        # Distance to each alias
        for alias in def.aliases
            d = levenshtein_distance(key_str, string(alias))
            min_dist = min(min_dist, d)
        end
        push!(results, (primary=primary_name, aliases=def.aliases, distance=min_dist))
    end
    
    # Sort by distance, then take top suggestions
    sort!(results, by=x -> x.distance)
    n = min(max_suggestions, length(results))
    return results[1:n]
end

"""
$(TYPEDSIGNATURES)

Format a suggestion entry as a human-readable string.

# Example
```julia-repl
julia> format_suggestion((primary=:backend, aliases=(:adnlp_backend,), distance=1))
":backend (alias: adnlp_backend) [distance: 1]"
```
"""
function format_suggestion(s::NamedTuple)
    str = ":$(s.primary)"
    if !isempty(s.aliases)
        alias_label = length(s.aliases) == 1 ? "alias" : "aliases"
        str *= " ($alias_label: $(join(s.aliases, ", ")))"
    end
    str *= " [distance: $(s.distance)]"
    return str
end

"""
$(TYPEDSIGNATURES)

Compute the Levenshtein distance between two strings.

The Levenshtein distance is the minimum number of single-character edits
(insertions, deletions, or substitutions) required to change one string into another.

# Arguments
- `s1::String`: First string
- `s2::String`: Second string

# Returns
- `Int`: Levenshtein distance between the two strings

# Example
```julia-repl
julia> levenshtein_distance("kitten", "sitting")
3

julia> levenshtein_distance("max_iter", "max_it")
2
```

# Algorithm
Uses dynamic programming with O(m*n) time and space complexity,
where m and n are the lengths of the input strings.

See also: [`suggest_options`](@ref)
"""
function levenshtein_distance(s1::String, s2::String)
    m, n = length(s1), length(s2)
    d = zeros(Int, m + 1, n + 1)
    
    # Initialize base cases
    for i in 0:m
        d[i+1, 1] = i
    end
    for j in 0:n
        d[1, j+1] = j
    end
    
    # Fill the matrix
    for j in 1:n
        for i in 1:m
            if s1[i] == s2[j]
                d[i+1, j+1] = d[i, j]  # No operation needed
            else
                d[i+1, j+1] = min(
                    d[i, j+1] + 1,    # deletion
                    d[i+1, j] + 1,    # insertion
                    d[i, j] + 1       # substitution
                )
            end
        end
    end
    
    return d[m+1, n+1]
end

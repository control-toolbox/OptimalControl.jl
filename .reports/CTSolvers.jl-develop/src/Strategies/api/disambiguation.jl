# ============================================================================
# Option disambiguation helpers
# ============================================================================

# ----------------------------------------------------------------------------
# Routed Option Type
# ----------------------------------------------------------------------------

"""
$(TYPEDEF)

Routed option value with explicit strategy targeting.

This type is created by [`route_to`](@ref) to disambiguate options that exist
in multiple strategies. It wraps one or more (strategy_id => value) pairs,
allowing the orchestration layer to route each value to its intended strategy.

# Fields
- `routes::NamedTuple`: NamedTuple of strategy_id => value mappings

# Iteration
`RoutedOption` implements the collection interface and can be iterated like a dictionary:
- `keys(opt)`: Strategy IDs
- `values(opt)`: Option values  
- `pairs(opt)`: (strategy_id, value) pairs
- `for (id, val) in opt`: Direct iteration over pairs
- `opt[:strategy]`: Index by strategy ID
- `haskey(opt, :strategy)`: Check if strategy exists
- `length(opt)`: Number of routes

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> # Single strategy
julia> opt = route_to(solver=100)
RoutedOption((solver = 100,))

julia> # Multiple strategies
julia> opt = route_to(solver=100, modeler=50)
RoutedOption((solver = 100, modeler = 50))

julia> # Iterate over routes
julia> for (id, val) in opt
           println("\$id => \$val")
       end
solver => 100
modeler => 50
```

See also: [`route_to`](@ref)
"""
struct RoutedOption
    routes::NamedTuple
    
    function RoutedOption(routes::NamedTuple)
        if isempty(routes)
            throw(Exceptions.PreconditionError(
                "RoutedOption requires at least one route",
                reason="empty routes NamedTuple provided",
                suggestion="Use route_to(strategy=value) to create a routed option",
                context="RoutedOption constructor precondition"
            ))
        end
        new(routes)
    end
end

"""
$(TYPEDSIGNATURES)

Create a disambiguated option value by explicitly routing it to specific strategies.

This function resolves ambiguity when the same option name exists in multiple
strategies (e.g., both modeler and solver have `max_iter`). It creates a
[`RoutedOption`](@ref) that tells the orchestration layer exactly which strategy
should receive which value.

# Arguments
- `kwargs...`: Named arguments where keys are strategy identifiers (`:solver`, `:modeler`, etc.)
  and values are the option values to route to those strategies

# Returns
- `RoutedOption`: A routed option containing the strategy => value mappings

# Throws
- `Exceptions.PreconditionError`: If no strategies are provided

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> # Single strategy
julia> route_to(solver=100)
RoutedOption((solver = 100,))

julia> # Multiple strategies with different values
julia> route_to(solver=100, modeler=50)
RoutedOption((solver = 100, modeler = 50))
```

# Usage in solve()
```julia
# Without disambiguation - error if max_iter exists in multiple strategies
solve(ocp, method; max_iter=100)  # ❌ Ambiguous!

# With disambiguation - explicit routing
solve(ocp, method; 
    max_iter = route_to(solver=100)              # Only solver gets 100
)

solve(ocp, method; 
    max_iter = route_to(solver=100, modeler=50)  # Different values for each
)
```

# Notes
- Strategy identifiers must match the actual strategy IDs in your method tuple
- You can route to one or multiple strategies in a single call
- This is the recommended way to disambiguate options
- The orchestration layer will validate that the strategy IDs exist

See also: [`RoutedOption`](@ref), [`route_all_options`](@ref)
"""
function route_to(; kwargs...)
    if isempty(kwargs)
        throw(Exceptions.PreconditionError(
            "route_to requires at least one strategy argument",
            reason="no strategy arguments provided",
            suggestion="Use route_to(solver=100) or route_to(solver=100, modeler=50)",
            context="route_to - function call precondition"
        ))
    end
    
    # Convert Base.Pairs to NamedTuple - super clean!
    return RoutedOption(NamedTuple(kwargs))
end

# ============================================================================
# Collection Interface for RoutedOption
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return an iterator over the strategy IDs in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> collect(keys(opt))
2-element Vector{Symbol}:
 :solver
 :modeler
```
"""
Base.keys(r::RoutedOption) = keys(r.routes)

"""
$(TYPEDSIGNATURES)

Return an iterator over the values in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> collect(values(opt))
2-element Vector{Int64}:
 100
  50
```
"""
Base.values(r::RoutedOption) = values(r.routes)

"""
$(TYPEDSIGNATURES)

Return an iterator over (strategy_id => value) pairs.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> for (id, val) in pairs(opt)
           println("\$id => \$val")
       end
solver => 100
modeler => 50
```
"""
Base.pairs(r::RoutedOption) = pairs(r.routes)

"""
$(TYPEDSIGNATURES)

Iterate over (strategy_id => value) pairs.

This allows direct iteration: `for (id, val) in routed_option`.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> for (id, val) in opt
           println("\$id => \$val")
       end
solver => 100
modeler => 50
```
"""
Base.iterate(r::RoutedOption, state...) = iterate(pairs(r.routes), state...)

"""
$(TYPEDSIGNATURES)

Return the number of routes in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> length(opt)
2
```
"""
Base.length(r::RoutedOption) = length(r.routes)

"""
$(TYPEDSIGNATURES)

Check if a strategy ID exists in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100)
julia> haskey(opt, :solver)
true
julia> haskey(opt, :modeler)
false
```
"""
Base.haskey(r::RoutedOption, key::Symbol) = haskey(r.routes, key)

"""
$(TYPEDSIGNATURES)

Get the value for a specific strategy ID.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> opt[:solver]
100
julia> opt[:modeler]
50
```
"""
Base.getindex(r::RoutedOption, key::Symbol) = r.routes[key]


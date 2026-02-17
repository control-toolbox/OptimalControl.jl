"""
$(TYPEDSIGNATURES)

Extract strategy symbols from provided components to build a partial method description.

This function extracts the symbolic IDs from concrete strategy instances using
`CTSolvers.Strategies.id(typeof(component))`. It returns a tuple containing
the symbols of all non-`nothing` components in the order: discretizer, modeler, solver.

# Arguments
- `discretizer`: Discretization strategy or `nothing`
- `modeler`: NLP modeling strategy or `nothing`
- `solver`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of strategy symbols (empty if all `nothing`)

# Examples
```julia
julia> disc = CTDirect.Collocation()
julia> _build_partial_description(disc, nothing, nothing)
(:collocation,)

julia> mod = CTSolvers.ADNLP()
julia> sol = CTSolvers.Ipopt()
julia> _build_partial_description(nothing, mod, sol)
(:adnlp, :ipopt)

julia> _build_partial_description(nothing, nothing, nothing)
()
```

# See Also
- [`CTSolvers.Strategies.id`](@ref): Extracts symbolic ID from strategy types
- [`_complete_description`](@ref): Completes partial description via registry
"""
function _build_partial_description(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)::Tuple{Vararg{Symbol}}
    # Count non-nothing components
    count = 0
    if !isnothing(discretizer)
        count += 1
    end
    if !isnothing(modeler)
        count += 1
    end
    if !isnothing(solver)
        count += 1
    end
    
    # Build tuple directly to avoid allocations
    if count == 0
        return ()
    elseif count == 1
        if !isnothing(discretizer)
            return (CTSolvers.Strategies.id(typeof(discretizer)),)
        elseif !isnothing(modeler)
            return (CTSolvers.Strategies.id(typeof(modeler)),)
        else
            return (CTSolvers.Strategies.id(typeof(solver)),)
        end
    elseif count == 2
        if !isnothing(discretizer) && !isnothing(modeler)
            return (
                CTSolvers.Strategies.id(typeof(discretizer)),
                CTSolvers.Strategies.id(typeof(modeler))
            )
        elseif !isnothing(discretizer) && !isnothing(solver)
            return (
                CTSolvers.Strategies.id(typeof(discretizer)),
                CTSolvers.Strategies.id(typeof(solver))
            )
        else
            return (
                CTSolvers.Strategies.id(typeof(modeler)),
                CTSolvers.Strategies.id(typeof(solver))
            )
        end
    else  # count == 3
        return (
            CTSolvers.Strategies.id(typeof(discretizer)),
            CTSolvers.Strategies.id(typeof(modeler)),
            CTSolvers.Strategies.id(typeof(solver))
        )
    end
end

"""
$(TYPEDSIGNATURES)

Complete a partial method description into a full triplet using CTBase.complete().

This function takes a partial description (tuple of strategy symbols) and
completes it to a full (discretizer, modeler, solver) triplet using the
available methods as the completion set.

# Arguments
- `partial_description`: Tuple of strategy symbols (may be empty or partial)

# Returns
- `Tuple{Symbol, Symbol, Symbol}`: Complete method triplet

# Examples
```julia
julia> _complete_description((:collocation,))
(:collocation, :adnlp, :ipopt)

julia> _complete_description(())
(:collocation, :adnlp, :ipopt)  # First available method

julia> _complete_description((:collocation, :exa))
(:collocation, :exa, :ipopt)
```

# See Also
- [`CTBase.complete`](@ref): Generic completion function
- [`methods`](@ref): Available method triplets
- [`_build_partial_description`](@ref): Builds partial description
"""
function _complete_description(
    partial_description::Tuple{Vararg{Symbol}}
)::Tuple{Symbol, Symbol, Symbol}
    return CTBase.complete(partial_description...; descriptions=OptimalControl.methods())
end

"""
$(TYPEDSIGNATURES)

Generic strategy builder that either returns a provided strategy or builds one from a method description.

This function works for any strategy family (discretizer, modeler, or solver).
If a strategy is provided, it is returned directly. If `nothing` is provided,
a strategy is built from the complete description using the registry.

# Arguments
- `complete_description`: Complete method triplet (discretizer, modeler, solver)
- `provided`: Strategy instance or `nothing`
- `family_type`: Abstract strategy type (e.g., `CTDirect.AbstractDiscretizer`)
- `registry`: Strategy registry for building new strategies

# Returns
- `T`: Strategy instance of the specified family type

# Examples
```julia
# Use provided strategy
disc = CTDirect.Collocation()
result = _build_or_use_strategy((:collocation, :adnlp, :ipopt), disc, CTDirect.AbstractDiscretizer, registry)
@test result === disc

# Build from registry
result = _build_or_use_strategy((:collocation, :adnlp, :ipopt), nothing, CTDirect.AbstractDiscretizer, registry)
@test result isa CTDirect.AbstractDiscretizer
```

# See Also
- [`CTSolvers.Strategies.build_strategy_from_method`](@ref): Builds strategy from method description
- [`get_strategy_registry`](@ref): Creates the strategy registry
- [`_complete_description`](@ref): Completes partial method descriptions
"""
function _build_or_use_strategy(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    provided::Union{T, Nothing},
    family_type::Type{T},
    registry::CTSolvers.Strategies.StrategyRegistry
)::T where {T <: CTSolvers.Strategies.AbstractStrategy}
    if !isnothing(provided)
        return provided::T
    end

    return CTSolvers.Strategies.build_strategy_from_method(
        complete_description, family_type, registry
    )
end

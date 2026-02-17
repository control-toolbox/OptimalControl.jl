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

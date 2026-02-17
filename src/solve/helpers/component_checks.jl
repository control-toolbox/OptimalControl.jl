"""
$(TYPEDSIGNATURES)

Check if all three resolution components are provided.

This is a pure predicate function with no side effects. It returns `true` if and only if
all three components (discretizer, modeler, solver) are concrete instances (not `nothing`).

# Arguments
- `discretizer`: Discretization strategy or `nothing`
- `modeler`: NLP modeling strategy or `nothing`
- `solver`: NLP solver strategy or `nothing`

# Returns
- `Bool`: `true` if all components are provided, `false` otherwise

# Examples
```julia
julia> disc = CTDirect.Collocation()
julia> mod = CTSolvers.ADNLP()
julia> sol = CTSolvers.Ipopt()
julia> _has_complete_components(disc, mod, sol)
true

julia> _has_complete_components(nothing, mod, sol)
false

julia> _has_complete_components(disc, nothing, sol)
false
```

# See Also
- [`_complete_components`](@ref): Completes missing components via registry
"""
function _has_complete_components(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)::Bool
    return !isnothing(discretizer) && !isnothing(modeler) && !isnothing(solver)
end

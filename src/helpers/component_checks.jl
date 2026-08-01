"""
$(TYPEDSIGNATURES)

Check if all three resolution components are provided.

This is a pure predicate function with no side effects. It returns `true` if and only if
all three components (discretizer, modeler, solver) are concrete instances (not `nothing`).

# Arguments
- `discretizer::Union{CTSolvers.DOCP.AbstractDiscretizer, Nothing}`: Discretization strategy or `nothing`
- `modeler::Union{CTSolvers.Modelers.AbstractNLPModeler, Nothing}`: NLP modeling strategy or `nothing`
- `solver::Union{CTSolvers.Solvers.AbstractNLPSolver, Nothing}`: NLP solver strategy or `nothing`

# Returns
- `Bool`: `true` if all components are provided, `false` otherwise

# Examples
```julia
julia> disc = CTDirect.Collocation()
julia> mod = CTSolvers.Modelers.ADNLP()
julia> sol = CTSolvers.Solvers.Ipopt()
julia> OptimalControl._has_complete_components(disc, mod, sol)
true

julia> OptimalControl._has_complete_components(nothing, mod, sol)
false

julia> OptimalControl._has_complete_components(disc, nothing, sol)
false
```

# Notes
- This is a pure predicate function with no side effects
- Allocation-free and type-stable
- Used by `solve_explicit` to determine if component completion is needed

See also: [`_complete_components`](@ref), [`solve_explicit`](@ref)
"""
function _has_complete_components(
    discretizer::Union{CTSolvers.DOCP.AbstractDiscretizer,Nothing},
    modeler::Union{CTSolvers.Modelers.AbstractNLPModeler,Nothing},
    solver::Union{CTSolvers.Solvers.AbstractNLPSolver,Nothing},
)::Bool
    return !isnothing(discretizer) && !isnothing(modeler) && !isnothing(solver)
end

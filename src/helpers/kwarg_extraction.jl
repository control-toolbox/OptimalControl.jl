"""
$(TYPEDSIGNATURES)

Extract the first value of abstract type `T` from `kwargs`, or return `nothing`.

This function enables type-based mode detection: explicit resolution components
(discretizer, modeler, solver) are identified by their abstract type rather than
by their keyword name. This avoids name collisions with strategy-specific options
that might share the same keyword names.

# Arguments
- `kwargs`: Keyword arguments from a `solve` call (`Base.Pairs`)
- `T`: Abstract type to search for

# Returns
- `Union{T, Nothing}`: First matching value, or `nothing` if none found

# Examples
```julia
julia> using CTDirect
julia> disc = CTDirect.Collocation()
julia> kw = pairs((; discretizer=disc, print_level=0))
julia> OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
Collocation(...)

julia> OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler)
nothing
```

# See Also
- [`_explicit_or_descriptive`](@ref): Uses this to detect explicit components
- [`_solve(::ExplicitMode, ...)`](@ref): Uses this to extract components for `solve_explicit`
"""
function _extract_kwarg(
    kwargs::Base.Pairs,
    ::Type{T}
)::Union{T, Nothing} where {T}
    for (_, v) in kwargs
        v isa T && return v
    end
    return nothing
end

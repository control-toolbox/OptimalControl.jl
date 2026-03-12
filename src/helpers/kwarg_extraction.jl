"""
$(TYPEDSIGNATURES)

Extract the first value of abstract type `T` from `kwargs`, or return `nothing`.

This function enables type-based mode detection: explicit resolution components
(discretizer, modeler, solver) are identified by their abstract type rather than
by their keyword name. This avoids name collisions with strategy-specific options
that might share the same keyword names.

# Arguments
- `kwargs::Base.Pairs`: Keyword arguments from a `solve` call
- `T::Type`: Abstract type to search for

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

# Notes
- Type-based extraction allows keyword name independence
- Returns the first matching value found (order depends on kwargs iteration)
- Used for mode detection and component extraction in explicit mode

See also: [`_explicit_or_descriptive`](@ref), [`solve_explicit`](@ref)
"""
function _extract_kwarg(kwargs::Base.Pairs, ::Type{T})::Union{T,Nothing} where {T}
    for (_, v) in kwargs
        v isa T && return v
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Extract an action-level option from `kwargs` by trying multiple alias names.

Returns the value and the remaining kwargs with the matched key removed.
Raises an error if more than one alias is present simultaneously.

# Arguments
- `kwargs::Base.Pairs`: Keyword arguments from a `solve` call
- `names::Tuple{Vararg{Symbol}}`: Tuple of accepted names/aliases, in priority order
- `default`: Default value if none of the names is found

# Returns
- `(value, remaining_kwargs)`: Extracted value and kwargs with the key removed

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If more than one alias is provided at the same time

# Examples
```julia
julia> kw = pairs((; init=x0, display=false))
julia> val, rest = OptimalControl._extract_action_kwarg(kw, (:initial_guess, :init), nothing)
julia> val === x0
true
```

# Notes
- Supports alias resolution with conflict detection
- Used for extracting `initial_guess`/`init` and `display` options
- Returns default value if none of the aliases are present

See also: [`_extract_kwarg`](@ref), [`solve_explicit`](@ref), [`solve_descriptive`](@ref)
"""
function _extract_action_kwarg(kwargs::Base.Pairs, names::Tuple{Vararg{Symbol}}, default)
    present = [n for n in names if haskey(kwargs, n)]
    if isempty(present)
        return default, kwargs
    elseif length(present) == 1
        name = present[1]
        value = kwargs[name]
        remaining = Base.pairs(NamedTuple(k => v for (k, v) in kwargs if k != name))
        return value, remaining
    else
        throw(
            CTBase.IncorrectArgument(
                "Conflicting aliases for the same option";
                got="multiple aliases $(present) provided simultaneously",
                expected="at most one of $(names)",
                suggestion="Use only one alias at a time, e.g. `init=x0` or `initial_guess=x0`",
                context="solve - action option extraction",
            ),
        )
    end
end

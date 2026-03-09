"""
$(TYPEDSIGNATURES)

Detect the resolution mode from `description` and `kwargs`, and validate consistency.

Returns an instance of [`ExplicitMode`](@ref) if at least one explicit resolution
component (of type `CTDirect.AbstractDiscretizer`, `CTSolvers.AbstractNLPModeler`, or
`CTSolvers.AbstractNLPSolver`) is found in `kwargs`. Returns [`DescriptiveMode`](@ref)
otherwise.

Raises [`CTBase.Exceptions.IncorrectArgument`](@extref) if both explicit components and a symbolic
description are provided simultaneously.

# Arguments
- `description::Tuple{Vararg{Symbol}}`: Tuple of symbolic description tokens (e.g., `(:collocation, :adnlp, :ipopt)`)
- `kwargs::Base.Pairs`: Keyword arguments from the `solve` call

# Returns
- `ExplicitMode()` if explicit components are present
- `DescriptiveMode()` if no explicit components are present

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If explicit components and symbolic description are mixed

# Examples
```julia
julia> using CTDirect
julia> disc = CTDirect.Collocation()
julia> kw = pairs((; discretizer=disc))

julia> OptimalControl._explicit_or_descriptive((), kw)
ExplicitMode()

julia> OptimalControl._explicit_or_descriptive((:collocation, :adnlp, :ipopt), pairs(NamedTuple()))
DescriptiveMode()

julia> OptimalControl._explicit_or_descriptive((:collocation,), kw)
# throws CTBase.IncorrectArgument
```

# Notes
- This function is used internally by the main `solve` dispatcher to determine the resolution path
- Mode detection is based on the presence of typed components in kwargs
- Validation ensures users don't accidentally mix both modes
- The function uses type-based detection via `_extract_kwarg` for robustness

See also: [`_extract_kwarg`](@ref), [`ExplicitMode`](@ref), [`DescriptiveMode`](@ref), [`CommonSolve.solve`](@ref)
"""
function _explicit_or_descriptive(
    description::Tuple{Vararg{Symbol}},
    kwargs::Base.Pairs
)::SolveMode

    discretizer = _extract_kwarg(kwargs, CTDirect.AbstractDiscretizer)
    modeler     = _extract_kwarg(kwargs, CTSolvers.AbstractNLPModeler)
    solver      = _extract_kwarg(kwargs, CTSolvers.AbstractNLPSolver)

    has_explicit    = !isnothing(discretizer) || !isnothing(modeler) || !isnothing(solver)
    has_description = !isempty(description)

    if has_explicit && has_description
        throw(CTBase.IncorrectArgument(
            "Cannot mix explicit components with symbolic description",
            got="explicit components + symbolic description $(description)",
            expected="either explicit components OR symbolic description",
            suggestion="Use either solve(ocp; discretizer=..., modeler=..., solver=...) OR solve(ocp, :collocation, :adnlp, :ipopt)",
            context="solve function call"
        ))
    end

    return has_explicit ? ExplicitMode() : DescriptiveMode()
end

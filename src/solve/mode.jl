"""
Abstract supertype for solve mode sentinel types.

Concrete subtypes are used for multiple dispatch on `_solve` to route
resolution to the appropriate mode handler without `if/else` branching.

# Subtypes
- [`ExplicitMode`](@ref): User provided explicit components (discretizer, modeler, solver)
- [`DescriptiveMode`](@ref): User provided symbolic description (e.g., `:collocation, :adnlp, :ipopt`)

# See Also
- [`_explicit_or_descriptive`](@ref): Returns the appropriate mode instance
- [`_solve`](@ref): Dispatches on mode
"""
abstract type SolveMode end

"""
Sentinel type indicating that the user provided explicit resolution components.

An instance `ExplicitMode()` is passed to `_solve` when at least one of
`discretizer`, `modeler`, or `solver` is present in `kwargs` with the
correct abstract type.

# See Also
- [`DescriptiveMode`](@ref): The alternative mode
- [`_explicit_or_descriptive`](@ref): Mode detection logic
- [`_solve(::ExplicitMode, ...)`](@ref): Handler for this mode
"""
struct ExplicitMode <: SolveMode end

"""
Sentinel type indicating that the user provided a symbolic description.

An instance `DescriptiveMode()` is passed to `_solve` when no explicit
components are found in `kwargs`. The symbolic description (e.g.,
`:collocation, :adnlp, :ipopt`) is forwarded via `kwargs`.

# See Also
- [`ExplicitMode`](@ref): The alternative mode
- [`_explicit_or_descriptive`](@ref): Mode detection logic
- [`_solve(::DescriptiveMode, ...)`](@ref): Handler for this mode
"""
struct DescriptiveMode <: SolveMode end

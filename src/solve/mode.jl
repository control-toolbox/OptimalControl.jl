"""
Abstract supertype for solve mode sentinel types.

Concrete subtypes are used to route resolution to the appropriate mode handler
without `if/else` branching in mode detection.

# Subtypes
- [`ExplicitMode`](@ref): User provided explicit components (discretizer, modeler, solver)
- [`DescriptiveMode`](@ref): User provided symbolic description (e.g., `:collocation, :adnlp, :ipopt`)

# See Also
- [`_explicit_or_descriptive`](@ref): Returns the appropriate mode instance
"""
abstract type SolveMode end

"""
Sentinel type indicating that the user provided explicit resolution components.

An instance `ExplicitMode()` is returned by [`_explicit_or_descriptive`](@ref) when at
least one of `discretizer`, `modeler`, or `solver` is present in `kwargs` with the
correct abstract type.

# See Also
- [`DescriptiveMode`](@ref): The alternative mode
- [`_explicit_or_descriptive`](@ref): Mode detection logic
"""
struct ExplicitMode <: SolveMode end

"""
Sentinel type indicating that the user provided a symbolic description.

An instance `DescriptiveMode()` is returned by [`_explicit_or_descriptive`](@ref) when
no explicit components are found in `kwargs`.

# See Also
- [`ExplicitMode`](@ref): The alternative mode
- [`_explicit_or_descriptive`](@ref): Mode detection logic
"""
struct DescriptiveMode <: SolveMode end

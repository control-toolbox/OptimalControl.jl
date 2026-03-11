"""
$(TYPEDEF)

Abstract supertype for solve mode sentinel types.

Concrete subtypes are used to route resolution to the appropriate mode handler
without `if/else` branching in mode detection.

# Subtypes
- [`ExplicitMode`](@ref): User provided explicit components (discretizer, modeler, solver)
- [`DescriptiveMode`](@ref): User provided symbolic description (e.g., `:collocation, :adnlp, :ipopt`)

See also: [`_explicit_or_descriptive`](@ref), [`ExplicitMode`](@ref), [`DescriptiveMode`](@ref)
"""
abstract type SolveMode end

"""
$(TYPEDEF)

Sentinel type indicating that the user provided explicit resolution components.

An instance `ExplicitMode()` is returned by [`_explicit_or_descriptive`](@ref) when at
least one of `discretizer`, `modeler`, or `solver` is present in `kwargs` with the
correct abstract type.

# Notes
- This is a zero-field struct used purely for dispatch
- Enables type-stable routing without runtime branching
- Part of the solve architecture's mode detection system

See also: [`SolveMode`](@ref), [`DescriptiveMode`](@ref), [`_explicit_or_descriptive`](@ref)
"""
struct ExplicitMode <: SolveMode end

"""
$(TYPEDEF)

Sentinel type indicating that the user provided a symbolic description.

An instance `DescriptiveMode()` is returned by [`_explicit_or_descriptive`](@ref) when
no explicit components are found in `kwargs`.

# Notes
- This is a zero-field struct used purely for dispatch
- Enables type-stable routing without runtime branching
- Part of the solve architecture's mode detection system

See also: [`SolveMode`](@ref), [`ExplicitMode`](@ref), [`_explicit_or_descriptive`](@ref)
"""
struct DescriptiveMode <: SolveMode end

# ============================================================================
# NotProvided Type - Sentinel for "no default value"
# ============================================================================

"""
$(TYPEDEF)

Singleton type representing the absence of a default value for an option.

This type is used to distinguish between:
- `default = NotProvided`: No default value, option must be provided by user or not stored
- `default = nothing`: The default value is explicitly `nothing`

# Example
```julia-repl
julia> using CTSolvers.Options

julia> # Option with no default - won't be stored if not provided
julia> opt1 = OptionDefinition(
           name = :minimize,
           type = Union{Bool, Nothing},
           default = NotProvided,
           description = "Whether to minimize"
       )

julia> # Option with explicit nothing default - will be stored as nothing
julia> opt2 = OptionDefinition(
           name = :backend,
           type = Union{Nothing, KernelAbstractions.Backend},
           default = nothing,
           description = "Execution backend"
       )
```

See also: [`OptionDefinition`](@ref), [`extract_options`](@ref)
"""
struct NotProvidedType end

"""
    NotProvided

Singleton instance of [`NotProvidedType`](@ref).

Use this as the default value in [`OptionDefinition`](@ref) to indicate
that an option has no default value and should not be stored if not provided
by the user.

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(
           name = :optional_param,
           type = Any,
           default = NotProvided,
           description = "Optional parameter"
       )

julia> # If user doesn't provide it, it won't be stored
julia> opts, _ = extract_options((other=1,), [def])
julia> haskey(opts, :optional_param)
false
```
"""
const NotProvided = NotProvidedType()

# Pretty printing
Base.show(io::IO, ::NotProvidedType) = print(io, "NotProvided")

"""
$(TYPEDEF)

Internal sentinel type used by the option extraction system to signal that an option
should not be stored in the instance.

This is returned by [`extract_option`](@ref) when an option has `NotProvided` as its
default and was not provided by the user.

# Note
This type is internal to the Options module and should not be used directly by users.
Use [`NotProvided`](@ref) instead.

See also: [`NotProvided`](@ref), [`extract_option`](@ref)
"""
struct NotStoredType end

"""
    NotStored

Internal singleton instance of [`NotStoredType`](@ref).

Used internally by the option extraction system to signal that an option should not
be stored. This is distinct from `nothing` which is a valid option value.

See also: [`NotProvided`](@ref), [`extract_option`](@ref)
"""
const NotStored = NotStoredType()

# Pretty printing
Base.show(io::IO, ::NotStoredType) = print(io, "NotStored")

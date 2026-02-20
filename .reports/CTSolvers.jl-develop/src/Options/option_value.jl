# ============================================================================
# Option value representation with provenance
# ============================================================================

"""
$(TYPEDEF)

Represents an option value with its source provenance.

# Fields
- `value::T`: The actual option value.
- `source::Symbol`: Where the value came from (`:default`, `:user`, `:computed`).

# Notes
The `source` field tracks the provenance of the option value:
- `:default`: Value comes from the tool's default configuration
- `:user`: Value was explicitly provided by the user
- `:computed`: Value was computed/derived from other options

# Example
```julia-repl
julia> using CTSolvers.Options

julia> opt = OptionValue(100, :user)
100 (user)

julia> opt.value
100

julia> opt.source
:user
```

# Throws
- `Exceptions.IncorrectArgument`: If source is not one of `:default`, `:user`, or `:computed`
"""
struct OptionValue{T}
    value::T
    source::Symbol
    
    function OptionValue(value::T, source::Symbol) where T
        if source ∉ (:default, :user, :computed)
            throw(Exceptions.IncorrectArgument(
                "Invalid option source",
                got="source=$source",
                expected=":default, :user, or :computed",
                suggestion="Use one of the valid source symbols: :default (tool default), :user (user-provided), or :computed (derived)",
                context="OptionValue constructor - validating source provenance"
            ))
        end
        new{T}(value, source)
    end
end

"""
$(TYPEDSIGNATURES)

Create an `OptionValue` defaulting to `:user` source.

# Arguments
- `value`: The option value.

# Returns
- `OptionValue{T}`: Option value with `:user` source.

# Example
```julia-repl
julia> using CTSolvers.Options

julia> OptionValue(42)
42 (user)
```
"""
OptionValue(value) = OptionValue(value, :user)

# =============================================================================
# OptionValue getters and introspection
# =============================================================================

"""
$(TYPEDSIGNATURES)

Get the value from this option value wrapper.

# Returns
- The stored option value

# Example
```julia-repl
julia> using CTSolvers.Options

julia> opt = OptionValue(100, :user)

julia> value(opt)
100
```

See also: [`source`](@ref), [`is_user`](@ref)
"""
value(opt::OptionValue) = opt.value

"""
$(TYPEDSIGNATURES)

Get the source provenance of this option value.

# Returns
- `Symbol`: `:default`, `:user`, or `:computed`

# Example
```julia-repl
julia> using CTSolvers.Options

julia> opt = OptionValue(100, :user)

julia> source(opt)
:user
```

See also: [`value`](@ref), [`is_user`](@ref)
"""
source(opt::OptionValue) = opt.source

"""
$(TYPEDSIGNATURES)

Check if this option value was explicitly provided by the user.

# Returns
- `Bool`: `true` if the source is `:user`

# Example
```julia-repl
julia> using CTSolvers.Options

julia> opt = OptionValue(100, :user)

julia> is_user(opt)
true
```

See also: [`is_default`](@ref), [`is_computed`](@ref), [`source`](@ref)
"""
is_user(opt::OptionValue) = opt.source === :user

"""
$(TYPEDSIGNATURES)

Check if this option value is using its default.

# Returns
- `Bool`: `true` if the source is `:default`

# Example
```julia-repl
julia> using CTSolvers.Options

julia> opt = OptionValue(100, :default)

julia> is_default(opt)
true
```

See also: [`is_user`](@ref), [`is_computed`](@ref), [`source`](@ref)
"""
is_default(opt::OptionValue) = opt.source === :default

"""
$(TYPEDSIGNATURES)

Check if this option value was computed from other options.

# Returns
- `Bool`: `true` if the source is `:computed`

# Example
```julia-repl
julia> using CTSolvers.Options

julia> opt = OptionValue(100, :computed)

julia> is_computed(opt)
true
```

See also: [`is_user`](@ref), [`is_default`](@ref), [`source`](@ref)
"""
is_computed(opt::OptionValue) = opt.source === :computed

"""
$(TYPEDSIGNATURES)

Display the option value in the format "value (source)".

# Example
```julia-repl
julia> using CTSolvers.Options

julia> println(OptionValue(3.14, :default))
3.14 (default)
```
"""
Base.show(io::IO, opt::OptionValue) = print(io, "$(opt.value) ($(opt.source))")

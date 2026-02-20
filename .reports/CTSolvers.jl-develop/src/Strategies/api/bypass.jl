# ============================================================================
# Bypass Mechanism for Explicit Option Validation
# ============================================================================

"""
$(TYPEDEF)

Wrapper type for option values that should bypass validation.

This type is used to explicitly skip validation for specific options when
constructing strategies. It is particularly useful for passing backend-specific
options that are not defined in the strategy's metadata.

# Fields
- `value::T`: The wrapped option value

# Example
```julia-repl
julia> val = bypass(42)
BypassValue(42)
```

See also: [`bypass`](@ref)
"""
struct BypassValue{T}
    value::T
end

"""
$(TYPEDSIGNATURES)

Mark an option value to bypass validation.

This function creates a [`BypassValue`](@ref) wrapper around the provided value.
When passed to a strategy constructor, this value will be accepted even if the
option name is unknown (not in metadata) or if validation would otherwise fail.

This is the explicit mode equivalent of `route_to(..., bypass=true)`.

# Arguments
- `val`: The option value to wrap

# Returns
- `BypassValue`: The wrapped value

# Example
```julia
# Pass an unknown option to Ipopt
solver = Ipopt(
    max_iter=100, 
    custom_backend_option=bypass(42)  # Bypasses validation
)
```

# Notes
- Use with caution! Bypassed options are passed directly to the backend.
- Typos in option names will not be caught.
- Invalid values for the backend will cause backend-level errors.

See also: [`BypassValue`](@ref), [`route_to`](@ref)
"""
bypass(val) = BypassValue(val)

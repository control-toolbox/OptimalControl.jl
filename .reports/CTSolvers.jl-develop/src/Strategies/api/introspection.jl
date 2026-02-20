# ============================================================================
# Strategy and option introspection API
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get all option names for a strategy type.

Returns a tuple of all option names defined in the strategy's metadata.
This is useful for discovering what options are available without needing
to instantiate the strategy.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type to introspect

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of option names

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> option_names(MyStrategy)
(:max_iter, :tol, :backend)

julia> for name in option_names(MyStrategy)
           println("Available option: ", name)
       end
Available option: max_iter
Available option: tol
Available option: backend
```

# Notes
- This function operates on types, not instances
- If you have an instance, use `option_names(typeof(strategy))`

See also: [`option_type`](@ref), [`option_description`](@ref), [`option_default`](@ref)
"""
function option_names(strategy_type::Type{<:AbstractStrategy})
    meta = metadata(strategy_type)
    return Tuple(keys(meta))
end

"""
$(TYPEDSIGNATURES)

Get the expected type for a specific option.

Returns the Julia type that the option value must satisfy. This is useful
for validation and documentation purposes.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type
- `key::Symbol`: The option name

# Returns
- `Type`: The expected type for the option value

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> option_type(MyStrategy, :max_iter)
Int64

julia> option_type(MyStrategy, :tol)
Float64
```

# Throws
- `KeyError`: If the option name does not exist

# Notes
- This function operates on types, not instances
- If you have an instance, use `option_type(typeof(strategy), key)`

See also: [`option_description`](@ref), [`option_default`](@ref)
"""
function option_type(strategy_type::Type{<:AbstractStrategy}, key::Symbol)
    meta = metadata(strategy_type)
    return Options.type(meta[key])
end

"""
$(TYPEDSIGNATURES)

Get the human-readable description for a specific option.

Returns the documentation string that explains what the option controls.
This is useful for generating help messages and documentation.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type
- `key::Symbol`: The option name

# Returns
- `String`: The option description

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> option_description(MyStrategy, :max_iter)
"Maximum number of iterations"

julia> option_description(MyStrategy, :tol)
"Convergence tolerance"
```

# Throws
- `KeyError`: If the option name does not exist

# Notes
- This function operates on types, not instances
- If you have an instance, use `option_description(typeof(strategy), key)`

See also: [`option_type`](@ref), [`option_default`](@ref)
"""
function option_description(strategy_type::Type{<:AbstractStrategy}, key::Symbol)
    meta = metadata(strategy_type)
    return Options.description(meta[key])
end

"""
$(TYPEDSIGNATURES)

Get the default value for a specific option.

Returns the value that will be used if the option is not explicitly provided
by the user during strategy construction.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type
- `key::Symbol`: The option name

# Returns
- The default value for the option (type depends on the option)

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> option_default(MyStrategy, :max_iter)
100

julia> option_default(MyStrategy, :tol)
1.0e-6
```

# Throws
- `KeyError`: If the option name does not exist

# Notes
- This function operates on types, not instances
- If you have an instance, use `option_default(typeof(strategy), key)`

See also: [`option_defaults`](@ref), [`option_type`](@ref)
"""
function option_default(strategy_type::Type{<:AbstractStrategy}, key::Symbol)
    meta = metadata(strategy_type)
    return Options.default(meta[key])
end

"""
$(TYPEDSIGNATURES)

Get all default values as a NamedTuple.

Returns a NamedTuple containing the default value for every option defined
in the strategy's metadata. This is useful for resetting configurations or
understanding the baseline behavior.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type

# Returns
- `NamedTuple`: All default values keyed by option name

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> option_defaults(MyStrategy)
(max_iter = 100, tol = 1.0e-6)

julia> defaults = option_defaults(MyStrategy)
julia> defaults.max_iter
100
```

# Notes
- This function operates on types, not instances
- If you have an instance, use `option_defaults(typeof(strategy))`

See also: [`option_default`](@ref), [`option_names`](@ref)
"""
function option_defaults(strategy_type::Type{<:AbstractStrategy})
    meta = metadata(strategy_type)
    defaults = NamedTuple(
        key => Options.default(spec)
        for (key, spec) in pairs(meta)
    )
    return defaults
end

"""
$(TYPEDSIGNATURES)

Get the current value of an option from a strategy instance.

Returns the effective value that the strategy is using for the specified option.
This may be a user-provided value or the default value.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: The option name

# Returns
- The current option value (type depends on the option)

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> strategy = MyStrategy(max_iter=200)
julia> option_value(strategy, :max_iter)
200

julia> option_value(strategy, :tol)  # Uses default
1.0e-6
```

# Throws
- `KeyError`: If the option name does not exist

See also: [`option_source`](@ref), [`options`](@ref)
"""
function option_value(strategy::AbstractStrategy, key::Symbol)
    opts = options(strategy)
    return opts[key]
end

"""
$(TYPEDSIGNATURES)

Get the source provenance of an option value.

Returns a symbol indicating where the option value came from:
- `:user` - Explicitly provided by the user
- `:default` - Using the default value from metadata
- `:computed` - Calculated from other options

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: The option name

# Returns
- `Symbol`: The source provenance (`:user`, `:default`, or `:computed`)

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> strategy = MyStrategy(max_iter=200)
julia> option_source(strategy, :max_iter)
:user

julia> option_source(strategy, :tol)
:default
```

# Throws
- `KeyError`: If the option name does not exist

See also: [`option_value`](@ref), [`is_user`](@ref), [`is_default`](@ref)
"""
function option_source(strategy::AbstractStrategy, key::Symbol)
    return Options.source(options(strategy), key)
end

"""
$(TYPEDSIGNATURES)

Check if an option exists in a strategy instance.

Returns `true` if the option is present in the strategy's options,
`false` otherwise. This is useful for checking if unknown options
were stored in permissive mode.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: The option name

# Returns
- `Bool`: `true` if the option exists

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> strategy = MyStrategy(max_iter=200; mode=:permissive, custom_opt=123)
julia> has_option(strategy, :max_iter)
true

julia> has_option(strategy, :custom_opt)
true

julia> has_option(strategy, :nonexistent)
false
```

See also: [`option_value`](@ref), [`option_source`](@ref)
"""
function has_option(strategy::AbstractStrategy, key::Symbol)
    return haskey(options(strategy), key)
end


"""
$(TYPEDSIGNATURES)

Check if an option value was provided by the user.

Returns `true` if the option was explicitly set by the user during construction,
`false` if it's using the default value or was computed.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: The option name

# Returns
- `Bool`: `true` if the option source is `:user`

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> strategy = MyStrategy(max_iter=200)
julia> is_user(strategy, :max_iter)
true

julia> is_user(strategy, :tol)
false
```

See also: [`is_default`](@ref), [`is_computed`](@ref), [`option_source`](@ref)
"""
function option_is_user(strategy::AbstractStrategy, key::Symbol)
    return Options.is_user(options(strategy), key)
end

"""
$(TYPEDSIGNATURES)

Check if an option value is using its default.

Returns `true` if the option is using the default value from metadata,
`false` if it was provided by the user or computed.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: The option name

# Returns
- `Bool`: `true` if the option source is `:default`

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> strategy = MyStrategy(max_iter=200)
julia> is_default(strategy, :max_iter)
false

julia> is_default(strategy, :tol)
true
```

See also: [`is_user`](@ref), [`is_computed`](@ref), [`option_source`](@ref)
"""
function option_is_default(strategy::AbstractStrategy, key::Symbol)
    return Options.is_default(options(strategy), key)
end

"""
$(TYPEDSIGNATURES)

Check if an option value was computed from other options.

Returns `true` if the option was calculated based on other option values,
`false` if it was provided by the user or is using the default.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: The option name

# Returns
- `Bool`: `true` if the option source is `:computed`

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> strategy = MyStrategy()
julia> is_computed(strategy, :derived_value)
true
```

See also: [`is_user`](@ref), [`is_default`](@ref), [`option_source`](@ref)
"""
function option_is_computed(strategy::AbstractStrategy, key::Symbol)
    return Options.is_computed(options(strategy), key)
end

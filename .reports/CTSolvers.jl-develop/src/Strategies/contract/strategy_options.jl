"""
$(TYPEDEF)

Wrapper for strategy option values with provenance tracking.

This type stores options as a collection of `OptionValue` objects, each containing
both the value and its source (`:user`, `:default`, or `:computed`).

## Validation Modes

Strategy options are built using `build_strategy_options()` which supports two validation modes:

- **Strict Mode (default)**: Only known options are accepted
  - Unknown options trigger detailed error messages with suggestions
  - Type validation and custom validators are enforced
  - Provides early error detection and safety

- **Permissive Mode**: Unknown options are accepted with warnings
  - Unknown options are stored with `:user` source
  - Type validation and custom validators still apply to known options
  - Allows backend-specific options without breaking changes

# Fields
- `options::NamedTuple`: NamedTuple of OptionValue objects with provenance

# Construction

```julia-repl
julia> using CTSolvers.Strategies, CTSolvers.Options

julia> opts = StrategyOptions(
           max_iter = OptionValue(200, :user),
           tol = OptionValue(1e-6, :default)
       )
StrategyOptions with 2 options:
  max_iter = 200  [user]
  tol = 1.0e-6  [default]
```

# Building Options with Validation

```julia-repl
# Strict mode (default) - rejects unknown options
julia> opts = build_strategy_options(MyStrategy; max_iter=200)
StrategyOptions(...)

# Permissive mode - accepts unknown options with warning
julia> opts = build_strategy_options(MyStrategy; max_iter=200, custom_opt=123; mode=:permissive)
StrategyOptions(...)  # with warning about custom_opt
```

# Access patterns

```julia-repl
# Get value only
julia> opts[:max_iter]
200

# Get OptionValue (value + source)
julia> opts.max_iter
OptionValue(200, :user)

# Get source only
julia> source(opts, :max_iter)
:user

# Check if user-provided
julia> is_user(opts, :max_iter)
true
```

# Iteration

```julia-repl
# Iterate over values
julia> for value in opts
           println(value)
       end

# Iterate over (name, value) pairs
julia> for (name, value) in opts
           println("\$name = \$value")
       end
```

See also: [`OptionValue`](@ref), [`source`](@ref), [`is_user`](@ref), [`is_default`](@ref), [`is_computed`](@ref)
"""
struct StrategyOptions{NT <: NamedTuple}
    options::NT
    
    function StrategyOptions(options::NT) where NT <: NamedTuple
        for (key, val) in pairs(options)
            if !(val isa Options.OptionValue)
                throw(Exceptions.IncorrectArgument(
                    "Invalid option value type",
                    got="$(typeof(val)) for key :$key",
                    expected="OptionValue for all strategy options",
                    suggestion="Wrap your value with OptionValue(value, :user/:default/:computed) or use the StrategyOptions constructor",
                    context="StrategyOptions constructor - validating option types"
                ))
            end
        end
        new{NT}(options)
    end
    
    StrategyOptions(; kwargs...) = StrategyOptions((; kwargs...))
end

# ============================================================================
# Value access - returns unwrapped value
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get the value of an option (without source information).

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- The unwrapped option value

# Notes
This method is type-unstable due to dynamic key lookup. For type-stable access,
use the `get(::Val{key})` method or direct field access.

# Example
```julia-repl
julia> opts[:max_iter]  # Type-unstable
200

julia> get(opts, Val(:max_iter))  # Type-stable
200
```

See also: [`Base.getproperty`](@ref), [`source`](@ref), [`get(::StrategyOptions, ::Val)`](@ref)
"""
Base.getindex(opts::StrategyOptions, key::Symbol) = Options.value(option(opts, key))

"""
$(TYPEDSIGNATURES)

Type-stable access to option value using Val.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `::Val{key}`: Compile-time key

# Returns
- The unwrapped option value with exact type inference

# Example
```julia-repl
julia> get(opts, Val(:max_iter))
200
```

See also: [`Base.getindex`](@ref), [`Base.getproperty`](@ref)
"""
function Base.get(opts::StrategyOptions{NT}, ::Val{key}) where {NT <: NamedTuple, key}
    return Options.value(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Get the OptionValue for an option (with source information).

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name or `:options` for the internal field

# Returns
- `OptionValue`: Complete option with value and source, or the internal options field

# Example
```julia-repl
julia> opts.max_iter
OptionValue(200, :user)

julia> opts.max_iter.value
200

julia> opts.max_iter.source
:user
```

See also: [`Base.getindex`](@ref), [`source`](@ref)
"""
Base.getproperty(opts::StrategyOptions, key::Symbol) = 
    key === :options ? _raw_options(opts) : _raw_options(opts)[key]

# ==========================================================================
# OptionValue access helpers
# ==========================================================================

"""
$(TYPEDSIGNATURES)

Get the `OptionValue` wrapper for an option.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Options.OptionValue`: The option value wrapper

# Example
```julia-repl
julia> opt = option(opts, :max_iter)
julia> Options.value(opt)
200
```

See also: [`Base.getproperty`](@ref), [`Options.source`](@ref)
"""
option(opts::StrategyOptions, key::Symbol) = _raw_options(opts)[key]

# ============================================================================
# Source access helpers
# ============================================================================
"""
$(TYPEDSIGNATURES)

Get the value of an option.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Any`: Value of the option

# Example
```julia-repl
julia> Options.value(opts, :max_iter)
200
```

See also: [`Options.is_user`](@ref), [`Options.is_default`](@ref), [`Options.is_computed`](@ref)
"""
function Options.value(opts::StrategyOptions, key::Symbol)
    return Options.value(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Get the source of an option.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Symbol`: Source of the option (`:user`, `:default`, or `:computed`)

# Example
```julia-repl
julia> Options.source(opts, :max_iter)
:user
```

See also: [`Options.is_user`](@ref), [`Options.is_default`](@ref), [`Options.is_computed`](@ref)
"""
function Options.source(opts::StrategyOptions, key::Symbol)
    return Options.source(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Check if an option was provided by the user.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Bool`: `true` if the option was provided by the user

# Example
```julia-repl
julia> Options.is_user(opts, :max_iter)
true
```

See also: [`Options.source`](@ref), [`Options.is_default`](@ref), [`Options.is_computed`](@ref)
"""
function Options.is_user(opts::StrategyOptions, key::Symbol)
    return Options.is_user(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Check if an option is using its default value.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Bool`: `true` if the option is using its default value

# Example
```julia-repl
julia> Options.is_default(opts, :tol)
true
```

See also: [`Options.source`](@ref), [`Options.is_user`](@ref), [`Options.is_computed`](@ref)
"""
function Options.is_default(opts::StrategyOptions, key::Symbol)
    return Options.is_default(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Check if an option was computed.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Bool`: `true` if the option was computed

# Example
```julia-repl
julia> Options.is_computed(opts, :step)
true
```

See also: [`Options.source`](@ref), [`Options.is_user`](@ref), [`Options.is_default`](@ref)
"""
function Options.is_computed(opts::StrategyOptions, key::Symbol)
    return Options.is_computed(option(opts, key))
end

# ============================================================================
# Private Helper for Internal Use
# ============================================================================

"""
$(TYPEDSIGNATURES)

**Private helper function** - for internal framework use only.

Returns the raw NamedTuple of OptionValue objects from the internal storage.
This is needed for `Options.extract_raw_options` which requires access to the
full OptionValue objects, not just their `.value` fields.

!!! warning "Internal Use Only"
    This function is **not part of the public API** and may change without notice.
    External code should use the public collection interface (`pairs`, `keys`, `values`, etc.).

# Returns
- NamedTuple of `(Symbol => OptionValue)` from the internal storage
"""
_raw_options(opts::StrategyOptions) = getfield(opts, :options)

# ============================================================================
# Collection interface
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get all option names.

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- Iterator of option names (Symbols)

# Example
```julia-repl
julia> collect(keys(opts))
[:max_iter, :tol]
```

See also: [`Base.values`](@ref), [`Base.pairs`](@ref)
"""
Base.keys(opts::StrategyOptions) = keys(_raw_options(opts))
"""
$(TYPEDSIGNATURES)

Get all option values (unwrapped).

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- Generator of unwrapped option values

# Example
```julia-repl
julia> collect(values(opts))
[200, 1.0e-6]
```

See also: [`Base.keys`](@ref), [`Base.pairs`](@ref)
"""
Base.values(opts::StrategyOptions) = (Options.value(opt) for opt in values(_raw_options(opts)))
"""
$(TYPEDSIGNATURES)

Get all (name, value) pairs (values unwrapped).

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- Generator of (Symbol, value) pairs

# Example
```julia-repl
julia> collect(pairs(opts))
[:max_iter => 200, :tol => 1.0e-6]
```

See also: [`Base.keys`](@ref), [`Base.values`](@ref)
"""
Base.pairs(opts::StrategyOptions) = (k => Options.value(v) for (k, v) in pairs(_raw_options(opts)))

"""
$(TYPEDSIGNATURES)

Iterate over option values (unwrapped).

# Arguments
- `opts::StrategyOptions`: Strategy options
- `state...`: Iteration state (optional)

# Returns
- Tuple of (value, state) or `nothing` when done

# Example
```julia-repl
julia> for value in opts
           println(value)
       end
200
1.0e-6
```

See also: [`Base.keys`](@ref), [`Base.values`](@ref), [`Base.pairs`](@ref)
"""
Base.iterate(opts::StrategyOptions, state...) = begin
    result = iterate(values(_raw_options(opts)), state...)
    result === nothing && return nothing
    (opt, newstate) = result
    return (Options.value(opt), newstate)
end

"""
$(TYPEDSIGNATURES)

Get number of options.

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- `Int`: Number of options

# Example
```julia-repl
julia> length(opts)
2
```

See also: [`Base.isempty`](@ref), [`Base.haskey`](@ref)
"""
Base.length(opts::StrategyOptions) = length(_raw_options(opts))
"""
$(TYPEDSIGNATURES)

Check if options collection is empty.

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- `Bool`: `true` if no options are present

# Example
```julia-repl
julia> isempty(opts)
false
```

See also: [`Base.length`](@ref), [`Base.haskey`](@ref)
"""
Base.isempty(opts::StrategyOptions) = isempty(_raw_options(opts))
"""
$(TYPEDSIGNATURES)

Check if an option exists.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name to check

# Returns
- `Bool`: `true` if the option exists

# Example
```julia-repl
julia> haskey(opts, :max_iter)
true

julia> haskey(opts, :nonexistent)
false
```

See also: [`Base.length`](@ref), [`Base.isempty`](@ref)
"""
Base.haskey(opts::StrategyOptions, key::Symbol) = haskey(_raw_options(opts), key)

# ============================================================================
# Display
# ============================================================================

"""
$(TYPEDSIGNATURES)

Display StrategyOptions with values and their provenance sources.

This method formats the output to show each option value alongside its source
(`:user`, `:default`, or `:computed`) for complete traceability.

# Arguments
- `io::IO`: Output stream
- `::MIME"text/plain"`: MIME type for pretty printing
- `opts::StrategyOptions`: Strategy options to display

# Example
```julia-repl
julia> opts
StrategyOptions with 2 options:
  max_iter = 200  [user]
  tol = 1.0e-6  [default]
```

See also: [`Base.show`](@ref)
"""
function Base.show(io::IO, ::MIME"text/plain", opts::StrategyOptions)
    n = length(opts)
    println(io, "StrategyOptions with $n option$(n == 1 ? "" : "s"):")
    items = collect(pairs(_raw_options(opts)))
    for (i, (key, opt)) in enumerate(items)
        is_last = i == length(items)
        prefix = is_last ? "└─ " : "├─ "
        println(io, prefix, key, " = ", Options.value(opt), "  [", Options.source(opt), "]")
    end
end

"""
$(TYPEDSIGNATURES)

Compact display of StrategyOptions.

# Arguments
- `io::IO`: Output stream
- `opts::StrategyOptions`: Strategy options to display

# Example
```julia-repl
julia> print(opts)
StrategyOptions(max_iter=200, tol=1.0e-6)
```

See also: [`Base.show(::IO, ::MIME"text/plain", ::StrategyOptions)`](@ref)
"""
function Base.show(io::IO, opts::StrategyOptions)
    print(io, "StrategyOptions(")
    print(io, join(("$k=$(Options.value(v))" for (k, v) in pairs(_raw_options(opts))), ", "))
    print(io, ")")
end

# ============================================================================
# Option extraction and alias management
# ============================================================================

"""
$(TYPEDSIGNATURES)

Extract a single option from a NamedTuple using its definition, with support for aliases.

This function searches through all valid names (primary name + aliases) in the definition
to find the option value in the provided kwargs. If found, it validates the value,
checks the type, and returns an `OptionValue` with `:user` source. If not found,
returns the default value with `:default` source.

# Arguments
- `kwargs::NamedTuple`: NamedTuple containing potential option values.
- `def::OptionDefinition`: Definition defining the option to extract.

# Returns
- `(OptionValue, NamedTuple)`: Tuple containing the extracted option value and the remaining kwargs.

# Notes
- If a validator is provided in the definition, it will be called on the extracted value.
- Validators should follow the pattern `x -> condition || throw(ArgumentError("message"))`.
- If validation fails, the original exception is rethrown after logging context with `@error`.
- Type mismatches throw `Exceptions.IncorrectArgument` exceptions.
- The function removes the found option from the returned kwargs.

# Throws
- `Exceptions.IncorrectArgument`: If type mismatch between value and definition
- `Exception`: If validator function fails

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(
           name = :grid_size,
           type = Int,
           default = 100,
           description = "Grid size",
           aliases = (:n, :size)
       )
OptionDefinition(...)

julia> kwargs = (n=200, tol=1e-6, max_iter=1000)
(n = 200, tol = 1.0e-6, max_iter = 1000)

julia> opt_value, remaining = extract_option(kwargs, def)
(200 (user), (tol = 1.0e-6, max_iter = 1000))

julia> opt_value.value
200

julia> opt_value.source
:user
```
"""
function extract_option(kwargs::NamedTuple, def::OptionDefinition)
    # Try all names (primary + aliases)
    for name in all_names(def)
        if haskey(kwargs, name)
            value = kwargs[name]
            
            # Validate if validator provided
            if def.validator !== nothing
                try
                    def.validator(value)
                catch e
                    @error "Validation failed for option $(def.name) with value $value" exception=(e, catch_backtrace())
                    rethrow()
                end
            end
            
            # Type check - strict validation with exceptions
            if !isa(value, def.type)
                throw(Exceptions.IncorrectArgument(
                    "Invalid option type",
                    got="value $value of type $(typeof(value))",
                    expected="$(def.type)",
                    suggestion="Ensure the option value matches the expected type",
                    context="Option extraction for $(def.name)"
                ))
            end
            
            # Remove from kwargs
            remaining = NamedTuple(k => v for (k, v) in pairs(kwargs) if k != name)
            
            return OptionValue(value, :user), remaining
        end
    end
    
    # Not found - check if default is NotProvided
    if def.default isa NotProvidedType
        # No default and not provided by user - return NotStored to signal "don't store"
        return NotStored, kwargs
    end
    
    # Not found, return default (including nothing if that's the default)
    return OptionValue(def.default, :default), kwargs
end

"""
$(TYPEDSIGNATURES)

Extract multiple options from a NamedTuple using a vector of definitions.

This function iteratively applies `extract_option` for each definition in the vector,
building a dictionary of extracted options while progressively removing processed
options from the kwargs.

# Arguments
- `kwargs::NamedTuple`: NamedTuple containing potential option values.
- `defs::Vector{OptionDefinition}`: Vector of definitions defining options to extract.

# Returns
- `(Dict{Symbol, OptionValue}, NamedTuple)`: Dictionary mapping option names to their values, and remaining kwargs.

# Notes
- The extraction order follows the order of definitions in the vector.
- Each definition's primary name is used as the dictionary key.
- Options not found in kwargs use their definition default values.
- Validation is performed for each option using `extract_option`.

# Throws
- Any exception raised by validators in the definitions

See also: [`extract_option`](@ref), [`OptionDefinition`](@ref), [`OptionValue`](@ref)

# Example
```julia-repl
julia> using CTSolvers.Options

julia> defs = [
           OptionDefinition(name = :grid_size, type = Int, default = 100, description = "Grid size"),
           OptionDefinition(name = :tol, type = Float64, default = 1e-6, description = "Tolerance")
       ]
2-element Vector{OptionDefinition}:

julia> kwargs = (grid_size=200, max_iter=1000)
(grid_size = 200, max_iter = 1000)

julia> extracted, remaining = extract_options(kwargs, defs)
(Dict(:grid_size => 200 (user), :tol => 1.0e-6 (default)), (max_iter = 1000,))

julia> extracted[:grid_size]
200 (user)

julia> extracted[:tol]
1.0e-6 (default)
```
"""
function extract_options(kwargs::NamedTuple, defs::Vector{<:OptionDefinition})
    extracted = Dict{Symbol, OptionValue}()
    remaining = kwargs
    
    for def in defs
        opt_value, remaining = extract_option(remaining, def)
        # Only store if not NotStored (NotProvided options that weren't provided return NotStored)
        if !(opt_value isa NotStoredType)
            extracted[def.name] = opt_value
        end
    end
    
    return extracted, remaining
end

"""
$(TYPEDSIGNATURES)

Extract multiple options from a NamedTuple using a NamedTuple of definitions.

This function is similar to the Vector version but returns a NamedTuple instead
of a Dict for convenience when the definition structure is known at compile time.

# Arguments
- `kwargs::NamedTuple`: NamedTuple containing potential option values.
- `defs::NamedTuple`: NamedTuple of definitions defining options to extract.

# Returns
- `(NamedTuple, NamedTuple)`: NamedTuple of extracted options and remaining kwargs.

# Notes
- The extraction order follows the order of definitions in the NamedTuple.
- Each definition's primary name is used as the key in the returned NamedTuple.
- Options not found in kwargs use their definition default values.
- Validation is performed for each option using `extract_option`.

# Throws
- Any exception raised by validators in the definitions

See also: [`extract_option`](@ref), [`OptionDefinition`](@ref), [`OptionValue`](@ref)

# Example
```julia-repl
julia> using CTSolvers.Options

julia> defs = (
           grid_size = OptionDefinition(name = :grid_size, type = Int, default = 100, description = "Grid size"),
           tol = OptionDefinition(name = :tol, type = Float64, default = 1e-6, description = "Tolerance")
       )

julia> kwargs = (grid_size=200, max_iter=1000)
(grid_size = 200, max_iter = 1000)

julia> extracted, remaining = extract_options(kwargs, defs)
((grid_size = 200 (user), tol = 1.0e-6 (default)), (max_iter = 1000,))

julia> extracted.grid_size
200 (user)

julia> extracted.tol
1.0e-6 (default)
```
"""
function extract_options(kwargs::NamedTuple, defs::NamedTuple)
    extracted_pairs = Pair{Symbol, OptionValue}[]
    remaining = kwargs
    
    for (key, def) in pairs(defs)
        opt_value, remaining = extract_option(remaining, def)
        # Only store if not NotStored (NotProvided options that weren't provided return NotStored)
        if !(opt_value isa NotStoredType)
            push!(extracted_pairs, key => opt_value)
        end
    end
    
    extracted = NamedTuple(extracted_pairs)
    return extracted, remaining
end

"""
$(TYPEDSIGNATURES)

Extract raw option values from a NamedTuple of options, unwrapping OptionValue wrappers
and filtering out `NotProvided` values.

This utility function is useful when passing options to external builders or functions
that expect plain keyword arguments without OptionValue wrappers or undefined options.

Options with `NotProvided` values are excluded from the result, allowing external
builders to use their own defaults. Options with explicit `nothing` values are included.

# Arguments
- `options::NamedTuple`: NamedTuple containing option values (may be wrapped in OptionValue)

# Returns
- `NamedTuple`: NamedTuple with unwrapped values, excluding any `NotProvided` values

# Example
```julia-repl
julia> using CTSolvers.Options

julia> opts = (backend = OptionValue(:optimized, :user), 
               show_time = OptionValue(false, :default),
               minimize = OptionValue(nothing, :default),
               optional = OptionValue(NotProvided, :default))

julia> extract_raw_options(opts)
(backend = :optimized, show_time = false, minimize = nothing)
```

See also: [`OptionValue`](@ref), [`extract_options`](@ref), [`NotProvided`](@ref)
"""
function extract_raw_options(options::NamedTuple)
    raw_opts_dict = Dict{Symbol, Any}()
    for (k, v) in pairs(options)
        val = v isa OptionValue ? v.value : v
        # Filter out NotProvided values, but keep nothing values
        if !(val isa NotProvidedType)
            raw_opts_dict[k] = val
        end
    end
    return NamedTuple(raw_opts_dict)
end

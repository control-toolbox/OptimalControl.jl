# ============================================================================
# Unified option definition and schema
# ============================================================================

"""
$(TYPEDEF)

Unified option definition for both option extraction and strategy contracts.

This type provides a comprehensive option definition that can be used for:
- Option extraction in the Options module
- Strategy contract definition in the Strategies module
- Action schema definition

# Fields
- `name::Symbol`: Primary name of the option
- `type::Type`: Expected Julia type for the option value
- `default::Any`: Default value when the option is not provided (use `nothing` for no default)
- `description::String`: Human-readable description of the option's purpose
- `aliases::Tuple{Vararg{Symbol}}`: Alternative names for this option (default: empty tuple)
- `validator::Union{Function, Nothing}`: Optional validation function (default: `nothing`)

# Validator Contract

Validators must follow this pattern:
```julia
x -> condition || throw(ArgumentError("error message"))
```

The validator should:
- Return `true` (or any truthy value) if the value is valid
- Throw an exception (preferably `ArgumentError`) if the value is invalid
- Be a pure function without side effects

# Constructor Validation

The constructor performs the following validations:
1. Checks that `default` matches the specified `type` (unless `default` is `nothing`)
2. Runs the `validator` on the `default` value (if both are provided)

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(
           name = :max_iter,
           type = Int,
           default = 100,
           description = "Maximum number of iterations",
           aliases = (:max, :maxiter),
           validator = x -> x > 0 || throw(ArgumentError("\$x must be positive"))
       )
max_iter (max, maxiter) :: Int64
  default: 100
  description: Maximum number of iterations

julia> def.name
:max_iter

julia> def.aliases
(:max, :maxiter)

julia> all_names(def)
(:max_iter, :max, :maxiter)
```

# Throws
- `Exceptions.IncorrectArgument`: If the default value does not match the declared type
- `Exception`: If the validator function fails when applied to the default value

See also: [`all_names`](@ref), [`extract_option`](@ref), [`extract_options`](@ref)
"""
struct OptionDefinition{T}
    name::Symbol
    type::Type  # Not parameterized to allow NotProvided with any declared type
    default::T
    description::String
    aliases::Tuple{Vararg{Symbol}}
    validator::Union{Function, Nothing}
    
    function OptionDefinition{T}(;
        name::Symbol,
        type::Type,
        default::T,
        description::String,
        aliases::Tuple{Vararg{Symbol}} = (),
        validator::Union{Function, Nothing} = nothing
    ) where T
        # Validate with custom validator if provided (skip for NotProvided)
        if validator !== nothing && !(default isa NotProvidedType)
            try
                validator(default)
            catch e
                @error "Validation failed for option $name with default value $default" exception=(e, catch_backtrace())
                rethrow()
            end
        end
        
        new{T}(name, type, default, description, aliases, validator)
    end
end

# Convenience constructor that infers T from default value
function OptionDefinition(;
    name::Symbol,
    type::Type,
    default,
    description::String,
    aliases::Tuple{Vararg{Symbol}} = (),
    validator::Union{Function, Nothing} = nothing
)
    # Handle nothing default specially
    if default === nothing
        return OptionDefinition{Any}(;
            name=name,
            type=Any,
            default=nothing,
            description=description,
            aliases=aliases,
            validator=validator
        )
    end
    
    # Handle NotProvided default specially - it's always valid regardless of declared type
    if default isa NotProvidedType
        return OptionDefinition{NotProvidedType}(;
            name=name,
            type=type,
            default=default,
            description=description,
            aliases=aliases,
            validator=validator
        )
    end
    
    # Infer T from default value
    T = typeof(default)
    
    # Check type compatibility
    if !isa(default, type)
        throw(Exceptions.IncorrectArgument(
            "Type mismatch in option definition",
            got="default value $default of type $T",
            expected="value of type $type",
            suggestion="Ensure the default value matches the declared type, or adjust the type parameter",
            context="OptionDefinition constructor - validating type compatibility"
        ))
    end
    
    # Create with inferred type
    return OptionDefinition{T}(;
        name=name,
        type=type,
        default=default,
        description=description,
        aliases=aliases,
        validator=validator
    )
end

# =============================================================================
# OptionDefinition getters and introspection
# =============================================================================

"""
$(TYPEDSIGNATURES)

Get the primary name of this option definition.

# Returns
- `Symbol`: The option name

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations")

julia> name(def)
:max_iter
```

See also: [`type`](@ref), [`default`](@ref), [`aliases`](@ref)
"""
name(def::OptionDefinition) = def.name

"""
$(TYPEDSIGNATURES)

Get the expected type for this option definition.

# Returns
- `Type`: The expected type

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations")

julia> type(def)
Int64
```

See also: [`name`](@ref), [`default`](@ref)
"""
type(def::OptionDefinition) = def.type

"""
$(TYPEDSIGNATURES)

Get the default value for this option definition.

# Returns
- The default value

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations")

julia> default(def)
100
```

See also: [`name`](@ref), [`type`](@ref), [`is_required`](@ref)
"""
default(def::OptionDefinition) = def.default

"""
$(TYPEDSIGNATURES)

Get the description for this option definition.

# Returns
- `String`: The option description

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations")

julia> description(def)
"Maximum iterations"
```

See also: [`name`](@ref), [`type`](@ref)
"""
description(def::OptionDefinition) = def.description

"""
$(TYPEDSIGNATURES)

Get the validator function for this option definition.

# Returns
- `Union{Function, Nothing}`: The validator function or `nothing`

# Example
```julia-repl
julia> using CTSolvers.Options

julia> validator_fn = x -> x > 0
julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations",
                              validator=validator_fn)

julia> validator(def) === validator_fn
true
```

See also: [`has_validator`](@ref), [`name`](@ref)
"""
validator(def::OptionDefinition) = def.validator

"""
$(TYPEDSIGNATURES)

Get the aliases for this option definition.

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of alias names

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations",
                              aliases=(:max, :maxiter))

julia> aliases(def)
(:max, :maxiter)
```

See also: [`all_names`](@ref), [`name`](@ref)
"""
aliases(def::OptionDefinition) = def.aliases

"""
$(TYPEDSIGNATURES)

Check if this option is required (has no default value).

Returns `true` when the default value is `NotProvided`.

# Returns
- `Bool`: `true` if the option is required

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:input, type=String, default=NotProvided,
                              description="Input file")

julia> is_required(def)
true
```

See also: [`has_default`](@ref), [`default`](@ref)
"""
is_required(def::OptionDefinition) = def.default isa NotProvidedType

"""
$(TYPEDSIGNATURES)

Check if this option definition has a default value.

Returns `false` when the default value is `NotProvided`.

# Returns
- `Bool`: `true` if a default value is defined

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations")

julia> has_default(def)
true
```

See also: [`is_required`](@ref), [`default`](@ref)
"""
has_default(def::OptionDefinition) = !(def.default isa NotProvidedType)

"""
$(TYPEDSIGNATURES)

Check if this option definition has a validator function.

# Returns
- `Bool`: `true` if a validator is defined

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                              description="Maximum iterations",
                              validator=x -> x > 0)

julia> has_validator(def)
true
```

See also: [`validator`](@ref), [`name`](@ref)
"""
has_validator(def::OptionDefinition) = def.validator !== nothing

# Get all names (primary + aliases) for extraction
"""
$(TYPEDSIGNATURES)

Return all valid names for an option definition (primary name plus aliases).

This function is used by the extraction system to search for an option in kwargs
using all possible names (primary name and all aliases).

# Arguments
- `def::OptionDefinition`: The option definition

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing the primary name followed by all aliases

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
grid_size (n, size) :: Int64
  default: 100
  description: Grid size

julia> all_names(def)
(:grid_size, :n, :size)
```

See also: [`OptionDefinition`](@ref), [`extract_option`](@ref)
"""
all_names(def::OptionDefinition) = (def.name, def.aliases...)

# Display
"""
$(TYPEDSIGNATURES)

Display an OptionDefinition in a readable format.

Shows the option name, type, default value, and description. If aliases are present,
they are shown in parentheses after the primary name.

# Arguments
- `io::IO`: Output stream
- `def::OptionDefinition`: The option definition to display

# Example
```julia-repl
julia> using CTSolvers.Options

julia> def = OptionDefinition(
           name = :max_iter,
           type = Int,
           default = 100,
           description = "Maximum iterations",
           aliases = (:max, :maxiter)
       )
max_iter (max, maxiter) :: Int64
  default: 100
  description: Maximum iterations

julia> println(def)
max_iter (max, maxiter) :: Int64
  default: 100
  description: Maximum iterations
```

See also: [`OptionDefinition`](@ref)
"""
function Base.show(io::IO, def::OptionDefinition)
    # Show primary name with aliases if present
    if isempty(def.aliases)
        print(io, "$(def.name) :: $(def.type)")
    else
        print(io, "$(def.name) ($(join(def.aliases, ", "))) :: $(def.type)")
    end
    print(io, " (default: $(def.default))")
end

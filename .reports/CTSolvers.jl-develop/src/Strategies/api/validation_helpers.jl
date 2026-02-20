# ============================================================================
# Validation helper functions for strict/permissive mode
# ============================================================================

using DocStringExtensions

"""
$(TYPEDSIGNATURES)

Throw an error for unknown options in strict mode.

This function generates a detailed error message that includes:
- List of unrecognized options
- Available options from metadata
- Suggestions based on Levenshtein distance
- Guidance on using permissive mode

# Arguments
- `remaining::NamedTuple`: Unknown options provided by user
- `strategy_type::Type{<:AbstractStrategy}`: Strategy type being configured
- `meta::StrategyMetadata`: Strategy metadata with option definitions

# Throws
- `Exceptions.IncorrectArgument`: Always throws with detailed error message

# Example
```julia
# Internal use only - called by build_strategy_options()
_error_unknown_options_strict((unknown_opt=123,), Solvers.Ipopt, meta)
```

See also: [`build_strategy_options`](@ref), [`suggest_options`](@ref)
"""
function _error_unknown_options_strict(
    remaining::NamedTuple,
    strategy_type::Type{<:AbstractStrategy},
    meta::StrategyMetadata
)
    unknown_keys = collect(keys(remaining))
    strategy_name = string(nameof(strategy_type))
    
    # Build list of available options
    available_keys = sort(collect(keys(meta)))
    available_str = join(["  :$k" for k in available_keys], ", ")
    
    # Generate suggestions for each unknown key
    suggestions_str = ""
    for key in unknown_keys
        suggestions = suggest_options(key, strategy_type; max_suggestions=3)
        if !isempty(suggestions)
            suggestions_str *= "\nSuggestions for :$key:\n"
            for s in suggestions
                suggestions_str *= "  - $(format_suggestion(s))\n"
            end
        end
    end
    
    # Build complete error message
    message = """
    Unknown options provided for $strategy_name
    
    Unrecognized options: $unknown_keys
    
    These options are not defined in the metadata of $strategy_name.
    
    Available options:
    $available_str
    $suggestions_str
    If you are certain these options exist for the backend,
    use permissive mode:
      $strategy_name(...; mode=:permissive)
    """
    
    throw(Exceptions.IncorrectArgument(
        message,
        context="build_strategy_options - strict validation"
    ))
end

"""
$(TYPEDSIGNATURES)

Warn about unknown options in permissive mode.

This function generates a warning message that informs the user that
unvalidated options will be passed directly to the backend without validation.

# Arguments
- `remaining::NamedTuple`: Unknown options provided by user
- `strategy_type::Type{<:AbstractStrategy}`: Strategy type being configured

# Example
```julia
# Internal use only - called by build_strategy_options()
_warn_unknown_options_permissive((custom_opt=123,), Solvers.Ipopt)
```

See also: [`build_strategy_options`](@ref), [`_error_unknown_options_strict`](@ref)
"""
function _warn_unknown_options_permissive(
    remaining::NamedTuple,
    strategy_type::Type{<:AbstractStrategy}
)
    unknown_keys = collect(keys(remaining))
    strategy_name = string(nameof(strategy_type))
    
    @warn """
    Unrecognized options passed to backend
    
    Unvalidated options: $unknown_keys
    
    These options will be passed directly to the $strategy_name backend
    without validation by CTSolvers. Ensure they are correct.
    """
end

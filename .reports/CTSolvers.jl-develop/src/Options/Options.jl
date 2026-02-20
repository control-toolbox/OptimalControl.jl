"""
Generic option handling for CTModels tools and strategies.

This module provides the foundational types and functions for:
- Option value tracking with provenance
- Option schema definition with validation and aliases
- Option extraction with alias support
- Type validation and helpful error messages

The Options module is deliberately generic and has no dependencies on other
CTModels modules, making it reusable across the ecosystem.
"""
module Options

# Importing to avoid namespace pollution
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import CTBase.Exceptions

# ==============================================================================
# Include submodules
# ==============================================================================

include(joinpath(@__DIR__, "not_provided.jl"))
include(joinpath(@__DIR__, "option_value.jl"))
include(joinpath(@__DIR__, "option_definition.jl"))
include(joinpath(@__DIR__, "extraction.jl"))

# ==============================================================================
# Public API
# ==============================================================================

export NotProvided, NotProvidedType
export OptionValue, OptionDefinition, extract_option, extract_options, extract_raw_options
export all_names, aliases
export is_user, is_default, is_computed
export is_required, has_default, has_validator
export name, type, default, description, validator, value, source

end # module Options
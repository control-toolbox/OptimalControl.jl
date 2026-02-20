"""
Strategy management and registry for CTSolvers.

This module provides:
- Abstract strategy contract and interface
- Strategy registry for explicit dependency management
- Strategy building and validation utilities
- Metadata management for strategy families

The Strategies module depends on Options for option handling
but provides higher-level strategy management capabilities.
"""
module Strategies

# Importing to avoid namespace pollution
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import CTBase.Exceptions

# Using CTSolvers modules to get access to the api
using ..Options

# ==============================================================================
# Include submodules
# ==============================================================================

include(joinpath(@__DIR__, "contract", "abstract_strategy.jl"))
include(joinpath(@__DIR__, "contract", "metadata.jl"))
include(joinpath(@__DIR__, "contract", "strategy_options.jl"))

include(joinpath(@__DIR__, "api", "registry.jl"))
include(joinpath(@__DIR__, "api", "introspection.jl"))
include(joinpath(@__DIR__, "api", "bypass.jl"))
include(joinpath(@__DIR__, "api", "builders.jl"))
include(joinpath(@__DIR__, "api", "configuration.jl"))
include(joinpath(@__DIR__, "api", "utilities.jl"))
include(joinpath(@__DIR__, "api", "validation_helpers.jl"))
include(joinpath(@__DIR__, "api", "disambiguation.jl"))

# ==============================================================================
# Public API
# ==============================================================================

# Core types
export AbstractStrategy, StrategyRegistry, StrategyMetadata, StrategyOptions, OptionDefinition
export RoutedOption, BypassValue

# Type-level contract methods
export id, metadata

# Instance-level contract methods
export options

# Display and introspection
export describe

# Registry functions
export create_registry, strategy_ids, type_from_id

# Introspection functions
export option_names, option_type, option_description, option_default, option_defaults
export option_is_user, option_is_default, option_is_computed
export option_value, option_source, has_option
# export is_user, is_default, is_computed # no need to re-export
# export value, source # no need to re-export

# Builder functions
export build_strategy, build_strategy_from_method
export extract_id_from_method, option_names_from_method

# Configuration functions
export build_strategy_options, resolve_alias

# Utility functions
export filter_options, suggest_options, format_suggestion, options_dict, route_to
export bypass

end # module Strategies

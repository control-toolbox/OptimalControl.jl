"""
`CTSolvers.Orchestration` — High-level orchestration utilities
============================================================

This module provides the glue between **actions** (problem-level options)
 and **strategies** (algorithmic components) by handling option routing,
 disambiguation and helper builders.

The public API will eventually expose:
  • `route_all_options` — smart option router with disambiguation support
  • `extract_strategy_ids`, `build_strategy_to_family_map`, … — helpers used
    by the router
  • `build_strategy_from_method`, `option_names_from_method` — convenience
    wrappers for strategy construction / introspection (to be added)

Design guidelines follow `reference/16_development_standards_reference.md`:
  • Explicit registry passing, no global state
  • Type-stable, allocation-free inner loops
  • Helpful error messages with actionable hints
"""
module Orchestration

# Importing to avoid namespace pollution
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import CTBase.Exceptions

# Using CTSolvers modules to get access to the api
using ..Options
using ..Strategies

# ---------------------------------------------------------------------------
# Submodules / helper source files
# ---------------------------------------------------------------------------

include(joinpath(@__DIR__, "disambiguation.jl"))
include(joinpath(@__DIR__, "routing.jl"))

# ---------------------------------------------------------------------------
# Public API re-exports (populated incrementally)
# ---------------------------------------------------------------------------

export route_all_options
export extract_strategy_ids, build_strategy_to_family_map, build_option_ownership_map
#export build_strategy_from_method, option_names_from_method # no need to reexport

end # module Orchestration
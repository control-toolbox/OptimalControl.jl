"""
    CTSolvers

Control Toolbox Solvers (CTSolvers) - A Julia package for solving optimal control problems.

This module provides a comprehensive framework for solving optimal control problems
with a modular architecture that separates concerns and facilitates extensibility.

# Architecture Overview

CTSolvers is organized into specialized modules, each with clear responsibilities:

## Core Modules

- **Options**: Configuration and options management system
  - Option definitions and validation
  - Option extraction API
  - NotProvided sentinel for optional parameters

## Implemented Modules

- **DOCP**: Discretized Optimal Control Problem types and operations
- **Modelers**: Backend modeler implementations (Modelers.ADNLP, Modelers.Exa)
- **Optimization**: General optimization abstractions and builders
- **Orchestration**: High-level coordination and method routing
- **Strategies**: Strategy patterns for solution approaches
- **Solvers**: Solver integration and CommonSolve API

# Loading Order

Modules are loaded in dependency order to ensure all types and functions are available
when needed.

# Public API

All functions and types are accessible via qualified module paths (e.g., `CTSolvers.Options.extract_options()`).
The modular architecture ensures that:

- Types are defined where they belong
- Dependencies are explicit and minimal
- Extensions can target specific modules
- The public API remains stable and clean
- No direct exports to avoid namespace conflicts
"""
module CTSolvers

# Options module - configuration and options management
include(joinpath(@__DIR__, "Options", "Options.jl"))
using .Options

# Strategies module - strategy patterns for solution approaches
include(joinpath(@__DIR__, "Strategies", "Strategies.jl"))
using .Strategies

# Orchestration module - high-level coordination and method routing
include(joinpath(@__DIR__, "Orchestration", "Orchestration.jl"))
using .Orchestration

# Optimization module - general optimization abstractions and builders
include(joinpath(@__DIR__, "Optimization", "Optimization.jl"))
using .Optimization

# Modelers module - backend modeler implementations (Modelers.ADNLP, Modelers.Exa)
include(joinpath(@__DIR__, "Modelers", "Modelers.jl"))
using .Modelers

# DOCP module - Discretized Optimal Control Problem types and operations
include(joinpath(@__DIR__, "DOCP", "DOCP.jl"))
using .DOCP

# Solvers module - optimization solver implementations and CommonSolve API
include(joinpath(@__DIR__, "Solvers", "Solvers.jl"))
using .Solvers

end
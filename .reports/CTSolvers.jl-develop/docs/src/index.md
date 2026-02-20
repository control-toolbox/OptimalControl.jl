# CTSolvers.jl

```@meta
CurrentModule = CTSolvers
```

The `CTSolvers.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).
It provides the **solution layer** for optimal control problems:

- **Options** — flexible configuration with provenance tracking and validation
- **Strategies** — two-level contract pattern for configurable components
- **Orchestration** — automatic option routing across multi-strategy pipelines
- **Optimization** — abstract problem types and callable builder pattern
- **Modelers** — NLP backend adapters (ADNLPModels, ExaModels)
- **DOCP** — discretized optimal control problem types
- **Solvers** — NLP solver integration (Ipopt, MadNLP, Knitro) via tag dispatch

!!! info "CTSolvers vs CTModels"
    **CTSolvers** focuses on **solving** optimal control problems (discretization, NLP backends, optimization strategies).
    For **defining** these problems and representing their solutions,
    see [CTModels.jl](https://github.com/control-toolbox/CTModels.jl).

!!! note
    The root package is [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) which aims
    to provide tools to model and solve optimal control problems with ordinary differential equations
    by direct and indirect methods, both on CPU and GPU.

!!! warning "Qualified Module Access"
    CTSolvers does **not** export functions directly. All functions and types are accessed
    via qualified module paths:

    ```julia
    using CTSolvers
    CTSolvers.Options.extract_options(kwargs, defs)   # ✓ Qualified
    CTSolvers.Strategies.id(Solvers.Ipopt)              # ✓ Qualified
    ```

## Modules

| Module | Purpose |
|--------|---------|
| `Options` | Option definition, extraction, validation, provenance tracking |
| `Strategies` | Abstract strategy contract, metadata, options, registry |
| `Orchestration` | Option routing, disambiguation, method tuple handling |
| `Optimization` | Abstract problem types, builder pattern, build/solve API |
| `Modelers` | Modelers.ADNLP, Modelers.Exa — NLP backend adapters |
| `DOCP` | DiscretizedModel — concrete problem type |
| `Solvers` | Solvers.Ipopt, Solvers.MadNLP, Solvers.Knitro — NLP solver wrappers |

## Documentation

### Developer Guides

- [Architecture](@ref) — module overview, type hierarchy, data flow
- [Options System](@ref) — OptionDefinition, OptionValue, extraction, validation modes
- [Implementing a Strategy](@ref) — two-level contract, metadata, StrategyOptions, registry
- [Implementing a Solver](@ref) — tag dispatch, extension pattern, CommonSolve integration
- [Implementing a Modeler](@ref) — callable contracts, builder interaction
- [Implementing an Optimization Problem](@ref) — builder pattern, DOCP example
- [Orchestration and Routing](@ref) — method tuples, auto-routing, disambiguation
- [Error Messages Reference](@ref) — all exception types with examples and fixes

### API Reference

Auto-generated documentation for all public and private symbols, organized by module.

## Quick Start

```julia
using CTSolvers
using NLPModelsIpopt  # loads the Ipopt extension

# Create a solver with validated options
solver = CTSolvers.Solvers.Ipopt(max_iter = 1000, tol = 1e-8)

# Create a modeler
modeler = CTSolvers.Modelers.ADNLP(backend = :optimized)

# Solve (high-level API)
using CommonSolve
solution = solve(problem, initial_guess, modeler, solver; display = false)
```
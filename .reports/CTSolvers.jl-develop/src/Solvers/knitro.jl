# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for Knitro-specific implementation dispatch.
"""
struct KnitroTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
# ============================================================================

"""
$(TYPEDEF)

Commercial optimization solver with advanced algorithms.

Knitro is a commercial solver offering state-of-the-art algorithms for
nonlinear optimization, including interior point, active set, and SQP methods.
It provides excellent performance and robustness for large-scale problems.

# Fields

$(TYPEDFIELDS)

# Solver Options

Solver options are defined in the CTSolversKnitro extension.
Load the extension to access option definitions and documentation:
```julia
using NLPModelsKnitro
```

# Examples

```julia
# Load the extension first
using NLPModelsKnitro

# Create solver with default options
solver = Knitro()

# Create solver with custom options
solver = Knitro(maxit=1000, maxtime=3600, ftol=1e-10, outlev=2)

# Solve an NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `NLPModelsKnitro` package:
```julia
using NLPModelsKnitro
```

**Note:** Knitro is a commercial solver requiring a valid license.

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversKnitro extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::Knitro)(nlp; display=true)` provided by extension
- Requires valid Knitro license for operation

See also: [`AbstractNLPSolver`](@ref), [`Ipopt`](@ref), [`MadNLP`](@ref)
"""
struct Knitro <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for Knitro.
"""
Strategies.id(::Type{<:Solvers.Knitro}) = :knitro

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a Knitro with specified options.

Requires the CTSolversKnitro extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Examples
```julia
using NLPModelsKnitro

# Strict mode (default) - rejects unknown options
solver = Knitro(maxit=1000, outlev=2)

# Permissive mode - accepts unknown options with warning
solver = Knitro(maxit=1000, custom_option=123; mode=:permissive)
```

# Throws
- `Strategies.Exceptions.ExtensionError`: If the NLPModelsKnitro extension is not loaded
"""
function Solvers.Knitro(; mode::Symbol=:strict, kwargs...)
    return build_knitro_solver(KnitroTag(); mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversKnitro extension is not loaded.
Real implementation provided by the extension.

# Throws
- `Strategies.Exceptions.ExtensionError`: Always thrown by this stub implementation
"""
function build_knitro_solver(::AbstractTag; kwargs...)
    throw(Exceptions.ExtensionError(
        :NLPModelsKnitro;
        message="to create Knitro, access options, and solve problems",
        feature="Knitro functionality",
        context="Load NLPModelsKnitro extension first: using NLPModelsKnitro"
    ))
end

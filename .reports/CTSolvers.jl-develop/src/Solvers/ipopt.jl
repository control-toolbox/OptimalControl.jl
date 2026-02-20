# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for Ipopt-specific implementation dispatch.
"""
struct IpoptTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
# ============================================================================

"""
$(TYPEDEF)

Interior point optimization solver using the Ipopt backend.

Ipopt (Interior Point OPTimizer) is an open-source software package for large-scale
nonlinear optimization. It implements a primal-dual interior point method with proven
global convergence properties.

# Fields

$(TYPEDFIELDS)

# Solver Options

Solver options are defined in the CTSolversIpopt extension.
Load the extension to access option definitions and documentation:
```julia
using NLPModelsIpopt
```

# Examples

```julia
# Load the extension first
using NLPModelsIpopt

# Create solver with default options
solver = Ipopt()

# Create solver with custom options
solver = Ipopt(max_iter=1000, tol=1e-6, print_level=3)

# Solve an NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `NLPModelsIpopt` package to be loaded:
```julia
using NLPModelsIpopt
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversIpopt extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::Ipopt)(nlp; display=true)` provided by extension

See also: [`AbstractNLPSolver`](@ref), [`MadNLP`](@ref), [`Knitro`](@ref)
"""
struct Ipopt <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for Ipopt.
"""
Strategies.id(::Type{<:Solvers.Ipopt}) = :ipopt

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create an Ipopt with specified options.

Requires the CTSolversIpopt extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Examples
```julia
using NLPModelsIpopt

# Strict mode (default) - rejects unknown options
solver = Ipopt(max_iter=1000, tol=1e-6)

# Permissive mode - accepts unknown options with warning
solver = Ipopt(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `Strategies.Exceptions.ExtensionError`: If the NLPModelsIpopt extension is not loaded
"""
function Solvers.Ipopt(; mode::Symbol=:strict, kwargs...)
    return build_ipopt_solver(IpoptTag(); mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversIpopt extension is not loaded.
Real implementation provided by the extension.

# Throws
- `Strategies.Exceptions.ExtensionError`: Always thrown by this stub implementation
"""
function build_ipopt_solver(::AbstractTag; kwargs...)
    throw(Exceptions.ExtensionError(
        :NLPModelsIpopt;
        message="to create Ipopt, access options, and solve problems",
        feature="Ipopt functionality",
        context="Load NLPModelsIpopt extension first: using NLPModelsIpopt"
    ))
end

# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for MadNLP-specific implementation dispatch.
"""
struct MadNLPTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
# ============================================================================

"""
$(TYPEDEF)

Pure-Julia interior point solver with GPU support.

MadNLP is a modern implementation of an interior point method written entirely in Julia,
with support for GPU acceleration and various linear solver backends. It provides excellent
performance for large-scale optimization problems.

# Fields

$(TYPEDFIELDS)

# Solver Options

- `max_iter::Integer`: Maximum number of iterations (default: 3000, must be ≥ 0)
- `tol::Real`: Convergence tolerance (default: 1e-8, must be > 0)
- `print_level::MadNLP.LogLevels`: MadNLP log level (default: MadNLP.INFO)
  - MadNLP.DEBUG: Detailed debugging output
  - MadNLP.INFO: Standard informational output
  - MadNLP.WARN: Warning messages only
  - MadNLP.ERROR: Error messages only
- `linear_solver::Type{<:MadNLP.AbstractLinearSolver}`: Linear solver backend (default: MadNLPMumps.MumpsSolver)

# Examples

```julia
# Create solver with default options
solver = MadNLP()

# Create solver with custom options
using MadNLP, MadNLPMumps
solver = MadNLP(max_iter=1000, tol=1e-6, print_level=MadNLP.DEBUG)

# Solve an NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `MadNLP` and `MadNLPMumps` packages:
```julia
using MadNLP, MadNLPMumps
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id`, `Strategies.metadata`, and `Strategies.options`
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::MadNLP)(nlp; display=true)`
- Supports GPU acceleration when appropriate backends are loaded

See also: [`AbstractNLPSolver`](@ref), [`Ipopt`](@ref), [`Solvers.MadNCL`](@ref)
"""
struct MadNLP <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for MadNLP.
"""
Strategies.id(::Type{<:Solvers.MadNLP}) = :madnlp

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a MadNLP with specified options.

Requires the CTSolversMadNLP extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Examples
```julia
using MadNLP, MadNLPMumps

# Strict mode (default) - rejects unknown options
solver = MadNLP(max_iter=1000, tol=1e-6)

# Permissive mode - accepts unknown options with warning
solver = MadNLP(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `Strategies.Exceptions.ExtensionError`: If the MadNLP extension is not loaded
"""
function Solvers.MadNLP(; mode::Symbol=:strict, kwargs...)
    return build_madnlp_solver(MadNLPTag(); mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversMadNLP extension is not loaded.
Real implementation provided by the extension.

# Throws
- `Strategies.Exceptions.ExtensionError`: Always thrown by this stub implementation
"""
function build_madnlp_solver(::AbstractTag; kwargs...)
    throw(Exceptions.ExtensionError(
        :MadNLP, :MadNLPMumps;
        message="to create MadNLP, access options, and solve problems",
        feature="MadNLP functionality",
        context="Load MadNLP extension first: using MadNLP, MadNLPMumps"
    ))
end

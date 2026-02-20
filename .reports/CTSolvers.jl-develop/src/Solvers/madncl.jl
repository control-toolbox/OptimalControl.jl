# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for MadNCL-specific implementation dispatch.
"""
struct MadNCLTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
# ============================================================================

"""
$(TYPEDEF)

NCL (Non-Convex Lagrangian) variant of MadNLP solver.

MadNCL extends MadNLP with specialized handling for non-convex problems
using a modified Lagrangian approach, providing improved convergence for
challenging nonlinear optimization problems.

# Fields

$(TYPEDFIELDS)

# Solver Options

Solver options are defined in the CTSolversMadNCL extension.
Load the extension to access option definitions and documentation:
```julia
using MadNCL, MadNLP, MadNLPMumps
```

# Examples

```julia
# Load the extension first
using MadNCL, MadNLP, MadNLPMumps

# Create solver with default options
solver = Solvers.MadNCL()

# Create solver with custom options
solver = Solvers.MadNCL(max_iter=1000, tol=1e-6, print_level=MadNLP.DEBUG)

# Solve an NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `MadNCL`, `MadNLP` and `MadNLPMumps` packages:
```julia
using MadNCL, MadNLP, MadNLPMumps
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversMadNCL extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::Solvers.MadNCL)(nlp; display=true)` provided by extension
- Specialized for non-convex optimization problems

See also: [`AbstractNLPSolver`](@ref), [`Solvers.MadNLP`](@ref), [`Solvers.Ipopt`](@ref)
"""
struct MadNCL <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for Solvers.MadNCL.
"""
Strategies.id(::Type{<:Solvers.MadNCL}) = :madncl

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a Solvers.MadNCL with specified options.

Requires the CTSolversMadNCL extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Examples
```julia
using MadNCL, MadNLP, MadNLPMumps

# Strict mode (default) - rejects unknown options
solver = Solvers.MadNCL(max_iter=1000, tol=1e-6)

# Permissive mode - accepts unknown options with warning
solver = Solvers.MadNCL(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `Strategies.Exceptions.ExtensionError`: If the MadNCL extension is not loaded
"""
function Solvers.MadNCL(; mode::Symbol=:strict, kwargs...)
    return build_madncl_solver(MadNCLTag(); mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversMadNCL extension is not loaded.
Real implementation provided by the extension.

# Throws
- `Strategies.Exceptions.ExtensionError`: Always thrown by this stub implementation
"""
function build_madncl_solver(::AbstractTag; kwargs...)
    throw(Exceptions.ExtensionError(
        :MadNCL, :MadNLP, :MadNLPMumps;
        message="to create MadNCL, access options, and solve problems",
        feature="MadNCL functionality",
        context="Load MadNCL extension first: using MadNCL, MadNLP, MadNLPMumps"
    ))
end

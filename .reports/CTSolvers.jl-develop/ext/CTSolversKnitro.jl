"""
CTSolversKnitro Extension

Extension providing Knitro solver metadata, constructor, and backend interface.
Implements the complete Solvers.Knitro functionality with proper option definitions.
"""
module CTSolversKnitro

import DocStringExtensions: TYPEDSIGNATURES
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTBase.Exceptions
import NLPModelsKnitro
import NLPModels
import SolverCore

# ============================================================================
# Metadata Definition
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining Knitro options and their specifications.
"""
function Strategies.metadata(::Type{<:Solvers.Knitro})
    return Strategies.StrategyMetadata(
        # ====================================================================
        # TERMINATION OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:maxit,
            type=Integer,
            default=1000,
            description="Maximum number of iterations before termination",
            aliases=(:max_iter, :maxiter),
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid maxit value",
                got="maxit=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Provide a non-negative value for maximum iterations",
                context="Knitro maxit validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:maxtime,
            type=Real,
            default=1e8,
            description="Maximum allowable real time in seconds before termination",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid maxtime value",
                got="maxtime=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive time limit in seconds (e.g., 3600 for 1 hour)",
                context="Knitro maxtime validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:maxfevals,
            type=Integer,
            default=-1,
            description="Maximum number of function evaluations before termination (-1 for unlimited)",
            validator=x -> x >= -1 || throw(Exceptions.IncorrectArgument(
                "Invalid maxfevals value",
                got="maxfevals=$x",
                expected="integer >= -1 (-1 for unlimited)",
                suggestion="Use -1 for unlimited or positive integer for limit",
                context="Knitro maxfevals validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:feastol_abs,
            type=Real,
            default=1e-8,
            description="Absolute feasibility tolerance for successful termination",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid feastol_abs value",
                got="feastol_abs=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-8 for standard tolerance or smaller for stricter feasibility",
                context="Knitro feastol_abs validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:opttol_abs,
            type=Real,
            default=1e-8,
            description="Absolute optimality tolerance for KKT error",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid opttol_abs value",
                got="opttol_abs=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-8 for standard tolerance or smaller for stricter optimality",
                context="Knitro opttol_abs validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:ftol,
            type=Real,
            default=1e-12,
            description="Relative change tolerance for objective function",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid ftol value",
                got="ftol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-12 for standard tolerance or smaller for stricter convergence",
                context="Knitro ftol validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:xtol,
            type=Real,
            default=1e-12,
            description="Relative change tolerance for solution point estimate",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid xtol value",
                got="xtol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-12 for standard tolerance or smaller for stricter convergence",
                context="Knitro xtol validation"
            ))
        ),
        
        # ====================================================================
        # ALGORITHM OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:soltype,
            type=Integer,
            default=0,
            description="Solution type returned by Knitro (0=final, 1=bestfeas)",
            validator=x -> x in [0, 1] || throw(Exceptions.IncorrectArgument(
                "Invalid soltype value",
                got="soltype=$x",
                expected="0 (final) or 1 (bestfeas)",
                suggestion="Use 0 for final solution or 1 for best feasible encountered",
                context="Knitro soltype validation"
            ))
        ),
        
        # ====================================================================
        # OUTPUT OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:outlev,
            type=Integer,
            default=2,
            description="Controls the level of output produced by Knitro",
            aliases=(:print_level, ),
            validator=x -> (0 <= x <= 6) || throw(Exceptions.IncorrectArgument(
                "Invalid outlev value",
                got="outlev=$x",
                expected="integer between 0 and 6",
                suggestion="Use 0 for no output, 2 for every 10 iterations, 3 for each iteration, or higher for more details",
                context="Knitro outlev validation"
            ))
        )
    )
end

# ============================================================================
# Constructor Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a Knitro with validated options.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Options to pass to the Knitro constructor

# Examples
```julia-repl
# Strict mode (default) - rejects unknown options
julia> solver = build_knitro_solver(KnitroTag; max_iter=1000)
Knitro(...)

# Permissive mode - accepts unknown options with warning
julia> solver = build_knitro_solver(KnitroTag; max_iter=1000, custom_option=123; mode=:permissive)
Knitro(...)  # with warning about custom_option
```
"""
function Solvers.build_knitro_solver(::Solvers.KnitroTag; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(Solvers.Knitro; mode=mode, kwargs...)
    return Solvers.Knitro(opts)
end

# ============================================================================
# Callable Interface with Display Handling
# ============================================================================

"""
$(TYPEDSIGNATURES)

Solve an NLP problem using Knitro.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics
"""
function (solver::Solvers.Knitro)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::SolverCore.GenericExecutionStats
    options = Strategies.options_dict(solver)
    options[:outlev] = display ? options[:outlev] : 0
    return solve_with_knitro(nlp; options...)
end

# ============================================================================
# Backend Solver Interface
# ============================================================================

"""
$(TYPEDSIGNATURES)

Backend interface for Knitro solver.

Calls NLPModelsKnitro to solve the NLP problem.
"""
function solve_with_knitro(
    nlp::NLPModels.AbstractNLPModel;
    kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsKnitro.KnitroSolver(nlp; kwargs...)
    return NLPModelsKnitro.solve!(solver, nlp)
end

end

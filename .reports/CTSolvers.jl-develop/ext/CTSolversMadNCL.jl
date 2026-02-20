"""
CTSolversMadNCL Extension

Extension providing MadNCL solver metadata, constructor, and backend interface.
Implements the complete Solvers.MadNCL functionality with proper option definitions.
"""
module CTSolversMadNCL

import DocStringExtensions: TYPEDSIGNATURES
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Optimization
import CTBase.Exceptions
import MadNCL
import MadNLP
import MadNLPMumps
import NLPModels
import SolverCore

# ============================================================================
# Helper Functions
# ============================================================================

"""
$(TYPEDSIGNATURES)

Extract the base floating-point type from NCLOptions type parameter.
"""
base_type(::MadNCL.NCLOptions{BaseType}) where {BaseType<:AbstractFloat} = BaseType

# ============================================================================
# Metadata Definition
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining MadNCL options and their specifications.
"""
function Strategies.metadata(::Type{<:Solvers.MadNCL})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:max_iter,
            type=Integer,
            default=1000,
            description="Maximum number of augmented Lagrangian iterations",
            aliases=(:maxiter,),
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_iter value",
                got="max_iter=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Provide a non-negative value for maximum iterations",
                context="MadNCL max_iter validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:tol,
            type=Real,
            default=1e-8,
            description="Optimality tolerance",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid tolerance value",
                got="tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
                context="MadNCL tol validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:print_level,
            type=MadNLP.LogLevels,
            default=MadNLP.INFO,
            description="MadNCL/MadNLP logging level"
        ),
        Strategies.OptionDefinition(;
            name=:linear_solver,
            type=Type{<:MadNLP.AbstractLinearSolver},
            default=MadNLPMumps.MumpsSolver,
            description="Linear solver implementation used inside MadNCL"
        ),
        # ---- Termination options ----
        Strategies.OptionDefinition(;
            name=:acceptable_tol,
            type=Real,
            default=Options.NotProvided,
            description="Relaxed tolerance for acceptable solution. If optimality error stays below this for 'acceptable_iter' iterations, algorithm terminates with SOLVED_TO_ACCEPTABLE_LEVEL.",
            aliases=(:acc_tol,),
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid acceptable_tol value",
                got="acceptable_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive tolerance (typically 1e-6)",
                context="MadNCL acceptable_tol validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:acceptable_iter,
            type=Integer,
            default=Options.NotProvided,
            description="Number of consecutive iterations with acceptable (but not optimal) error required before accepting the solution.",
            validator=x -> x >= 1 || throw(Exceptions.IncorrectArgument(
                "Invalid acceptable_iter value",
                got="acceptable_iter=$x",
                expected="positive integer (>= 1)",
                suggestion="Provide a positive integer (typically 15)",
                context="MadNCL acceptable_iter validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:max_wall_time,
            type=Real,
            default=Options.NotProvided,
            description="Maximum wall-clock time limit in seconds. Algorithm terminates with MAXIMUM_WALLTIME_EXCEEDED if exceeded.",
            aliases=(:max_time,),
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_wall_time value",
                got="max_wall_time=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive time limit in seconds",
                context="MadNCL max_wall_time validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:diverging_iterates_tol,
            type=Real,
            default=Options.NotProvided,
            description="NLP error threshold above which algorithm is declared diverging. Terminates with DIVERGING_ITERATES status.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid diverging_iterates_tol value",
                got="diverging_iterates_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a large positive value (typically 1e20)",
                context="MadNCL diverging_iterates_tol validation"
            ))
        ),
        # ---- NLP Scaling Options ----
        Strategies.OptionDefinition(;
            name=:nlp_scaling,
            type=Bool,
            default=Options.NotProvided,
            description="Whether to scale the NLP problem. If true, MadNLP automatically scales the objective and constraints."
        ),
        Strategies.OptionDefinition(;
            name=:nlp_scaling_max_gradient,
            type=Real,
            default=Options.NotProvided,
            description="Maximum allowed gradient value when scaling the NLP problem. Used to prevent excessive scaling.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid nlp_scaling_max_gradient value",
                got="nlp_scaling_max_gradient=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (typically 100.0)",
                context="MadNCL nlp_scaling_max_gradient validation"
            ))
        ),
        # ---- Structural Options ----
        Strategies.OptionDefinition(;
            name=:jacobian_constant,
            type=Bool,
            default=Options.NotProvided,
            description="Whether the Jacobian of the constraints is constant (i.e., linear constraints). Can improve performance.",
            aliases=(:jacobian_cst,)
        ),
        Strategies.OptionDefinition(;
            name=:hessian_constant,
            type=Bool,
            default=Options.NotProvided,
            description="Whether the Hessian of the Lagrangian is constant (i.e., quadratic objective with linear constraints). Can improve performance.",
            aliases=(:hessian_cst,)
        ),
        # ---- Initialization Options ----
        Strategies.OptionDefinition(;
            name=:bound_push,
            type=Real,
            default=Options.NotProvided,
            description="Amount by which the initial point is pushed inside the bounds to ensure strictly interior starting point.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid bound_push value",
                got="bound_push=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (e.g., 0.01)",
                context="MadNCL bound_push validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:bound_fac,
            type=Real,
            default=Options.NotProvided,
            description="Factor to determine how much the initial point is pushed inside the bounds.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid bound_fac value",
                got="bound_fac=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (e.g., 0.01)",
                context="MadNCL bound_fac validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:constr_mult_init_max,
            type=Real,
            default=Options.NotProvided,
            description="Maximum allowed value for the initial constraint multipliers.",
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid constr_mult_init_max value",
                got="constr_mult_init_max=$x",
                expected="non-negative real number (>= 0)",
                suggestion="Provide a non-negative value (e.g., 1000.0)",
                context="MadNCL constr_mult_init_max validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:fixed_variable_treatment,
            type=Type{<:MadNLP.AbstractFixedVariableTreatment},
            default=Options.NotProvided,
            description="Method to handle fixed variables. Options: MadNLP.MakeParameter, MadNLP.RelaxBound, MadNLP.NoFixedVariables."
        ),
        Strategies.OptionDefinition(;
            name=:equality_treatment,
            type=Type{<:MadNLP.AbstractEqualityTreatment},
            default=Options.NotProvided,
            description="Method to handle equality constraints. Options: MadNLP.EnforceEquality, MadNLP.RelaxEquality."
        ),
        # ---- Advanced Options ----
        Strategies.OptionDefinition(;
            name=:kkt_system,
            type=Union{Type{<:MadNLP.AbstractKKTSystem},UnionAll},
            default=Options.NotProvided,
            description="KKT system solver type (e.g., MadNLP.SparseKKTSystem, MadNLP.DenseKKTSystem)."
        ),
        Strategies.OptionDefinition(;
            name=:hessian_approximation,
            type=Union{Type{<:MadNLP.AbstractHessian},UnionAll},
            default=Options.NotProvided,
            description="Hessian approximation method (e.g., MadNLP.ExactHessian, MadNLP.CompactLBFGS, MadNLP.BFGS)."
        ),
        Strategies.OptionDefinition(;
            name=:inertia_correction_method,
            type=Type{<:MadNLP.AbstractInertiaCorrector},
            default=Options.NotProvided,
            description="Method for assumption of inertia correction (e.g., MadNLP.InertiaAuto, MadNLP.InertiaBased)."
        ),
        Strategies.OptionDefinition(;
            name=:mu_init,
            type=Real,
            default=Options.NotProvided,
            description="Initial value for the barrier parameter mu.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid mu_init value",
                got="mu_init=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (e.g., 1e-1)",
                context="MadNCL mu_init validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:mu_min,
            type=Real,
            default=Options.NotProvided,
            description="Minimum value for the barrier parameter mu.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid mu_min value",
                got="mu_min=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (e.g., 1e-11)",
                context="MadNCL mu_min validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:tau_min,
            type=Real,
            default=Options.NotProvided,
            description="Lower bound for the fraction-to-the-boundary parameter tau.",
            validator=x -> x > 0 && x < 1 || throw(Exceptions.IncorrectArgument(
                "Invalid tau_min value",
                got="tau_min=$x",
                expected="real number between 0 and 1 (exclusive)",
                suggestion="Provide a value between 0 and 1 (e.g., 0.99)",
                context="MadNCL tau_min validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:ncl_options,
            type=MadNCL.NCLOptions,
            default=MadNCL.NCLOptions{Float64}(;
                verbose=true,
                opt_tol=1e-8,
                feas_tol=1e-8
            ),
            description="Low-level NCLOptions structure controlling the augmented Lagrangian algorithm. 
Available fields: 
- `verbose` (Bool): Print convergence logs (default: true)
- `scaling` (Bool): Enable scaling (default: false)
- `opt_tol` (Float): Optimality tolerance (default: 1e-8)
- `feas_tol` (Float): Feasibility tolerance (default: 1e-8)
- `rho_init` (Float): Initial Augmented Lagrangian penalty (default: 10.0)
- `max_auglag_iter` (Int): Maximum number of outer iterations (default: 30)"
        )
    )
end

# ============================================================================
# Constructor Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a MadNCL with validated options.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Options to pass to the MadNCL constructor

# Examples
```julia-repl
# Strict mode (default) - rejects unknown options
julia> solver = build_madncl_solver(MadNCLTag; max_iter=1000)
MadNCL(...)

# Permissive mode - accepts unknown options with warning
julia> solver = build_madncl_solver(MadNCLTag; max_iter=1000, custom_option=123; mode=:permissive)
MadNCL(...)  # with warning about custom_option
```
"""
function Solvers.build_madncl_solver(::Solvers.MadNCLTag; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(Solvers.MadNCL; mode=mode, kwargs...)
    return Solvers.MadNCL(opts)
end

# ============================================================================
# Callable Interface with Display Handling
# ============================================================================

"""
$(TYPEDSIGNATURES)

Solve an NLP problem using MadNCL.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `MadNCL.NCLStats`: MadNCL execution statistics
"""
function (solver::Solvers.MadNCL)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::MadNCL.NCLStats
    options = Strategies.options_dict(solver)
    options[:print_level] = display ? options[:print_level] : MadNLP.ERROR
    
    # Handle ncl_options verbose flag
    if !display
        ncl_opts = options[:ncl_options]
        BaseType = base_type(ncl_opts)
        ncl_opts_dict = Dict(field => getfield(ncl_opts, field) for field in fieldnames(MadNCL.NCLOptions))
        ncl_opts_dict[:verbose] = false
        options[:ncl_options] = MadNCL.NCLOptions{BaseType}(; ncl_opts_dict...)
    end
    
    return solve_with_madncl(nlp; options...)
end

# ============================================================================
# Backend Solver Interface
# ============================================================================

"""
$(TYPEDSIGNATURES)

Backend interface for MadNCL solver.

Calls MadNCL to solve the NLP problem.
"""
function solve_with_madncl(
    nlp::NLPModels.AbstractNLPModel;
    ncl_options::MadNCL.NCLOptions,
    kwargs...
)::MadNCL.NCLStats
    solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, kwargs...)
    return MadNCL.solve!(solver)
end

# ============================================================================
# Solver Information Extraction
# ============================================================================

"""
$(TYPEDSIGNATURES)

Extract solver information from MadNCL execution statistics.

This method handles MadNCL-specific behavior:
- Objective sign depends on whether the problem is a minimization or maximization
- Status codes are MadNLP-specific (e.g., `:SOLVE_SUCCEEDED`, `:SOLVED_TO_ACCEPTABLE_LEVEL`)
- Uses the same field mapping as MadNLP since NCLStats has compatible structure

# Arguments

- `nlp_solution::MadNCL.NCLStats`: MadNCL execution statistics
- `minimize::Bool`: Whether the problem is a minimization problem or not

# Returns
- `objective`: The objective value (MadNCL returns correct sign, no flip needed)
- `iterations`: Number of iterations
- `constraints_violation`: Constraint violation measure
- `message`: Solver name ("MadNCL")
- `status`: Solver status as a Symbol
- `successful`: Whether the solve was successful

# Notes
Unlike MadNLP, MadNCL correctly handles maximization problems and returns the
objective with the correct sign. Therefore, we do NOT flip the sign for maximization.
"""
function Optimization.extract_solver_infos(
    nlp_solution::MadNCL.NCLStats,
    ::Bool,
)
    # MadNCL returns the correct objective sign (no bug like MadNLP)
    objective = nlp_solution.objective
    iterations = nlp_solution.iter
    constraints_violation = nlp_solution.primal_feas
    status = Symbol(nlp_solution.status)
    successful = (status == :SOLVE_SUCCEEDED) || (status == :SOLVED_TO_ACCEPTABLE_LEVEL)
    return objective, iterations, constraints_violation, "MadNCL", status, successful
end

end

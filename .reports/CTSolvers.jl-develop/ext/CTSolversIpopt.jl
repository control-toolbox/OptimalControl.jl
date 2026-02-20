"""
CTSolversIpopt Extension

Extension providing Ipopt solver metadata, constructor, and backend interface.
Implements the complete Solvers.Ipopt functionality with proper option definitions.
"""
module CTSolversIpopt

import DocStringExtensions: TYPEDSIGNATURES
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTBase.Exceptions
import NLPModelsIpopt
import NLPModels
import SolverCore

# ============================================================================
# Metadata Definition
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining Ipopt options and their specifications.
"""
function Strategies.metadata(::Type{<:Solvers.Ipopt})
    return Strategies.StrategyMetadata(
        # ====================================================================
        # TERMINATION OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:tol,
            type=Real,
            default=1e-8,
            description="Desired convergence tolerance (relative). Determines the convergence tolerance for the algorithm. The algorithm terminates successfully, if the (scaled) NLP error becomes smaller than this value, and if the (absolute) criteria according to dual_inf_tol, constr_viol_tol, and compl_inf_tol are met.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid tolerance value",
                got="tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
                context="Ipopt tol validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:max_iter,
            type=Integer,
            default=1000,
            description="Maximum number of iterations. The algorithm terminates with a message if the number of iterations exceeded this number.",
            aliases=(:maxiter, ),
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_iter value",
                got="max_iter=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Provide a non-negative value for maximum iterations",
                context="Ipopt max_iter validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:max_wall_time,
            type=Real,
            default=Options.NotProvided,
            description="Maximum number of walltime clock seconds. A limit on walltime clock seconds that Ipopt can use to solve one problem.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_wall_time value",
                got="max_wall_time=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive time limit in seconds (e.g., 3600 for 1 hour)",
                context="Ipopt max_wall_time validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:max_cpu_time,
            type=Real,
            default=Options.NotProvided,
            description="Maximum number of CPU seconds. A limit on CPU seconds that Ipopt can use to solve one problem.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_cpu_time value",
                got="max_cpu_time=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive CPU time limit in seconds",
                context="Ipopt max_cpu_time validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:dual_inf_tol,
            type=Real,
            default=Options.NotProvided,
            description="Desired threshold for the dual infeasibility. Absolute tolerance on the dual infeasibility. Successful termination requires that the max-norm of the (unscaled) dual infeasibility is less than this threshold.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid dual_inf_tol value",
                got="dual_inf_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1.0 for standard tolerance or smaller for stricter convergence",
                context="Ipopt dual_inf_tol validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:constr_viol_tol,
            type=Real,
            default=Options.NotProvided,
            description="Desired threshold for the constraint and variable bound violation. Absolute tolerance on the constraint and variable bound violation.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid constr_viol_tol value",
                got="constr_viol_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-4 for standard tolerance or smaller for stricter feasibility",
                context="Ipopt constr_viol_tol validation"
            ))
        ),

        Strategies.OptionDefinition(;
            name=:acceptable_tol,
            type=Real,
            default=Options.NotProvided,
            description="Acceptable convergence tolerance (relative). Determines which (scaled) optimality error is considered close enough.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid acceptable_tol value",
                got="acceptable_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Use roughly 10 orders of magnitude larger than tol",
                context="Ipopt acceptable_tol validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:acceptable_iter,
            type=Integer,
            default=Options.NotProvided,
            description="Number of \"acceptable\" iterations required to trigger termination. If the algorithm encounters this many consecutive iterations that are acceptable, it terminates.",
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid acceptable_iter value",
                got="acceptable_iter=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Use 15 (default) or 0 to disable acceptable termination",
                context="Ipopt acceptable_iter validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:diverging_iterates_tol,
            type=Real,
            default=Options.NotProvided,
            description="Threshold for maximal value of primal iterates. If any component of the primal iterates exceeds this value (in absolute terms), the optimization is aborted.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid diverging_iterates_tol value",
                got="diverging_iterates_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Use a very large number like 1e20",
                context="Ipopt diverging_iterates_tol validation"
            ))
        ),

        # ====================================================================
        # DEBUGGING OPTIONS
        # ====================================================================

        Strategies.OptionDefinition(;
            name=:derivative_test,
            type=String,
            default=Options.NotProvided,
            description="Enable derivative check. If enabled, performs a finite difference check of the derivatives.",
            validator=x -> x in ["none", "first-order", "second-order", "only-second-order"] || throw(Exceptions.IncorrectArgument(
                "Invalid derivative_test value",
                got="derivative_test='$x'",
                expected="'none', 'first-order', 'second-order', or 'only-second-order'",
                suggestion="Use 'first-order' to check gradients, or 'none' for normal operation",
                context="Ipopt derivative_test validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:derivative_test_tol,
            type=Real,
            default=Options.NotProvided,
            description="Threshold for identifying incorrect derivatives. If the relative error of the finite difference approximation exceeds this value, an error is reported.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid derivative_test_tol value",
                got="derivative_test_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-4 or similar",
                context="Ipopt derivative_test_tol validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:derivative_test_print_all,
            type=String,
            default=Options.NotProvided,
            description="Indicates whether information for all estimated derivatives should be printed.",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid derivative_test_print_all value",
                got="derivative_test_print_all='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' for verbose derivative debugging",
                context="Ipopt derivative_test_print_all validation"
            ))
        ),

        # ====================================================================
        # HESSIAN OPTIONS
        # ====================================================================

        Strategies.OptionDefinition(;
            name=:hessian_approximation,
            type=String,
            default=Options.NotProvided,
            description="Indicates what Hessian information regarding the Lagrangian function is to be used.",
            validator=x -> x in ["exact", "limited-memory"] || throw(Exceptions.IncorrectArgument(
                "Invalid hessian_approximation value",
                got="hessian_approximation='$x'",
                expected="'exact' or 'limited-memory'",
                suggestion="Use 'exact' if derivatives are available, 'limited-memory' otherwise",
                context="Ipopt hessian_approximation validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:limited_memory_update_type,
            type=String,
            default=Options.NotProvided,
            description="Quasi-Newton update method for the limited memory approximation.",
            validator=x -> x in ["bfgs", "sr1"] || throw(Exceptions.IncorrectArgument(
                "Invalid limited_memory_update_type value",
                got="limited_memory_update_type='$x'",
                expected="'bfgs' or 'sr1'",
                suggestion="Use 'bfgs' for typical problems",
                context="Ipopt limited_memory_update_type validation"
            ))
        ),

        # ====================================================================
        # WARM START OPTIONS
        # ====================================================================

        Strategies.OptionDefinition(;
            name=:warm_start_init_point,
            type=String,
            default=Options.NotProvided,
            description="Indicates whether specific warm start values should be used for the primal and dual variables.",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid warm_start_init_point value",
                got="warm_start_init_point='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' if you provide good initial guesses for all variables",
                context="Ipopt warm_start_init_point validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:warm_start_bound_push,
            type=Real,
            default=Options.NotProvided,
            description="Indicates how much the primal variables should be pushed inside the bounds for the warm start.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid warm_start_bound_push value",
                got="warm_start_bound_push=$x",
                expected="positive real number (> 0)",
                suggestion="Use a small positive value like 1e-9",
                context="Ipopt warm_start_bound_push validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:warm_start_mult_bound_push,
            type=Real,
            default=Options.NotProvided,
            description="Indicates how much the dual variables should be pushed inside the bounds for the warm start.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid warm_start_mult_bound_push value",
                got="warm_start_mult_bound_push=$x",
                expected="positive real number (> 0)",
                suggestion="Use a small positive value like 1e-9",
                context="Ipopt warm_start_mult_bound_push validation"
            ))
        ),

        # ====================================================================
        # ALGORITHM OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:mu_strategy,
            type=String,
            default="adaptive",
            description="Barrier parameter update strategy",
            validator=x -> x in ["monotone", "adaptive"] || throw(Exceptions.IncorrectArgument(
                "Invalid mu_strategy value",
                got="mu_strategy='$x'",
                expected="'monotone' or 'adaptive'",
                suggestion="Use 'adaptive' for most problems or 'monotone' for specific cases",
                context="Ipopt mu_strategy validation"
            ))
        ),

        Strategies.OptionDefinition(;
            name=:mu_init,
            type=Real,
            default=Options.NotProvided,
            description="Initial value for the barrier parameter.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid mu_init value",
                got="mu_init=$x",
                expected="positive real number (> 0)",
                suggestion="Use 0.1 (default) or smaller for closer start",
                context="Ipopt mu_init validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:mu_max_fact,
            type=Real,
            default=Options.NotProvided,
            description="Factor for maximal barrier parameter. This factor determines the upper bound on the barrier parameter.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid mu_max_fact value",
                got="mu_max_fact=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1000.0 (default)",
                context="Ipopt mu_max_fact validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:mu_max,
            type=Real,
            default=Options.NotProvided,
            description="Maximal value for barrier parameter. This option overrides the factor setting.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid mu_max value",
                got="mu_max=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e5 (default)",
                context="Ipopt mu_max validation"
            ))
        ), Strategies.OptionDefinition(;
            name=:mu_min,
            type=Real,
            default=Options.NotProvided,
            description="Minimal value for barrier parameter.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid mu_min value",
                got="mu_min=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-11 (default)",
                context="Ipopt mu_min validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:timing_statistics,
            type=String,
            default=Options.NotProvided,
            description="Indicates whether to measure time spent in components of Ipopt and NLP evaluation. The overall algorithm time is unaffected by this option.",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid timing_statistics value",
                got="timing_statistics='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' to enable component timing or 'no' to disable",
                context="Ipopt timing_statistics validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:linear_solver,
            type=String,
            default="mumps",
            description="Linear solver used for step computations. Determines which linear algebra package is to be used for the solution of the augmented linear system (for obtaining the search directions).",
            validator=x -> x in ["ma27", "ma57", "ma77", "ma86", "ma97", "pardiso", "pardisomkl", "spral", "wsmp", "mumps"] || throw(Exceptions.IncorrectArgument(
                "Invalid linear_solver value",
                got="linear_solver='$x'",
                expected="one of: ma27, ma57, ma77, ma86, ma97, pardiso, pardisomkl, spral, wsmp, mumps",
                suggestion="Use 'mumps' for general purpose, 'ma57' for robust performance, or 'pardiso' for Intel MKL",
                context="Ipopt linear_solver validation"
            ))
        ),
        
        # ====================================================================
        # OUTPUT OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:print_level,
            type=Integer,
            default=5,
            description="Ipopt output verbosity (0-12)",
            validator=x -> (0 <= x <= 12) || throw(Exceptions.IncorrectArgument(
                "Invalid print_level value",
                got="print_level=$x",
                expected="integer between 0 and 12",
                suggestion="Use 0 for no output, 5 for standard output, or 12 for maximum verbosity",
                context="Ipopt print_level validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:print_timing_statistics,
            type=String,
            default=Options.NotProvided,
            description="Switch to print timing statistics. If selected, the program will print the time spent for selected tasks. This implies timing_statistics=yes.",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid print_timing_statistics value",
                got="print_timing_statistics='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' to enable timing statistics or 'no' to disable",
                context="Ipopt print_timing_statistics validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:print_frequency_iter,
            type=Integer,
            default=Options.NotProvided,
            description="Determines at which iteration frequency the summarizing iteration output line should be printed. Summarizing iteration output is printed every print_frequency_iter iterations, if at least print_frequency_time seconds have passed since last output.",
            validator=x -> x >= 1 || throw(Exceptions.IncorrectArgument(
                "Invalid print_frequency_iter value",
                got="print_frequency_iter=$x",
                expected="integer >= 1",
                suggestion="Use 1 for every iteration, or larger values for less frequent output",
                context="Ipopt print_frequency_iter validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:print_frequency_time,
            type=Real,
            default=Options.NotProvided,
            description="Determines at which time frequency the summarizing iteration output line should be printed. Summarizing iteration output is printed if at least print_frequency_time seconds have passed since last output and the iteration number is a multiple of print_frequency_iter.",
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid print_frequency_time value",
                got="print_frequency_time=$x",
                expected="real number >= 0",
                suggestion="Use 0 for no time-based filtering, or positive value for time-based output control",
                context="Ipopt print_frequency_time validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:sb,
            type=String,
            default="yes",
            description="Suppress Ipopt banner (yes/no)",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid sb (suppress banner) value",
                got="sb='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' to suppress Ipopt banner or 'no' to show it",
                context="Ipopt sb validation"
            ))
        )
    )
end

# ============================================================================
# Constructor Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build an Ipopt with validated options.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Options to pass to the Ipopt constructor

# Examples
```julia-repl
# Strict mode (default) - rejects unknown options
julia> solver = build_ipopt_solver(IpoptTag; max_iter=1000)
Ipopt(...)

# Permissive mode - accepts unknown options with warning
julia> solver = build_ipopt_solver(IpoptTag; max_iter=1000, custom_option=123; mode=:permissive)
Ipopt(...)  # with warning about custom_option
```
"""
function Solvers.build_ipopt_solver(::Solvers.IpoptTag; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(Solvers.Ipopt; mode=mode, kwargs...)
    return Solvers.Ipopt(opts)
end

# ============================================================================
# Callable Interface with Display Handling
# ============================================================================

"""
$(TYPEDSIGNATURES)

Solve an NLP problem using Ipopt.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics
"""
function (solver::Solvers.Ipopt)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::SolverCore.GenericExecutionStats
    options = Strategies.options_dict(solver)
    options[:print_level] = display ? options[:print_level] : 0
    return solve_with_ipopt(nlp; options...)
end

# ============================================================================
# Backend Solver Interface
# ============================================================================

"""
$(TYPEDSIGNATURES)

Backend interface for Ipopt solver.

Calls NLPModelsIpopt to solve the NLP problem.
"""
function solve_with_ipopt(
    nlp::NLPModels.AbstractNLPModel;
    kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsIpopt.IpoptSolver(nlp)
    return NLPModelsIpopt.solve!(solver, nlp; kwargs...)
end

end

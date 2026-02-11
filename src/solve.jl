# Solve function
# todo: 
# - initial_guess is an option of the solve method, add aliases (init, init_guess, i)
# - put display in the canonical solve method

#
import CommonSolve
@reexport import CommonSolve: solve
import CTModels
import CTDirect
import CTSolvers

# Default options
__display() = true
__initial_guess() = nothing

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Canonical solve function
function CommonSolve.solve(
    ocp::CTModels.AbstractOptimalControlProblem,
    discretizer::CTDirect.AbstractOptimalControlDiscretizer,
    modeler::CTSolvers.AbstractOptimizationModeler,
    solver::CTSolvers.AbstractOptimizationSolver;
    display::Bool=__display(),
    initial_guess=__initial_guess(),
)::CTModels.AbstractOptimalControlSolution

    # Validate initial guess against the optimal control problem before discretization.
    normalized_init = CTModels.build_initial_guess(ocp, initial_guess)
    CTModels.validate_initial_guess(ocp, normalized_init)

    # Discretize the optimal control problem.
    discrete_problem = CTDirect.discretize(ocp, discretizer)

    # Solve the discretized optimal control problem.
    return CommonSolve.solve(
        discrete_problem, normalized_init, modeler, solver; display=display
    )
end
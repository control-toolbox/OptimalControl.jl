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
#__initial_guess() = nothing

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Canonical solve function
function CommonSolve.solve(
    ocp::CTModels.AbstractModel,
    initial_guess,
    discretizer::CTDirect.AbstractDiscretizer,
    modeler::CTSolvers.AbstractNLPModeler,
    solver::CTSolvers.AbstractNLPSolver;
    display::Bool=__display(),
)::CTModels.AbstractSolution

    # Build and validate initial guess against the optimal control problem before discretization.
    normalized_init = CTModels.build_initial_guess(ocp, initial_guess)

    # Discretize the optimal control problem.
    discrete_problem = CTDirect.discretize(ocp, discretizer)

    # Display configuration (compact, user options only)
    if display
        OptimalControl.display_ocp_configuration(
            discretizer, modeler, solver;
            display=true, show_options=true, show_sources=false,
        )
    end

    # Solve the discretized optimal control problem.
    return CommonSolve.solve(
        discrete_problem, normalized_init, modeler, solver; display=display
    )
end
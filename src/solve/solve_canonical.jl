# ============================================================================
# Layer 3: Canonical Solve - Pure Execution
# ============================================================================

# This file implements the lowest-level solve function that performs actual
# resolution with fully specified, concrete components.

import CommonSolve
@reexport import CommonSolve: solve
import CTModels
import CTDirect
import CTSolvers

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Canonical solve function - Layer 3 (Pure Execution)
# All inputs are concrete types, no defaults, no normalization
function CommonSolve.solve(
    ocp::CTModels.AbstractModel,
    initial_guess::CTModels.AbstractInitialGuess,   # Already normalized by Layer 1
    discretizer::CTDirect.AbstractDiscretizer,      # Concrete type (no Nothing)
    modeler::CTSolvers.AbstractNLPModeler,          # Concrete type (no Nothing)
    solver::CTSolvers.AbstractNLPSolver;            # Concrete type (no Nothing)
    display::Bool                                   # Explicit value (no default)
)::CTModels.AbstractSolution
    
    # 1. Discretize the optimal control problem
    discrete_problem = CTDirect.discretize(ocp, discretizer)
    
    # 2. Display configuration (compact, user options only)
    if display
        OptimalControl.display_ocp_configuration(
            discretizer, modeler, solver;
            display=true, show_options=true, show_sources=false
        )
    end
    
    # 3. Solve the discretized optimal control problem
    return CommonSolve.solve(
        discrete_problem, initial_guess, modeler, solver; display=display
    )
end
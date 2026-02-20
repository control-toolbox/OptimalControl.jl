# ============================================================================
# Layer 3: Canonical Solve - Pure Execution
# ============================================================================

# This file implements the lowest-level solve function that performs actual
# resolution with fully specified, concrete components.

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Canonical solve function - Layer 3 (Pure Execution)
# All inputs are concrete types, no defaults, no normalization

"""
$(TYPEDSIGNATURES)

Resolve an optimal control problem using fully specified, concrete components (Layer 3).

This is the lowest-level execution layer for solving an optimal control problem. It expects all
components (initial guess, discretizer, modeler, and solver) to be fully instantiated and
normalized. It discretizes the problem and passes it to the underlying `solve` pipeline.

# Arguments
- `ocp::CTModels.AbstractModel`: The optimal control problem to solve
- `initial_guess::CTModels.AbstractInitialGuess`: Normalized initial guess for the solution
- `discretizer::CTDirect.AbstractDiscretizer`: Concrete discretization strategy
- `modeler::CTSolvers.AbstractNLPModeler`: Concrete NLP modeling strategy
- `solver::CTSolvers.AbstractNLPSolver`: Concrete NLP solver strategy
- `display::Bool`: Whether to display the OCP configuration before solving

# Returns
- `CTModels.AbstractSolution`: The solution to the optimal control problem

# Example
```julia
# Conceptual usage pattern for Layer 3 solve
ocp = Model(time=:final)
# ... define OCP ...
init = CTModels.build_initial_guess(ocp, nothing)
disc = CTDirect.Collocation(grid_size=100)
mod  = CTSolvers.ADNLP()
sol  = CTSolvers.Ipopt()

solution = solve(ocp, init, disc, mod, sol; display=true)
```

See also: [`solve_explicit`](@ref), [`solve_descriptive`](@ref)
"""
function CommonSolve.solve(
    ocp::CTModels.AbstractModel,
    initial_guess::CTModels.AbstractInitialGuess,   # Already normalized by Layer 1
    discretizer::CTDirect.AbstractDiscretizer,      # Concrete type (no Nothing)
    modeler::CTSolvers.AbstractNLPModeler,          # Concrete type (no Nothing)
    solver::CTSolvers.AbstractNLPSolver;            # Concrete type (no Nothing)
    display::Bool                                   # Explicit value (no default)
)::CTModels.AbstractSolution
    
    # 1. Display configuration (compact, user options only)
    if display
        OptimalControl.display_ocp_configuration(
            discretizer, modeler, solver;
            display=true, show_options=true, show_sources=false
        )
    end
    
    # 2. Discretize the optimal control problem
    discrete_problem = CTDirect.discretize(ocp, discretizer)

    # 3. Solve the discretized optimal control problem
    return CommonSolve.solve(
        discrete_problem, initial_guess, modeler, solver; display=display
    )
end
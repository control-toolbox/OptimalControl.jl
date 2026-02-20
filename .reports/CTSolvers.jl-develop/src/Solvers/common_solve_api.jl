"""
CommonSolve API implementation for optimization solvers.

Provides unified solve interface for optimization problems at multiple levels:
1. High-level: OptimizationProblem → Solution
2. Mid-level: NLP → ExecutionStats
3. Low-level: Flexible solve with any compatible types
"""

# Default display setting
"""
$(TYPEDSIGNATURES)

Internal helper to define default display behavior.
"""
__display() = true

"""
$(TYPEDSIGNATURES)

High-level solve: Build NLP model, solve it, and build solution.

# Arguments
- `problem::Optimization.AbstractOptimizationProblem`: The optimization problem
- `initial_guess`: Initial guess for the solution
- `modeler::Modelers.AbstractNLPModeler`: Modeler to build NLP
- `solver::AbstractNLPSolver`: Solver to use
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- Solution object from the optimization problem

# Example
```julia
using CTSolvers

# Define problem, initial guess, modeler, solver
problem = ...
x0 = ...
modeler = Modelers.ADNLP()
solver = Solvers.Ipopt(max_iter=1000)

# Solve
solution = solve(problem, x0, modeler, solver, display=true)
```
"""
function CommonSolve.solve(
    problem::Optimization.AbstractOptimizationProblem,
    initial_guess,
    modeler::Modelers.AbstractNLPModeler,
    solver::AbstractNLPSolver;
    display::Bool=__display(),
)
    # Build NLP model
    nlp = Optimization.build_model(problem, initial_guess, modeler)
    
    # Solve NLP
    nlp_solution = CommonSolve.solve(nlp, solver; display=display)
    
    # Build OCP solution
    solution = Optimization.build_solution(problem, nlp_solution, modeler)
    
    return solution
end

"""
$(TYPEDSIGNATURES)

Mid-level solve: Solve NLP problem directly.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `solver::AbstractNLPSolver`: Solver to use
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.AbstractExecutionStats`: Solver execution statistics

# Example
```julia
using ADNLPModels

nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
solver = Solvers.Ipopt()
stats = solve(nlp, solver, display=false)
```
"""
function CommonSolve.solve(
    nlp::NLPModels.AbstractNLPModel,
    solver::AbstractNLPSolver;
    display::Bool=__display(),
)::SolverCore.AbstractExecutionStats
    return solver(nlp; display=display)
end

"""
$(TYPEDSIGNATURES)

Flexible solve: Allow user freedom with any compatible types.

This method provides flexibility for users to pass different types
that may be compatible with the solver's callable interface.

# Arguments
- `nlp`: Problem to solve (any type compatible with solver)
- `solver::AbstractNLPSolver`: Solver to use
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- Result from solver (type depends on solver implementation)
"""
function CommonSolve.solve(
    nlp, 
    solver::AbstractNLPSolver; 
    display::Bool=__display()
)
    return solver(nlp; display=display)
end

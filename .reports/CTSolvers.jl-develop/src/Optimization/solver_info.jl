"""
$(TYPEDSIGNATURES)

Retrieve convergence information from an NLP solution.

This function extracts standardized solver information from NLP solver execution
statistics. It returns a 6-element tuple that can be used to construct solver
metadata for optimal control solutions.

# Arguments

- `nlp_solution::SolverCore.AbstractExecutionStats`: A solver execution statistics object.
- `minimize::Bool`: Whether the problem is a minimization problem or not.

# Returns

A 6-element tuple `(objective, iterations, constraints_violation, message, status, successful)`:
- `objective::Float64`: The final objective value
- `iterations::Int`: Number of iterations performed
- `constraints_violation::Float64`: Maximum constraint violation (primal feasibility)
- `message::String`: Solver identifier string (e.g., "Ipopt/generic")
- `status::Symbol`: Termination status (e.g., `:first_order`, `:acceptable`)
- `successful::Bool`: Whether the solver converged successfully

# Example

```julia-repl
julia> using CTSolvers, SolverCore

julia> # After solving an NLP problem with a solver
julia> obj, iter, viol, msg, stat, success = extract_solver_infos(nlp_solution, minimize)
(1.23, 15, 1.0e-6, "Ipopt/generic", :first_order, true)
```
"""
function extract_solver_infos(
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::Bool, # whether the problem is a minimization problem or not
)
    objective = nlp_solution.objective
    iterations = nlp_solution.iter
    constraints_violation = nlp_solution.primal_feas
    status = nlp_solution.status
    successful = (status == :first_order) || (status == :acceptable)
    return objective, iterations, constraints_violation, "Ipopt/generic", status, successful
end
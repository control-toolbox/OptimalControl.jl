# --------------------------------------------------------------------------------------------------
# Resolution

# by order of preference
algorithmes = ()

# descent methods
algorithmes = add(algorithmes, (:descent, :bfgs, :bissection))
algorithmes = add(algorithmes, (:descent, :bfgs, :backtracking))
algorithmes = add(algorithmes, (:descent, :bfgs, :fixedstep))
algorithmes = add(algorithmes, (:descent, :gradient, :bissection))
algorithmes = add(algorithmes, (:descent, :gradient, :backtracking))
algorithmes = add(algorithmes, (:descent, :gradient, :fixedstep))

function solve(ocp::OptimalControlProblem, description...; kwargs...)
    method = getFullDescription(makeDescription(description...), algorithmes)
    # if no error before, then the method is correct: no need of else
    if :descent in method
        return solve_by_descent(ocp, method; kwargs...)
    end
end
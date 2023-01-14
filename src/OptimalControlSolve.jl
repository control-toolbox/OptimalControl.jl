# --------------------------------------------------------------------------------------------------
# Resolution

# by order of preference
algorithmes = ()

# descent methods
algorithmes = add(algorithmes, (:direct, :simple_shooting, :descent, :bfgs, :bissection))
algorithmes = add(algorithmes, (:direct, :simple_shooting, :descent, :bfgs, :backtracking))
algorithmes = add(algorithmes, (:direct, :simple_shooting, :descent, :bfgs, :fixedstep))
algorithmes = add(algorithmes, (:direct, :simple_shooting, :descent, :gradient, :bissection))
algorithmes = add(algorithmes, (:direct, :simple_shooting, :descent, :gradient, :backtracking))
algorithmes = add(algorithmes, (:direct, :simple_shooting, :descent, :gradient, :fixedstep))

function solve(prob::OptimalControlProblem, description...; kwargs...)
    method = getFullDescription(makeDescription(description...), algorithmes)
    # if no error before, then the method is correct: no need of else
    if :direct ∈ method
        if :simple_shooting ∈ method
            return solve_by_udss(prob, method; kwargs...)
        end
    end
end

function clean_description(d::Description)
    return d\(:direct, :simple_shooting)
end
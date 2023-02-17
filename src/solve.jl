# --------------------------------------------------------------------------------------------------
# Resolution

# by order of preference
algorithmes = ()

# descent methods
algorithmes = add(algorithmes, (:direct, :ADNLProblem, :ipopt))
algorithmes = add(algorithmes, (:direct, :shooting, :descent, :bfgs, :bissection))
algorithmes = add(algorithmes, (:direct, :shooting, :descent, :bfgs, :backtracking))
algorithmes = add(algorithmes, (:direct, :shooting, :descent, :bfgs, :fixedstep))
algorithmes = add(algorithmes, (:direct, :shooting, :descent, :gradient, :bissection))
algorithmes = add(algorithmes, (:direct, :shooting, :descent, :gradient, :backtracking))
algorithmes = add(algorithmes, (:direct, :shooting, :descent, :gradient, :fixedstep))

function solve(prob::OptimalControlModel, description...; 
    display::Bool=__display(),
    kwargs...)

    #
    method = getFullDescription(makeDescription(description...), algorithmes)
        
    # print chosen method
    display ? println("\nMethod = ", method) : nothing

    # if no error before, then the method is correct: no need of else
    if :direct ∈ method
        if :shooting ∈ method
            return CTDirectShooting.solve(prob, clean(method); display=display, kwargs...)
        else
            return CTDirect.solve(prob, clean(method); display=display, kwargs...)
        end
    end
end

function clean(d::Description)
    return d\(:direct, :shooting)
end
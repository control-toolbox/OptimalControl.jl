# --------------------------------------------------------------------------------------------------
# Resolution

# by order of preference
algorithmes = ()

# descent methods
algorithmes = add(algorithmes, (:direct, :adnlp, :ipopt))

"""
$(TYPEDSIGNATURES)

Solve the the optimal control problem `ocp`. 

"""
function solve(ocp::OptimalControlModel, description::Symbol...; 
    display::Bool=__display(),
    init=nothing,
    kwargs...)

    #
    method = getFullDescription(description, algorithmes)

    # todo: OptimalControlInit must be in CTBase
    #=
    if isnothing(init)
        init =  OptimalControlInit()
    elseif init isa CTBase.OptimalControlSolution
        init = OptimalControlInit(init)
    else
        OptimalControlInit(init...)
    end
    =#

    # print chosen method
    display ? println("\nMethod = ", method) : nothing

    # if no error before, then the method is correct: no need of else
    if :direct ∈ method
        return CTDirect.solve(ocp, clean(method)...; display=display, init=init, kwargs...)
    end
end

function clean(d::Description)
    return d\(:direct, )
end
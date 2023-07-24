# --------------------------------------------------------------------------------------------------
# Resolution

# by order of preference
methods = ()

# descent methods
methods = add(methods, (:direct, :adnlp, :ipopt))

"""
$(TYPEDSIGNATURES)

Solve the the optimal control problem `ocp` by the method given by the (optional) description.

# The (optional) description

You can pass a partial description.
If you give a partial description, then, if several complete descriptions contains the partial one, 
then, the method with the highest priority is chosen. The higher in the list `OptimalControl.methods`, 
the higher is the priority.

Keyword arguments:

- `display`: print or not information during the resolution
- `init`: an initial condition for the solver

!!! warning

    There is only one available method for the moment: a direct method which transforms
    the optimal control problem into a nonlinear programming problem (NLP) solved
    by `IPOPT`, thanks to the package `ADNLProblems`. The direct method comes from
    the `CTDirect` package.

!!! tip

    - To see the list of available methods, simply print `OptimalControl.methods`.
    - You can pass any other option by a pair `keyword=value` according to the chosen method.

# Examples

```julia-repl
julia> sol = solve(ocp)
julia> sol = solve(ocp, :direct)
julia> sol = solve(ocp, :direct, :ipopt)
```

"""
function solve(ocp::OptimalControlModel, description::Symbol...; 
    display::Bool=__display(),
    init=nothing,
    kwargs...)

    #
    method = getFullDescription(description, methods)

    # todo: OptimalControlInit must be in CTBase, it is for the moment in CTDirect
    
    if isnothing(init)
        init =  OptimalControlInit()
    elseif init isa CTBase.OptimalControlSolution
        init = OptimalControlInit(init)
    else
        init = OptimalControlInit(x_init=init[rg(1, ocp.state_dimension)], 
                            u_init=init[rg(ocp.state_dimension+1, ocp.state_dimension+ocp.control_dimension)],
                            v_init=init[rg(ocp.state_dimension+ocp.control_dimension+1, lastindex(init))])
    end
    

    # print chosen method
    display ? println("Method = ", method) : nothing

    # if no error before, then the method is correct: no need of else
    if :direct ∈ method
        return CTDirect.solve(ocp, clean(method)...; display=display, init=init, kwargs...)
    end
end

rg(i, j) = i == j ? i : i:j

function clean(d::Description)
    return d\(:direct, )
end
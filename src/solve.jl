# --------------------------------------------------------------------------------------------------
# Resolution

# by order of preference
algorithmes = ()

# descent methods
algorithmes = add(algorithmes, (:direct, :adnlp, :ipopt))

"""
$(TYPEDSIGNATURES)

Return the list of available methods to solve the optimal control problem.
"""
function available_methods()::Tuple{Tuple{Vararg{Symbol}}}
    return algorithmes
end

"""
$(TYPEDSIGNATURES)

Solve the the optimal control problem `ocp` by the method given by the (optional) description.

# The (optional) description

You can pass a partial description.
If you give a partial description, then, if several complete descriptions contains the partial one, 
then, the method with the highest priority is chosen. The higher in the list, 
the higher is the priority.

Keyword arguments:

- `display`: print or not information during the resolution
- `init`: an initial condition for the solver

!!! warning

    There is only one available method for the moment: a direct method which transforms
    the optimal control problem into a nonlinear programming problem (NLP) solved
    by [`Ipopt`](https://coin-or.github.io/Ipopt/), thanks to the package 
    [`ADNLPModels`](https://github.com/JuliaSmoothOptimizers/ADNLPModels.jl).
    The direct method comes from the 
    [`CTDirect`](https://github.com/control-toolbox/CTDirect.jl) package.

!!! tip

    - To see the list of available methods, simply call `available_methods()`.
    - You can pass any other option by a pair `keyword=value` according to the chosen method.

# Examples

```julia-repl
julia> sol = solve(ocp)
julia> sol = solve(ocp, :direct)
julia> sol = solve(ocp, :direct, :ipopt)
julia> sol = solve(ocp, :direct, :ipopt, display=false)
julia> sol = solve(ocp, :direct, :ipopt, display=false, init=sol)
julia> sol = solve(ocp, init=(state=[-0.5, 0.2],))
julia> sol = solve(ocp, init=(state=[-0.5, 0.2], control=0.5))
julia> sol = solve(ocp, init=(state=[-0.5, 0.2], control=0.5, variable=[1, 2]))
julia> sol = solve(ocp, init=(state=[-0.5, 0.2], control=t->6-12*t))
julia> sol = solve(ocp, init=(state=t->[-1+t, t*(t-1)], control=0.5))
julia> sol = solve(ocp, init=(state=t->[-1+t, t*(t-1)], control=t->6-12*t))
```

"""
function solve(ocp::OptimalControlModel, description::Symbol...; 
    display::Bool=__display(),
    init=nothing,
    kwargs...)

    #
    method = getFullDescription(description, available_methods())

    # todo: OptimalControlInit must be in CTBase, it is for the moment in CTDirect
    
    if isnothing(init)
        init =  OptimalControlInit()
    elseif init isa CTBase.OptimalControlSolution
        init = OptimalControlInit(init)
    else
        x_init = :state    ∈ keys(init) ? init[:state]    : nothing
        u_init = :control  ∈ keys(init) ? init[:control]  : nothing
        v_init = :variable ∈ keys(init) ? init[:variable] : nothing
        init = OptimalControlInit(x_init=x_init, u_init=u_init, v_init=v_init)
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

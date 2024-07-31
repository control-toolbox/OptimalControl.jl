# --------------------------------------------------------------------------------------------------
# Resolution
import CommonSolve: solve

# by order of preference
algorithms = ()

# descent methods
algorithms = add(algorithms, (:direct, :adnlp, :ipopt))

"""
$(TYPEDSIGNATURES)

Return the list of available methods to solve the optimal control problem.
"""
function available_methods()::Tuple{Tuple{Vararg{Symbol}}}
    return algorithms
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
    init=__ocp_init(),
    grid_size::Integer=CTDirect.__grid_size_direct(),
    display::Bool=CTDirect.__display(),
    print_level::Integer=CTDirect.__print_level_ipopt(),
    mu_strategy::String=CTDirect.__mu_strategy_ipopt(),
    max_iter::Integer=CTDirect.__max_iter(),
    tol::Real=CTDirect.__tol(),
    linear_solver::String=CTDirect.__linear_solver(),
    time_grid=nothing,
    kwargs...)

    # print chosen method
    method = getFullDescription(description, available_methods())
    #display ? println("Method = ", method) : nothing

    # if no error before, then the method is correct: no need of else
    if :direct ∈ method
    
        # build discretized OCP
        docp, nlp = direct_transcription(ocp, description, init=init, grid_size=grid_size, time_grid=time_grid)

        # solve DOCP (NB. init is already embedded in docp)
        docp_solution = CTDirect.solve_docp(docp, nlp,  display=display, print_level=print_level, mu_strategy=mu_strategy, tol=tol, max_iter=max_iter, linear_solver=linear_solver; kwargs...)

        # build and return OCP solution
        return build_solution(docp, docp_solution)
    end

end


rg(i, j) = i == j ? i : i:j

function clean(d::Description)
    return d\(:direct, )
end

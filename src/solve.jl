"""
$(TYPEDSIGNATURES)

Return the list of available methods to solve the optimal control problem.
"""
function available_methods()
    # by order of preference: from top to bottom
    methods = ()
    for method ∈ CTDirect.available_methods()
        methods = add(methods, (:direct, method...))
    end
    return methods
end

"""
$(TYPEDSIGNATURES)

Remove from the description, the Symbol that are specific to [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) and so must not 
be passed.
"""
function clean(d::Description)
    return remove(d, (:direct,))
end

"""
$(TYPEDSIGNATURES)

Solve the the optimal control problem `ocp` by the method given by the (optional) description.

# The (optional) description

You can pass a partial description.
If you give a partial description, then, if several complete descriptions contains the partial one, 
then, the method with the highest priority is chosen. The higher in the list, 
the higher is the priority. To get the list of available methods, call `available_methods()`.

Keyword arguments: you can pass any other option by a pair `keyword=value` according to the chosen method.

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
function CommonSolve.solve(ocp::OptimalControlModel, description::Symbol...; kwargs...)

    # get the full description
    method = getFullDescription(description, available_methods())

    # solve the problem
    :direct ∈ method && return CTDirect.direct_solve(ocp, clean(description)...; kwargs...)

end

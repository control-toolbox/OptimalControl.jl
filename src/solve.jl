"""
$(TYPEDSIGNATURES)

Return the list of available methods that can be used to solve the optimal control problem.
"""
function available_methods()
    # by order of preference: from top to bottom
    methods = ()
    for method in CTDirect.available_methods()
        methods = CTBase.add(methods, (:direct, method...))
    end
    return methods
end

"""
$(TYPEDSIGNATURES)

When calling the function `solve`, the user can provide a description of the method to use to solve the optimal control problem.
The description can be a partial description or a full description.
The function `solve` will find the best match from the available methods, thanks to the function `getFullDescription`.
Then, the description is cleaned by the function `clean` to remove the Symbols that are specific to 
[OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) and so must not be passed to the solver.
For instance, the Symbol `:direct` is specific to [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) and must be removed.
It must not be passed to the CTDirect.jl solver.
"""
function clean(d::CTBase.Description)
    return CTBase.remove(d, (:direct,))
end

"""
$(TYPEDSIGNATURES)

Solve the the optimal control problem `ocp` by the method given by the (optional) description.
The available methods are given by `available_methods()`.
The higher in the list, the higher is the priority.
The keyword arguments are specific to the chosen method and represent the options of the solver.

!!! note
    See the [tutorial on solving optimal control problems](@ref tutorial-solve) for more information.

# Arguments

- `ocp::OptimalControlModel`: the optimal control problem to solve.
- `description::Symbol...`: the description of the method to use to solve the problem.
- `kwargs...`: the options of the solver.

# Examples

The simplest way to solve the optimal control problem is to call the function without any argument.

```julia-rep
julia> sol = solve(ocp)
```

The method can be specified by passing the description as a Symbol. You can provide a partial description, the function will 
find the best match.

```julia-rep
julia> sol = solve(ocp, :direct)
```

The method can be specified by passing the full description as a list of Symbols.

```julia-repl
julia> sol = solve(ocp, :direct, :adnlp, :ipopt)
```

The keyword arguments are specific to the chosen method and represent the options of the solver.
For example, the keyword `display` is used to display the information of the solver.
The default value is `true`.

```julia-rep
julia> sol = solve(ocp, :direct, :ipopt, display=false)
```

The initial guess can be provided by the keyword `init`.
You can provide the initial guess for the state, control, and variable.

```julia-rep
julia> sol = solve(ocp, init=(state=[-0.5, 0.2], control=0.5))
```

!!! tip 
    For more information on how to provide the initial guess, see the [tutorial on the initial guess](@ref tutorial-initial-guess).

"""
function CommonSolve.solve(
    ocp::CTModels.Model, description::Symbol...; kwargs...
)::CTModels.Solution

    # get the full description
    method = CTBase.getFullDescription(description, available_methods())

    # solve the problem
    if :direct ∈ method
        return CTDirect.solve(ocp, clean(description)...; kwargs...)
    end
end

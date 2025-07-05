"""
$(TYPEDSIGNATURES)

Used to set the default display toggle.
The default value is true.
"""
__display() = true

"""
Return the version of the current module as a string.

This function returns the version number defined in the `Project.toml` of the package
to which the current module belongs. It uses `@__MODULE__` to infer the calling context.

# Example
```julia-repl
julia> version()   # e.g., "1.2.3"
```
"""
version() = string(pkgversion(@__MODULE__))

"""
$(TYPEDSIGNATURES)

Return the list of available methods that can be used to solve optimal control problems.
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

Solve the optimal control problem `ocp` by the method given by the (optional) description.
The get the list of available methods:
```julia-repl
julia> available_methods()
```
The higher in the list, the higher is the priority.
The keyword arguments are specific to the chosen method and represent the options of the solver.

# Arguments

- `ocp::OptimalControlModel`: the optimal control problem to solve.
- `description::Symbol...`: the description of the method used to solve the problem.
- `kwargs...`: the options of the method.

# Examples

The simplest way to solve the optimal control problem is to call the function without any argument.

```julia-repl
julia> sol = solve(ocp)
```

The method description is a list of Symbols. The default is

```julia-repl
julia> sol = solve(ocp, :direct, :adnlp, :ipopt)
```

You can provide a partial description, the function will find the best match.

```julia-repl
julia> sol = solve(ocp, :direct)
```

!!! note
    
    See the [resolution methods section](@ref manual-solve-methods) for more details about the available methods.

The keyword arguments are specific to the chosen method and correspond to the options of the different solvers.
For example, the keyword `max_iter` is an Ipopt option that may be used to set the maximum number of iterations.

```julia-repl
julia> sol = solve(ocp, :direct, :ipopt, max_iter=100)
```

!!! note
    
    See the [direct method section](@ref manual-solve-direct-method) for more details about associated options.
    These options also detailed in the [`CTDirect.solve`](@extref) documentation.
    This main `solve` method redirects to `CTDirect.solve` when the `:direct` Symbol is given in the description.
    See also the [NLP solvers section](@ref manual-solve-solvers-specific-options) for more details about Ipopt or MadNLP options.

To help the solve converge, an initial guess can be provided within the keyword `init`.
You can provide the initial guess for the state, control, and variable.

```julia-repl
julia> sol = solve(ocp, init=(state=[-0.5, 0.2], control=0.5))
```

!!! note

    See [how to set an initial guess](@ref manual-initial-guess) for more details.
"""
function CommonSolve.solve(
    ocp::CTModels.Model, description::Symbol...; display::Bool=__display(), kwargs...
)::CTModels.Solution

    # get the full description
    method = CTBase.complete(description; descriptions=available_methods())

    # display the chosen method
    if display
        print("▫ This is OptimalControl version v$(version()) running with: ")
        for (i, m) in enumerate(method)
            sep = i == length(method) ? ".\n\n" : ", "
            printstyled(string(m) * sep; color=:cyan, bold=true)
        end
    end

    # solve the problem
    if :direct ∈ method
        return CTDirect.solve(ocp, clean(description)...; display=display, kwargs...)
    end
end

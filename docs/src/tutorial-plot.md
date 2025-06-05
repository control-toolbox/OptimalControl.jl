# [How to plot a solution](@id tutorial-plot)

```@meta
Draft = false
```>

In this tutorial, we explain the different options for plotting the solution of an optimal control problem using the `plot` and `plot!` functions, which are extensions of the [Plots.jl](https://docs.juliaplots.org) package. Use `plot` to create a new plot object, and `plot!` to add to an existing one:

```julia
plot(args...; kw...)           # creates a new Plot, and set it to be the `current`
plot!(args...; kw...)          # modifies Plot `current()`
plot!(plt, args...; kw...)     # modifies Plot `plt`
```

More precisely, the signature of `plot`, to plot a solution, is as follows.

```@docs; canonical=false
plot(::CTModels.Solution, ::Symbol...)
```

## Argument Overview

The table below summarizes the main plotting arguments and links to the corresponding documentation sections for detailed explanations:

| Section                                             | Relevant Arguments                                                                            |
| :---------------------------------------------------| :-------------------------------------------------------------------------------------------- |
| [Basic concepts](@ref tutorial-plot-basic)          | `size`, `state_style`, `costate_style`, `control_style`, `time_style`, `kwargs...`            |
| [Split vs. group layout](@ref tutorial-plot-layout) | `layout`                                                                                      |
| [Plotting control norm](@ref tutorial-plot-control) | `control`                                                                                     |
| [Normalised time](@ref tutorial-plot-time)          | `time`                                                                                        |
| [Constraints](@ref tutorial-plot-constraints)       | `state_bounds_style`, `control_bounds_style`, `path_style`, `path_bounds_style`, `dual_style` |
| [What to plot](@ref tutorial-plot-select)           | `description...`                                                                              |

You can plot solutions obtained from the `solve` function or from a flow computed using an optimal control problem and a control law. See the [Basic Concepts](@ref tutorial-plot-basic) and [From Flow function](@ref tutorial-plot-flow) sections for details.

To overlay a new plot on an existing one, use the `plot!` function (see [Add a plot](@ref tutorial-plot-add)).

If you prefer full control over the visualization, you can extract the state, costate, and control to create your own plots. Refer to the [Custom plot](@ref tutorial-plot-custom) section for guidance.

## The problem and the solution

Let us start by importing the packages needed to define and solve the problem.

```@example main
using OptimalControl
using NLPModelsIpopt
```

We consider the simple optimal control problem from the [basic example page](@ref tutorial-double-integrator-energy).

```@example main
t0 = 0            # initial time
tf = 1            # final time
x0 = [ -1, 0 ]    # initial condition
xf = [  0, 0 ]    # final condition

ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == xf
    ẋ(t) == [x₂(t), u(t)]
    ∫( 0.5u(t)^2 ) → min
end

sol = solve(ocp, display=false)
nothing # hide
```

## [Basic concepts](@id tutorial-plot-basic)

The simplest way to plot the solution is to use the `plot` function with the solution as the only argument.

!!! warning

    The `plot` function for a solution of an optimal control problem extends the `plot` function from Plots. Therefore, you need to import this package in order to plot a solution.

```@example main
using Plots
plot(sol)
```

In the figure above, we have a grid of subplots: the left column displays the state component trajectories, the right column shows the costate component trajectories, and the bottom row contains the control component trajectories.

As in Plots, input data is passed positionally (for example, `sol` in `plot(sol)`), and attributes are passed as keyword arguments (for example, `plot(sol; color = :blue)`). After executing `using Plots` in the REPL, you can use the `plotattr()` function to print a list of all available attributes for series, plots, subplots, or axes.

```julia
# Valid Operations
plotattr(:Plot)
plotattr(:Series)
plotattr(:Subplot)
plotattr(:Axis)
```

Once you have the list of attributes, you can either use the aliases of a specific attribute or inspect a specific attribute to display its aliases and description.

```@repl main
plotattr("color") # Specific Attribute Example
```

!!! warning

    Some attributes have different default values in OptimalControl compared to Plots. For instance, the default figure size is 600x400 in Plots, while in OptimalControl, it depends on the number of states and controls.

You can also visit the Plot documentation online to get the descriptions of the attributes:

- To pass attributes to the plot, see the [attributes plot](https://docs.juliaplots.org/latest/generated/attributes_plot/) documentation. For instance, you can specify the size of the figure.
```@raw html
<details><summary>List of plot attributes.</summary>
```

```@example main
for a in Plots.attributes(:Plot) # hide
    println(a) # hide
end # hide
```

```@raw html
</details>
```
- You can pass attributes to all subplots at once by referring to the [attributes subplot](https://docs.juliaplots.org/latest/generated/attributes_subplot/) documentation. For example, you can specify the location of the legends.
  ```@raw html
<details><summary>List of subplot attributes.</summary>
```

```@example main
for a in Plots.attributes(:Subplot) # hide
    println(a) # hide
end # hide
```

```@raw html
</details>
```
- Similarly, you can pass axis attributes to all subplots. See the [attributes axis](https://docs.juliaplots.org/latest/generated/attributes_axis/) documentation. For example, you can remove the grid from every subplot.
```@raw html
<details><summary>List of axis attributes.</summary>
```

```@example main
for a in Plots.attributes(:Axis) # hide
    println(a) # hide
end # hide
```

```@raw html
</details>
```
- Finally, you can pass series attributes to all subplots. Refer to the [attributes series](https://docs.juliaplots.org/latest/generated/attributes_series/) documentation. For instance, you can set the width of the curves using `linewidth`.
```@raw html
<details><summary>List of series attributes.</summary>
```

```@example main
for a in Plots.attributes(:Series) # hide
    println(a) # hide
end # hide
```

```@raw html
</details>
```

```@example main
plot(sol, size=(700, 450), legend=:bottomright, grid=false, linewidth=2)
```

To specify series attributes for a specific group of subplots (state, costate or control), you can use the optional keyword arguments `state_style`, `costate_style`, and `control_style`, which correspond to the state, costate, and control trajectories, respectively.

```@example main
plot(sol; 
     state_style   = (color=:blue,),                  # style: state trajectory
     costate_style = (color=:black, linestyle=:dash), # style: costate trajectory
     control_style = (color=:red, linewidth=2))       # style: control trajectory
```

Vertical axes at the initial and final times are automatically plotted.  
Additionally, you can choose not to display the state and costate trajectories by setting their styles to `:none`.

```@example main
plot(sol; 
     state_style    = :none,             # do not plot the state
     costate_style  = :none,             # do not plot the costate
     control_style  = (color = :red,),   # plot the control in red
     time_style     = (color = :green,)) # vertical axes at initial and final times in green
```

To select what to display, you can also use the `description` argument by providing a list of symbols such as `:state`, `:costate`, and `:control`.

```@example main
plot(sol, :state, :control)  # plot the state and the control
```

!!! note "Select what to plot"

    For more details on how to choose what to plot, see the [What to plot](@ref tutorial-plot-select) section.

## [From Flow function](@id tutorial-plot-flow)

The previous solution of the optimal control problem was obtained using the `solve` function. If you prefer using an indirect shooting method and solving shooting equations, you may also want to plot the associated solution. To do this, you need to use the `Flow` function to reconstruct the solution. See the manual on [how to compute flows](@ref manual-flow) for more details. In our case, you must provide the maximizing control $(x, p) \mapsto p_2$ along with the optimal control problem. For an introduction to simple indirect shooting, see the [indirect simple shooting](https://control-toolbox.org/Tutorials.jl/stable/tutorial-iss.html) tutorial for an example.

!!! tip "Interactions with an optimal control solution"

    Please check [`state`](@ref), [`costate`](@ref), [`control`](@ref), and [`variable`](@ref) to retrieve data from the solution. The functions `state`, `costate`, and `control` return functions of time, while `variable` returns a vector.

```@example main
using OrdinaryDiffEq

p  = costate(sol)                # costate as a function of time
p0 = p(t0)                       # costate solution at the initial time
f  = Flow(ocp, (x, p) -> p[2])   # flow from an ocp and a control law

sol_flow = f( (t0, tf), x0, p0 ) # compute the solution
plot(sol_flow)                   # plot the solution from a flow
```

We may notice that the time grid contains very few points. This is evident from the subplot of $x_2$, or by retrieving the time grid directly from the solution.

```@example main
time_grid(sol_flow)
```

To improve visualization (without changing the accuracy), you can provide a finer grid.

```@example main
fine_grid = range(t0, tf, 100)
sol_flow = f( (t0, tf), x0, p0; saveat=fine_grid )
plot(sol_flow)
```

## [Split vs. group layout](@id tutorial-plot-layout)

If you prefer to get a more compact figure, you can use the `layout` optional keyword argument with `:group` value. It will group the state, costate and control trajectories in one subplot for each.

```@example main
plot(sol; layout=:group)
```
    
The default layout value is `:split` which corresponds to the grid of subplots presented above.

```@example main
plot(sol; layout=:split)
```

## [Add a plot](@id tutorial-plot-add)

You can plot the solution of a second optimal control problem on the same figure if it has the same number of states, costates and controls. For instance, consider the same optimal control problem but with a different initial condition.

```@example main
ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == [-0.5, -0.5]
    x(tf) == xf
    ẋ(t) == [x₂(t), u(t)]
    ∫( 0.5u(t)^2 ) → min
end
sol2 = solve(ocp; display=false)
nothing # hide
```

We first plot the solution of the first optimal control problem, then, we plot the solution of the second optimal control problem on the same figure, but with dashed lines.

```@example main
plt = plot(sol; label="sol1", size=(700, 500))
plot!(plt, sol2; label="sol2", linestyle=:dash)
```

## [Plotting control norm](@id tutorial-plot-control)

For some problem, it is interesting to plot the (Euclidean) norm of the control. You can do it by using the `control` optional keyword argument with `:norm` value.

```@example main
plot(sol; control=:norm, size=(800, 300), layout=:group)
```

The default value is `:components`.

```@example main
plot(sol; control=:components, size=(800, 300), layout=:group)
```

You can also plot the control and is norm.

```@example main
plot(sol; control=:all, layout=:group)
```

## [Custom plot](@id tutorial-plot-custom)

You can, of course, create your own plots by extracting the `state`, `costate`, and `control` from the optimal control solution. For instance, let us plot the norm of the control.

```@example main
using LinearAlgebra
t = time_grid(sol)
u = control(sol)
plot(t, norm∘u; label="‖u‖", xlabel="t") 
``` 

## [Normalised time](@id tutorial-plot-time)

We consider a [LQR example](https://control-toolbox.org/Tutorials.jl/stable/tutorial-lqr-basic.html) and solve the problem for different values of the final time `tf`. Then, we plot the solutions on the same figure using a normalised time $s = (t - t_0) / (t_f - t_0)$, enabled by the keyword argument `time = :normalize` (or `:normalise`) in the `plot` function.

```@example main
# definition of the problem, parameterised by the final time
function lqr(tf)

    ocp = @def begin
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [0, 1]
        ẋ(t) == [x₂(t), - x₁(t) + u(t)]
        ∫( 0.5(x₁(t)^2 + x₂(t)^2 + u(t)^2) ) → min
    end

    return ocp
end;

# solve the problems and store them
solutions = []
tfs = [3, 5, 30]
for tf ∈ tfs
    solution = solve(lqr(tf); display=false)
    push!(solutions, solution)
end

# create plots
plt = plot()
for (tf, sol) ∈ zip(tfs, solutions)
    plot!(plt, sol; time=:normalize, label="tf = $tf", xlabel="s")
end

# make a custom plot: keep only state and control
px1 = plot(plt[1]; legend=false) # x₁
px2 = plot(plt[2]; legend=true)  # x₂
pu  = plot(plt[5]; legend=false) # u    

using Plots.PlotMeasures # for leftmargin, bottommargin
plot(px1, px2, pu; layout=(1, 3), size=(800, 300), leftmargin=5mm, bottommargin=5mm)
```

## [Constraints](@id tutorial-plot-constraints)

We define an optimal control problem with constraints, solve it and plot the solution.

```@example main
ocp = @def begin
    tf ∈ R,          variable
    t ∈ [0, tf],     time
    x = (q, v) ∈ R², state
    u ∈ R,           control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1
    q(0)  == -1
    v(0)  == 0
    q(tf) == 0
    v(tf) == 0
    1 ≤ v(t)+1 ≤ 1.8, (1)
    ẋ(t) == [v(t), u(t)]
    tf → min
end
sol = solve(ocp)
plot(sol)
```

On the plot, you can see the lower and upper bounds of the path constraint. Additionally, the dual variable associated with the path constraint is displayed alongside it.

You can customise the plot styles. For style options related to the state, costate, and control, refer to the [Basic Concepts](@ref tutorial-plot-basic) section.

```@example main
plot(sol; 
     state_bounds_style = (linestyle = :dash,),
     control_bounds_style = (linestyle = :dash,),
     path_style = (color = :green,),
     path_bounds_style = (linestyle = :dash,),
     dual_style = (color = :red,),
     time_style = :none, # do not plot axes at t0 and tf
)
```

## [What to plot](@id tutorial-plot-select)

You can choose what to plot using the `description` argument. To plot only one subgroup:

```julia
plot(sol, :state)   # plot only the state
plot(sol, :costate) # plot only the costate
plot(sol, :control) # plot only the control
plot(sol, :path)    # plot only the path constraint
plot(sol, :dual)    # plot only the path constraint dual variable
```

You can combine elements to plot exactly what you need:

```@example main
plot(sol, :state, :control, :path)
```

Similarly, you can choose what not to plot passing `:none` to the corresponding style.

```julia
plot(sol; state_style=:none)   # do not plot the state
plot(sol; costate_style=:none) # do not plot the costate
plot(sol; control_style=:none) # do not plot the control
plot(sol; path_style=:none)    # do not plot the path constraint
plot(sol; dual_style=:none)    # do not plot the path constraint dual variable
```

For instance, let's plot everything except the dual variable associated with the path constraint.

```@example main
plot(sol; dual_style=:none)
```

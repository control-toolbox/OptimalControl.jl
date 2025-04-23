# [How to plot a solution](@id tutorial-plot)

In this tutorial, we explain the different options for plotting the solution of an optimal control problem using the `plot` and `plot!` functions, which are extensions of the [Plots.jl](https://docs.juliaplots.org) package. Use `plot` to create a new plot object, and `plot!` to add to an existing one:

```julia
plot(args...; kw...)           # creates a new Plot, and set it to be the `current`
plot!(args...; kw...)          # modifies Plot `current()`
plot!(plt, args...; kw...)     # modifies Plot `plt`
```

More precisely, the signature of `plot` is as follows.

```julia
function plot(
    sol;            # optimal control solution
    layout,         # layout of the subplots
    control,        # plot the norm or components of the control
    time,           # normalise the time or not
    size,           # size of the figure
    solution_label, # suffix for the labels
    state_style,    # style for the state trajectory
    costate_style,  # style for the costate trajectory
    control_style,  # style for the control trajectory
    kwargs...,      # attributes from Plots
)
```

In the following, we detail the roles of the arguments.

| Section                                                    | Arguments        |
| :------                                                    | :------          |
| [Basic concepts](@ref tutorial-plot-basic)                 | `size`, `state_style`, `costate_style`, `control_style`, `kwargs...` |
| [Split versus group layout](@ref tutorial-plot-layout)     | `layout`         |
| [Plot the norm of the control](@ref tutorial-plot-control) | `control`        |
| [Normalised time](@ref tutorial-plot-time)                 | `time`           |
| [Add a plot](@ref tutorial-plot-add)                       | `solution_label` |

You can plot a solution obtained from the `solve` function, as well as from the flow computed using an optimal control problem and a control law. See, respectively, [Basic Concepts](@ref tutorial-plot-basic) and [From Flow](@ref tutorial-plot-flow) sections for more details.

You can also retrieve the state, the costate and the control to create your own plots, see [Custom plot](@ref tutorial-plot-custom) section.

## The problem and the solution

Let us start by importing the packages needed to define and solve the problem.

```@example main
using OptimalControl
using NLPModelsIpopt
```

We consider the simple optimal control problem from the [basic example tutorial](@ref tutorial-double-integrator-energy).

```@example main
const t0 = 0            # initial time
const tf = 1            # final time
const x0 = [ -1, 0 ]    # initial condition
const xf = [  0, 0 ]    # final condition

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
- You can pass attributes to all subplots at once by referring to the [attributes subplot](https://docs.juliaplots.org/latest/generated/attributes_subplot/) documentation. For example, you can specify the location of the legends.
- Similarly, you can pass axis attributes to all subplots. See the [attributes axis](https://docs.juliaplots.org/latest/generated/attributes_axis/) documentation. For example, you can remove the grid from every subplot.
- Finally, you can pass series attributes to all subplots. Refer to the [attributes series](https://docs.juliaplots.org/latest/generated/attributes_series/) documentation. For instance, you can set the width of the curves using `linewidth`.


```@example main
plot(sol, size=(700, 450), legend=:bottomright, grid=false, linewidth=2)
```

To specify series attributes for a specific group of subplots (state, costate or control), you can use the optional keyword arguments `state_style`, `costate_style`, and `control_style`, which correspond to the state, costate, and control trajectories, respectively.

```@example main
plot(sol; 
     state_style   = (color=:blue,),                    # style of the state trajectory
     costate_style = (color=:black, linestyle=:dash),   # style of the costate trajectory
     control_style = (color=:red, linewidth=2))         # style of the control trajectory
```

## [From Flow](@id tutorial-plot-flow)

The previous solution of the optimal control problem was obtained using the `solve` function. If you prefer using an indirect shooting method and solving shooting equations, you may also want to plot the associated solution. To do this, you need to use the `Flow` function to reconstruct the solution. See the manual on [how to compute flows](@ref manual-flow) for more details. In our case, you must provide the maximizing control $(x, p) \mapsto p_2$ along with the optimal control problem. For an introduction to simple indirect shooting, see the [indirect simple shooting](@ref tutorial-indirect-simple-shooting) tutorial for an example.

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

## [Split versus group layout](@id tutorial-plot-layout)

If you prefer to get a more compact figure, you can use the `layout` optional keyword argument with `:group` value. It will group the state, costate and control trajectories in one subplot for each.

```@example main
plot(sol; layout=:group, size=(800, 300))
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
plt = plot(sol; solution_label="(sol1)", size=(700, 500))
plot!(plt, sol2; solution_label="(sol2)", linestyle=:dash)
```

## [Plot the norm of the control](@id tutorial-plot-control)

For some problem, it is interesting to plot the (Euclidean) norm of the control. You can do it by using the `control` optional keyword argument with `:norm` value.

```@example main
plot(sol; control=:norm, size=(800, 300), layout=:group)
```

The default value is `:components`.

```@example main
plot(sol; control=:components, size=(800, 300), layout=:group)
```

## [Custom plot](@id tutorial-plot-custom)

You can, of course, create your own plots by extracting the `state`, `costate`, and `control` from the optimal control solution. For instance, let us plot the norm of the control.

```@example main
using LinearAlgebra
t = time_grid(sol)
x = state(sol)
p = costate(sol)
u = control(sol)
plot(t, norm∘u; label="‖u‖") 
```

!!! note "Nota bene"

    - The `norm` function is from `LinearAlgebra.jl`. 
    - The `∘` operator is the composition operator. Hence, `norm∘u` is the function `t -> norm(u(t))`. 

## [Normalised time](@id tutorial-plot-time)

We consider a [LQR example](@ref) and solve the problem for different values of the final time `tf`. Then, we plot the solutions on the same figure using a normalized time $s = (t - t_0) / (t_f - t_0)$, enabled by the keyword argument `time = :normalize` (or `:normalise`) in the `plot` function.

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
plt = plot(solutions[1]; time=:normalize)
for sol ∈ solutions[2:end]
    plot!(plt, sol; time=:normalize)
end

# make a custom plot: keep only state and control
N = length(tfs)
px1 = plot(plt[1]; legend=false, xlabel="s", ylabel="x₁")
px2 = plot(plt[2]; label=reshape(["tf = $tf" for tf ∈ tfs], (1, N)), xlabel="s", ylabel="x₂")
pu  = plot(plt[5]; legend=false, xlabel="s", ylabel="u")

using Plots.PlotMeasures # for leftmargin, bottommargin
plot(px1, px2, pu; layout=(1, 3), size=(800, 300), leftmargin=5mm, bottommargin=5mm)
```

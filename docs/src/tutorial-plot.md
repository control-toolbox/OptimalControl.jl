# [How to plot a solution](@id tutorial-plot)

In this tutorial we explain the different ways to plot a solution of an optimal control problem.

Let us start by importing the package to define the problem and solve it.

```@example main
using OptimalControl
using NLPModelsIpopt
```

Then, we define a simple optimal control problem and solve it.

```@example main
ocp = @def begin

    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control

    x(0) == [-1, 0]
    x(1) == [0, 0]

    ẋ(t) == [x₂(t), u(t)]

    ∫( 0.5u(t)^2 ) → min

end

sol = solve(ocp, display=false)
nothing # hide
```

## First ways to plot

The simplest way to plot the solution is to use the `plot` function with only the solution as argument.

!!! note "The plot function"

    The plot function on a solution of an optimal control problem is an extension of the plot function from the package Plots.jl. Hence, we need to import this package to plot a solution.

```@example main
using Plots
plot(sol)
```

As you can see, it produces a grid of subplots. The left column contains the state trajectories, the right column the costate trajectories, and at the bottom we have the control trajectory.

Attributes from [Plots.jl](https://docs.juliaplots.org) can be passed to the `plot` function:

- In addition to `sol` you can pass attributes to the full plot, see the [attributes plot documentation](https://docs.juliaplots.org/latest/generated/attributes_plot/) from Plots.jl for more details. For instance, you can specify the size of the figure.
- You can also pass attributes to the subplots, see the [attributes subplot documentation](https://docs.juliaplots.org/latest/generated/attributes_subplot/) from Plots.jl for more details. However, it will affect all the subplots. For instance, you can specify the location of the legend.
- In the same way, you can pass axis attributes to the subplots, see the [attributes axis documentation](https://docs.juliaplots.org/latest/generated/attributes_axis/) from Plots.jl for more details. It will also affect all the subplots. For instance, you can remove the grid.
- In the same way, you can pass series attributes to the all the subplots, see the [attributes series documentation](https://docs.juliaplots.org/latest/generated/attributes_series/) from Plots.jl for more details. It will also affect all the subplots. For instance, you can set the width of the curves with `linewidth`.

```@example main
plot(sol, size=(700, 450), legend=:bottomright, grid=false, linewidth=2)
```

To specify series attributes to a specific subplot, you can use the optional keyword arguments `state_style`, `costate_style` and `control_style` which correspond respectively to the state, costate and control trajectories. See the [attribute series documentation](https://docs.juliaplots.org/latest/generated/attributes_series/) from Plots.jl for more details. For instance, you can specify the color of the state trajectories and more.

```@example main
plot(sol; 
     state_style   = (color=:blue,), 
     costate_style = (color=:black, linestyle=:dash),
     control_style = (color=:red, linewidth=2))
```

## From Flow

The previous resolution of the optimal control problem was done with the `solve` function. If you use an indirect shooting method and solve shooting equations, you may want to plot the associated solution. To do so, you need to use the `Flow` function to  reconstruct the solution. See the [Indirect Simple Shooting](@ref tutorial-indirect-simple-shooting) tutorial for an example. In our example, you must provide the maximising control $(x, p) \mapsto p_2$ together with the optimal control problem.

!!! tip "Interactions with an optimal control solution"

    Please check [`state`](@ref), [`costate`](@ref), [`control`](@ref) and [`variable`](@ref) to get data from the solution. The functions `state`, `costate` and `control` return functions of time and `variable` returns a vector.

```@example main
using OrdinaryDiffEq
t0 = 0
tf = 1
x0 = [ -1, 0 ]
p0 = costate(sol)(t0)
f  = Flow(ocp, (x, p) -> p[2])
sol_flow = f( (t0, tf), x0, p0 )
plot(sol_flow)
```

You can notice that the time grid has very few points. To have a better visualisation (the accuracy won't change), you can give a finer grid.

```@example main
sol_flow = f( (t0, tf), x0, p0; saveat=range(t0, tf, 100) )
plot(sol_flow)
```

## Split versus group layout

If you prefer to get a more compact figure, you can use the `layout` optional keyword argument with `:group` value. It will group the state, costate and control trajectories in one subplot for each.

```@example main
plot(sol; layout=:group, size=(800, 300))
```

!!! note "Default layout value"

    The default layout value is `:split` which corresponds to the grid of subplots presented above.

## Additional plots

You can plot the solution of a second optimal control problem on the same figure if it has the same number of states, costates and controls. For instance, consider the same optimal control problem but with a different initial condition.

```@example main
ocp = @def begin

    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control

    x(0) == [-0.5, -0.5]
    x(1) == [0, 0]

    ẋ(t) == [x₂(t), u(t)]

    ∫( 0.5u(t)^2 ) → min

end
sol2 = solve(ocp; display=false)
nothing # hide
```

We first plot the solution of the first optimal control problem, then, we plot the solution of the second optimal control problem on the same figure, but with dashed lines.

```@example main
# first plot
plt = plot(sol; solution_label="(sol1)", size=(700, 500))

# second plot
plot!(plt, sol2; solution_label="(sol2)", linestyle=:dash)
```

## Plot the norm of the control

For some problem, it is interesting to plot the norm of the control. You can do it by using the `control` optional keyword argument with `:norm` value. The default value is `:components`.

```@example main
plot(sol; control=:norm, size=(800, 300), layout=:group)
```

## Custom plot

You can of course create your own plots by getting the `state`, `costate` and `control` from the optimal control solution. For instance, let us plot the norm of the control for the orbital transfer problem.

!!! tip "Interactions with an optimal control solution"

    Additionally to [`state`](@ref), [`costate`](@ref), [`control`](@ref) and [`variable`](@ref), the function [`time_grid`](@ref) returns the discretized time grid returned by the solver.

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

## Normalized time

We consider a [LQR example](@ref) and solve the problem for different values of the final time `tf`. Then, we plot the solutions on the same figure considering a normalized time $s=(t-t_0)/(t_f-t_0)$, thanks to the keyword argument `time=:normalize` of the `plot` function.

```@example main

# parameters
x0 = [ 0
       1 ]

# definition
function lqr(tf)

    ocp = @def begin
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        x(0) == x0
        ẋ(t) == [x₂(t), - x₁(t) + u(t)]
        ∫( 0.5(x₁(t)^2 + x₂(t)^2 + u(t)^2) ) → min
    end

    return ocp
end;

# solve
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

# make a custom plot from created plots: only state and control are plotted
N = length(tfs)
px1 = plot(plt[1]; legend=false, xlabel="s", ylabel="x₁")
px2 = plot(plt[2]; label=reshape(["tf = $tf" for tf ∈ tfs], (1, N)), xlabel="s", ylabel="x₂")
pu  = plot(plt[5]; legend=false, xlabel="s", ylabel="u")

using Plots.PlotMeasures # for leftmargin, bottommargin
plot(px1, px2, pu; layout=(1, 3), size=(800, 300), leftmargin=5mm, bottommargin=5mm)
```

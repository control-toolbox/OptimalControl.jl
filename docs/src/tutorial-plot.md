# Plot a solution

In this tutorial we explain the different ways to plot a solution of an optimal control problem.

Let us start by importing the necessary package.

```@example main
using OptimalControl
```

Then, we define a simple optimal control problem and solve it.

```@example main
@def ocp begin
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [ -1, 0 ]
    x(1) == [ 0, 0 ]
    ẋ(t) == [ x₂(t), u(t) ]
    ∫( 0.5u(t)^2 ) → min
end

sol = solve(ocp, display=false)
nothing # hide
```

## First ways to plot

The simplest way to plot the solution is to use the [`plot`](@ref) function with only the solution as argument.

```@example main
plot(sol)
```

As you can see, it produces a grid of subplots. The left column contains the state trajectories, the right column the costate trajectories, and at the bottom we have the control trajectory.

Attributes from [`Plots.jl`](https://docs.juliaplots.org) can be passed to the `plot` function:

- In addition to `sol` you can pass attributes to the full `Plot`, see the [attributes plot documentation](https://docs.juliaplots.org/latest/generated/attributes_plot/) from `Plots.jl` for more details. For instance, you can specify the size of the figure.
- You can also pass attributes to the subplots, see the [attributes subplot documentation](https://docs.juliaplots.org/latest/generated/attributes_subplot/) from `Plots.jl` for more details. However, it will affect all the subplots. For instance, you can specify the location of the legend.
- In the same way, you can pass axis attributes to the subplots, see the [attributes axis documentation](https://docs.juliaplots.org/latest/generated/attributes_axis/) from `Plots.jl` for more details. It will also affect all the subplots. For instance, you can remove the grid.

```@example main
plot(sol, size=(700, 450), legend=:bottomright, grid=false)
```

To specify series attributes to a specific subplot, you can use the optional keyword arguments `state_style`, `costate_style` and `control_style` which correspond respectively to the state, costate and control trajectories. See the [attribute series documentation](https://docs.juliaplots.org/latest/generated/attributes_series/) from `Plots.jl` for more details. For instance, you can specify the color of the state trajectories and more.

```@example main
plot(sol, 
    state_style=(color=:blue,), 
    costate_style=(color=:black, linestyle=:dash),
    control_style=(color=:red, linewidth=2))
```

## Split versus group layout

If you prefer to get a more compact figure, you can use the `layout` optional keyword argument with `:group` value. It will group the state, costate and control trajectories in one subplot each.

```@example main
plot(sol, layout=:group, size=(700, 300))
```

!!! note "Default layout value"

    The default layout value is `:split` which corresponds to the grid of subplots presented above.

## Additional plots

You can plot the solution of a second optimal control problem on the same figure if it has the same number of states, costates and controls. For instance, consider the same optimal control problem but with a different initial condition.

```@example main
@def ocp begin
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [ -0.5, -0.5 ]
    x(1) == [ 0, 0 ]
    ẋ(t) == [ x₂(t), u(t) ]
    ∫( 0.5u(t)^2 ) → min
end
sol2 = solve(ocp, display=false)
nothing # hide
```

We first plot the solution of the first optimal control problem, then, we plot the solution of the second optimal control problem on the same figure, but with dashed lines.

```@example main
# first plot
plt = plot(sol, size=(700, 450))

# second plot
style = (linestyle=:dash, )
plot!(plt, sol2, state_style=style, costate_style=style, control_style=style)
```

## Plot the norm of the control

For some problem, it is interesting to plot the norm of the control. You can do it by using the `control` optional keyword argument with `:norm` value. The default value is `:components`. Let us illustrate this on the consumption minimisation orbital transfer problem from [CTProlbems.jl](https://control-toolbox.org/docs/ctproblems).

```@example main
using CTProblems
prob = Problem(:orbital_transfert, :consumption)
sol  = prob.solution
plot(sol, control=:norm, size=(800, 300), layout=:group)
```

## Custom plot

You can of course create your own plots by getting the `state`, `costate` and `control` from the optimal control solution. For instance, let us plot the norm of the control for the orbital transfer problem.

```@example main
using LinearAlgebra
t = sol.times
x = sol.state
p = sol.costate
u = sol.control
plot(t, norm∘u, label="‖u‖") 
```

!!! note "Nota bene"

    - The `norm` function is from `LinearAlgebra.jl`. 
    - The `∘` operator is the composition operator. Hence, `norm∘u` is the function `t -> norm(u(t))`. 
    - The `sol.state`, `sol.costate` and `sol.control` are functions that return the state, costate and control trajectories at a given time.

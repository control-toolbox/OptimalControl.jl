# [Double integrator: energy min (abstract syntax)](@id tutorial-basic)

Let us consider a wagon moving along a rail, whom acceleration can be controlled by a force $u$.
We denote by $x = (x_1, x_2)$ the state of the wagon, that is its position $x_1$ and its velocity $x_2$.

```@raw html
<img src="./assets/chariot.png" style="display: block; margin: 0 auto 20px auto;" width="300px">
```

We assume that the mass is constant and unitary and that there is no friction. The dynamics we consider is given by

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t),\quad u(t) \in \R,
```

which is simply the [double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674) system.
Les us consider a transfer starting at time $t_0 = 0$ and ending at time $t_f = 1$, for which we want to minimise the transfer energy

```math
    \frac{1}{2}\int_{0}^{1} u^2(t) \, \mathrm{d}t
```

starting from the condition $x(0) = (-1, 0)$ and with the goal to reach the target $x(1) = (0, 0)$.

First, we need to import the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package to define the 
optimal control problem and [NLPModelsIpopt.jl](jso.dev/NLPModelsIpopt.jl) to solve it. 
We also need to import the [Plots.jl](https://docs.juliaplots.org) package to plot the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Optimal control problem

Let us define the problem

```@example main
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [ -1, 0 ]
    x(1) == [ 0, 0 ]
    ẋ(t) == [ x₂(t), u(t) ]
    ∫( 0.5u(t)^2 ) → min
end
nothing # hide
```

!!! note "Nota bene"

    For a comprehensive introduction to the syntax used above to describe the optimal control problem, check [this abstract syntax tutorial](@ref abstract). In particular, there are non-unicode alternatives for derivatives, integrals, *etc.*
    
## [Solve and plot](@id basic-solve-plot)

We can solve it simply with:

```@example main
sol = solve(ocp)
nothing # hide
```

And plot the solution with:

```@example main
plot(sol)
```

## State constraint

We add the path constraint

```math
x_2(t) \le 1.2.
```

```@example main
ocp = @def begin

    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control

    x₂(t) ≤ 1.2

    x(0) == [ -1, 0 ]
    x(1) == [ 0, 0 ]

    ẋ(t) == [ x₂(t), u(t) ]

    ∫( 0.5u(t)^2 ) → min

end

sol = solve(ocp)
plot(sol)
```

## Save and load

We can save the solution in a Julia `.jld2` data file and reload it later, and also export a discretised version of the solution in a more portable [JSON](https://en.wikipedia.org/wiki/JSON) format. Note that the OCP is needed when loading a solution.

```@example main
# load additional modules
using JLD2, JSON3

# JLD save / load
using Suppressor # hide
@suppress_err begin # hide
export_ocp_solution(sol; filename_prefix="my_solution")
end # hide
sol_reloaded = import_ocp_solution(ocp; filename_prefix="my_solution")
println("Objective from loaded solution: ", sol_reloaded.objective)

# JSON export / read
export_ocp_solution(sol; filename_prefix="my_solution", format=:JSON)
sol_json = import_ocp_solution(ocp; filename_prefix="my_solution", format=:JSON)
println("Objective from JSON discrete solution: ", sol_json.objective)
```


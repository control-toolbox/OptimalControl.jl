# [Basic example](@id basic)

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

First, we need to import the `OptimalControl.jl` package to define the optimal control problem and `NLPModelsIpopt.jl` to solve it. 
We also need to import the `Plots.jl` package to plot the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

Then, we can define the problem

```@example main
@def ocp begin
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

Solve it

```@example main
sol = solve(ocp)
nothing # hide
```

And plot the solution

```@example main
plot(sol)
```

We can save the solution in a julia `.jld2` data file and reload it later, and also export a discretised version of the solution in a more portable [JSON](https://en.wikipedia.org/wiki/JSON) format.

```@example main
# load additional modules
using JLD2, JSON3

# JLD save / load
save(sol, filename_prefix="my_solution")
sol_reloaded = load("my_solution")
println("Objective from loaded solution: ", sol_reloaded.objective)

# JSON export / read
export_ocp_solution(sol, filename_prefix="my_solution")
sol_json = import_ocp_solution("my_solution")
println("Objective from JSON discrete solution: ", sol_json.objective)
```

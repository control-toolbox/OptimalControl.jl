# [Double integrator: time minimisation](@id example-double-integrator-time)

The problem consists in minimising the final time $t_f$ for the double integrator system

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t), \quad u(t) \in [-1,1],
```

and the limit conditions

```math
    x(0) = (1,2), \quad x(t_f) = (0,0).
```

This problem can be interpretated as a simple model for a wagon with constant mass moving along a line without fricton.

```@raw html
<img src="./assets/chariot.svg" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

First, we need to import the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package to define the 
optimal control problem and [NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl) to solve it. 
We also need to import the [Plots.jl](https://docs.juliaplots.org) package to plot the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Optimal control problem

Let us define the problem:

```@example main
ocp = @def begin

    tf ∈ R,          variable
    t ∈ [0, tf],     time
    x = (q, v) ∈ R², state
    u ∈ R,           control

    -1 ≤ u(t) ≤ 1

    q(0)  == -1
    v(0)  == 0
    q(tf) == 0
    v(tf) == 0

    ẋ(t) == [v(t), u(t)]

    tf → min

end
nothing # hide
```

!!! note "Nota bene"

    For a comprehensive introduction to the syntax used above to define the optimal control problem, see [this abstract syntax tutorial](@ref manual-abstract-syntax). In particular, non-Unicode alternatives are available for derivatives, integrals, *etc.*

## Solve and plot

### Direct method

Let us solve it with a direct method (we set the number of time steps to 200):

```@example main
sol = solve(ocp; grid_size=200)
nothing # hide
```

and plot the solution:

```@example main
plt = plot(sol; label="Direct", size=(800, 600))
```

!!! note "Nota bene"

    The `solve` function has options, see the [solve tutorial](@ref manual-solve). You can customise the plot, see the [plot tutorial](@ref manual-plot).

### Indirect method

We now turn to the indirect method, which relies on Pontryagin’s Maximum Principle.  The pseudo-Hamiltonian is given by

```math
H(x, p, u) = p_1 v + p_2 u - 1,
```

where $p = (p_1, p_2)$ is the costate vector. The optimal control is of bang–bang type:

```math
u(t) = \mathrm{sign}(p_2(t)),
```

with one switch from $u=+1$ to $u=-1$ at one single time denoted $t_1$. Let us implement this approach. First, we import the necessary packages:

```@example main
using OrdinaryDiffEq
using NonlinearSolve
```

Define the bang–bang control and Hamiltonian flow:

```@example main
# pseudo-Hamiltonian
H(x, p, u) = p[1]*x[2] + p[2]*u - 1

# bang–bang control
u_max = +1
u_min = -1

# Hamiltonian flow
f_max = Flow(ocp, (x, p, tf) -> u_max)
f_min = Flow(ocp, (x, p, tf) -> u_min)
nothing # hide
```

The shooting function enforces the conditions:

```@example main
t0 = 0
x0 = [-1, 0]
xf = [ 0, 0]
function shoot!(s, p0, t1, tf) 
    x_t0, p_t0 = x0, p0
    x_t1, p_t1 = f_max(t0, x_t0, p_t0, t1)
    x_tf, p_tf = f_min(t1, x_t1, p_t1, tf)
    s[1:2] = x_tf - xf                          # target conditions
    s[3] = p_t1[2]                              # switching condition
    s[4] = H(x_tf, p_tf, -1)                    # free final time
end
nothing # hide
```

We are now ready to solve the shooting equations:

```@example main
# in-place shooting function
nle!(s, ξ, λ) = shoot!(s, ξ[1:2], ξ[3], ξ[4]) 

# initial guess: costate and final time
ξ_guess = [1, 1, 1, 2]

# NLE problem
prob = NonlinearProblem(nle!, ξ_guess)

# resolution of the shooting equations
sol = solve(prob; show_trace=Val(true))
p0, t1, tf = sol.u[1:2], sol.u[3], sol.u[4]

# print the solution
println("\np0 = ", p0, "\nt1 = ", t1, "\ntf = ", tf)
```

Finally, we reconstruct and plot the solution obtained by the indirect method:

```@example main
# concatenation of the flows
φ = f_max * (t1, f_min)

# compute the solution: state, costate, control...
flow_sol = φ((t0, tf), x0, p0; saveat=range(t0, tf, 200))

# plot the solution on the previous plot
plot!(plt, flow_sol; label="Indirect", color=2, linestyle=:dash)
```

!!! note

    - You can use [MINPACK.jl](@extref Tutorials Resolution-of-the-shooting-equation) instead of [NonlinearSolve.jl](https://docs.sciml.ai/NonlinearSolve).
    - For more details about the flow construction, visit the [Compute flows from optimal control problems](@ref manual-flow-ocp) page.
    - In this simple example, we have set an arbitrary initial guess. It can be helpful to use the solution of the direct method to initialise the shooting method. See the [Goddard tutorial](@extref Tutorials tutorial-goddard) for such a concrete application.
# [Double integrator: energy minimisation](@id example-double-integrator-energy)

Let us consider a wagon moving along a rail, whose acceleration can be controlled by a force $u$.
We denote by $x = (q, v)$ the state of the wagon, where $q$ is the position and $v$ the velocity.

```@raw html
<img src="./assets/chariot_q.svg" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

We assume that the mass is constant and equal to one, and that there is no friction. The dynamics are given by

```math
    \dot q(t) = v(t), \quad \dot v(t) = u(t),\quad u(t) \in \R,
```

which is simply the [double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674) system. Let us consider a transfer starting at time $t_0 = 0$ and ending at time $t_f = 1$, for which we want to minimise the transfer energy

```math
    \frac{1}{2}\int_{0}^{1} u^2(t) \, \mathrm{d}t
```

starting from $x(0) = (-1, 0)$ and aiming to reach the target $x(1) = (0, 0)$.

First, we need to import the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package to define the optimal control problem, [NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl) to solve it, and [Plots.jl](https://docs.juliaplots.org) to visualise the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## Optimal control problem

Let us define the problem with the [`@def`](@ref) macro:

```@raw html
<div class="responsive-columns-left-priority">
<div>
```

```@example main
t0 = 0; tf = 1; x0 = [-1, 0]; xf = [0, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫( u(t)^2 ) → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

### Mathematical formulation

```math
    \begin{aligned}
        & \text{Minimise} && \frac{1}{2}\int_0^1 u^2(t) \,\mathrm{d}t \\
        & \text{subject to} \\
        & && \dot{x}(t) = [v(t), u(t)], \\[1.0em]
        & && x(0) = (-1,0), \\[0.5em] 
        & && x(1) = (0,0).
    \end{aligned}
```

```@raw html
</div>
</div>
```

!!! note "Nota bene"

    For a comprehensive introduction to the syntax used above to define the optimal control problem, see [this abstract syntax tutorial](@ref manual-abstract-syntax). In particular, non-Unicode alternatives are available for derivatives, integrals, *etc.*

## [Solve and plot](@id example-double-integrator-energy-solve-plot)

### Direct method

We can [`solve`](@ref) it simply with:

```@example main
direct_sol = solve(ocp)
nothing # hide
```

And [`plot`](@ref) the solution with:

```@example main
plot(direct_sol)
```

!!! note "Nota bene"

    The `solve` function has options, see the [solve tutorial](@ref manual-solve). You can customise the plot, see the [plot tutorial](@ref manual-plot).

### Indirect method

The first solution was obtained using the so-called direct method.[^1] Another approach is to use an [indirect simple shooting](@extref tutorial-indirect-simple-shooting) method. We begin by importing the necessary packages.

```@example main
using OrdinaryDiffEq # Ordinary Differential Equations (ODE) solver
using NonlinearSolve # Nonlinear Equations (NLE) solver
```

To define the shooting function, we must provide the maximising control in feedback form:

```@example main
# maximising control, H(x, p, u) = p₁v + p₂u - u²/2
u(x, p) = p[2]

# Hamiltonian flow
f = Flow(ocp, u)

# state projection, p being the costate
π((x, p)) = x

# shooting function
S(p0) = π( f(t0, x0, p0, tf) ) - xf
nothing # hide
```

We are now ready to solve the shooting equations.

```@example main
# auxiliary in-place NLE function
nle!(s, p0, _) = s[:] = S(p0)

# initial guess for the Newton solver from the direct solution
t = time_grid(direct_sol) # the time grid as a vector
p = costate(direct_sol)   # the costate as a function of time
p0_guess = p(t0)          # initial costate

# NLE problem with initial guess
prob = NonlinearProblem(nle!, p0_guess)

# resolution of S(p0) = 0
shooting_sol = solve(prob; show_trace=Val(true))
p0_sol = shooting_sol.u # costate solution

# print the costate solution and the shooting function evaluation
println("\ncostate: p0 = ", p0_sol)
println("shoot: S(p0) = ", S(p0_sol), "\n")
```

To plot the solution obtained by the indirect method, we need to build the solution of the optimal control problem. This is done using the costate solution and the flow function.

```@example main
indirect_sol = f((t0, tf), x0, p0_sol; saveat=range(t0, tf, 100))
plot(indirect_sol)
```

[^1]: J. T. Betts. Practical methods for optimal control using nonlinear programming. Society for Industrial and Applied Mathematics (SIAM), Philadelphia, PA, 2001.

!!! note

    - You can use [MINPACK.jl](@extref Tutorials Resolution-of-the-shooting-equation) instead of [NonlinearSolve.jl](https://docs.sciml.ai/NonlinearSolve).
    - For more details about the flow construction, visit the [Compute flows from optimal control problems](@ref manual-flow-ocp) page.
    - In this simple example, we have set an arbitrary initial guess. It can be helpful to use the solution of the direct method to initialise the shooting method. See the [Goddard tutorial](@extref Tutorials tutorial-goddard) for such a concrete application.
    - For a version with a state constraint on the velocity, see the [State constraint](@ref example-state-constraint) example.

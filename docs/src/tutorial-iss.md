# [Indirect simple shooting](@id iss)

In this tutorial we present the indirect simple shooting method on a simple example.

```@setup main
using Suppressor # to suppress warnings
```

Let us start by importing the necessary packages.

```@example main
using OptimalControl  # to define the optimal control problem and its flow
using OrdinaryDiffEq  # to get the Flow function from OptimalControl
using NonlinearSolve  # interface to NLE solvers
using MINPACK         # NLE solver: use to solve the shooting equation
using Plots           # to plot the solution
```

## Optimal control problem

Let us consider the following optimal control problem:

```math
\left\{ 
    \begin{array}{l}
        \min \displaystyle \frac{1}{2} \int_{t_0}^{t_f} u^2(t) \, \mathrm{d} t\\[1.0em]
        \dot{x}(t)  =  \displaystyle -x(t)+\alpha x^2(t)+u(t), \quad  u(t) \in \R, 
        \quad t \in [t_0, t_f] \text{ a.e.}, \\[0.5em]
        x(t_0) = x_0, \quad x(t_f) = x_f,
    \end{array}
\right.%
```

with $t_0 = 0$, $t_f = 1$, $x_0 = -1$, $x_f = 0$, $\alpha=1.5$ and $\forall\, t \in [t_0, t_f]$, $x(t) \in \R$.

```@example main
t0 = 0
tf = 1
x0 = -1
xf = 0
α  = 1.5
@def ocp begin

    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == -x(t) + α * x(t)^2 + u(t)

    ∫( 0.5u(t)^2 ) → min
    
end;
nothing # hide
```

## Boundary value problem

The **pseudo-Hamiltonian** of this problem is

```math
    H(x,p,u) = p \, (-x+\alpha x^2+u) + p^0 u^2 /2,
```

where $p^0 = -1$ since we are in the normal case. From the Pontryagin Maximum Principle, the maximising control is given by

```math
u(x, p) = p
```

since $\partial^2_{uu} H = p^0 = - 1 < 0$. Plugging this control in feedback form into the pseudo-Hamiltonian, and considering the limit conditions, we obtain the following two-points boundary value problem (BVP).

```math
    \left\{ 
        \begin{array}{l}
            \dot{x}(t)  = \phantom{-} \nabla_p H[t] = -x(t) + \alpha x^2(t) + u(x(t), p(t)) 
            = -x(t) + \alpha x^2(t) + p(t), \\[0.5em]
            \dot{p}(t)  = -           \nabla_x H[t] = (1 - 2 \alpha x(t))\, p(t),    \\[0.5em]
            x(t_0)        = x_0, \quad x(t_f) = x_f,
        \end{array}
    \right.
```

where $[t]~=  (x(t),p(t),u(x(t), p(t)))$.

!!! note "Our goal"

    Our goal is to solve this (BVP). Solving (BVP) consists in solving the Pontryagin Maximum Principle which provides necessary conditions of optimality.

## Shooting function

To achive our goal, let us first introduce the pseudo-Hamiltonian vector field

```math
    \vec{H}(z,u) = \left( \nabla_p H(z,u), -\nabla_x H(z,u) \right), \quad z = (x,p),
```

and then denote by $\varphi_{t_0, x_0, p_0}(\cdot)$ the solution of the following Cauchy problem

```math
\dot{z}(t) = \vec{H}(z(t), u(z(t))), \quad z(t_0) = (x_0, p_0).
```

Our goal becomes to solve

```math
\pi( \varphi_{t_0, x_0, p_0}(t_f) ) = x_f, \quad \pi(x, p) = x.
```

To compute $\varphi$ with the `OptimalControl` package, we define the flow of the associated Hamiltonian vector field by:

```@example main
u(x, p) = p
φ = Flow(ocp, u)
nothing # hide
```

We define also the projection function on the state space.

```@example main
π((x, p)) = x
nothing # hide
```

!!! note "Nota bene"

    Actually, $\varphi_{t_0, x_0, p_0}(\cdot)$ is also solution of
    
    ```math
        \dot{z}(t) = \vec{\mathbf{H}}(z(t)), \quad z(t_0) = (x_0, p_0),
    ```
    where $\mathbf{H}(z) = H(z, u(z))$ and $\vec{\mathbf{H}} = (\nabla_p \mathbf{H}, -\nabla_x \mathbf{H})$. This is what is actually computed by `Flow`.

Now, to solve the (BVP) we introduce the **shooting function**.

```math
    \begin{array}{rlll}
        S \colon    & \R    & \longrightarrow   & \R \\
                    & p_0    & \longmapsto     & S(p_0) = \pi( \varphi_{t_0, x_0, p_0}(t_f) ) - x_f.
    \end{array}
```

```@example main
S(p0) = π( φ(t0, x0, p0, tf) ) - xf # shooting function
nothing # hide
```

## Resolution of the shooting equation

At the end, solving (BVP) is equivalent to solve $S(p_0) = 0$. This is what we call the 
**indirect simple shooting method**. We define an initial guess.

```@example main
ξ = [ 0.0 ] # initial guess
nothing # hide
```

### NonlinearSolve.jl

We first use the [NonlinearSolve.jl](https://github.com/SciML/NonlinearSolve.jl) package to solve the shooting
equation. Let us define the problem.

```@example main
nle! = (s, ξ, λ) -> s[1] = S(ξ[1]) # auxiliary function
prob = NonlinearProblem(nle!, ξ)   # NLE problem with initial guess
nothing # hide
```

Let us do some benchmarking.

```@example main
using BenchmarkTools
@benchmark solve(prob; show_trace=Val(false))
```

For small nonlinear systems, it could be faster to use the 
[`SimpleNewtonRaphson()` descent algorithm](https://docs.sciml.ai/NonlinearSolve/stable/tutorials/code_optimization/).

```@example main
@benchmark solve(prob, SimpleNewtonRaphson(); show_trace=Val(false))
```

Now, let us solve the problem and retrieve the initial costate solution.

```@example main
global indirect_sol =                               # hide
@suppress_err begin                                 # hide
solve(prob; show_trace=Val(false))                  # hide
indirect_sol = solve(prob; show_trace=Val(true))    # resolution of S(p0) = 0  
end                                                 # hide
p0_sol = indirect_sol.u[1]                          # costate solution
println("\ncostate:    p0 = ", p0_sol)
@suppress_err begin                                 # hide
println("shoot: |S(p0)| = ", abs(S(p0_sol)), "\n")
end                                                 # hide
nothing                                             # hide
```

### MINPACK.jl

```@setup main
using MINPACK
function fsolve(f, j, x; kwargs...)
    try
        MINPACK.fsolve(f, j, x; kwargs...)
    catch e
        println("Erreur using MINPACK")
        println(e)
        println("hybrj not supported. Replaced by hybrd even if it is not visible on the doc.")
        MINPACK.fsolve(f, x; kwargs...)
    end
end
```

Instead of the [`NonlinearSolve.jl`](https://github.com/SciML/NonlinearSolve.jl) package we can use the 
[`MINPACK.jl`](https://github.com/sglyon/MINPACK.jl) package to solve 
the shooting equation. To compute the Jacobian of the shooting function we use the 
[`DifferentiationInterface.jl`](https://gdalle.github.io/DifferentiationInterface.jl/DifferentiationInterface) package with 
[`ForwardDiff`](https://github.com/JuliaDiff/ForwardDiff.jl) backend.

```@example main
using DifferentiationInterface
import ForwardDiff
backend = AutoForwardDiff()
nothing # hide
```

Let us define the problem to solve.

```@example main
nle!  = ( s, ξ) -> s[1] = S(ξ[1])                              # auxiliary function
jnle! = (js, ξ) -> jacobian!(nle!, similar(ξ), js, backend, ξ) # Jacobian of nle
nothing # hide
```

We are now in position to solve the problem with the `hybrj` solver from `MINPACK` through the `fsolve` 
function, providing the Jacobian. Let us do some benchmarking.

```@example main
@benchmark fsolve(nle!, jnle!, ξ; show_trace=false) # initial guess given to the solver
```

We can also use the [preparation step](https://gdalle.github.io/DifferentiationInterface.jl/DifferentiationInterface/stable/tutorial1/#Preparing-for-multiple-gradients) of `DifferentiationInterface.jl`.

```@example main
extras = prepare_jacobian(nle!, similar(ξ), backend, ξ)
jnle_prepared!(js, ξ) = jacobian!(nle!, similar(ξ), js, backend, ξ, extras)
@benchmark fsolve(nle!, jnle_prepared!, ξ; show_trace=false)
```

Now, let us solve the problem and retrieve the initial costate solution.

```@example main
global indirect_sol =                                   # hide
@suppress_err begin                                     # hide
fsolve(nle!, jnle!, ξ; show_trace=false)                # hide
indirect_sol = fsolve(nle!, jnle!, ξ; show_trace=true)  # resolution of S(p0) = 0
end                                                     # hide
p0_sol = indirect_sol.x[1]                              # costate solution
println("\ncostate:    p0 = ", p0_sol)
@suppress_err begin                                     # hide
println("shoot: |S(p0)| = ", abs(S(p0_sol)), "\n")
end                                                     # hide
nothing                                                 # hide
```

## Plot of the solution

The solution can be plot calling first the flow.

```@example main
sol = φ( (t0, tf), x0, p0_sol )
plot(sol, size=(800, 600))
```

In the indirect shooting method, the research of the optimal control is replaced by the computation
of its associated extremal. This computation is equivalent to finding the initial covector solution
to the shooting function.

```@example main
exp(p0; saveat=[]) = φ((t0, tf), x0, p0, saveat=saveat).ode_sol # hide
times = range(t0, tf, length=2) # hide
p0min = -0.5 # hide
p0max = 2 # hide
plt_flow = plot() # hide
p0s = range(p0min, p0max, length=20) # hide
for i ∈ 1:length(p0s) # hide
    sol = exp(p0s[i]) # hide
    x = [sol(t)[1] for t ∈ sol.t] # hide
    p = [sol(t)[2] for t ∈ sol.t] # hide
    label = i==1 ? "extremals" : false # hide
    plot!(plt_flow, x, p, color=:blue, label=label) # hide
end # hide
p0s = range(p0min, p0max, length=200) # hide
xs  = zeros(length(p0s), length(times)) # hide
ps  = zeros(length(p0s), length(times)) # hide
for i ∈ 1:length(p0s) # hide
    sol = exp(p0s[i], saveat=times) # hide
    xs[i, :] = [z[1] for z ∈ sol.(times)] # hide
    ps[i, :] = [z[2] for z ∈ sol.(times)] # hide
end # hide
for j ∈ 1:length(times) # hide
    label = j==1 ? "flow at times" : false # hide
    plot!(plt_flow, xs[:, j], ps[:, j], color=:green, linewidth=2, label=label) # hide
end # hide
plot!(plt_flow, xlims = (-1.1, 1), ylims =  (p0min, p0max)) # hide
plot!(plt_flow, [0, 0], [p0min, p0max], color=:black, xlabel="x", ylabel="p", label="x=xf") # hide
sol = exp(p0_sol) # hide
x = [sol(t)[1] for t ∈ sol.t] # hide
p = [sol(t)[2] for t ∈ sol.t] # hide
plot!(plt_flow, x, p, color=:red, linewidth=2, label="extremal solution") # hide
plot!(plt_flow, [x[end]], [p[end]], seriestype=:scatter, color=:green, label=false) # hide
plt_shoot = plot(xlims=(p0min, p0max), ylims=(-2, 4), xlabel="p₀", ylabel="y") # hide
plot!(plt_shoot, p0s, S, linewidth=2, label="S(p₀)", color=:green) # hide
plot!(plt_shoot, [p0min, p0max], [0, 0], color=:black, label="y=0") # hide
plot!(plt_shoot, [p0_sol, p0_sol], [-2, 0], color=:black, label="p₀ solution", linestyle=:dash) # hide
plot!(plt_shoot, [p0_sol], [0], seriestype=:scatter, color=:green, label=false) # hide
plot(plt_flow, plt_shoot, layout=(1,2), size=(800, 450)) # hide
```

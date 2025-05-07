# Direct and indirect methods for the Goddard problem

## Introduction

```@raw html
<img src="./assets/Goddard_and_Rocket.jpg" style="float: left; margin: auto 10px;" width="200px">
```

For this example, we consider the well-known Goddard problem[^1] [^2] which models the ascent of a rocket
through the atmosphere, and we restrict here ourselves to vertical (one dimensional) trajectories. The state variables
are the altitude $r$, speed $v$ and mass $m$ of the rocket during the flight, for a total dimension of 3. The rocket is
subject to gravity $g$, thrust $u$ and drag force $D$ (function of speed and altitude). The final time $t_f$ is free, and the objective is to reach a maximal altitude with a bounded fuel consumption.

We thus want to solve the optimal control problem in Mayer form

```math
    r(t_f) \to \max
```

subject to the controlled dynamics

```math
    \dot{r} = v, \quad
    \dot{v} = \frac{T_{\max}\,u - D(r,v)}{m} - g, \quad
    \dot{m} = -u,
```

and subject to the control constraint $u(t) \in [0,1]$ and the state constraint
$v(t) \leq v_{\max}$. The initial state is fixed while only the final mass is prescribed.

!!! note "Nota bene"

    The Hamiltonian is affine with respect to the control, so singular arcs may occur,
    as well as constrained arcs due to the path constraint on the velocity (see below).

We import the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package to define the optimal control problem and
[NLPModelsIpopt.jl](https://github.com/JuliaSmoothOptimizers/NLPModelsIpopt.jl) to solve it. 
We import the [Plots.jl](https://github.com/JuliaPlots/Plots.jl) package to plot the solution. 
The [OrdinaryDiffEq.jl](https://github.com/SciML/OrdinaryDiffEq.jl) package is used to 
define the shooting function for the indirect method and the [MINPACK.jl](https://github.com/sglyon/MINPACK.jl) package permits to solve the shooting equation.

```@example main
using OptimalControl  # to define the optimal control problem and more
using NLPModelsIpopt  # to solve the problem via a direct method
using OrdinaryDiffEq  # to get the Flow function from OptimalControl
using MINPACK         # NLE solver: use to solve the shooting equation
using Plots           # to plot the solution
```

## Optimal control problem

We define the problem

```@example main
const t0 = 0      # initial time
const r0 = 1      # initial altitude
const v0 = 0      # initial speed
const m0 = 1      # initial mass
const vmax = 0.1  # maximal authorized speed
const mf = 0.6    # final mass to target

ocp = @def begin # definition of the optimal control problem

    tf ∈ R, variable
    t ∈ [t0, tf], time
    x = (r, v, m) ∈ R³, state
    u ∈ R, control

    x(t0) == [r0, v0, m0]
    m(tf) == mf,         (1)
    0 ≤ u(t) ≤ 1
    r(t) ≥ r0
    0 ≤ v(t) ≤ vmax

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

    r(tf) → max

end

# Dynamics
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1)) # Drag force
    return [v, -D/m - 1/r^2, 0]
end

F1(x) = begin
    r, v, m = x
    return [0, Tmax/m, -b*Tmax]
end
nothing # hide
```

## Direct method

We then solve it

```@example main
direct_sol = solve(ocp; grid_size=100)
nothing # hide
```

and plot the solution

```@example main
plt = plot(direct_sol, solution_label="(direct)", size=(800, 800))
```

## [Structure of the solution](@id tutorial-goddard-structure)

We first determine visually the structure of the optimal solution which is composed of a
bang arc with maximal control, followed by a singular arc, then by a boundary arc and the final
arc is with zero control. Note that the switching function vanishes along the singular and
boundary arcs.

!!! tip "Interactions with an optimal control solution"

    Please check [`state`](@ref), [`costate`](@ref), [`control`](@ref) and [`variable`](@ref) to get data from the solution. The functions `state`, `costate` and `control` return functions of time and `variable` returns a vector. The function [`time_grid`](@ref) returns the discretized time grid returned by the solver.

```@example main
t = time_grid(direct_sol)
x = state(direct_sol)
u = control(direct_sol)
p = costate(direct_sol)

H1 = Lift(F1)           # H1(x, p) = p' * F1(x)
φ(t) = H1(x(t), p(t))   # switching function
g(x) = vmax - x[2]      # state constraint v ≤ vmax

u_plot  = plot(t, u,     label = "u(t)")
H1_plot = plot(t, φ,     label = "H₁(x(t), p(t))")
g_plot  = plot(t, g ∘ x, label = "g(x(t))")

plot(u_plot, H1_plot, g_plot, layout=(3,1), size=(500, 500))
```

We are now in position to solve the problem by an indirect shooting method. We first define
the four control laws in feedback form and their associated flows. For this we need to
compute some Lie derivatives,
namely [Poisson brackets](https://en.wikipedia.org/wiki/Poisson_bracket) of Hamiltonians
(themselves obtained as lifts to the cotangent bundle of vector fields), or
derivatives of functions along a vector field. For instance, the control along the
*minimal order* singular arcs is obtained as the quotient

```math
u_s = -\frac{H_{001}}{H_{101}}
```

of length three Poisson brackets:

```math
H_{001} = \{H_0,\{H_0,H_1\}\}, \quad H_{101} = \{H_1,\{H_0,H_1\}\}
```

where, for two Hamiltonians $H$ and $G$,

```math
\{H,G\} := (\nabla_p H|\nabla_x G) - (\nabla_x H|\nabla_p G).
```

While the Lie derivative of a function $f$ *wrt.* a vector field $X$ is simply obtained as

```math
(X \cdot f)(x) := f'(x) \cdot X(x),
```

and is used to the compute the control along the boundary arc,

```math
u_b(x) = -(F_0 \cdot g)(x) / (F_1 \cdot g)(x),
```

as well as the associated multiplier for the *order one* state constraint on the velocity:

```math
\mu(x, p) = H_{01}(x, p) / (F_1 \cdot g)(x).
```

!!! note "Poisson bracket and Lie derivative"

    The Poisson bracket $\{H,G\}$ is also given by the Lie derivative of $G$ along the
    Hamiltonian vector field $X_H = (\nabla_p H, -\nabla_x H)$ of $H$, that is

    ```math
        \{H,G\} = X_H \cdot G
    ```

    which is the reason why we use the `@Lie` macro to compute Poisson brackets below.

With the help of the [differential geometry primitives](https://control-toolbox.org/CTBase.jl/stable/api-diffgeom.html)
from [CTBase.jl](https://control-toolbox.org/OptimalControl.jl/stable/api-ctbase.html),
these expressions are straightforwardly translated into Julia code:

```@example main
# Controls
const u0 = 0                            # off control
const u1 = 1                            # bang control

H0 = Lift(F0)                           # H0(x, p) = p' * F0(x)
H01  = @Lie {H0, H1}
H001 = @Lie {H0, H01}
H101 = @Lie {H1, H01}
us(x, p) = -H001(x, p) / H101(x, p)     # singular control

ub(x) = -(F0⋅g)(x) / (F1⋅g)(x)          # boundary control
μ(x, p) = H01(x, p) / (F1⋅g)(x)         # multiplier associated to the state constraint g

# Flows
f0 = Flow(ocp, (x, p, tf) -> u0)
f1 = Flow(ocp, (x, p, tf) -> u1)
fs = Flow(ocp, (x, p, tf) -> us(x, p))
fb = Flow(ocp, (x, p, tf) -> ub(x), (x, u, tf) -> g(x), (x, p, tf) -> μ(x, p))
nothing # hide
```

## Shooting function

Then, we define the shooting function according to the optimal structure we have determined,
that is a concatenation of four arcs.

```@example main
x0 = [r0, v0, m0] # initial state

function shoot!(s, p0, t1, t2, t3, tf)

    x1, p1 = f1(t0, x0, p0, t1)
    x2, p2 = fs(t1, x1, p1, t2)
    x3, p3 = fb(t2, x2, p2, t3)
    xf, pf = f0(t3, x3, p3, tf)

    s[1] = xf[3] - mf                             # final mass constraint
    s[2:3] = pf[1:2] - [1, 0]                     # transversality conditions
    s[4] = H1(x1, p1)                             # H1 = H01 = 0
    s[5] = H01(x1, p1)                            # at the entrance of the singular arc
    s[6] = g(x2)                                  # g = 0 when entering the boundary arc
    s[7] = H0(xf, pf)                             # since tf is free

end
nothing # hide
```

## Initial guess

To solve the problem by an indirect shooting method, we then need a good initial guess,
that is a good approximation of the initial costate, the three switching times and the
final time.

```@example main
η = 1e-3
t13 = t[ abs.(φ.(t)) .≤ η ]
t23 = t[ 0 .≤ (g ∘ x).(t) .≤ η ]
p0 = p(t0)
t1 = min(t13...)
t2 = min(t23...)
t3 = max(t23...)
tf = t[end]

println("p0 = ", p0)
println("t1 = ", t1)
println("t2 = ", t2)
println("t3 = ", t3)
println("tf = ", tf)

# Norm of the shooting function at solution
using LinearAlgebra: norm
s = similar(p0, 7)
shoot!(s, p0, t1, t2, t3, tf)
println("\nNorm of the shooting function: ‖s‖ = ", norm(s), "\n")
```

## Indirect shooting

We aggregate the data to define the initial guess vector.

```@example main
ξ = [p0..., t1, t2, t3, tf] # initial guess
```

### MINPACK.jl

We can use [NonlinearSolve.jl](https://github.com/SciML/NonlinearSolve.jl) package or, instead, the 
[MINPACK.jl](https://github.com/sglyon/MINPACK.jl) package to solve 
the shooting equation. To compute the Jacobian of the shooting function we use the 
[DifferentiationInterface.jl](https://gdalle.github.io/DifferentiationInterface.jl/DifferentiationInterface) package with 
[ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) backend.

```@setup main
using NonlinearSolve  # interface to NLE solvers
struct MYSOL
    x::Vector{Float64}
end
function fsolve(f, j, x; kwargs...)
    try
        MINPACK.fsolve(f, j, x; kwargs...)
    catch e
        println("Error using MINPACK")
        println(e)
        println("hybrj not supported. Replaced by NonlinearSolve even if it is not visible on the doc.")
        nle! = (s, ξ, λ) -> f(s, ξ)
        prob = NonlinearProblem(nle!, ξ)
        sol = solve(prob; abstol=1e-8, reltol=1e-8, show_trace=Val(true))
        return MYSOL(sol.u)
    end
end
```

```@example main
using DifferentiationInterface
import ForwardDiff
backend = AutoForwardDiff()
nothing # hide
```

Let us define the problem to solve.

```@example main
# auxiliary function with aggregated inputs
nle!  = ( s, ξ) -> shoot!(s, ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7])

# Jacobian of the (auxiliary) shooting function
jnle! = (js, ξ) -> jacobian!(nle!, similar(ξ), js, backend, ξ)
nothing # hide
```

We are now in position to solve the problem with the `hybrj` solver from MINPACK.jl through the `fsolve` 
function, providing the Jacobian.
Let us solve the problem and retrieve the initial costate solution.

```@example main
# resolution of S(ξ) = 0
indirect_sol = fsolve(nle!, jnle!, ξ, show_trace=true)

# we retrieve the costate solution together with the times
p0 = indirect_sol.x[1:3]
t1 = indirect_sol.x[4]
t2 = indirect_sol.x[5]
t3 = indirect_sol.x[6]
tf = indirect_sol.x[7]

println("")
println("p0 = ", p0)
println("t1 = ", t1)
println("t2 = ", t2)
println("t3 = ", t3)
println("tf = ", tf)

# Norm of the shooting function at solution
s = similar(p0, 7)
shoot!(s, p0, t1, t2, t3, tf)
println("\nNorm of the shooting function: ‖s‖ = ", norm(s), "\n")
```

## [Plot of the solution](@id tutorial-goddard-plot)

We plot the solution of the indirect solution (in red) over the solution of the direct method 
(in blue).

```@example main
f = f1 * (t1, fs) * (t2, fb) * (t3, f0) # concatenation of the flows
flow_sol = f((t0, tf), x0, p0)          # compute the solution: state, costate, control...

plot!(plt, flow_sol, solution_label="(indirect)")
```

## References

[^1]: R.H. Goddard. A Method of Reaching Extreme Altitudes, volume 71(2) of Smithsonian Miscellaneous Collections. Smithsonian institution, City of Washington, 1919.

[^2]: H. Seywald and E.M. Cliff. Goddard problem in presence of a dynamic pressure limit. Journal of Guidance, Control, and Dynamics, 16(4):776–781, 1993.

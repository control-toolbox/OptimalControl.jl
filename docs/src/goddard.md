# Advanced example

This well-known problem[^1] [^2] models the ascent of a rocket through the atmosphere, and we restrict here ourselves to vertical (one dimensional) trajectories. The state variables are the altitude $r$, speed $v$ and mass $m$ of the rocket during the flight, for a total dimension of 3. The rocket is subject to gravity $g$, thrust $u$ and drag force $D$ (function of speed and altitude). The final time $T$ is free, and the objective is to reach a maximal altitude with a bounded fuel consumption.

We thus want to solve the optimal control problem in Mayer form

```math
    \max\, r(T)
```

subject to the control dynamics

```math
    \dot{r} = v, \quad
    \dot{v} = \frac{T_{\max}\,u - D(r,v)}{m} - g, \quad
    \dot{m} = -u,
```

and subject to the control constraint $u(t) \in [0,1]$ and the state constraint
$v(t) \leq v_{\max}$. The initial state is fixed while only the final mass is prescribed.

!!! note

    The Hamiltonian is affine with respect to the control, so singular arcs may occur, 
    as well as constrained arcs due to the path constraint on the velocity (see below).

We import the `OptimalControl.jl` package:

```@example main
using OptimalControl
```

We define the problem

```@example main
# Parameters
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2

t0 = 0
r0 = 1
v0 = 0
vmax = 0.1
m0 = 1
mf = 0.6

# Initial state
x0 = [ r0, v0, m0 ]

# Abstract model
@def ocp_goddard begin

    tf, variable
    t ∈ [ t0, tf ], time
    x ∈ R³, state
    u ∈ R, control
    
    r = x₁
    v = x₂
    m = x₃
   
    x(t0) == [ r0, v0, m0 ]
    0  ≤ u(t) ≤ 1
         r(t) ≥ r0,     (1)
    0  ≤ v(t) ≤ vmax,   (2)
    mf ≤ m(t) ≤ m0,     (3)

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))
 
    r(tf) → max
    
end;

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    return [ v, -D/m - 1/r^2, 0 ]
end

F1(x) = begin
    r, v, m = x
    return [ 0, Tmax/m, -b*Tmax ]
end
nothing # hide
```

Solve it

```@example main
N = 50
direct_sol_goddard = solve(ocp_goddard, grid_size=N)
nothing # hide
```

and plot the solution

```@example main
plot(direct_sol_goddard, size=(700, 700))
```

[^1]: R.H. Goddard. A Method of Reaching Extreme Altitudes, volume 71(2) of Smithsonian Miscellaneous Collections. Smithsonian institution, City of Washington, 1919.

[^2]: H. Seywald and E.M. Cliff. Goddard problem in presence of a dynamic pressure limit. Journal of Guidance, Control, and Dynamics, 16(4):776–781, 1993.

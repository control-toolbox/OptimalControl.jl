# [Discretisation methods](@id tutorial-discretisation-methods)

## Discretisation formulas
When calling `solve`, the option `disc_method=...` can be used to set the discretisation scheme.
In addition to the default implicit `:trapeze` method (aka Crank-Nicolson), other choices are available, namely implicit `:midpoint` and the Gauss-Legendre collocations with 2 and  stages, `:gauss_legendre_2` and `:gauss_legendre_3`, of order 4 and 6 respectively. 
Note that higher order methods will typically lead to larger NLP problems for the same number of time steps, and that accuracy will also depend on the smoothness of the problem.

As an example we will use the [Goddard problem](@ref tutorial-goddard)
```@example main
using OptimalControl  # to define the optimal control problem and more
using NLPModelsIpopt  # to solve the problem via a direct method
using Plots           # to plot the solution

t0 = 0      # initial time
r0 = 1      # initial altitude
v0 = 0      # initial speed
m0 = 1      # initial mass
vmax = 0.1  # maximal authorized speed
mf = 0.6    # final mass to target

ocp = @def begin # definition of the optimal control problem

    tf ∈ R, variable
    t ∈ [t0, tf], time
    x = (r, v, m) ∈ R³, state
    u ∈ R, control

    x(t0) == [ r0, v0, m0 ]
    m(tf) == mf,         (1)
    0 ≤ u(t) ≤ 1
    r(t) ≥ r0
    0 ≤ v(t) ≤ vmax

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

    r(tf) → max

end;

# Dynamics
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1)) # Drag force
    return [ v, -D/m - 1/r^2, 0 ]
end

F1(x) = begin
    r, v, m = x
    return [ 0, Tmax/m, -b*Tmax ]
end
nothing # hide
```
Now let us compare different discretisations
```@example main
sol_trapeze = solve(ocp; tol=1e-8)
plot(sol_trapeze)

sol_midpoint = solve(ocp, disc_method=:midpoint; tol=1e-8)
plot!(sol_midpoint)

sol_euler = solve(ocp, disc_method=:euler; tol=1e-8)
plot!(sol_euler)

sol_euler_imp = solve(ocp, disc_method=:euler_implicit; tol=1e-8)
plot!(sol_euler_imp)

sol_gl2 = solve(ocp, disc_method=:gauss_legendre_2; tol=1e-8)
plot!(sol_gl2)

sol_gl3 = solve(ocp, disc_method=:gauss_legendre_3; tol=1e-8)
plot!(sol_gl3)
```

## Large problems and AD backend
For some large problems, you may notice that solving spends a long time before the iterations actually begin.
This is due to the computing of the sparse derivatives, namely the Jacobian of the constraints and the Hessian of the Lagrangian, that can become quite costly.
A possible alternative is to set the option `adnlp_backend=:manual`, which will use more basic sparsity patterns.
The resulting matrices are faster to compute but are also less sparse, so this is a trade-off bewteen the AD preparation and the optimization itself.

```@example main
solve(ocp, disc_method=:gauss_legendre_3, grid_size=1000, adnlp_backend=:manual)
nothing # hide
```

## Explicit time grid
The option `time_grid=...` allows to pass the complete time grid vector `t0, t1, ..., tf`, which is typically useful if one wants a non uniform grid. 
In the case of a free initial and/or final time, provide a normalised grid between 0 and 1. 
Note that `time_grid` will override `grid_size` if both are present.

```@example main
sol = solve(ocp, time_grid=[0, 0.1, 0.5, 0.9, 1], display=false)
println(time_grid(sol))
```

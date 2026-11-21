# [The logo](@id examples-logo)

```@raw html
<ExampleFacts id="logo" />
```

The OptimalControl.jl logo is not a drawing. It is the solution of an optimal control
problem, an **energy-minimal low-thrust orbit transfer**, solved once and repeated by
symmetry.

```@raw html
<img src="../assets/logo.svg"      alt="OptimalControl.jl logo" class="oc-logo oc-logo--light" />
<img src="../assets/logo-dark.svg" alt="OptimalControl.jl logo" class="oc-logo oc-logo--dark" />
```

A spacecraft spirals from a low circular orbit out to a higher one under continuous weak
thrust. Two-body dynamics do not care which way is up, so the same optimal transfer, rotated
by $\pm 120°$, gives three trajectories at once, and their three departure points sit
exactly where the three dots of the Julia logo go, winding onto the outer orbit around the
central body.

This page rebuilds that figure from scratch. We load OptimalControl, the solver of the direct
method, and the packages of the figures:

```@example logo
using OptimalControl   # define the problem and solve it
using NLPModelsIpopt   # NLP solver of the direct method
using CairoMakie       # plots of the solution and of the logo
using Colors           # colours of the Julia logo
```

[CairoMakie](https://docs.makie.org) and [Colors](https://github.com/JuliaGraphics/Colors.jl)
are not dependencies of OptimalControl: add them to your environment to run the page.

## The problem

The dynamics are the two-body dynamics, normalised so that the gravitational parameter is
$\mu = 1$. The state is the spacecraft's position and velocity in the orbital plane,
$x = (x_1, x_2, x_3, x_4)$, with the position $(x_1, x_2)$ and the velocity $(x_3, x_4)$, and
the control $u = (u_1, u_2)$ is the thrust acceleration. The spacecraft starts on a circular
orbit of radius $r_0 = 1.1$ and must reach a circular orbit of radius $r_f = 2.2$ at
$t_f = 2\pi$: at the final time it has to be at the right radius, at the right (circular)
speed $1/\sqrt{r_f}$, and with **zero radial velocity**; the final angular position is free.
Along the way it minimises the thrust energy.

:::tabs key:example-problem

== @def

```@example logo
r0 = 1.1      # departure orbit radius
rf = 2.2      # target orbit radius
tf = 2π       # transfer duration — sets how far the trajectory winds

ocp = @def begin
    t ∈ [0, tf], time
    x ∈ R⁴,      state
    u ∈ R²,      control

    x(0) == [r0, 0, 0, 1 / sqrt(r0)]          # circular orbit of radius r0

    x₁(tf)^2 + x₂(tf)^2 == rf^2               # insertion radius
    x₃(tf)^2 + x₄(tf)^2 == 1 / rf             # circular speed at radius rf
    x₁(tf) * x₃(tf) + x₂(tf) * x₄(tf) == 0    # zero radial velocity

    ẋ(t) == [ x₃(t),
              x₄(t),
             -x₁(t) / (x₁(t)^2 + x₂(t)^2)^(3 / 2) + u₁(t),
             -x₂(t) / (x₁(t)^2 + x₂(t)^2)^(3 / 2) + u₂(t) ]

    ∫(u₁(t)^2 + u₂(t)^2) → min
end
nothing # hide
```

== Mathematics

```math
\begin{aligned}
& \text{Minimise} && \int_0^{t_f} \big( u_1^2(t) + u_2^2(t) \big) \,\mathrm{d}t \\[0.5em]
& \text{subject to} && \dot x(t) = \Big( x_3(t),\ x_4(t),\
    -\frac{x_1(t)}{r(t)^3} + u_1(t),\ -\frac{x_2(t)}{r(t)^3} + u_2(t) \Big),
    \quad r = \sqrt{x_1^2 + x_2^2}, \\[0.5em]
& && x(0) = \big( r_0, 0, 0, 1/\sqrt{r_0} \big), \\[0.5em]
& && x_1^2(t_f) + x_2^2(t_f) = r_f^2, \quad x_3^2(t_f) + x_4^2(t_f) = 1/r_f, \\[0.5em]
& && x_1(t_f)\, x_3(t_f) + x_2(t_f)\, x_4(t_f) = 0.
\end{aligned}
```

:::

## Direct method

We solve it by the [direct method](@ref solve-overview-direct-method), with 400 time steps.
Low-thrust transfers are hard to solve from a cold start, so we warm-start with a crude
analytical spiral: the radius grows linearly from $r_0$ to $r_f$, and the angle advances at
the local Keplerian rate $\dot\theta = r^{-3/2}$. The guess is a named tuple of functions of
time (see [Initial guess](@ref solve-initial-guess)):

```@example logo
k = (rf - r0) / tf

function spiral_guess(t)
    r  = r0 + k * t
    θ  = (2 / k) * (1 / sqrt(r0) - 1 / sqrt(r))
    dθ = r^(-3 / 2)
    return [r * cos(θ), r * sin(θ),
            k * cos(θ) - r * dθ * sin(θ), k * sin(θ) + r * dθ * cos(θ)]
end

sol = solve(
    ocp;
    grid_size=400,
    display=false,
    init=(state=spiral_guess, control=t -> [0, 0]),
)

xf = state(sol)(tf)
insertion_radius = sqrt(xf[1]^2 + xf[2]^2)
insertion_speed  = sqrt(xf[3]^2 + xf[4]^2)
radial_velocity  = xf[1] * xf[3] + xf[2] * xf[4]
thrust_energy    = objective(sol)
@show insertion_radius insertion_speed radial_velocity thrust_energy  # hide
nothing  # hide
```

The insertion radius and speed reach their targets, $r_f = 2.2$ and
$1/\sqrt{2.2} \approx 0.674$, and the radial velocity is zero: the spacecraft arrives tangent
to the outer orbit.

```@example logo
@assert successful(sol)                                    # hide
@assert isapprox(insertion_radius, rf; atol=1e-6)          # hide
@assert isapprox(insertion_speed, 1 / sqrt(rf); atol=1e-6) # hide
@assert abs(radial_velocity) < 1e-6                        # hide
nothing                                                    # hide
```

## Looking at the solution

The other pages plot solutions with [Plots.jl](https://docs.juliaplots.org); this one uses
[Makie](https://docs.makie.org) instead. CairoMakie is loaded, so `Makie.plot` is available
for a solution (see [Plot with Makie](@ref results-plot-makie)):

```@example logo
Makie.plot(sol)
```

The thrust $(u_1, u_2)$ stays small throughout: this is a *low-thrust* transfer, which nudges
the orbit rather than forcing it. The right-hand column is the costate, which the solver
returns with the state and the control (see [Solution object](@ref results-solution)): the
direct method gets it from the multipliers of the discretised dynamics.

This page uses the direct method only; the other examples also solve their problem by
[shooting](@ref flows-shooting), the indirect method.

## The trajectory in the plane

The logo lives in the $(x_1, x_2)$ plane. One transfer is a single spiral from the inner
orbit to the outer one.

```@example logo
xt  = state(sol)
arc = [Point2f(xt(t)[1], xt(t)[2]) for t in range(0, tf; length=500)]

circle(r) = [Point2f(r * cos(a), r * sin(a)) for a in range(0, 2π; length=300)]

fig = Figure(size=(460, 460))
ax  = Axis(fig[1, 1]; aspect=DataAspect())
lines!(ax, circle(r0); color=(:gray, 0.5))
lines!(ax, circle(rf); color=(:gray, 0.5))
lines!(ax, arc;        color=:purple, linewidth=3)
scatter!(ax, arc[1];   color=:purple, markersize=14)
fig
```

## Three-fold symmetry

Two-body dynamics are **rotation-equivariant**, and so are the cost and the final conditions,
which only involve the radius, the speed and the radial velocity. Hence, if $t \mapsto x(t)$
is an optimal transfer, the trajectory rotated by a fixed angle is an optimal transfer from
the rotated departure point, with the same cost. Rotating the solved spiral by $0$ and
$\pm 2\pi/3$ gives three transfers for the price of one.

Colour them with the Julia logo palette, drop a dot at each departure point, add the target
orbit in Julia blue and the central body, and the logo is done.

```@example logo
rot(ψ) = [cos(ψ) -sin(ψ); sin(ψ) cos(ψ)]
jl = Colors.JULIA_LOGO_COLORS   # (red, green, blue, purple)

# departure points placed as the Julia-logo dots — green on top
arms = [(7π / 6, jl.red), (π / 2, jl.green), (11π / 6, jl.purple)]

fig = Figure(size=(300, 300), backgroundcolor=:transparent)
ax  = Axis(fig[1, 1]; aspect=DataAspect(), backgroundcolor=:transparent)
hidedecorations!(ax)
hidespines!(ax)
limits!(ax, -1.32rf, 1.32rf, -1.32rf, 1.32rf)

poly!(ax, circle(rf); color=:white)   # white disk behind everything

for (ψ, c) in arms
    P = [Point2f(rot(ψ) * p) for p in arc]
    lines!(ax, P; color=c, linewidth=6.5)
    scatter!(ax, P[1]; color=:white, markersize=40)   # halo
    scatter!(ax, P[1]; color=c,      markersize=30)   # coloured dot
end

lines!(ax, circle(rf); color=jl.blue, linewidth=6.5)   # target orbit
scatter!(ax, Point2f(0, 0); color=:white,  markersize=25)
scatter!(ax, Point2f(0, 0); color=jl.blue, markersize=50)

fig
```

That is the figure the site uses as its logo.

## See also

- [Initial guess](@ref solve-initial-guess): the warm start used here, and the other forms.
- [Plot with Makie](@ref results-plot-makie) and [Plot with Plots](@ref results-plot): plotting a solution.
- [Example gallery](@ref examples-gallery): the other worked problems.

```@raw html
<ExampleNav id="logo" />
```

```@example logo
Main.gallery_thumbnail(fig, "logo")  # hide
nothing  # hide
```

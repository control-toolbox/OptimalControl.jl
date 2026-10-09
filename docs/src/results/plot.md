# [Plot](@id results-plot)

A [`Solution`](@ref results-solution) is drawn with `plot` and `plot!`, which extend
[Plots.jl](https://docs.juliaplots.org). Use `plot` to create a new figure, and `plot!` to add
to an existing one:

```julia
plot(sol, description...; kw...)        # a new plot, which becomes the current one
plot!(sol, description...; kw...)       # adds to the current plot
plot!(plt, sol, description...; kw...)  # adds to the plot plt
```

The same calls draw the solution of a [`Flow`](@ref flows-overview) (last section). The full
signatures are under [Reference](@ref results-plot-reference) at the end of the page.

**Choosing a backend.** This page uses Plots, the default. [Makie.jl](https://docs.makie.org)
draws the same figures, with the same keywords. It is useful for an interactive window, or if
you already draw with Makie: see [Plot with Makie](@ref results-plot-makie).

The table below lists the arguments of `plot`, and the section where each is explained:

| Section | Arguments |
| :--- | :--- |
| [What gets drawn](@ref results-plot-basic) | `size`, `state_style`, `costate_style`, `control_style`, `time_style`, any Plots.jl attribute |
| [Choosing what to draw](@ref results-plot-select) | `description...`: `:state`, `:costate`, `:control`, `:path`, `:dual` |
| [Layout](@ref results-plot-layout) | `layout` |
| [The control](@ref results-plot-control) | `control` |
| [Normalised time](@ref results-plot-time) | `time` |
| [Constraints](@ref results-plot-constraints) | `state_bounds_style`, `control_bounds_style`, `path_style`, `path_bounds_style`, `dual_style` |

To overlay a second solution, see [Adding to an existing plot](@ref results-plot-add). To build
your own figure from the trajectories, see [Custom plots](@ref results-plot-custom).

## Getting started

We take the energy-minimal double integrator, whose solution is u(t) = 6 − 12t (see
[First problem](@ref getting-started-first-problem)):

```@example main
using OptimalControl
using NLPModelsIpopt

t0 = 0
tf = 1
x0 = [-1, 0]
xf = [0, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == xf
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end

sol = solve(ocp; display=false)
nothing # hide
```

`plot` draws a solution once Plots is loaded:

```@example main
using Plots
plot(sol)
```

Without Plots, the call raises an error that names the package to load:

```julia
julia> plot(sol)
ERROR: ExtensionError
│
│  missing dependencies to plot solutions
│
│  Missing  Plots
│
│  Hint     Run: using Plots
└─
```

## [What gets drawn](@id results-plot-basic)

With every group shown, the figure is a grid: the state components on the left, the costate
components on the right, and the control at the bottom. The dashed vertical lines mark the
initial and final times. Plots.jl attributes apply to the whole figure:

```@example main
plot(
    sol, :state, :costate, :control;
    size=(700, 450), legend=:bottomright, grid=false, linewidth=2,
)
```

`state_style`, `costate_style` and `control_style` set the attributes of one group, as a
`NamedTuple`:

```@example main
plot(sol, :state, :costate, :control;
    state_style=(color=:blue,),
    costate_style=(color=:black, linestyle=:dash),
    control_style=(color=:red, linewidth=2),
)
```

`time_style` styles the vertical lines at the initial and final times. Every `*_style` also
accepts `:none`, which hides that group:

```@example main
plot(sol, :state, :costate, :control;
    state_style=:none,
    costate_style=:none,
    control_style=(color=:red,),
    time_style=(color=:green,),
)
```

Three attributes are the exception: `title`, `xlabel` and `ylabel` are set by `plot` itself,
from the names in the problem, and the values you pass are ignored without a warning
([CTBase#569](https://github.com/control-toolbox/CTBase.jl/issues/569)). To change them,
edit the subplot afterwards, for instance `xlabel!(plt[3], "s")` (see
[Custom plots](@ref results-plot-custom)).

```@example main
plt_check = plot(sol, :state; xlabel="s")                     # hide
@assert plt_check.subplots[end][:xaxis][:guide] == "t"        # hide
xlabel!(plt_check[end], "s")                                  # hide
@assert plt_check.subplots[end][:xaxis][:guide] == "s"        # hide
nothing                                                       # hide
```

To look up a Plots.jl attribute and its aliases, use `plotattr("linestyle")` (or any other
name) once Plots is loaded.

## [Choosing what to draw](@id results-plot-select)

The positional symbols select the groups to draw: `:state`, `:costate`, `:control`, and, for
a problem with [path constraints](@ref results-plot-constraints), `:path` and `:dual`.

```julia
plot(sol, :state)    # only the state
plot(sol, :costate)  # only the costate
plot(sol, :control)  # only the control
```

They combine freely:

```@example main
plot(sol, :state, :control)
```

## [Layout](@id results-plot-layout)

`layout=:group` puts each group (state, costate, control) in a single subplot, instead of one
subplot per component:

```@example main
plot(sol; layout=:group)
```

`layout=:split`, the default, is the grid with one subplot per component used above.

## [The control](@id results-plot-control)

For a control with several components, `control=:norm` draws its Euclidean norm instead of
its components, and `control=:all` draws both. Take a problem with a 2-D control:

```@example main
ocp_u = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R², control
    x(0) == [0, 0]
    x(1) == [1, 1]
    ẋ(t) == [u₁(t), x₁(t) + u₂(t)]
    0.5∫(u₁(t)^2 + u₂(t)^2) → min
end
sol_u = solve(ocp_u; display=false)
nothing # hide
```

The maximum principle gives u = p, with p₂ constant and ṗ₁ = −p₂. The final conditions
then give u₁(t) = (16 − 6t)/13 and u₂ = 6/13, so the norm decreases from about 1.31 to 0.90:

```@example main
@assert isapprox(objective(sol_u), 8 / 13; atol=1e-4)                 # hide
@assert isapprox(control(sol_u)(0.5), [13 / 13, 6 / 13]; atol=1e-2)   # hide
nothing                                                               # hide
```

```@example main
plot(sol_u; control=:components, layout=:group, size=(800, 300))  # the default
```

```@example main
plot(sol_u; control=:norm, layout=:group, size=(800, 300))
```

```@example main
plot(sol_u; control=:all, layout=:group)
```

## [Normalised time](@id results-plot-time)

To compare solutions with different final times, `time=:normalize` (or `:normalise`) draws
them against the normalised time s = (t − t₀)/(t_f − t₀) ∈ [0, 1]. Here the same linear-quadratic
problem is solved for three final times:

```@example main
function lqr(tf)
    ocp = @def begin
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [0, 1]
        ẋ(t) == [x₂(t), -x₁(t) + u(t)]
        ∫(0.5(x₁(t)^2 + x₂(t)^2 + u(t)^2)) → min
    end
    return ocp
end

tfs = [3, 5, 30]
solutions = [solve(lqr(tf); display=false) for tf in tfs]

plt = plot()
for (tf, sol) in zip(tfs, solutions)
    plot!(
        plt, sol, :state, :control;
        time=:normalize, label="tf = $tf",
    )
end

using Plots.PlotMeasures
px1 = plot(plt[1]; legend=false)  # x₁
px2 = plot(plt[2]; legend=true)   # x₂
pu = plot(plt[3]; legend=false)   # u
plot(
    px1, px2, pu;
    layout=(1, 3), size=(800, 300), leftmargin=5mm, bottommargin=5mm,
)
```

The longer the horizon, the longer the solution stays near the origin: this is the turnpike
behaviour of linear-quadratic problems.

## [Constraints](@id results-plot-constraints)

A minimum-time transfer, with the control in [−1, 1], and a thrust limited by the speed:
u(t) + v(t) ≤ 1. This mixed constraint involves the state and the control, so it is a
[path constraint](@ref modelling-formulation), not a box.

```@example main
ocp_c = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1, (u_box)
    u(t) + v(t) ≤ 1, (thrust)
    x(0) == [-1, 0]
    q(tf) == 0
    v(tf) == 0
    ẋ(t) == [v(t), u(t)]
    tf → min
end
sol_c = solve(ocp_c; display=false)
plot(sol_c, :state, :costate, :control, :path, :dual)
```

The vehicle accelerates as hard as the thrust limit allows, u = 1 − v, so v(t) = 1 − e^{−t},
then brakes at u = −1 until it stops. The `:path` panel shows u + v, equal to its bound 1 on
the first arc, and the `:dual` panel its multiplier, nonzero on that arc only. The box bounds
of the control are drawn on the control panel.

Switching at t₁ and stopping at t_f = t₁ + v(t₁) requires q(t₁) + v(t₁)²/2 = 0, that is
t₁ − v₁ + v₁²/2 = 1 with v₁ = 1 − e^{−t₁}. This gives t₁ ≈ 1.47 and t_f ≈ 2.24:

```@example main
final_time(sol_c)
```

```@example main
t1 = let t = 1.5                                         # hide
    for _ in 1:20                                        # hide
        v = 1 - exp(-t)                                  # hide
        r = t - v + v^2 / 2 - 1                          # hide
        dr = 1 - exp(-t) + v * exp(-t)                   # hide
        t -= r / dr                                      # hide
    end                                                  # hide
    t                                                    # hide
end                                                      # hide
@assert isapprox(final_time(sol_c), t1 + 1 - exp(-t1); atol=1e-2)   # hide
@assert dim_path_constraints_nl(sol_c) == 1                         # hide
nothing                                                             # hide
```

The style keywords of these groups are `path_style` and `dual_style`, and, for the bounds,
`state_bounds_style`, `control_bounds_style` and `path_bounds_style`:

```@example main
plot(sol_c, :state, :costate, :control, :path, :dual;
    control_bounds_style=(linestyle=:dash,),
    path_style=(color=:green,),
    path_bounds_style=(linestyle=:dash,),
    dual_style=(color=:red,),
    time_style=:none,
)
```

Box constraints are only drawn as bounds: `:path` and `:dual` show the path constraints, not
the boxes. The multipliers of the boxes are read with `dual` (see
[Dual variables](@ref results-solution-duals)).

## [Adding to an existing plot](@id results-plot-add)

`plot!` overlays a second solution, with the same state, costate and control dimensions:

```@example main
ocp2 = @def begin
    t ∈ [t0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(t0) == [-0.5, -0.5]
    x(tf) == xf
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end
sol2 = solve(ocp2; display=false)

plt = plot(sol, :state, :costate, :control; label="sol1", size=(700, 500))
plot!(plt, sol2, :state, :costate, :control; label="sol2", linestyle=:dash)
```

## [Custom plots](@id results-plot-custom)

`state`, `costate` and `control` return functions of time, which Plots draws directly. Here
the absolute value of the control:

```@example main
t = time_grid(sol)
u = control(sol)
plot(t, abs ∘ u; label="|u|", xlabel="t")
```

The subplots of a `plot(sol, ...)` figure can also be reached directly. They come in the
order of the groups requested, one per component: here x₁, x₂, p₁, p₂, then u.

```@example main
plt = plot(sol, :state, :costate, :control)
plot(plt[1])  # x₁
```

```@example main
plot(plt[5])  # u
```

A subplot accepts the usual Plots.jl calls, to annotate it rather than redraw it. For
example, to mark two levels of the control:

```@example main
plot(plt[5])
hline!([-6, 6]; linestyle=:dash, color=:red, label="")
```

In Makie the same takes one more step, since a panel there is an `Axis`, not a subplot: see
[Plot with Makie](@ref results-plot-makie).

## [Plotting a flow](@id results-plot-flow)

The same `plot` call draws the solution of a [`Flow`](@ref) (see [Flows](@ref flows-overview)
for how to build one). Here the flow of the energy problem, with the control u = p₂ given by
the maximum principle, from the exact initial costate p(0) = (12, 6):

```@example main
using OrdinaryDiffEqTsit5

f = Flow(ocp, (x, p) -> p[2])
p0 = [12, 6]
sol_flow = f((t0, tf), x0, p0)
plot(sol_flow)
```

The solution of a flow is kept at the steps of the integrator only, which are few on a smooth
problem ([CTFlows#435](https://github.com/control-toolbox/CTFlows.jl/issues/435)). Here
there are 5 points, so the curves above are polygons:

```@example main
time_grid(sol_flow)
```

```@example main
@assert isapprox(state(sol_flow)(tf), xf; atol=1e-8)   # hide
nothing                                                # hide
```

For a finer curve, pass `saveat` when you **build** the flow, together with `dense=false`. The
call itself only accepts `variable`, `unsafe` and `variable_costate`. Do not leave out
`dense=false`: without it, the call crashes the Julia session
([CTFlows#434](https://github.com/control-toolbox/CTFlows.jl/issues/434)).

```@example main
fine_grid = range(t0, tf, 100)
f2 = Flow(ocp, (x, p) -> p[2]; saveat=fine_grid, dense=false)
sol_flow2 = f2((t0, tf), x0, p0)
plot(sol_flow2)
```

## [Reference](@id results-plot-reference)

```@docs; canonical=false
plot(::CTModels.Solution, ::Symbol...)
plot!(::CTModels.Solution, ::Symbol...)
plot!(::Plots.Plot, ::CTModels.Solution, ::Symbol...)
```

## See also

- [Solution object](@ref results-solution): the functions this page draws.
- [Plot with Makie](@ref results-plot-makie): the same figures with Makie.
- [Save and load](@ref results-save-load): write a solution to disk instead of plotting it.
- [Flows](@ref flows-overview): how to build the `Flow` of the last section.

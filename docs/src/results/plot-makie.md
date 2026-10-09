# [Plot with Makie](@id results-plot-makie)

This site draws with [Plots.jl](@ref results-plot) by default. [Makie.jl](https://docs.makie.org)
is the second backend, at feature parity — same figures, same keywords. The one real
difference is how you call it, and that difference is worth a page of its own.

## When to use it

Stay on [Plots](@ref results-plot) unless one of these is true: you want an interactive
window to pan and zoom into a switching time or a stiff region, or you are already drawing in
Makie elsewhere in your project and want one plotting stack, not two.

## Loading a backend

::: code-group

```julia [CairoMakie]
using CairoMakie   # static — what this page uses
```

```julia [GLMakie]
using GLMakie   # interactive — a window you can pan and zoom
```

:::

## Qualify `plot`

`OptimalControl` exports `plot` and `plot!`: the generic functions of RecipesBase, which
Plots extends. Loading a Makie backend brings in *its* `plot`/`plot!` too — same names,
different functions — so the bare name becomes ambiguous:

```@example main
using OptimalControl
using NLPModelsIpopt
using CairoMakie
nothing # hide
```

```@repl main
try # hide
plot
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

Julia's hint lists the modules that export a `plot`: OptimalControl and CairoMakie, and
here also Plots and GR, which this site's build has loaded. The fix is to always qualify the
Makie call:

```julia
plot(sol)          # [!code error]
Makie.plot(sol)    # [!code ++]
```

Everything else is untouched — `solve`, `state`, `control`, `costate`, `objective`,
`time_grid`, `Flow`, `@def` all resolve exactly as before. `plot` and `plot!` are the only two
names that collide.

## The same figures

```@example main
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

```@example main
Makie.plot(sol)
```

```@example main
Makie.plot(sol; layout=:group, control=:all)
```

A problem with a box constraint on the control and a path constraint, the speed-limited
thrust used on [Plot](@ref results-plot-constraints):

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
Makie.plot(sol_c, :state, :costate, :control, :path, :dual)
```

Every keyword documented on [Plot](@ref results-plot) — `layout`, `control`, `time`, the
`*_style`/`*_bounds_style` keywords, `size`, `plot!` for overlay — works here unchanged. Only
the call itself, and how you customise beyond it, differ.

## What differs

| | Plots | Makie |
| --- | --- | --- |
| the call | `plot(sol)` | `Makie.plot(sol)` — always qualified |
| returns | `Plots.Plot` | `Makie.Figure` |
| reaching one panel | `plt[i]` | `f.content[i]` (an `Axis`) |
| annotating a panel | `Plots.plot!(plt[i], …)`, `hline!` | `lines!(ax, …)`, `hlines!`, `text!` |
| `*_style` contents | any Plots attribute | Makie attributes only — an unknown one throws |
| a solution into an axis you built | `plot!(plt[i], sol)` | not supported — `Makie.plot!` is figure-level (see below) |

The `*_style` keywords hold backend attributes, not a shared vocabulary — a Plots-only name
raises instead of being silently dropped:

```@repl main
try # hide
Makie.plot(sol, :state; state_style=(markershape=:circle,))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Annotating the figure

`plot`/`plot!` build a whole figure in one call — a convenience on top of the backend, not the
backend itself. To add something of your own, reach into the figure and use Makie directly. A
time-minimal problem makes this concrete: mark the control bounds and the switching time.
From x(0) = (0, 1), the optimal control is u = −1, then u = +1: the final time is
t_f = 1 + √2, and the switch happens at t = 1 + √2/2 ≈ 1.71, not at t_f/2.

```@example main
ocp_bb = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1
    x(0) == [0, 1]
    x(tf) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    tf → min
end
sol_bb = solve(ocp_bb; display=false)
nothing # hide
```

```@example main
f = Makie.plot(sol_bb, :state, :control)
ax = f.content[3]   # the control panel — see "Where the panels are" below
f
```

The switching time is read off the control: the first grid point where u becomes positive.

```@example main
u_bb = control(sol_bb)
t_switch = first(t for t in time_grid(sol_bb) if u_bb(t) > 0)
```

```@example main
@assert isapprox(final_time(sol_bb), 1 + sqrt(2); atol=1e-3)        # hide
@assert isapprox(t_switch, 1 + sqrt(2) / 2; atol=2e-2)              # hide
nothing                                                             # hide
```

```@example main
Makie.hlines!(ax, [-1.0, 1.0]; color=:red, linestyle=:dash)
Makie.vlines!(ax, [t_switch]; color=:green)
Makie.text!(ax, t_switch, 0.0; text="switch")
f
```

Two calls do the annotating here, and they are not interchangeable:

- `Makie.plot!(f, sol)` overlays another **solution** onto the whole figure — the CT
  extension, `Figure`-level, the Makie counterpart of `Plots.plot!(plt, sol2)`.
- `hlines!(ax, …)`, `vlines!(ax, …)`, `lines!(ax, …)`, `text!(ax, …)` add **native** Makie
  series onto one panel — plain Makie, `Axis`-level.

On Plots, `plot!` does both jobs — overlay a solution *and* add a native series, the same
function either way — which is why a reader coming from Plots reaches for `Makie.plot!(ax,
sol)` here. It fails:

```@repl main
try # hide
Makie.plot!(ax, sol_bb)
catch e # hide
print(replace(sprint(showerror, e), r"Solution\{.*"s => "Solution{…}}")) # hide
end # hide
```

```julia
Makie.plot!(ax, sol_bb)                    # [!code error]
Makie.lines!(ax, time_grid(sol_bb), …)     # [!code ++]
```

Use the native call instead — `lines!`, `hlines!`, `scatter!`, `text!` — for anything you draw
yourself.

## Where the panels are

Each panel is an `Axis`, in the order the description symbols were given, and it carries the
component's label — so you can check you grabbed the right one instead of counting:

```@example main
[(title=string(ax.title[]), ylabel=string(ax.ylabel[])) for ax in f.content]
```

Same ordering [Plot](@ref results-plot) documents for `plt[i]`.

## Building a figure from scratch

When annotating an existing panel is not enough — a custom layout, a different kind of plot
entirely — draw straight from the accessors instead of going through `plot` at all:

```@example main
tg = time_grid(sol_bb)
x_bb = state(sol_bb)

fig = Figure(size=(500, 300))
axq = Axis(fig[1, 1]; xlabel="x₁", ylabel="x₂", title="phase portrait")
Makie.lines!(axq, [x_bb(t)[1] for t in tg], [x_bb(t)[2] for t in tg])
fig
```

[The logo](@ref examples-logo) builds a whole figure this way, orbit trajectories and all — the
worked example for this approach.

## Interactive plots

`GLMakie` opens a real window instead of rendering to an image — useful to pan and zoom into a
switching structure. It cannot run inside this site's own (headless) build, so this block is
illustrative only:

```julia
using GLMakie

f = Makie.plot(sol)   # opens a window; unaffected otherwise
```

## Flows

The same call works on the solution of a [`Flow`](@ref) — see [Flows](@ref flows-overview)
for how to build one. Here from the exact initial costate p(0) = (12, 6), as on
[Plot](@ref results-plot-flow):

```@example main
using OrdinaryDiffEqTsit5

p0 = [12, 6]
flow = Flow(ocp, (x, p) -> p[2])
sol_flow = flow((t0, tf), x0, p0)
Makie.plot(sol_flow)
```

## [Reference](@id results-plot-makie-reference)

```@docs; canonical=false
CairoMakie.Makie.plot(::CTModels.Solution, ::Symbol...)
CairoMakie.Makie.plot!(::CairoMakie.Makie.Figure, ::CTModels.Solution, ::Symbol...)
```

## See also

- [Plot](@ref results-plot) — the Plots backend and the full keyword reference; every keyword
  there applies here too.
- [The logo](@ref examples-logo) — a whole figure built from the accessors, Makie throughout.
- [Flows](@ref flows-overview) — building the `Flow` used in the last section.

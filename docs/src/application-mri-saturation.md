# [MRI: saturation](@id mri-saturation)

## Definition of the problem

The parameters with the dynamics

```@example main
import OptimalControl: ⋅
⋅(a::Number, b::Number) = a*b

# Blood case
T₁ = 1.35 # s
T₂ = 0.05

ω = 2π⋅32.3 # Hz
γ = 1/(ω⋅T₁)
Γ = 1/(ω⋅T₂)

δ = γ - Γ
zs = γ / 2δ # singular ordinate

F₀(y, z) = [ -Γ⋅y, γ⋅(1-z) ]
F₁(y, z) = [ -z, y ]
nothing # hide
```

Then, we can define the problem

```@example main
using OptimalControl
@def ocp begin

    tf ∈ R, variable
    t ∈ [ 0, tf ], time
    q = [ y, z ] ∈ R², state
    u ∈ R, control

    tf ≥ 0
    q(0)  == [ 0, 1 ]
    q(tf) == [ 0, 0 ]

    -1 ≤ u(t) ≤ 1

    q̇(t) == F₀(q(t)...) + u(t) * F₁(q(t)...)

    tf → min

end
nothing # hide
```

## Direct method

```@example main
using NLPModelsIpopt
using Printf
using Plots
nothing # hide
```

```@example main
sol = solve(ocp, grid_size=50, tol=1e-6, display=false, init=(state=[-0.5, 0.0],))

#@printf("T %.2f objective %.6f iterations %d\n", T, sol1.objective, sol1.iterations)

plot(sol; size=(700, 500))
nothing # hide
```

Solve it

```@example main
sol = solve(ocp, init=sol, grid_size=500, tol=1e-10)
nothing # hide
```

The plot function.


```@raw html
<article class="docstring">
<header>
    <a class="docstring-article-toggle-button fa-solid fa-chevron-right" href="javascript:;" title="Expand docstring"> </a>
    <code>spinplot</code> — <span class="docstring-category">Function</span>
</header>
<section style="display: none;">
    <div>
    <pre>
    <code class="language-julia hljs">
    </code>
    <button class="copy-button fa-solid fa-copy" aria-label="Copy this code ;opblock" title="Copy"></button>
    </pre>
    </div>
</section>
</article>
```

```@example main
using Plots.PlotMeasures
function spinplot(sol; kwargs...)

    y2 = cos(asin(zs))
    y1 = -y2

    t = sol.times
    y = t -> sol.state(t)[1]
    z = t -> sol.state(t)[2]
    u = sol.control

    # styles
    Bloch_ball_style = (seriestype=[:shape, ], color=:grey, linecolor=:black, legend=false, fillalpha=0.1, aspect_ratio=1)
    axis_style = (color=:black, linewidth=0.5)
    state_style = (label=:none, linewidth=2, color=1)
    initial_point_style = (seriestype=:scatter, color=:1, linewidth=0)
    control_style = (label=:none, linewidth=2)

    # state trajectory in the Bloch ball
    θ = LinRange(0, 2π, 100)
    state_plt = plot(cos.(θ), sin.(θ); Bloch_ball_style...) # Bloch ball
    plot!(state_plt, [-1, 1], [ 0,  0]; axis_style...)      # horizontal axis 
    plot!(state_plt, [ 0, 0], [-1,  1]; axis_style...)      # vertical axis
    plot!(state_plt, [y1, y2], [zs, zs]; linestyle=:dash, axis_style...) # singular line
    plot!(state_plt, y.(t), z.(t); state_style...)
    plot!(state_plt, [0], [1]; initial_point_style...)
    plot!(state_plt; xlims=(-1.1, 0.1), ylims=(-0.1, 1.1), xlabel="y", ylabel="z")

    # control
    control_plt  = plot(t, u.(t); control_style...)
    plot!(control_plt; ylims=(-0.1, 1.1), xlabel="t", ylabel="u")

    return plot(state_plt, control_plt; layout=(1, 2), bottommargin=15px, kwargs...)

end
nothing # hide
```

and plot the solution

```@example main
spinplot(sol; size=(700, 350))
```

```@example main
plot(sol; size=(700, 500))
```
# LQR example

We consider the following Linear Quadratic Regulator (LQR) problem which consists in minimising

```math
    \frac{1}{2} \int_{0}^{t_f} \left( x_1^2(t) + x_2^2(t) + u^2(t) \right) \, \mathrm{d}t 
```

subject to the constraints

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = -x_1(t) + u(t), \quad u(t) \in \R
```

and the initial condition

```math
    x(0) = (0,1).
```

We define $A$ and $B$ as

```math
    A = \begin{pmatrix} 0 & 1 \\ -1 & 0 \\ \end{pmatrix}, \quad
    B = \begin{pmatrix} 0 \\ 1 \\ \end{pmatrix}
```

in order to get $\dot{x} = Ax + Bu$
and we aim to solve this optimal control problem for different values of $t_f$.
First, we need to import the `OptimalControl.jl` package.

```@example main
using OptimalControl
```

Then, we can define the problem parameterized by the final time `tf`.

```@example main
x0 = [ 0
       1 ]

A  = [ 0 1
      -1 0 ]

B  = [ 0
       1 ]

function lqr(tf)

    @def ocp begin
        t ∈ [ 0, tf ], time
        x ∈ R², state
        u ∈ R, control
        x(0) == x0
        ẋ(t) == A * x(t) + B * u(t)
        ∫( 0.5(x₁(t)^2 + x₂(t)^2 + u(t)^2) ) → min
    end

    return ocp
end;
nothing # hide
```

We solve the problem for $t_f \in \{3, 5, 30\}$.

```@example main
solutions = []   # empty list of solutions
tfs = [3, 5, 30]

for tf ∈ tfs
    solution = solve(lqr(tf), display=false)
    push!(solutions, solution)
end
nothing # hide
```

We choose to plot the solutions considering a normalized time $s=(t-t_0)/(t_f-t_0)$.
We thus introduce the function `rescale` that rescales the time and redefine the state, costate and control variables.

```@example main
function rescale(sol)

    # initial and final times
    t0 = sol.times[1]
    tf = sol.times[end]

    # s is the rescaled time between 0 and 1
    t(s)  = t0 + s * ( tf - t0 )

    # rescaled times
    sol.times = ( sol.times .- t0 ) ./ ( tf - t0 )

    # redefinition of the state, control and costate
    x = sol.state
    u = sol.control
    p = sol.costate

    sol.state   = x∘t   # s → x(t(s))
    sol.control = u∘t   # s → u(t(s))
    sol.costate = p∘t   # s → p(t(s))

    return sol
end
nothing # hide
```

!!! note "Nota bene"

    The `∘` operator is the composition operator. Hence, `x∘t` is the function `s -> x(t(s))`.

!!! tip

    Instead of defining the function `rescale`, you can consider $t_f$ as a parameter and define the following
    optimal control problem:
    
    ```julia
    @def ocp begin
        s ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        x(0) == x0
        ẋ(s) == tf * ( A * x(s) + B * u(s) )
        ∫( 0.5(x₁(s)^2 + x₂(s)^2 + u(s)^2) ) → min
    end
    ```

Finally we choose to plot only the state and control variables.

```@example main
using Plots.PlotMeasures # for leftmargin, bottommargin

# we construct the plots from the solutions with default options
plt = plot(rescale(solutions[1]))
for sol in solutions[2:end]
    plot!(plt, rescale(sol))
end

# we plot only the state and control variables and we add the legend
px1 = plot(plt[1], legend=false, xlabel="s", ylabel="x₁")
px2 = plot(plt[2], label=reshape(["tf = $tf" for tf ∈ tfs], 
    (1, length(tfs))), xlabel="s", ylabel="x₂")
pu  = plot(plt[5], legend=false, xlabel="s", ylabel="u")
plot(px1, px2, pu, layout=(1, 3), size=(800, 300), leftmargin=5mm, bottommargin=5mm)
```

!!! note

    We can observe that $x(t_f)$ converges to the origin as $t_f$ increases.

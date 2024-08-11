# A simple Linear–quadratic regulator example

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
First, we need to import the `OptimalControl.jl` package to define the optimal control problem and `NLPModelsIpopt.jl` to solve it. 
We also need to import the `Plots.jl` package to plot the solutions.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
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

    ocp = @def begin
        t ∈ [0, tf], time
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

We plot the state and control variables considering a normalized time $s=(t-t_0)/(t_f-t_0)$, thanks to the keyword argument `time=:normalized` of the `plot` function.

```@example main
plt = plot(solutions[1], time=:normalized)
for sol ∈ solutions[2:end]
    plot!(plt, sol, time=:normalized)
end

# we plot only the state and control variables and we add the legend
N = length(tfs)
px1 = plot(plt[1], legend=false, xlabel="s", ylabel="x₁")
px2 = plot(plt[2], label=reshape(["tf = $tf" for tf ∈ tfs], (1, N)), xlabel="s", ylabel="x₂")
pu  = plot(plt[5], legend=false, xlabel="s", ylabel="u")

using Plots.PlotMeasures # for leftmargin, bottommargin
plot(px1, px2, pu, layout=(1, 3), size=(800, 300), leftmargin=5mm, bottommargin=5mm)
```

!!! note "Nota bene"

    We can observe that $x(t_f)$ converges to the origin as $t_f$ increases.

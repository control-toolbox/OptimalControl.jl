using OptimalControl
using Markdown
using Plots

md"""

# Basic example

We solve using the default method in `OptimalControl.jl` the following simple problem:

```math
    \frac{1}{2} \int_0^1  u^2(t)\,\mathrm{d}t \to \min 
```
subject to
```math
    \dot{x}_1(t) = x_2(t),\quad \dot{x}_2(t) = u(t)\\
    x(0)=(-1,0),\quad x(1)=(0,0).
```
"""

t0 = 0
tf = 1

ocp = @def begin

    t ∈ [ t0, tf], time
    x ∈ R^2, state
    u ∈ R, control

    x(t0) == [ -1, 0 ] 
    x(tf) == [  0, 0 ] 

    ẋ(t) == A*x(t) + B*u(t)

    ∫( 0.5u(t)^2 ) → min

end

A = [ 0 1
      0 0 ]
B = [ 0
      1 ]

N = 50
sol = solve(ocp, grid_size=N)
plot(sol)
savefig("fig_basic.png")

md"![fig](fig_basic.png)"

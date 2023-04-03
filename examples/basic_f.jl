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

# Parameters
t0 = 0
tf = 1

# Model
ocp = Model()

time!(ocp, [t0, tf])
state!(ocp, 2)
control!(ocp, 1)

constraint!(ocp, :initial, [ -1, 0 ])
constraint!(ocp, :final,   [  0, 0 ])

A = [ 0 1
      0 0 ]
B = [ 0
      1 ]

constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)

objective!(ocp, :lagrange, (x, u) -> 0.5u^2)

# Solve
N = 50
sol = solve(ocp, grid_size=N)

# Plot
plot(sol)
savefig("fig_basic.png")
md"![fig](fig_basic.png)"

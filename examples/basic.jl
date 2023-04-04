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

# Abstract model
ocp_a = @__def begin

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

# Functional model
ocp_f = Model()

time!(ocp, [t0, tf])
state!(ocp, 2)
control!(ocp, 1)

constraint!(ocp, :initial, [ -1, 0 ])
constraint!(ocp, :final,   [  0, 0 ])
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)

objective!(ocp, :lagrange, (x, u) -> 0.5u^2)

# Solve
ocp = ocp_f
N = 50
sol = solve(ocp, grid_size=N)

# Plot
plot(sol)
savefig("basic_fig.png")
md"![fig](basic_fig.png)"

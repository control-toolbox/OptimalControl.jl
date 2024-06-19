# [Batch](@id batch)

Let us consider a wagon moving along a rail, whom acceleration can be controlled by a force $u$.
We denote by $x = (x_1, x_2)$ the state of the wagon, that is its position $x_1$ and its velocity $x_2$.

```@raw html
<img src="./assets/chariot.png" style="display: block; margin: 0 auto 20px auto;" width="300px">
```

We assume that the mass is constant and unitary and that there is no friction. The dynamics we consider is given by

```math
    \dot x_1(t) = x_2(t), \quad \dot x_2(t) = u(t), , \quad u(t) \in \R,
```

which is simply the [double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674) system.
Les us consider a transfer starting at time $t_0 = 0$ and ending at time $t_f = 1$, for which we want to minimise the transfer energy

```math
    \frac{1}{2}\int_{0}^{1} u^2(t) \, \mathrm{d}t
```

```@example main
using OptimalControl

t0 = 0      # initial time
tf = 90     # final time
s0 = 0.1
p0 = 0.001
r0 = 0.1
V0 = 0.003

@def ocp begin

    t ∈ [ t0, tf ], time
    φ = (s, p, r, V) ∈ R⁴, state 
    α ∈ R, control

    s(t0) == s0
    p(t0) == p0
    r(t0) == r0
    V(t0) == V0
    
    s(t) ≥ 0
    p(t) ≥ 0
    0 ≤ r(t) ≤ 1
    V(t) ≥ 0
    0 ≤ α(t) ≤ 1

    φ̇(t) == F0(φ(t)) + α(t) * F1(φ(t))

    V(tf) → max

end

# Dynamics
kᵣ = 1.1
kₘ = 1.2
Kᵣ = 1.3
Kₘ = 1.4

wᵣ(p) = kᵣ * p / (Kᵣ + p)
wₘ(s) = kₘ * s / (Kₘ + s)

F0(φ) = begin
    s, p, r, V = φ
    res = [ -wₘ(s) * (1 - r) * V
             wₘ(s) * (1 - r) - wᵣ(p) * r * (p + 1)
            -wᵣ(p) * r^2
             wᵣ(p) * r * V ]
    return res
end

F1(φ) = begin
    s, p, r, V = φ
    res = [ 0, 0, wᵣ(p) * r, 0 ]
    return res
end

sol0  = solve(ocp, grid_size=1000)
println("Objective ", sol0.objective, " after ", sol0.iterations, " iterations")
sol1 = solve(ocp, grid_size=20)
println("Objective ", sol1.objective, " after ", sol1.iterations, " iterations")
sol2 = solve(ocp, grid_size=1000, init=sol1)
println("Objective ", sol2.objective, " after ", sol2.iterations, " iterations")

plot(sol1, size=(600, 600))
plot!(sol2)
```
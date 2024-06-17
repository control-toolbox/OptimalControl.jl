# batch.jl

using OptimalControl

t0 = 0      # initial time
tf = 300    # final time
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

end;

# Dynamics
const kᵣ = 1.1
const kₘ = 1.2
const Kᵣ = 1.3
const Kₘ = 1.4

wᵣ(p) = kᵣ * p / (Kᵣ + p)
wₘ(s) = kₘ * s / (Kₘ + s)

F0(s, p, r, V) =
    [ -wₘ(s) * (1 - r) * V
       wₘ(s) * (1 - r) - wᵣ(p) * r * (p + 1)
      -wᵣ(p) * r^2
       wᵣ(p) * r * V ]

F1(s, p, r, V) = [ 0, 0, wᵣ(p) * r, 0 ]

direct_sol1 = solve(ocp, grid_size=100)
direct_sol2 = solve(ocp, grid_size=1000)

plt1 = plot(direct_sol1, size=(600, 600))
plt2 = plot(direct_sol2, size=(600, 600))
plot(plt1, plt2, layout=(1, 2))
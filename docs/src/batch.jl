# batch.jl

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

sol1 = solve(ocp, grid_size=20)
sol2 = solve(ocp, grid_size=1000, init=sol1)
sol2 = solve(ocp, grid_size=1000)

plot(sol1, size=(600, 600))
plot!(sol2)
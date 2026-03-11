using OptimalControl
using OrdinaryDiffEq

t0 = 0
tf = 2
x0 = 1
xf = 1/2
lb = 0.1

ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1

    x(t0) == x0
    x(tf) == xf

    x(t) - lb ≥ 0           # state constraint

    ẋ(t) == u(t)

    ∫(x(t)^2) → min
end

u(x, p) = 0     # boundary control
c(x, u) = x-lb  # constraint
η(x, p) = 2x    # dual variable

f1 = Flow(ocp, (x, p) -> -1)
f2 = Flow(ocp, u, c, η)
f3 = Flow(ocp, (x, p) -> +1)

t1 = 0.9
t2 = 1.6
f = f1 * (t1, f2) * (t2, f3)

p0 = -0.982237546583301
xf, pf = f(t0, x0, p0, tf)
xf

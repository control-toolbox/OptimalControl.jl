using OptimalControl
using NLPModelsIpopt
using Plots

t0 = 0
tf = π/4
x0 = 0
xf = tan(π/4) - 2log(√(2)/2)

ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == u(t) * (1 + tan(t))

    0.5∫(u(t)^2) → min
end;

sol = solve(ocp; print_level=4);

plt = plot(sol, ocp)

u(t) = 1 + tan(t)
plot!(plt[3], range(t0, tf, 101), u; color=:red, legend=false)

using OrdinaryDiffEq
u(t, x, p) = p * (1 + tan(t))
f = Flow(ocp, u; autonomous=false)
p0 = 1
xf, pf = f(t0, x0, p0, tf)

xf - (tan(π/4) - 2log(√(2)/2))

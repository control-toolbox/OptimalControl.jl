using OptimalControl
using NLPModelsIpopt
using Plots

c0(N) = repeat([-1, 0], N)
cf(N) = repeat([0, 0], N)
f(x, u) = [x[2], u]
f(x, u, N) = reduce(vcat, [f(x[(2i - 1):2i], u) for i in 1:N])

N = 3
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R^(2N), state
    u ∈ R, control
    x(0) == c0(N)
    x(1) == cf(N)
    ẋ(t) == f(x(t), u(t), N)
    ∫(0.5u(t)^2) → min
end

sol = solve(ocp)

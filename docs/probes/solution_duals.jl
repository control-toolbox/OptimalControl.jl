# Page: results/solution.md, note "Sign and scale of the multipliers".
# Claims: the same constraint, written as a box or as a path constraint, gets
# multipliers of opposite signs, and only the path one is divided by the time step
# (CTDirect#639); with :exa, the boundary and path multipliers come back as zeros
# (CTDirect#405). Both are known bugs: this probe checks the current behaviour, and fails
# when they are fixed.

include("common.jl")
using OptimalControl, NLPModelsIpopt

box = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1, (u_con)
    x(0) == [-1, 0], (start)
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    tf → min
end

path = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) + v(t) - v(t) ≤ 1, (u_con)
    x(0) == [-1, 0], (start)
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    tf → min
end

# u = 1 on [0, 1), u = -1 on (1, 2], p₂(t) = 1 - t: p₂(0.5) = 0.5, upper bound active.
μ(ocp, N) = dual(solve(ocp; grid_size=N, display=false), ocp, :u_con)(0.5)

μ_box_100, μ_box_400 = μ(box, 100), μ(box, 400)
μ_path_100, μ_path_400 = μ(path, 100), μ(path, 400)

check(
    μ_box_100 < 0 && μ_path_100 > 0,
    "box and path multipliers have opposite signs where the upper bound is active " *
    "(box $(round(μ_box_100; sigdigits=3)), path $(round(μ_path_100; sigdigits=3)))",
)
check(
    isapprox(μ_box_100 / μ_box_400, 4; rtol=0.1),
    "the box multiplier scales with the time step (÷ 4 when the grid is 4 times finer)",
)
check(
    isapprox(μ_path_100, 0.5; atol=0.02) && isapprox(μ_path_400, 0.5; atol=0.01),
    "the path multiplier converges to p₂(0.5) = 0.5",
)

sol_exa = solve(box, :exa; display=false)
check(
    all(iszero, dual(sol_exa, box, :start)),
    "with :exa, the multiplier of the initial condition is zero",
)
check(
    all(iszero, boundary_constraints_dual(sol_exa)),
    "with :exa, all boundary multipliers are zero",
)
sol_adnlp = solve(box, :adnlp; display=false)
check(
    isapprox(dual(sol_adnlp, box, :start), [1, 1]; atol=1e-2),
    "with :adnlp, the multiplier of the initial condition is p(0) = (1, 1)",
)

# Note "The costate is shifted by half a step": p(t_i) ≈ p(t_i + h/2) with :midpoint, and
# p(t_i + h) with Gauss–Legendre (CTDirect#640, known bug).
energy = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0], (start)
    x(1) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end
offset(scheme) =
    let s = solve(energy; scheme, grid_size=100, display=false)
        ((6 - costate(s)(0.5)[2]) / 12 - 0.5) / 0.01   # p₂(t) = 6 - 12t, h = 0.01
    end
check(
    isapprox(offset(:midpoint), 0.5; atol=0.02),
    "with :midpoint, the costate at t is p(t + h/2)",
)
check(
    isapprox(offset(:gauss_legendre_2), 1; atol=0.02),
    "with :gauss_legendre_2, the costate at t is p(t + h)",
)

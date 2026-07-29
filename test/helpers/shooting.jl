# ============================================================================
# Shooting helpers
# ============================================================================
# Ported from `CTFlows.jl/test/suite/integration/utils.jl`, so the indirect
# tests here check the same two things upstream does — and check them the same
# way.
#
# This file is NOT a module: it is `include`d at module scope inside each test
# module, which must already import
#
#     using Test: Test
#     using NonlinearSolve: NonlinearProblem, SimpleNewtonRaphson, solve
#
# (The `solve` here is NonlinearSolve's, not OptimalControl's — import
# qualified or the two collide.)

"""
    test_shooting(shoot!, ξ_exact, ξ_guess; atol=1e-8)

Check a shooting function two ways, and return the solution.

`shoot!` must have the flat-vector signature `shoot!(s, ξ) → nothing`, with
`length(s) == length(ξ)`.

1. `‖shoot!(s, ξ_exact)‖ < atol` — the PMP derivation is right. This is the
   assertion that catches a bad Hamiltonian or a mis-stated switching
   condition: a wrong derivation still converges, just to the wrong thing.
2. Newton from `ξ_guess` reaches a root, and `‖shoot!(s, ξ_opt)‖ < atol` —
   the problem is actually solvable from a realistic starting point.

Returns `ξ_opt`, for downstream quantitative assertions.
"""
function test_shooting(shoot!, ξ_exact, ξ_guess; atol=1e-8)
    n = length(ξ_exact)
    s = zeros(n)

    shoot!(s, ξ_exact)
    Test.@test sqrt(sum(abs2, s)) < atol

    prob = NonlinearProblem((s, ξ, _) -> shoot!(s, ξ), ξ_guess)
    nl = solve(
        prob, SimpleNewtonRaphson(); abstol=1e-10, reltol=1e-10, show_trace=Val(false)
    )

    sc = zeros(n)
    shoot!(sc, nl.u)
    Test.@test sqrt(sum(abs2, sc)) < atol

    return nl.u
end

"""
    perturb(ξ, ε=0.1)

A starting guess `ε` away from `ξ`, relative to each component's own scale.

Shooting from the exact solution proves nothing about the basin, and a
hard-coded guess per problem is one more constant to keep in sync. This derives
one from the reference the problem already carries.
"""
perturb(ξ, ε=0.1) = ξ .* (1 + ε)

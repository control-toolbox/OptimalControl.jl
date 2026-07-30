# ============================================================================
# hamiltonian_type = :total | :partial
# ============================================================================
# `Flow(ocp, law)` and `Flow(h̃, law)` take a `hamiltonian_type`:
#
#   :total   (default) composes a `Data.ComposedHamiltonian` — it substitutes
#            the law into H̃ and differentiates *through* it:
#                ẋ = ∂H/∂p = ∂H̃/∂p + (∂H̃/∂u)(∂u/∂p)
#   :partial builds a `Systems.PseudoHamiltonianSystem` and takes partials of
#            H̃ at the frozen feedback value:
#                ẋ = ∂H̃/∂p |_{u = u(x,p)}
#
# They coincide **iff the law is stationary for H̃** (∂H̃/∂u = 0 on the arc).
# Every optimal control law is, which is why the two modes agree everywhere in
# the indirect suite and it is easy to believe they are redundant.
#
# They are not, and this file proves it. On the energy double integrator with
# H̃ = p₁x₂ + p₂u − ½u², the minimiser is u* = p₂. Feed it u = p₂ + 1 instead:
#
#   ∂H̃/∂u = p₂ − u = −1 ≠ 0,  ∂u/∂p₂ = 1
#   :partial → ẋ₂ = u        = p₂ + 1   ("apply this feedback")
#   :total   → ẋ₂ = u + (−1)(1) = p₂    (the perturbation cancels)
#
# Both are correct for what they compute. Picking the wrong one on a law that
# is not stationary silently integrates different dynamics — no error, just a
# different answer. That is what makes this worth a test rather than a docstring.

module TestHamiltonianType

using Test: Test
using OptimalControl
using NonlinearSolve: NonlinearProblem, SimpleNewtonRaphson, solve
import OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

include(joinpath(@__DIR__, "..", "..", "helpers", "shooting.jl"))

# The three shooting derivations below used to be written out here a second
# time — once per problem, independently of `suite/indirect/test_shooting_sweep.jl`.
# They now come from `pb.shoot_builder(; hamiltonian_type=ht)`, the single copy
# both files consume (see `test/problems/common.jl`). What stays genuinely
# specific to *this* file is the `ht` sweep itself: `shoot_builder` only fixes
# the derivation, not which mode it is checked under.

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const HAMILTONIAN_TYPES = (:total, :partial)

function test_hamiltonian_type()
    Test.@testset "hamiltonian_type" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # The two modes agree on a stationary law — across both front ends
        # ====================================================================

        Test.@testset "energy double integrator (smooth, single arc)" begin
            for form in TestProblems.FORMS, ht in HAMILTONIAN_TYPES
                Test.@testset "$form / $ht" begin
                    pb = TestProblems.build(:double_integrator_energy, form)
                    shoot!, ξ_exact, ξ_guess = pb.shoot_builder(; hamiltonian_type=ht)

                    ξ_opt = test_shooting(shoot!, ξ_exact, ξ_guess)
                    Test.@test ξ_opt ≈ ξ_exact atol = 1e-6

                    # Reconstruction reaches the reference objective — the one
                    # assertion `shoot_builder` itself has no reason to carry,
                    # since it is specific to this file's purpose, not to the
                    # derivation.
                    t0, tf, x0 = pb.data.t0, pb.data.tf, pb.data.x0
                    f = Flow(pb.ocp, (x, p) -> p[2]; hamiltonian_type=ht)
                    sol = f((t0, tf), x0, ξ_opt)
                    Test.@test objective(sol) ≈ pb.objective rtol = 1e-8
                end
            end
        end

        Test.@testset "time-optimal double integrator (bang-bang, NonFixed)" begin
            # Bang-bang: the control is *constant* on each arc, so it is
            # trivially stationary there and the modes must agree.
            for form in TestProblems.FORMS, ht in HAMILTONIAN_TYPES
                Test.@testset "$form / $ht" begin
                    pb = TestProblems.build(:double_integrator_time, form)
                    shoot!, ξ_exact, ξ_guess = pb.shoot_builder(; hamiltonian_type=ht)

                    ξ_opt = test_shooting(shoot!, ξ_exact, ξ_guess)
                    Test.@test ξ_opt ≈ ξ_exact atol = 1e-6
                end
            end
        end

        Test.@testset "Goddard (B+ S C B0, constrained arc)" begin
            # The full workout: four arcs, one of them constrained, free final
            # time. Every law here is the PMP minimiser, so again the modes
            # must agree — this time through a `constraint`/`multiplier` pair.
            #
            # Residual at the reference only, no Newton: the `:total`
            # convergence sweep already lives in
            # `suite/indirect/test_shooting_sweep.jl`, and redoing it here for
            # both `ht` values would be the fixture's ~90 s cost paid twice for
            # the same conclusion. What is unique to this file — that `:total`
            # and `:partial` agree — only needs the reference point.
            for form in TestProblems.FORMS, ht in HAMILTONIAN_TYPES
                Test.@testset "$form / $ht" begin
                    pb = TestProblems.build(:goddard, form)
                    shoot!, ξ_exact, _ = pb.shoot_builder(; hamiltonian_type=ht)

                    s = zeros(length(ξ_exact))
                    shoot!(s, ξ_exact)
                    Test.@test sqrt(sum(abs2, s)) < 1e-6
                end
            end
        end

        # ====================================================================
        # …and disagree on a law that is NOT stationary
        # ====================================================================

        Test.@testset "the two modes are not redundant" begin
            pb = TestProblems.DoubleIntegratorEnergy()
            t0, tf, x0, p0 = pb.data.t0, pb.data.tf, pb.data.x0, pb.data.p0

            # u = p₂ + 1 is *not* the minimiser of H̃ = p₁x₂ + p₂u − ½u².
            law(x, p) = p[2] + 1.0

            f_total = Flow(pb.ocp, law; hamiltonian_type=:total)
            f_partial = Flow(pb.ocp, law; hamiltonian_type=:partial)

            xf_total, _ = f_total(t0, x0, p0, tf)
            xf_partial, _ = f_partial(t0, x0, p0, tf)

            # They must genuinely differ — if this ever passes by accident the
            # two code paths have silently merged.
            Test.@test !isapprox(xf_total, xf_partial; atol=1e-6)

            # And each must differ the way the algebra says:
            #   :partial integrates ẋ₂ = u = p₂ + 1
            #   :total   integrates ẋ₂ = u + (∂H̃/∂u)(∂u/∂p₂) = (p₂+1) − 1 = p₂
            # so `:total` reproduces the *stationary* law's trajectory exactly.
            xf_stationary, _ = Flow(pb.ocp, (x, p) -> p[2])(t0, x0, p0, tf)
            Test.@test xf_total ≈ xf_stationary atol = 1e-8
            Test.@test !isapprox(xf_partial, xf_stationary; atol=1e-6)
        end

        Test.@testset "default is :total" begin
            pb = TestProblems.DoubleIntegratorEnergy()
            t0, tf, x0, p0 = pb.data.t0, pb.data.tf, pb.data.x0, pb.data.p0
            law(x, p) = p[2] + 1.0

            xf_default, _ = Flow(pb.ocp, law)(t0, x0, p0, tf)
            xf_total, _ = Flow(pb.ocp, law; hamiltonian_type=:total)(t0, x0, p0, tf)
            Test.@test xf_default ≈ xf_total
        end

        Test.@testset "anything else is rejected" begin
            pb = TestProblems.DoubleIntegratorEnergy()
            Test.@test_throws OptimalControl.IncorrectArgument Flow(
                pb.ocp, (x, p) -> p[2]; hamiltonian_type=:nope
            )
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_hamiltonian_type() = TestHamiltonianType.test_hamiltonian_type()

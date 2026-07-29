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
                    t0, tf = pb.data.t0, pb.data.tf
                    x0, xf, p0 = pb.data.x0, pb.data.xf, pb.data.p0

                    # u*(x,p) = p₂ — the smooth interior optimum, so
                    # ∂H̃/∂u = 0 on the whole arc.
                    f = Flow(pb.ocp, (x, p) -> p[2]; hamiltonian_type=ht)

                    function shoot!(s, ξ)
                        x_f, _ = f(t0, x0, ξ, tf)
                        s .= x_f .- xf
                        return nothing
                    end

                    ξ_opt = test_shooting(shoot!, p0, perturb(p0))
                    Test.@test ξ_opt ≈ p0 atol = 1e-6

                    # Reconstruction reaches the reference objective.
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
                    t0, x0, xf = pb.data.t0, pb.data.x0, pb.data.xf
                    u_max, u_min = pb.data.u_max, pb.data.u_min
                    p0 = pb.data.p0
                    (t1,) = pb.data.switching_times
                    tf = pb.data.tf

                    H(x, p, u) = p[1] * x[2] + p[2] * u - 1

                    f_max = Flow(pb.ocp, (x, p, v) -> u_max; hamiltonian_type=ht)
                    f_min = Flow(pb.ocp, (x, p, v) -> u_min; hamiltonian_type=ht)

                    # Flat shooting vector: [p0 (2); t1; tf].
                    function shoot!(s, ξ)
                        p_0 = ξ[1:2]
                        τ1, τf = ξ[3], ξ[4]
                        x_1, p_1 = f_max(t0, x0, p_0, τ1; variable=τf)
                        x_f, p_f = f_min(τ1, x_1, p_1, τf; variable=τf)
                        s[1:2] = x_f - xf
                        s[3] = p_1[2]                    # switching condition
                        s[4] = H(x_f, p_f, u_min)        # free final time
                        return nothing
                    end

                    ξ_ref = [p0; t1; tf]
                    ξ_opt = test_shooting(shoot!, ξ_ref, perturb(ξ_ref, 0.05))
                    Test.@test ξ_opt ≈ ξ_ref atol = 1e-6
                end
            end
        end

        Test.@testset "Goddard (B+ S C B0, constrained arc)" begin
            # The full workout: four arcs, one of them constrained, free final
            # time. Every law here is the PMP minimiser, so again the modes
            # must agree — this time through a `constraint`/`multiplier` pair.
            for form in TestProblems.FORMS, ht in HAMILTONIAN_TYPES
                Test.@testset "$form / $ht" begin
                    pb = TestProblems.build(:goddard, form)
                    d = pb.data
                    t0, x0, vmax, mf = 0.0, d.x0, d.vmax, d.mf

                    H0 = Lift(d.F0)
                    H1 = Lift(d.F1)
                    H01 = @Lie {H0, H1}
                    H001 = @Lie {H0, H01}
                    H101 = @Lie {H1, H01}

                    g(x) = vmax - x[2]
                    us(x, p) = -H001(x, p) / H101(x, p)
                    ub(x) = -ad(d.F0, g)(x) / ad(d.F1, g)(x)
                    μ(x, p) = H01(x, p) / ad(d.F1, g)(x)

                    f0 = Flow(pb.ocp, (x, p, v) -> 0.0; hamiltonian_type=ht)
                    f1 = Flow(pb.ocp, (x, p, v) -> 1.0; hamiltonian_type=ht)
                    fs = Flow(pb.ocp, (x, p, v) -> us(x, p); hamiltonian_type=ht)
                    fb = Flow(
                        pb.ocp,
                        (x, p, v) -> ub(x);
                        constraint=(x, u, v) -> g(x),
                        multiplier=(x, p, v) -> μ(x, p),
                        hamiltonian_type=ht,
                    )

                    # Flat shooting vector: [p0 (3); t1; t2; t3; tf].
                    function shoot!(s, ξ)
                        p_0 = ξ[1:3]
                        τ1, τ2, τ3, τf = ξ[4], ξ[5], ξ[6], ξ[7]
                        x1, p1 = f1(t0, x0, p_0, τ1; variable=τf)
                        x2, p2 = fs(τ1, x1, p1, τ2; variable=τf)
                        x3, p3 = fb(τ2, x2, p2, τ3; variable=τf)
                        x_f, p_f = f0(τ3, x3, p3, τf; variable=τf)
                        s[1] = x_f[3] - mf
                        s[2:3] = p_f[1:2] - [1, 0]
                        s[4] = H1(x1, p1)
                        s[5] = H01(x1, p1)
                        s[6] = g(x2)
                        s[7] = H0(x_f, p_f)
                        return nothing
                    end

                    ξ_ref = [d.p0; collect(d.switching_times); d.tf_ref]
                    s = zeros(7)
                    shoot!(s, ξ_ref)
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

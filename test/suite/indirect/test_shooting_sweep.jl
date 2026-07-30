# ============================================================================
# Generic shooting sweep
# ============================================================================
# Replaces what used to be three separate files (`test_goddard.jl`,
# `test_double_integrator_time.jl`, `test_double_integrator_energy.jl`), each
# hand-writing its own control laws, `Flow`s and `shoot!` — a derivation now
# written once, next to each problem, as `TestProblem.shoot_builder` (see
# `test/problems/common.jl`).
#
# What moved here: the shooting-residual checks, both at the known reference
# and, via `test_shooting`, from a perturbed guess through Newton — the
# convergence half neither of the three original files actually exercised.
#
# What did NOT move here: the problem-specific guard-rail assertions the three
# files also carried (mandatory `variable=` on `NonFixed`, the
# `constraint`/`multiplier` pairing, trajectory form, `Lift` type semantics).
# Those test the `Flow` API, not the shooting derivation, and live in
# `test_flow_api.jl` / `test_ctlie.jl` — most were already covered there
# generically; the one gap (`variable=` mandatory when *omitted*) was added to
# `test_flow_api.jl` alongside its mirror image ("no variable on a Fixed
# flow"), which already existed.
#
# This file scales with the problem library by construction: any problem that
# declares `methods=(..., :indirect)` is picked up by `problems_for(:indirect)`
# automatically, no name to add here.

module TestShootingSweep

using Test: Test
using OptimalControl: OptimalControl
using NonlinearSolve: NonlinearProblem, SimpleNewtonRaphson, solve
import LinearAlgebra: norm
import OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

# `@Lie` (used by the Goddard shoot_builder) expands to bare `CTLie.*` /
# `CTBase.Traits.*` prefixes — both modules must be in scope here too, for the
# same reason `test/problems/goddard.jl` needs them via `TestProblems`' own
# `using OptimalControl`.
import CTLie: CTLie
import CTBase: CTBase

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

include(joinpath(@__DIR__, "..", "..", "helpers", "shooting.jl"))

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_shooting_sweep()
    Test.@testset "Shooting sweep (indirect fixtures)" verbose = VERBOSE showtiming = SHOWTIMING begin
        for form in TestProblems.FORMS
            Test.@testset "$form" begin
                for pb in TestProblems.problems_for(:indirect, form)
                    Test.@testset "$(pb.name)" begin
                        shoot!, ξ_exact, ξ_guess = pb.shoot_builder()

                        # 1. The derivation is right: residual at the known
                        #    reference is (near) zero.
                        s = zeros(length(ξ_exact))
                        shoot!(s, ξ_exact)
                        Test.@test norm(s) < 1e-6

                        # 2. The problem is actually solvable from a realistic
                        #    guess — Newton from `ξ_guess` converges back to
                        #    (a root as good as) `ξ_exact`. Neither of the
                        #    three files this replaces checked this half.
                        #
                        # ⚠️ `atol=1e-6`, not `test_shooting`'s own `1e-8`
                        # default: Goddard's reference residual is ~1.19e-8,
                        # numerically just past the tighter default. `1e-6` is
                        # the tolerance every one of the three files this
                        # replaces already used for these exact fixtures.
                        ξ_opt = test_shooting(shoot!, ξ_exact, ξ_guess; atol=1e-6)
                        Test.@test ξ_opt ≈ ξ_exact atol = 1e-6
                    end
                end
            end
        end

        # ====================================================================
        # The self-enforcement in `TestProblem` actually holds
        # ====================================================================

        Test.@testset "every :indirect fixture carries a shoot_builder" begin
            # Guards this file's own genericity: a problem that opts into
            # `:indirect` without a working derivation would otherwise fail
            # deep inside the loop above with a confusing `MethodError` on
            # `nothing()`, rather than at problem-construction time.
            for pb in TestProblems.problems_for(:indirect)
                Test.@test pb.shoot_builder !== nothing
            end
        end

        Test.@testset "the quadrotor opts out" begin
            # No exploitable extremal structure — the reason this whole
            # mechanism exists rather than a hard-coded list of problem names.
            for form in TestProblems.FORMS
                q = TestProblems.build(:quadrotor, form)
                Test.@test q.shoot_builder === nothing
                Test.@test !TestProblems.supports(q, :indirect)
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_shooting_sweep() = TestShootingSweep.test_shooting_sweep()

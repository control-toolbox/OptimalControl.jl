# ============================================================================
# CTFlows Reexports Tests
# ============================================================================
# Almost everything this file used to cover has moved:
#
#   the type vocabulary (`Hamiltonian`, `VectorField`, …) → CTBase.Data
#                                                            (test_ctbase.jl)
#   the differential geometry (`Lie`, `Lift`, `@Lie`, …)   → CTLie
#                                                            (test_ctlie.jl)
#
# What is left here is what genuinely belongs to CTFlows: `Flow`, the
# `Systems` accessors, and the multi-phase vocabulary. The flow *call*
# convention and the `Flow` constructor grid are exercised in suite/flows/.

module TestCtflows

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
using CTFlows: CTFlows
using OrdinaryDiffEqTsit5 # `Flow` needs an integrator loaded — the user's call now

include(joinpath(@__DIR__, "..", "..", "helpers", "reexport.jl"))
using .ReexportUtils: reexports, is_exported

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtflows

function test_ctflows()
    Test.@testset "CTFlows reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Generated Code Prefix" begin
            Test.@test isdefined(OptimalControl, :CTFlows)
            Test.@test isdefined(CurrentModule, :CTFlows)
            Test.@test CTFlows isa Module
        end

        Test.@testset "Flows" begin
            Test.@test reexports(OptimalControl, :Flow, CTFlows.Flows)
            Test.@test isdefined(CurrentModule, :Flow)
            # `Flow` is a parametric *type*, not a function — the constructor
            # grid is 9 methods over it.
            Test.@test Flow isa UnionAll
        end

        Test.@testset "Systems accessors" begin
            # ⚠️ `control_law` and `pseudo_hamiltonian` also exist in
            # `CTBase.Data` as *distinct* objects. The CTFlows ones are the
            # exported pair — siblings of `hamiltonian(sys)`. `isdefined` would
            # not tell the two apart.
            for f in (:control_law, :pseudo_hamiltonian)
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTFlows.Systems)
                    Test.@test getfield(OptimalControl, f) === getfield(CTFlows.Systems, f)
                    Test.@test getfield(OptimalControl, f) !==
                        getfield(OptimalControl.CTBase.Data, f)
                end
            end
        end

        Test.@testset "MultiPhase" begin
            for f in (
                :n_phases,
                :get_flow,
                :get_flows,
                :get_jump,
                :get_jumps,
                :get_switching_time,
                :get_switching_times,
            )
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTFlows.MultiPhase)
                    Test.@test isdefined(CurrentModule, f)
                end
            end
            for T in (
                :AnyMultiPhaseFlow,
                :MultiPhaseFlow,
                :MultiPhaseStateFlow,
                :MultiPhaseHamiltonianFlow,
            )
                Test.@testset "$T" begin
                    Test.@test isdefined(OptimalControl, T)
                    Test.@test is_exported(OptimalControl, T)
                    Test.@test getfield(OptimalControl, T) ===
                        getfield(CTFlows.MultiPhase, T)
                end
            end
            # `*` concatenates flows. It is `Base.:*`, extended by MultiPhase,
            # so it needs no re-export of its own — but the method must exist.
            Test.@test any(m -> parentmodule(m) === CTFlows.MultiPhase, methods(*))
        end

        Test.@testset "Moved away from CTFlows" begin
            # These used to be re-exported from CTFlows. They must now resolve
            # to their new owners — the point of the whole migration.
            Test.@test reexports(OptimalControl, :Hamiltonian, OptimalControl.CTBase.Data)
            Test.@test reexports(OptimalControl, :VectorField, OptimalControl.CTBase.Data)
            Test.@test reexports(OptimalControl, :Lift, OptimalControl.CTLie)
            Test.@test reexports(OptimalControl, :Poisson, OptimalControl.CTLie)
        end

        # ====================================================================
        # SIGNATURE FREEZING
        # ====================================================================
        # Simple calls that pin the API down. Not functional verification —
        # the real behaviour lives in suite/flows/ and suite/indirect/.

        Test.@testset "Signature Freezing" begin
            Test.@testset "Flow from a Hamiltonian" begin
                H = Hamiltonian((x, p) -> p[1] * x[2] - x[1] * p[2])
                f = Flow(H)
                xf, pf = f(0.0, [1.0, 0.0], [0.0, 1.0], 1.0)
                Test.@test xf isa AbstractVector
                Test.@test pf isa AbstractVector
            end

            Test.@testset "Flow from a VectorField" begin
                X = VectorField(x -> [x[2], -x[1]])
                f = Flow(X)
                Test.@test f(0.0, [1.0, 0.0], 1.0) isa AbstractVector
            end

            Test.@testset "Flow from a control-free OCP" begin
                t0, tf, x0 = 0, 1, 1.0

                ocp = @def begin
                    λ ∈ R, variable
                    t ∈ [t0, tf], time
                    x ∈ R, state
                    x(t0) == x0
                    ẋ(t) == λ * x(t)
                    ∫(x(t)^2) → min
                end

                f = Flow(ocp)

                # ⚠️ `variable=` is now a mandatory *keyword* on NonFixed flows.
                # The old positional slot `f(t0, x0, p0, tf, λ)` is gone.
                xf, pf = f(t0, x0, 1.0, tf; variable=0.5)
                Test.@test xf isa Real   # 1-D state → scalar, not a 1-vector
                Test.@test pf isa Real

                # `variable_costate=true` (formerly `augment=true`) integrates
                # the augmented adjoint and returns a 3-tuple.
                xf2, pf2, pλ = f(t0, x0, 1.0, tf; variable=0.5, variable_costate=true)
                Test.@test xf2 ≈ xf rtol = 1e-6
                Test.@test pf2 ≈ pf rtol = 1e-6
                Test.@test pλ isa Real

                # Omitting the variable is a PreconditionError, not a silent default.
                Test.@test_throws OptimalControl.PreconditionError f(t0, x0, 1.0, tf)
            end

            Test.@testset "Trajectory form" begin
                t0, tf, x0 = 0, 1, 1.0

                ocp = @def begin
                    λ ∈ R, variable
                    t ∈ [t0, tf], time
                    x ∈ R, state
                    x(t0) == x0
                    ẋ(t) == λ * x(t)
                    ∫(x(t)^2) → min
                end

                traj = Flow(ocp)((t0, tf), x0, 1.0; variable=0.0)
                # λ = 0 ⟹ x stays constant.
                Test.@test state(traj)(tf) ≈ x0 rtol = 1e-10
            end

            Test.@testset "Manual vs automatic Hamiltonian" begin
                t0, tf, x0, λ, p0 = 0, 1, 1.0, 0.5, 1.0

                ocp = @def begin
                    λ ∈ R, variable
                    t ∈ [t0, tf], time
                    x ∈ R, state
                    x(t0) == x0
                    ẋ(t) == λ * x(t)
                    ∫(x(t)^2) → min
                end

                H(x, p, v) = p * v * x - x^2
                H_aug(x_, p_) = H(x_[1], p_[1], x_[2])
                f_manual = Flow(Hamiltonian(H_aug))
                f_auto = Flow(ocp)

                xf_manual, pf_manual = f_manual(t0, [x0, λ], [p0, 0.0], tf)
                xf_auto, pf_auto = f_auto(t0, x0, p0, tf; variable=λ)

                Test.@test xf_manual[1] ≈ xf_auto rtol = 1e-6
                Test.@test pf_manual[1] ≈ pf_auto rtol = 1e-6
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctflows() = TestCtflows.test_ctflows()

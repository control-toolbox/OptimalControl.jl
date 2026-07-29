# ============================================================================
# Double Integrator Time Minimization - Indirect Method Tests
# ============================================================================
# Indirect shooting for the double integrator, time cost. Bang-bang control
# with one switching time.
#
# ⚠️ This OCP declares `tf ∈ R, variable`, so it is `NonFixed`: `variable=` is
# a mandatory keyword at every call. The old positional slot
# `f(t0, x0, p0, tf, λ)` is gone.

module TestDoubleIntegratorTime

using Test: Test
using OptimalControl: OptimalControl
import LinearAlgebra: norm
import OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_double_integrator_time()
    Test.@testset "Double Integrator Time Minimization" verbose = VERBOSE showtiming =
        SHOWTIMING begin

        # ====================================================================
        # INTEGRATION TEST - Bang-Bang Shooting Method
        # ====================================================================

        Test.@testset "Bang-bang shooting with switching time" begin
            # Get problem from TestProblems
            prob_data = TestProblems.DoubleIntegratorTime()
            ocp = prob_data.ocp
            x0 = prob_data.x0
            xf = prob_data.xf
            t0 = prob_data.t0
            u_max = prob_data.u_max
            u_min = prob_data.u_min
            obj_ref = prob_data.obj

            # Pseudo-Hamiltonian: H(x, p, u) = p₁v + p₂u - 1
            H(x, p, u) = p[1] * x[2] + p[2] * u - 1

            # Hamiltonian flows for bang-bang control. The third lambda
            # argument is the OCP variable (here `tf`), as the OCP is NonFixed.
            f_max = OptimalControl.Flow(ocp, (x, p, v) -> u_max)
            f_min = OptimalControl.Flow(ocp, (x, p, v) -> u_min)

            # Shooting function — `variable=tf` at every call.
            function shoot!(s, p0, t1, tf)
                x_t0, p_t0 = x0, p0
                x_t1, p_t1 = f_max(t0, x_t0, p_t0, t1; variable=tf)
                x_tf, p_tf = f_min(t1, x_t1, p_t1, tf; variable=tf)
                s[1:2] = x_tf - xf                    # target conditions
                s[3] = p_t1[2]                        # switching condition
                return s[4] = H(x_tf, p_tf, u_min)           # free final time
            end

            # Known solution (from documentation)
            p0_ref = [1.0, 1.0]
            t1_ref = 1.0
            tf_ref = 2.0

            # Test shooting function with known solution
            s = zeros(4)
            shoot!(s, p0_ref, t1_ref, tf_ref)

            # Verify solution (should be close to zero)
            Test.@test norm(s) < 1e-6

            # Verify objective value
            Test.@test tf_ref ≈ obj_ref atol = 1e-6

            Test.@testset "variable is mandatory on NonFixed" begin
                Test.@test_throws OptimalControl.PreconditionError f_max(
                    t0, x0, p0_ref, t1_ref
                )
            end

            Test.@testset "trajectory form" begin
                # The `(tspan, x0, p0)` overload returns a Solution rather
                # than an end-point pair; same mandatory `variable=`.
                traj = f_max((t0, t1_ref), x0, p0_ref; variable=tf_ref)
                Test.@test OptimalControl.state(traj)(t0) ≈ x0
                x_t1, _ = f_max(t0, x0, p0_ref, t1_ref; variable=tf_ref)
                Test.@test OptimalControl.state(traj)(t1_ref) ≈ x_t1 rtol = 1e-6
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_double_integrator_time() = TestDoubleIntegratorTime.test_double_integrator_time()

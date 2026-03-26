# ============================================================================
# Double Integrator Energy Minimization - Indirect Method Tests
# ============================================================================
# This file tests the indirect shooting method for the double integrator
# energy minimization problem, both unconstrained and with state constraint.

module TestDoubleIntegratorEnergy

import Test
import OptimalControl
import NonlinearSolve: NonlinearProblem, solve
import LinearAlgebra: norm
import OrdinaryDiffEq: OrdinaryDiffEq

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_double_integrator_energy()
    Test.@testset "Double Integrator Energy Minimization" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TEST - Unconstrained Energy Minimization
        # ====================================================================
        
        Test.@testset "Unconstrained singular control" begin
            # Get problem from TestProblems
            prob_data = TestProblems.DoubleIntegratorEnergy()
            ocp = prob_data.ocp
            x0 = prob_data.x0
            xf = prob_data.xf
            t0 = prob_data.t0
            tf = prob_data.tf
            obj_ref = prob_data.obj
            
            # Singular control: u(x, p) = p₂
            u(x, p) = p[2]
            
            # Hamiltonian flow
            f = OptimalControl.Flow(ocp, u)
            
            # State projection
            π((x, p)) = x
            
            # Shooting function
            S(p0) = π(f(t0, x0, p0, tf)) - xf
            
            # Known solution (from documentation)
            p0_ref = [12.0, 6.0]
            
            # Test shooting function with known solution
            s = S(p0_ref)
            
            # Verify solution (should be close to zero)
            Test.@test norm(s) < 1e-6
            
            # Note: We don't test the objective value directly here since
            # we're testing the shooting method, not the full solution
        end
        
        # ====================================================================
        # INTEGRATION TEST - Constrained Energy Minimization
        # ====================================================================
        
        Test.@testset "Constrained three-arc structure" begin
            # Get problem from TestProblems
            prob_data = TestProblems.DoubleIntegratorEnergyConstrained()
            ocp = prob_data.ocp
            x0 = prob_data.x0
            xf = prob_data.xf
            t0 = prob_data.t0
            tf = prob_data.tf
            v_max = prob_data.v_max
            
            # Flow for unconstrained extremals (singular control u = p₂)
            f_interior = OptimalControl.Flow(ocp, (x, p) -> p[2])
            
            # Boundary control and constraint
            ub = 0.0                    # boundary control
            g(x) = v_max - x[2]         # constraint: g(x) ≥ 0
            μ(p) = p[1]                 # dual variable
            
            # Flow for boundary extremals
            f_boundary = OptimalControl.Flow(ocp, (x, p) -> ub, (x, u) -> g(x), (x, p) -> μ(p))
            
            # Shooting function
            function shoot!(s, p0, t1, t2)
                x_t0, p_t0 = x0, p0
                x_t1, p_t1 = f_interior(t0, x_t0, p_t0, t1)
                x_t2, p_t2 = f_boundary(t1, x_t1, p_t1, t2)
                x_tf, p_tf = f_interior(t2, x_t2, p_t2, tf)
                s[1:2] = x_tf - xf      # target conditions
                s[3] = g(x_t1)          # constraint activation at entry
                s[4] = p_t1[2]          # switching condition
            end
            
            # Known solution (from documentation)
            p0_ref = [38.4, 9.6]
            t1_ref = 0.25
            t2_ref = 0.75
            
            # Test shooting function with known solution
            s = zeros(4)
            shoot!(s, p0_ref, t1_ref, t2_ref)
            
            # Verify solution (should be close to zero)
            Test.@test norm(s) < 1e-6
            
            # Note: obj_ref is nothing for this problem (no reference value available)
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_double_integrator_energy() = TestDoubleIntegratorEnergy.test_double_integrator_energy()

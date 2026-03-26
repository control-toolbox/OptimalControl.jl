# ============================================================================
# Goddard Indirect Method Tests
# ============================================================================
# This file tests the indirect shooting method for the Goddard rocket problem.
# It uses CTFlows (Hamiltonian flows, Lie brackets) and NonlinearSolve to
# solve the shooting equations for a complex bang-singular-constrained-bang
# control structure.

module TestGoddardIndirect

import Test
import OptimalControl
import LinearAlgebra: norm
import OrdinaryDiffEq: OrdinaryDiffEq
import CTFlows: CTFlows ## TODO: remove when CTFlows is exported by OptimalControl

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Problem parameters
# ============================================================================

const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2
const t0 = 0
const r0 = 1
const v0 = 0
const vmax = 0.1
const m0 = 1
const mf = 0.6
const x0 = [r0, v0, m0]

function test_goddard()
    Test.@testset "Goddard Indirect Method" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TEST - Indirect Shooting Method
        # ====================================================================
        
        Test.@testset "Shooting with B+ S C B0 structure" begin
            # Get problem from TestProblems
            prob_data = TestProblems.Goddard()
            ocp = prob_data.ocp
            F0 = prob_data.F0
            F1 = prob_data.F1
            
            # Constraint function
            g(x) = vmax - x[2]
            final_mass_cons(xf) = xf[3] - mf
            
            # Bang controls
            u0 = 0
            u1 = 1
            
            # Singular control
            H0 = OptimalControl.Lift(F0)
            H1 = OptimalControl.Lift(F1)
            H01 = OptimalControl.@Lie {H0, H1}
            H001 = OptimalControl.@Lie {H0, H01}
            H101 = OptimalControl.@Lie {H1, H01}
            us(x, p) = -H001(x, p) / H101(x, p)
            
            # Boundary control
            ub(x) = -OptimalControl.Lie(F0, g)(x) / OptimalControl.Lie(F1, g)(x)
            μ(x, p) = H01(x, p) / OptimalControl.Lie(F1, g)(x)
            
            # Flows
            f0 = OptimalControl.Flow(ocp, (x, p, v) -> u0)
            f1 = OptimalControl.Flow(ocp, (x, p, v) -> u1)
            fs = OptimalControl.Flow(ocp, (x, p, v) -> us(x, p))
            fb = OptimalControl.Flow(ocp, (x, p, v) -> ub(x), (x, u, v) -> g(x), (x, p, v) -> μ(x, p))
            
            # Shooting function
            function shoot!(s, p0, t1, t2, t3, tf)
                x1, p1 = f1(t0, x0, p0, t1)
                x2, p2 = fs(t1, x1, p1, t2)
                x3, p3 = fb(t2, x2, p2, t3)
                xf, pf = f0(t3, x3, p3, tf)
                s[1] = final_mass_cons(xf)
                s[2:3] = pf[1:2] - [1, 0]
                s[4] = H1(x1, p1)
                s[5] = H01(x1, p1)
                s[6] = g(x2)
                return s[7] = H0(xf, pf)
            end
            
            # Known solution
            p0 = [3.9457646586891744, 0.15039559623165552, 0.05371271293970545]
            t1 = 0.023509684041879215
            t2 = 0.059737380899876
            t3 = 0.10157134842432228
            tf = 0.20204744057100849
            
            # Test shooting function with known solution
            s = zeros(eltype(p0), 7)
            shoot!(s, p0, t1, t2, t3, tf)
            
            # Verify solution
            Test.@test norm(s) < 1e-6
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_goddard() = TestGoddardIndirect.test_goddard()

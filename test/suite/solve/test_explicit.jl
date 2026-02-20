# ============================================================================
# Explicit Mode Tests (Layer 2)
# ============================================================================
# This file tests the `solve_explicit` function. It verifies that when the user
# provides instantiated strategy components (discretizer, modeler, solver) as
# keyword arguments, any missing components are correctly completed via the
# strategy registry before delegating to the canonical Layer 3 solve.

module TestExplicit

import Test
import OptimalControl
import CTModels
import CTDirect
import CTSolvers
import CTBase
import CommonSolve

#
import NLPModelsIpopt
import MadNLP
import MadNLPMumps
import MadNLPGPU
import MadNCL
import CUDA

#
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# TOP-LEVEL MOCKS
# ====================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution end

# ====================================================================
# TEST PROBLEMS FOR INTEGRATION TESTS
# ====================================================================

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.StrategyOptions
end

struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end

struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

CommonSolve.solve(
    ::MockOCP,
    ::MockInit,
    ::MockDiscretizer,
    ::MockModeler,
    ::MockSolver;
    display::Bool
)::MockSolution = MockSolution()

function test_explicit()
    Test.@testset "solve_explicit (contract tests with mocks)" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = MockOCP()
        init = MockInit()
        disc = MockDiscretizer(CTSolvers.StrategyOptions())
        mod = MockModeler(CTSolvers.StrategyOptions())
        sol = MockSolver(CTSolvers.StrategyOptions())
        registry = OptimalControl.get_strategy_registry()

        # ================================================================
        # COMPLETE COMPONENTS PATH
        # ================================================================
        Test.@testset "Complete components -> direct path" begin
            result = OptimalControl.solve_explicit(
                ocp;
                initial_guess=init,
                discretizer=disc,
                modeler=mod,
                solver=sol,
                display=false,
                registry=registry
            )
            Test.@test result isa MockSolution
        end

        # ================================================================
        # INTEGRATION TESTS WITH REAL STRATEGIES
        # ================================================================
        Test.@testset "Integration with real strategies" begin
            registry = OptimalControl.get_strategy_registry()
            
            # Test with real test problems
            problems = [
                ("Beam", TestProblems.Beam()),
                ("Goddard", TestProblems.Goddard()),
            ]
            
            for (pname, pb) in problems
                Test.@testset "$pname" begin
                    # Build initial guess
                    init = OptimalControl.build_initial_guess(pb.ocp, pb.init)
                    
                    Test.@testset "Complete components - real strategies" begin
                        result = OptimalControl.solve_explicit(
                            pb.ocp;
                            initial_guess=init,
                            discretizer=CTDirect.Collocation(),
                            modeler=CTSolvers.ADNLP(),
                            solver=CTSolvers.Ipopt(),
                            display=false,
                            registry=registry
                        )
                        Test.@test result isa CTModels.AbstractSolution
                        Test.@test OptimalControl.successful(result)
                        Test.@test OptimalControl.objective(result) ≈ pb.obj rtol=1e-2
                    end
                    
                    Test.@testset "Partial components - completion" begin
                        # Test with only discretizer provided
                        result = OptimalControl.solve_explicit(
                            pb.ocp;
                            initial_guess=init,
                            discretizer=CTDirect.Collocation(),
                            modeler=nothing,
                            solver=nothing,
                            display=false,
                            registry=registry
                        )
                        Test.@test result isa CTModels.AbstractSolution
                        Test.@test OptimalControl.successful(result)
                    end
                end
            end
            
        end
    end
end

end # module

test_explicit() = TestExplicit.test_explicit()

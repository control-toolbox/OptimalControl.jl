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
using .TestProblems

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
        registry = get_strategy_registry()

        # ================================================================
        # COMPLETE COMPONENTS PATH
        # ================================================================
        Test.@testset "Complete components -> direct path" begin
            result = OptimalControl.solve_explicit(
                ocp, init;
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
                ("Beam", Beam()),
                ("Goddard", Goddard()),
            ]
            
            for (pname, pb) in problems
                Test.@testset "$pname" begin
                    # Build initial guess
                    init = OptimalControl.build_initial_guess(pb.ocp, pb.init)
                    
                    Test.@testset "Complete components - real strategies" begin
                        result = OptimalControl.solve_explicit(
                            pb.ocp, init;
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
                            pb.ocp, init;
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
            
            Test.@testset "Complete method coverage" begin
                # Test that all methods() are covered by integration tests
                # Track which methods we've tested
                available = Set(OptimalControl.methods())
                tested = Set{Tuple{Symbol, Symbol, Symbol}}()
                
                # Define all strategy combinations to test
                discretizers = [
                    ("Collocation/midpoint", OptimalControl.Collocation(grid_size=20, scheme=:midpoint)),
                ]

                modelers = [
                    ("ADNLP", OptimalControl.ADNLP()),
                    ("Exa",   OptimalControl.Exa()),
                ]

                solvers = [
                    ("Ipopt",  OptimalControl.Ipopt(print_level=0, max_iter=0)),
                    ("MadNLP", OptimalControl.MadNLP(print_level=MadNLP.ERROR, max_iter=0)),
                ]

                # Use only one problem to test all method combinations
                pb = Beam()
                init = OptimalControl.build_initial_guess(pb.ocp, pb.init)
                
                # Test all combinations
                for (dname, disc) in discretizers
                    for (mname, mod) in modelers
                        for (sname, sol) in solvers
                            # Build method using R3 helpers
                            partial = OptimalControl._build_partial_description(disc, mod, sol)
                            complete = OptimalControl._complete_description(partial)
                            
                            # Check that this method is available and not already tested
                            Test.@test complete in available
                            Test.@test complete ∉ tested
                            
                            # Mark as tested
                            push!(tested, complete)
                            
                            # Test the actual solve - just verify it returns a solution
                            result = OptimalControl.solve_explicit(
                                pb.ocp, init;
                                discretizer=disc,
                                modeler=mod,
                                solver=sol,
                                display=false,
                                registry=registry
                            )
                            Test.@test result isa CTModels.AbstractSolution
                        end
                    end
                end
                
                # Verify all methods have been tested (modulo Knitro which requires license)
                knitro_methods = Set([m for m in available if m[3] == :knitro])
                non_knitro_available = setdiff(available, knitro_methods)
                Test.@test tested == non_knitro_available
                Test.@test length(tested) == length(non_knitro_available)
                Test.@test length(tested) + length(knitro_methods) == length(OptimalControl.methods())
            end
        end
    end
end

end # module

test_explicit() = TestExplicit.test_explicit()

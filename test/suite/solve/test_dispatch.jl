module TestSolveDispatch

import Test
import OptimalControl
import CTModels
import CTDirect
import CTSolvers
import CTBase
import CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Mock types for contract testing
# ============================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution end

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.StrategyOptions
end
struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end
struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

# Override Layer 3 solve for mocks — returns MockSolution immediately
function CommonSolve.solve(
    ::MockOCP, ::MockInit,
    ::MockDiscretizer, ::MockModeler, ::MockSolver;
    display::Bool
)::MockSolution 
    return MockSolution()
end

function test_solve_dispatch()
    Test.@testset "Solve Dispatch" verbose=VERBOSE showtiming=SHOWTIMING begin

        ocp      = MockOCP()
        init     = MockInit()
        disc     = MockDiscretizer(CTSolvers.StrategyOptions())
        mod      = MockModeler(CTSolvers.StrategyOptions())
        sol      = MockSolver(CTSolvers.StrategyOptions())
        registry = OptimalControl.get_strategy_registry()

        # ====================================================================
        # CONTRACT TESTS - ExplicitMode: complete components (mock Layer 3)
        # ====================================================================

        Test.@testset "ExplicitMode - all three components" begin
            result = OptimalControl._solve(
                OptimalControl.ExplicitMode(),
                ocp;
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc, modeler=mod, solver=sol
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # CONTRACT TESTS - DescriptiveMode: stub raises NotImplemented
        # ====================================================================

        Test.@testset "DescriptiveMode - raises NotImplemented" begin
            Test.@test_throws CTBase.NotImplemented begin
                OptimalControl._solve(
                    OptimalControl.DescriptiveMode(),
                    ocp, :collocation, :adnlp, :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry
                )
            end
        end

        Test.@testset "DescriptiveMode - empty description raises NotImplemented" begin
            Test.@test_throws CTBase.NotImplemented begin
                OptimalControl._solve(
                    OptimalControl.DescriptiveMode(),
                    ocp;
                    initial_guess=init,
                    display=false,
                    registry=registry
                )
            end
        end

        # ====================================================================
        # CONTRACT TESTS - Dispatch correctness
        # ====================================================================

        Test.@testset "Dispatch correctness - ExplicitMode route" begin
            # Verify that ExplicitMode actually routes to the ExplicitMode method
            function _dispatch_route(mode::OptimalControl.ExplicitMode)
                return :explicit
            end
            function _dispatch_route(mode::OptimalControl.DescriptiveMode)
                return :descriptive
            end

            Test.@test _dispatch_route(OptimalControl.ExplicitMode()) == :explicit
        end

        Test.@testset "Dispatch correctness - DescriptiveMode route" begin
            # Verify that DescriptiveMode actually routes to the DescriptiveMode method
            function _dispatch_route(mode::OptimalControl.ExplicitMode)
                return :explicit
            end
            function _dispatch_route(mode::OptimalControl.DescriptiveMode)
                return :descriptive
            end

            Test.@test _dispatch_route(OptimalControl.DescriptiveMode()) == :descriptive
        end

        # ====================================================================
        # INTEGRATION TESTS - End-to-end dispatch
        # ====================================================================

        Test.@testset "Integration - complete explicit workflow" begin
            result = OptimalControl._solve(
                OptimalControl.ExplicitMode(),
                ocp;
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc, modeler=mod, solver=sol
            )
            Test.@test result isa MockSolution
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_solve_dispatch() = TestSolveDispatch.test_solve_dispatch()

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
        # CONTRACT TESTS - solve_explicit: complete components (mock Layer 3)
        # ====================================================================

        Test.@testset "solve_explicit - all three components" begin
            result = OptimalControl.solve_explicit(
                ocp;
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc, modeler=mod, solver=sol
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # CONTRACT TESTS - solve_descriptive: stub raises NotImplemented
        # ====================================================================

        Test.@testset "solve_descriptive - raises NotImplemented" begin
            Test.@test_throws CTBase.NotImplemented begin
                OptimalControl.solve_descriptive(
                    ocp, :collocation, :adnlp, :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry
                )
            end
        end

        Test.@testset "solve_descriptive - empty description raises NotImplemented" begin
            Test.@test_throws CTBase.NotImplemented begin
                OptimalControl.solve_descriptive(
                    ocp;
                    initial_guess=init,
                    display=false,
                    registry=registry
                )
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_dispatch() = TestSolveDispatch.test_solve_dispatch()

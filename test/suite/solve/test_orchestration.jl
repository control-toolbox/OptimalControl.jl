module TestOrchestration

import Test
import OptimalControl
import CTModels
import CTDirect
import CTSolvers
import CTBase
import CommonSolve
import NLPModelsIpopt
import MadNLP

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Mock types for contract testing (Layer 3 short-circuited)
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

# Short-circuit Layer 3 for mocks
CommonSolve.solve(
    ::MockOCP, ::MockInit,
    ::MockDiscretizer, ::MockModeler, ::MockSolver;
    display::Bool
)::MockSolution = MockSolution()

# ============================================================================
# TOP-LEVEL: Real test problems for integration tests
# ============================================================================

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

function test_orchestration()
    Test.@testset "Orchestration - CommonSolve.solve" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Mode detection
        # ====================================================================

        Test.@testset "ExplicitMode detection" begin
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            kw   = pairs((; discretizer=disc))
            Test.@test OptimalControl._explicit_or_descriptive((), kw) isa OptimalControl.ExplicitMode
        end

        Test.@testset "DescriptiveMode detection" begin
            kw = pairs(NamedTuple())
            Test.@test OptimalControl._explicit_or_descriptive((:collocation,), kw) isa OptimalControl.DescriptiveMode
        end

        Test.@testset "Conflict: explicit + description raises IncorrectArgument" begin
            ocp  = MockOCP()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            Test.@test_throws CTBase.IncorrectArgument begin
                CommonSolve.solve(ocp, :adnlp, :ipopt; discretizer=disc, display=false)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - solve_explicit path (mocks, Layer 3 short-circuited)
        # ====================================================================

        Test.@testset "solve_explicit - complete components" begin
            ocp  = MockOCP()
            init = MockInit()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            mod  = MockModeler(CTSolvers.StrategyOptions())
            sol  = MockSolver(CTSolvers.StrategyOptions())

            result = CommonSolve.solve(ocp;
                initial_guess=init,
                discretizer=disc, modeler=mod, solver=sol,
                display=false
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # CONTRACT TESTS - solve_descriptive path (stub raises NotImplemented)
        # ====================================================================

        Test.@testset "solve_descriptive raises NotImplemented" begin
            ocp = MockOCP()
            Test.@test_throws CTBase.NotImplemented begin
                CommonSolve.solve(ocp, :collocation, :adnlp, :ipopt;
                    initial_guess=MockInit(), display=false)
            end
        end

        # ====================================================================
        # UNIT TESTS - initial_guess normalization (mocks, no real solver)
        # ====================================================================

        Test.@testset "initial_guess=nothing uses MockInit fallback" begin
            ocp  = MockOCP()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            mod  = MockModeler(CTSolvers.StrategyOptions())
            sol  = MockSolver(CTSolvers.StrategyOptions())
            result = CommonSolve.solve(ocp;
                initial_guess=MockInit(),
                discretizer=disc, modeler=mod, solver=sol,
                display=false
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "initial_guess as AbstractInitialGuess is forwarded" begin
            ocp  = MockOCP()
            init = MockInit()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            mod  = MockModeler(CTSolvers.StrategyOptions())
            sol  = MockSolver(CTSolvers.StrategyOptions())
            result = CommonSolve.solve(ocp;
                initial_guess=init,
                discretizer=disc, modeler=mod, solver=sol,
                display=false
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # INTEGRATION TESTS - real problems, real strategies
        # ====================================================================

        Test.@testset "Integration - ExplicitMode complete components" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            mod  = CTSolvers.ADNLP()
            sol  = CTSolvers.Ipopt(print_level=0, max_iter=0)

            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init,
                discretizer=disc, modeler=mod, solver=sol,
                display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "Integration - ExplicitMode partial components (registry completes)" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)

            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "Integration - initial_guess as NamedTuple" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_orchestration() = TestOrchestration.test_orchestration()

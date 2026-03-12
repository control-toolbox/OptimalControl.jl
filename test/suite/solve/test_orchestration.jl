# ============================================================================
# Solve Orchestration Integration Tests
# ============================================================================
# This file provides integration tests for the full solve orchestration pipeline.
# It verifies the interaction between Layer 1 (dispatch), Layer 2 (explicit/descriptive
# component completion and option routing), and a mocked Layer 3 to ensure the
# entire component assembly chain works correctly before execution.

module TestOrchestration

using Test: Test
using OptimalControl: OptimalControl
using CTModels: CTModels
using CTDirect: CTDirect
using CTSolvers: CTSolvers
using CTBase: CTBase
using CommonSolve: CommonSolve
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Mock types for contract testing (Layer 3 short-circuited)
# ============================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution end
CTModels.build_initial_guess(::MockOCP, ::Nothing) = MockInit()
CTModels.build_initial_guess(::MockOCP, i::MockInit) = i

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.StrategyOptions
end
struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end
struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

# Short-circuit Layer 3 for mocks (explicit mode: typed mock components)
CommonSolve.solve(::MockOCP, ::MockInit, ::MockDiscretizer, ::MockModeler, ::MockSolver; display::Bool)::MockSolution = MockSolution()

# Short-circuit Layer 3 for mocks (descriptive mode: real abstract component types)
# solve_descriptive builds real CTDirect.Collocation, CTSolvers.ADNLP, etc.
# This override catches those calls for MockOCP without running a real solver.
CommonSolve.solve(::MockOCP, ::CTModels.AbstractInitialGuess, ::CTDirect.AbstractDiscretizer, ::CTSolvers.AbstractNLPModeler, ::CTSolvers.AbstractNLPSolver; display::Bool)::MockSolution = MockSolution()

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
            kw = pairs((; discretizer=disc))
            Test.@test OptimalControl._explicit_or_descriptive((), kw) isa
                OptimalControl.ExplicitMode
        end

        Test.@testset "DescriptiveMode detection" begin
            kw = pairs(NamedTuple())
            Test.@test OptimalControl._explicit_or_descriptive((:collocation,), kw) isa
                OptimalControl.DescriptiveMode
        end

        Test.@testset "Conflict: explicit + description raises IncorrectArgument" begin
            ocp = MockOCP()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            Test.@test_throws CTBase.IncorrectArgument begin
                CommonSolve.solve(ocp, :adnlp, :ipopt; discretizer=disc, display=false)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - solve_explicit path (mocks, Layer 3 short-circuited)
        # ====================================================================

        Test.@testset "solve_explicit - complete components" begin
            ocp = MockOCP()
            init = MockInit()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            mod = MockModeler(CTSolvers.StrategyOptions())
            sol = MockSolver(CTSolvers.StrategyOptions())

            result = CommonSolve.solve(
                ocp;
                initial_guess=init,
                discretizer=disc,
                modeler=mod,
                solver=sol,
                display=false,
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # CONTRACT TESTS - solve_descriptive path (mock Layer 3 short-circuit)
        # ====================================================================

        Test.@testset "solve_descriptive - complete description dispatches correctly" begin
            ocp = MockOCP()
            result = CommonSolve.solve(
                ocp, :collocation, :adnlp, :ipopt; initial_guess=MockInit(), display=false
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_descriptive - partial description (:collocation only)" begin
            ocp = MockOCP()
            result = CommonSolve.solve(
                ocp, :collocation; initial_guess=MockInit(), display=false
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_descriptive - empty description (full defaults)" begin
            ocp = MockOCP()
            result = CommonSolve.solve(ocp; initial_guess=MockInit(), display=false)
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_descriptive - alias 'init'" begin
            ocp = MockOCP()
            result = CommonSolve.solve(
                ocp, :collocation, :adnlp, :ipopt; init=MockInit(), display=false
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_descriptive - error on unknown option" begin
            ocp = MockOCP()
            Test.@test_throws CTBase.IncorrectArgument begin
                CommonSolve.solve(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=MockInit(),
                    display=false,
                    totally_unknown_option=42,
                )
            end
        end

        # ====================================================================
        # UNIT TESTS - initial_guess normalization (mocks, no real solver)
        # ====================================================================

        Test.@testset "initial_guess=nothing → default MockInit" begin
            ocp = MockOCP()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            mod = MockModeler(CTSolvers.StrategyOptions())
            sol = MockSolver(CTSolvers.StrategyOptions())
            result = CommonSolve.solve(
                ocp; discretizer=disc, modeler=mod, solver=sol, display=false
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "initial_guess as AbstractInitialGuess is forwarded" begin
            ocp = MockOCP()
            init = MockInit()
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            mod = MockModeler(CTSolvers.StrategyOptions())
            sol = MockSolver(CTSolvers.StrategyOptions())
            result = CommonSolve.solve(
                ocp;
                initial_guess=init,
                discretizer=disc,
                modeler=mod,
                solver=sol,
                display=false,
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # INTEGRATION TESTS - real problems, real strategies
        # ====================================================================

        Test.@testset "Integration - ExplicitMode complete components" begin
            pb = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            mod = CTSolvers.ADNLP()
            sol = CTSolvers.Ipopt(print_level=0, max_iter=0)

            result = CommonSolve.solve(
                pb.ocp;
                initial_guess=pb.init,
                discretizer=disc,
                modeler=mod,
                solver=sol,
                display=false,
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "Integration - ExplicitMode partial components (registry completes)" begin
            pb = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)

            result = CommonSolve.solve(
                pb.ocp; initial_guess=pb.init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "Integration - initial_guess as NamedTuple" begin
            pb = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            result = CommonSolve.solve(
                pb.ocp; initial_guess=pb.init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "Integration - DescriptiveMode complete description" begin
            pb = TestProblems.Beam()
            result = CommonSolve.solve(
                pb.ocp,
                :collocation,
                :adnlp,
                :ipopt;
                initial_guess=pb.init,
                display=false,
                grid_size=10,
                print_level=0,
                max_iter=0,
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "Integration - DescriptiveMode partial description" begin
            pb = TestProblems.Beam()
            result = CommonSolve.solve(
                pb.ocp,
                :collocation;
                initial_guess=pb.init,
                display=false,
                grid_size=10,
                print_level=0,
                max_iter=0,
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "Integration - DescriptiveMode empty description (full defaults)" begin
            pb = TestProblems.Beam()
            result = CommonSolve.solve(
                pb.ocp;
                initial_guess=pb.init,
                display=false,
                grid_size=10,
                print_level=0,
                max_iter=0,
            )
            Test.@test result isa CTModels.AbstractSolution
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_orchestration() = TestOrchestration.test_orchestration()

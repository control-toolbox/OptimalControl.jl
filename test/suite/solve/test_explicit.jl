module TestExplicit

using Test
using OptimalControl
using CTModels
using CTDirect
using CTSolvers
using CTBase
using CommonSolve
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# TOP-LEVEL MOCKS
# ====================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution end

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.Strategies.StrategyOptions
end

struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.Strategies.StrategyOptions
end

struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.Strategies.StrategyOptions
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
    @testset "solve_explicit (contract tests with mocks)" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = MockOCP()
        init = MockInit()
        disc = MockDiscretizer(CTSolvers.Strategies.StrategyOptions())
        mod = MockModeler(CTSolvers.Strategies.StrategyOptions())
        sol = MockSolver(CTSolvers.Strategies.StrategyOptions())
        registry = get_strategy_registry()

        # ================================================================
        # COMPLETE COMPONENTS PATH
        # ================================================================
        @testset "Complete components -> direct path" begin
            result = OptimalControl.solve_explicit(
                ocp, init;
                discretizer=disc,
                modeler=mod,
                solver=sol,
                display=false,
                registry=registry
            )
            @test result isa MockSolution
        end

        # ================================================================
        # PARTIAL COMPONENTS PATH (NotImplemented placeholder)
        # ================================================================
        @testset "Partial components -> completion" begin
            @test_throws CTBase.Exceptions.NotImplemented OptimalControl.solve_explicit(
                ocp, init;
                discretizer=disc,
                modeler=nothing,
                solver=sol,
                display=false,
                registry=registry
            )
        end
    end
end

end # module

test_explicit() = TestExplicit.test_explicit()

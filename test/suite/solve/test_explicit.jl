module TestExplicit

using Test
using OptimalControl
using CTModels
using CTDirect
using CTSolvers
using CTBase
using CommonSolve
using NLPModelsIpopt  # Load extension for Ipopt
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
        # INTEGRATION TESTS WITH REAL STRATEGIES
        # ================================================================
        @testset "Integration with real strategies" begin
            registry = OptimalControl.get_strategy_registry()
            
            # Test with real test problems
            problems = [
                ("Beam", Beam()),
                ("Goddard", Goddard()),
            ]
            
            for (pname, pb) in problems
                @testset "$pname" begin
                    # Build initial guess
                    init = OptimalControl.build_initial_guess(pb.ocp, pb.init)
                    
                    @testset "Complete components - real strategies" begin
                        result = OptimalControl.solve_explicit(
                            pb.ocp, init;
                            discretizer=CTDirect.Collocation(),
                            modeler=CTSolvers.Modelers.ADNLP(),
                            solver=CTSolvers.Solvers.Ipopt(),
                            display=false,
                            registry=registry
                        )
                        @test result isa CTModels.AbstractSolution
                        @test OptimalControl.successful(result)
                        @test OptimalControl.objective(result) ≈ pb.obj rtol=1e-2
                    end
                    
                    @testset "Partial components - completion" begin
                        # Test with only discretizer provided
                        result = OptimalControl.solve_explicit(
                            pb.ocp, init;
                            discretizer=CTDirect.Collocation(),
                            modeler=nothing,
                            solver=nothing,
                            display=false,
                            registry=registry
                        )
                        @test result isa CTModels.AbstractSolution
                        @test OptimalControl.successful(result)
                    end
                end
            end
            
            @testset "All missing components" begin
                # Test with Beam problem - all components missing
                pb = Beam()
                init = OptimalControl.build_initial_guess(pb.ocp, pb.init)
                
                result = OptimalControl.solve_explicit(
                    pb.ocp, init;
                    discretizer=nothing,
                    modeler=nothing,
                    solver=nothing,
                    display=false,
                    registry=registry
                )
                @test result isa CTModels.AbstractSolution
                @test OptimalControl.successful(result)
                @test OptimalControl.objective(result) ≈ pb.obj rtol=1e-2
            end
        end
    end
end

end # module

test_explicit() = TestExplicit.test_explicit()

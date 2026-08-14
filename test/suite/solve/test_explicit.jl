# ============================================================================
# Explicit Mode Tests (Layer 2)
# ============================================================================
# This file tests the `solve_explicit` function. It verifies that when the user
# provides instantiated strategy components (discretizer, modeler, solver) as
# keyword arguments, any missing components are correctly completed via the
# strategy registry before delegating to the canonical Layer 3 solve.

module TestExplicit

using Test: Test
using OptimalControl: OptimalControl
using CTModels: CTModels
using CTDirect: CTDirect
using CTSolvers: CTSolvers
using CTBase: CTBase
using CommonSolve: CommonSolve

#
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP
using MadNCL: MadNCL

#
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# TOP-LEVEL MOCKS
# ====================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution end
CTModels.build_initial_guess(::MockOCP, ::Nothing) = MockInit()
CTModels.build_initial_guess(::MockOCP, init::MockInit) = init

# ====================================================================
# TEST PROBLEMS FOR INTEGRATION TESTS
# ====================================================================

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

struct MockDiscretizer <: CTSolvers.DOCP.AbstractDiscretizer
    options::CTBase.Strategies.StrategyOptions
end

struct MockModeler <: CTSolvers.Modelers.AbstractNLPModeler
    options::CTBase.Strategies.StrategyOptions
end

struct MockSolver <: CTSolvers.Solvers.AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end

function CTBase.Strategies.metadata(::Type{MockDiscretizer})
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Options.OptionDefinition(;
            name=:grid_size, type=Int, default=100, description="Grid size"
        ),
    )
end

function CTBase.Strategies.metadata(::Type{MockModeler})
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:dense, description="Backend"
        ),
        CTBase.Options.OptionDefinition(;
            name=:modeler_only, type=Bool, default=false, description="Modeler-only option"
        ),
    )
end

function CTBase.Strategies.metadata(::Type{MockSolver})
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:cpu, description="Backend"
        ),
        CTBase.Options.OptionDefinition(;
            name=:solver_only, type=Bool, default=false, description="Solver-only option"
        ),
    )
end

CTBase.Strategies.options(strategy::MockDiscretizer) = strategy.options
CTBase.Strategies.options(strategy::MockModeler) = strategy.options
CTBase.Strategies.options(strategy::MockSolver) = strategy.options

function MockDiscretizer(; kwargs...)
    return MockDiscretizer(
        CTBase.Strategies.build_strategy_options(MockDiscretizer; kwargs...)
    )
end
function MockModeler(; kwargs...)
    return MockModeler(CTBase.Strategies.build_strategy_options(MockModeler; kwargs...))
end
function MockSolver(; kwargs...)
    return MockSolver(CTBase.Strategies.build_strategy_options(MockSolver; kwargs...))
end

CommonSolve.solve(
    ::MockOCP, ::MockInit, ::MockDiscretizer, ::MockModeler, ::MockSolver; display::Bool
)::MockSolution = MockSolution()

function test_explicit()
    Test.@testset "solve_explicit (contract tests with mocks)" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = MockOCP()
        init = MockInit()
        disc = MockDiscretizer(CTBase.Strategies.StrategyOptions())
        mod = MockModeler(CTBase.Strategies.StrategyOptions())
        sol = MockSolver(CTBase.Strategies.StrategyOptions())
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
                registry=registry,
            )
            Test.@test result isa MockSolution
        end

        # ================================================================
        # EXPLICIT OPTION VALIDATION
        # ================================================================
        Test.@testset "Action options remain valid" begin
            result = OptimalControl.solve_explicit(
                ocp;
                init=init,
                discretizer=disc,
                modeler=mod,
                solver=sol,
                display=false,
                registry=registry,
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "Dispatcher validates explicit options" begin
            err = try
                CommonSolve.solve(
                    ocp;
                    initial_guess=init,
                    disc=MockDiscretizer(),
                    modeler=MockModeler(),
                    solver=MockSolver(),
                    backend=:generic,
                    display=false,
                )
                nothing
            catch exception
                exception
            end
            Test.@test err isa CTBase.IncorrectArgument
            Test.@test occursin("backend", sprint(showerror, err))
        end

        Test.@testset "Strategy option suggests construction" begin
            configured_disc = MockDiscretizer()
            configured_mod = MockModeler()
            configured_sol = MockSolver()
            err = try
                OptimalControl.solve_explicit(
                    ocp;
                    initial_guess=init,
                    discretizer=configured_disc,
                    modeler=configured_mod,
                    solver=configured_sol,
                    modeler_only=true,
                    registry=registry,
                )
                nothing
            catch exception
                exception
            end
            Test.@test err isa CTBase.IncorrectArgument
            message = sprint(showerror, err)
            Test.@test occursin("modeler_only", message)
            Test.@test occursin("MockModeler", message)
            Test.@test occursin("Construct", message)
        end

        Test.@testset "Ambiguous strategy option is rejected" begin
            err = try
                OptimalControl.solve_explicit(
                    ocp;
                    initial_guess=init,
                    discretizer=MockDiscretizer(),
                    modeler=MockModeler(),
                    solver=MockSolver(),
                    backend=:generic,
                    registry=registry,
                )
                nothing
            catch exception
                exception
            end
            Test.@test err isa CTBase.IncorrectArgument
            message = sprint(showerror, err)
            Test.@test occursin("backend", message)
            Test.@test occursin("modeler", message)
            Test.@test occursin("solver", message)
        end

        Test.@testset "Unknown explicit option is rejected" begin
            err = try
                OptimalControl.solve_explicit(
                    ocp;
                    initial_guess=init,
                    discretizer=disc,
                    modeler=mod,
                    solver=sol,
                    beep=:beep,
                    registry=registry,
                )
                nothing
            catch exception
                exception
            end
            Test.@test err isa CTBase.IncorrectArgument
            message = sprint(showerror, err)
            Test.@test occursin("beep", message)
            Test.@test occursin("initial_guess", message)
            Test.@test occursin("display", message)
        end

        Test.@testset "bypass does not change explicit mode validation" begin
            err = try
                OptimalControl.solve_explicit(
                    ocp;
                    initial_guess=init,
                    discretizer=MockDiscretizer(),
                    modeler=MockModeler(),
                    solver=MockSolver(),
                    backend=CTBase.Strategies.bypass(:generic),
                    registry=registry,
                )
                nothing
            catch exception
                exception
            end
            Test.@test err isa CTBase.IncorrectArgument
            Test.@test occursin("backend", sprint(showerror, err))
        end

        # ================================================================
        # INTEGRATION TESTS WITH REAL STRATEGIES
        # ================================================================
        Test.@testset "Integration with real strategies" begin
            registry = OptimalControl.get_strategy_registry()

            # Test with real test problems
            problems = [("Beam", TestProblems.Beam()), ("Goddard", TestProblems.Goddard())]

            for (pname, pb) in problems
                Test.@testset "$pname" begin
                    # Build initial guess
                    init = OptimalControl.build_initial_guess(pb.ocp, pb.init)

                    Test.@testset "Complete components - real strategies" begin
                        result = OptimalControl.solve_explicit(
                            pb.ocp;
                            initial_guess=init,
                            discretizer=CTDirect.Collocation(),
                            modeler=CTSolvers.Modelers.ADNLP(),
                            solver=CTSolvers.Solvers.Ipopt(),
                            display=false,
                            registry=registry,
                        )
                        Test.@test result isa CTModels.AbstractSolution
                        Test.@test OptimalControl.successful(result)
                        Test.@test OptimalControl.objective(result) ≈ pb.objective rtol=1e-2
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
                            registry=registry,
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

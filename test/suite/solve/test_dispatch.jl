# ============================================================================
# Solve Dispatch Integration Tests
# ============================================================================
# This file tests the main `solve` entry point (Layer 1) integration. It verifies
# that the initial guess is properly normalized at the top level and that the
# execution successfully flows through the correct sub-method (explicit or
# descriptive) based on the user's input arguments.

module TestSolveDispatch

using Test: Test
using OptimalControl: OptimalControl
using CTModels: CTModels
using CTDirect: CTDirect
using CTSolvers: CTSolvers
using CTBase: CTBase
using CommonSolve: CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Mock types for contract testing
# ============================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution end
CTModels.build_initial_guess(::MockOCP, ::Nothing) = MockInit()
CTModels.build_initial_guess(::MockOCP, i::MockInit) = i

struct MockDiscretizer <: CTSolvers.DOCP.AbstractDiscretizer
    options::CTBase.Strategies.StrategyOptions
end
CTBase.Strategies.id(::Type{<:MockDiscretizer}) = :collocation
function CTBase.Strategies.metadata(::Type{<:MockDiscretizer})
    return CTBase.Strategies.StrategyMetadata()
end
CTBase.Strategies.options(d::MockDiscretizer) = d.options
# ⚠️ v2.1.0-beta contract: every strategy must implement `parameter` (the CTBase
# generic throws `NotImplemented` by default, unlike the old `get_parameter_type`).
CTBase.Strategies.parameter(::Type{<:MockDiscretizer}) = nothing
function MockDiscretizer(; mode::Symbol=:strict, kwargs...)
    opts = CTBase.Strategies.build_strategy_options(
        MockDiscretizer; mode=mode, kwargs...
    )
    return MockDiscretizer(opts)
end

struct MockModeler <: CTSolvers.Modelers.AbstractNLPModeler
    options::CTBase.Strategies.StrategyOptions
end
CTBase.Strategies.id(::Type{<:MockModeler}) = :adnlp
function CTBase.Strategies.metadata(::Type{<:MockModeler})
    return CTBase.Strategies.StrategyMetadata()
end
CTBase.Strategies.options(m::MockModeler) = m.options
# ⚠️ v2.1.0-beta contract: every strategy must implement `parameter` (the CTBase
# generic throws `NotImplemented` by default, unlike the old `get_parameter_type`).
CTBase.Strategies.parameter(::Type{<:MockModeler}) = nothing
function MockModeler(; mode::Symbol=:strict, kwargs...)
    opts = CTBase.Strategies.build_strategy_options(MockModeler; mode=mode, kwargs...)
    return MockModeler(opts)
end

struct MockSolver <: CTSolvers.Solvers.AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end
CTBase.Strategies.id(::Type{<:MockSolver}) = :ipopt
function CTBase.Strategies.metadata(::Type{<:MockSolver})
    return CTBase.Strategies.StrategyMetadata()
end
CTBase.Strategies.options(s::MockSolver) = s.options
# ⚠️ v2.1.0-beta contract: every strategy must implement `parameter` (the CTBase
# generic throws `NotImplemented` by default, unlike the old `get_parameter_type`).
CTBase.Strategies.parameter(::Type{<:MockSolver}) = nothing
function MockSolver(; mode::Symbol=:strict, kwargs...)
    opts = CTBase.Strategies.build_strategy_options(MockSolver; mode=mode, kwargs...)
    return MockSolver(opts)
end

# Mock registry: maps mock types so _complete_components builds mocks, not real solvers
function mock_strategy_registry()::CTBase.Strategies.StrategyRegistry
    return CTBase.Strategies.create_registry(
        CTSolvers.DOCP.AbstractDiscretizer => (MockDiscretizer,),
        CTSolvers.Modelers.AbstractNLPModeler => (MockModeler,),
        CTSolvers.Solvers.AbstractNLPSolver => (MockSolver,),
    )
end

# Override Layer 3 solve for mocks — returns MockSolution immediately (explicit mode)
function CommonSolve.solve(
    ::MockOCP, ::MockInit, ::MockDiscretizer, ::MockModeler, ::MockSolver; display::Bool
)::MockSolution
    return MockSolution()
end

# Override Layer 3 for descriptive mode: solve_descriptive builds real mock types via registry
# MockDiscretizer <: AbstractDiscretizer, so this catches those calls too
function CommonSolve.solve(
    ::MockOCP,
    ::CTModels.AbstractInitialGuess,
    ::CTSolvers.DOCP.AbstractDiscretizer,
    ::CTSolvers.Modelers.AbstractNLPModeler,
    ::CTSolvers.Solvers.AbstractNLPSolver;
    display::Bool,
)::MockSolution
    return MockSolution()
end

function test_solve_dispatch()
    Test.@testset "Solve Dispatch" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = MockOCP()
        init = MockInit()
        disc = MockDiscretizer(CTBase.Strategies.StrategyOptions())
        mod = MockModeler(CTBase.Strategies.StrategyOptions())
        sol = MockSolver(CTBase.Strategies.StrategyOptions())
        registry = mock_strategy_registry()

        # ====================================================================
        # CONTRACT TESTS - solve_explicit: complete components (mock Layer 3)
        # ====================================================================

        Test.@testset "solve_explicit - all three components" begin
            result = OptimalControl.solve_explicit(
                ocp;
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc,
                modeler=mod,
                solver=sol,
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_explicit - alias 'init'" begin
            result = OptimalControl.solve_explicit(
                ocp;
                init=init,
                display=false,
                registry=registry,
                discretizer=disc,
                modeler=mod,
                solver=sol,
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_explicit - partial components (mock registry completes)" begin
            result = OptimalControl.solve_explicit(
                ocp;
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc,
                modeler=nothing,
                solver=nothing,
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # CONTRACT TESTS - solve_descriptive: dispatches correctly
        # ====================================================================

        Test.@testset "solve_descriptive - complete description dispatches" begin
            result = OptimalControl.solve_descriptive(
                ocp,
                :collocation,
                :adnlp,
                :ipopt;
                initial_guess=init,
                display=false,
                registry=registry,
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_descriptive - alias 'init'" begin
            result = OptimalControl.solve_descriptive(
                ocp,
                :collocation,
                :adnlp,
                :ipopt;
                init=init,
                display=false,
                registry=registry,
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "solve_descriptive - alias 'i' (removed)" begin
            # :i is no longer recognized as an alias for initial_guess
            Test.@test_throws CTBase.IncorrectArgument begin
                OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    i=init,
                    display=false,
                    registry=registry,
                )
            end
        end

        Test.@testset "solve_descriptive - empty description dispatches" begin
            result = OptimalControl.solve_descriptive(
                ocp; initial_guess=init, display=false, registry=registry
            )
            Test.@test result isa MockSolution
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_dispatch() = TestSolveDispatch.test_solve_dispatch()

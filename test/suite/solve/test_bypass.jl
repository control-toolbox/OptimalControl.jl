# ============================================================================
# Bypass Mechanism Integration Tests
# ============================================================================
# This file tests the integration of the bypass mechanism across all solve
# layers (`solve`, `solve_explicit`, `solve_descriptive`). It verifies that
# options wrapped in `bypass(val)` combined with `route_to` correctly
# skip validation and propagate down to the final Layer 3 execution.

module TestBypassMechanism

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
# TOP-LEVEL MOCKS AND TYPES
# ============================================================================

# Mock OCP and Initial Guess
struct MockBypassOCP <: CTModels.AbstractModel end
struct MockBypassInit <: CTModels.AbstractInitialGuess end
CTModels.build_initial_guess(::MockBypassOCP, ::Nothing) = MockBypassInit()

# Mock Strategies
struct MockBypassDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.StrategyOptions
end

CTSolvers.id(::Type{MockBypassDiscretizer}) = :collocation
function CTSolvers.metadata(::Type{MockBypassDiscretizer})
    CTSolvers.StrategyMetadata(
        CTSolvers.OptionDefinition(;
            name=:grid_size, type=Int, default=100, description="Grid size"
        ),
    )
end
CTSolvers.options(s::MockBypassDiscretizer) = s.options

function MockBypassDiscretizer(; kwargs...)
    opts = CTSolvers.build_strategy_options(MockBypassDiscretizer; kwargs...)
    return MockBypassDiscretizer(opts)
end

struct MockBypassModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end

CTSolvers.id(::Type{MockBypassModeler}) = :adnlp
function CTSolvers.metadata(::Type{MockBypassModeler})
    CTSolvers.StrategyMetadata(
        CTSolvers.OptionDefinition(;
            name=:backend, type=Symbol, default=:dense, description="Backend"
        ),
    )
end
CTSolvers.options(s::MockBypassModeler) = s.options

function MockBypassModeler(; kwargs...)
    opts = CTSolvers.build_strategy_options(MockBypassModeler; kwargs...)
    return MockBypassModeler(opts)
end

struct MockBypassSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

CTSolvers.id(::Type{MockBypassSolver}) = :ipopt
function CTSolvers.metadata(::Type{MockBypassSolver})
    CTSolvers.StrategyMetadata(
        CTSolvers.OptionDefinition(;
            name=:max_iter, type=Int, default=1000, description="Max iterations"
        ),
    )
end
CTSolvers.options(s::MockBypassSolver) = s.options

function MockBypassSolver(; kwargs...)
    opts = CTSolvers.build_strategy_options(MockBypassSolver; kwargs...)
    return MockBypassSolver(opts)
end

# Registry builder for tests
function build_bypass_mock_registry()
    return CTSolvers.create_registry(
        CTDirect.AbstractDiscretizer => (MockBypassDiscretizer,),
        CTSolvers.AbstractNLPModeler => (MockBypassModeler,),
        CTSolvers.AbstractNLPSolver => (MockBypassSolver,),
    )
end

# Layer 3 override to intercept options
struct MockBypassSolution <: CTModels.AbstractSolution
    discretizer::CTDirect.AbstractDiscretizer
    modeler::CTSolvers.AbstractNLPModeler
    solver::CTSolvers.AbstractNLPSolver
end

function CommonSolve.solve(
    ocp::MockBypassOCP,
    init::CTModels.AbstractInitialGuess,
    discretizer::CTDirect.AbstractDiscretizer,
    modeler::CTSolvers.AbstractNLPModeler,
    solver::CTSolvers.AbstractNLPSolver;
    display::Bool,
)::MockBypassSolution
    return MockBypassSolution(discretizer, modeler, solver)
end

# ============================================================================
# TESTS
# ============================================================================

function test_bypass()
    Test.@testset "Bypass Mechanism Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        registry = build_bypass_mock_registry()
        ocp = MockBypassOCP()
        init = MockBypassInit()

        # ====================================================================
        # Descriptive Mode (`solve_descriptive`)
        # ====================================================================
        Test.@testset "Descriptive Mode" begin
            Test.@testset "Error without bypass" begin
                Test.@test_throws CTBase.Exceptions.IncorrectArgument OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                    unknown_opt=42,
                )
            end

            Test.@testset "Success with route_to(strategy=bypass(val))" begin
                sol = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                    unknown_opt=CTSolvers.route_to(ipopt=CTSolvers.bypass(42)),
                )
                Test.@test sol isa MockBypassSolution
                # The bypassed option should be inside the solver's options
                # CTSolvers `build_strategy_options` strips the `BypassValue` 
                # and returns the raw value in the options.
                Test.@test CTSolvers.has_option(sol.solver, :unknown_opt)
                Test.@test CTSolvers.option_value(sol.solver, :unknown_opt) == 42
            end

            Test.@testset "Bypass on discretizer" begin
                sol = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                    disc_custom=CTSolvers.route_to(collocation=CTSolvers.bypass(:fine)),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTSolvers.has_option(sol.discretizer, :disc_custom)
                Test.@test CTSolvers.option_value(sol.discretizer, :disc_custom) == :fine
            end

            Test.@testset "Bypass on modeler" begin
                sol = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                    mod_custom=CTSolvers.route_to(adnlp=CTSolvers.bypass("sparse_mode")),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTSolvers.has_option(sol.modeler, :mod_custom)
                Test.@test CTSolvers.option_value(sol.modeler, :mod_custom) == "sparse_mode"
            end

            Test.@testset "Multi-bypass: two strategies simultaneously" begin
                sol = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                    shared_opt=CTSolvers.route_to(
                        ipopt=CTSolvers.bypass(100), adnlp=CTSolvers.bypass(:dense)
                    ),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTSolvers.has_option(sol.solver, :shared_opt)
                Test.@test CTSolvers.option_value(sol.solver, :shared_opt) == 100
                Test.@test CTSolvers.has_option(sol.modeler, :shared_opt)
                Test.@test CTSolvers.option_value(sol.modeler, :shared_opt) == :dense
            end

            Test.@testset "Bypass with nothing value" begin
                sol = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                    nullable_opt=CTSolvers.route_to(ipopt=CTSolvers.bypass(nothing)),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTSolvers.has_option(sol.solver, :nullable_opt)
                Test.@test isnothing(CTSolvers.option_value(sol.solver, :nullable_opt))
            end
        end

        # ====================================================================
        # Explicit Mode (`solve_explicit`)
        # ====================================================================
        Test.@testset "Explicit Mode" begin
            Test.@testset "Success with manually bypassed option" begin
                solver = MockBypassSolver(unknown_opt=CTSolvers.bypass("passed"))
                sol = OptimalControl.solve_explicit(
                    ocp;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                    discretizer=MockBypassDiscretizer(),
                    modeler=MockBypassModeler(),
                    solver=solver,
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTSolvers.has_option(sol.solver, :unknown_opt)
                Test.@test CTSolvers.option_value(sol.solver, :unknown_opt) == "passed"
            end
        end

        # ====================================================================
        # Top-level Dispatch (`solve`)
        # ====================================================================
        Test.@testset "Top-level Dispatch" begin
            Test.@testset "Descriptive via solve" begin
                sol = OptimalControl.solve(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    display=false,
                    registry=registry,
                    custom_backend_opt=CTSolvers.route_to(ipopt=CTSolvers.bypass(99)),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTSolvers.has_option(sol.solver, :custom_backend_opt)
                Test.@test CTSolvers.option_value(sol.solver, :custom_backend_opt) == 99
            end

            Test.@testset "Explicit via solve" begin
                solver = MockBypassSolver(custom_backend_opt=CTSolvers.bypass(99))
                sol = OptimalControl.solve(
                    ocp;
                    display=false,
                    registry=registry,
                    discretizer=MockBypassDiscretizer(),
                    modeler=MockBypassModeler(),
                    solver=solver,
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTSolvers.has_option(sol.solver, :custom_backend_opt)
                Test.@test CTSolvers.option_value(sol.solver, :custom_backend_opt) == 99
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_bypass() = TestBypassMechanism.test_bypass()

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
struct MockBypassDiscretizer <: CTSolvers.DOCP.AbstractDiscretizer
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{MockBypassDiscretizer}) = :collocation
function CTBase.Strategies.metadata(::Type{MockBypassDiscretizer})
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Options.OptionDefinition(;
            name=:grid_size, type=Int, default=100, description="Grid size"
        ),
    )
end
CTBase.Strategies.options(s::MockBypassDiscretizer) = s.options
# ⚠️ v2.1.0-beta contract: every strategy must implement `parameter`. The old
# `CTSolvers.Strategies.get_parameter_type` defaulted to `nothing`; the CTBase
# generic throws `NotImplemented` instead, so a mock that omits it makes option
# routing fail rather than treating the strategy as non-parameterized.
CTBase.Strategies.parameter(::Type{<:MockBypassDiscretizer}) = nothing

function MockBypassDiscretizer(; kwargs...)
    opts = CTBase.Strategies.build_strategy_options(MockBypassDiscretizer; kwargs...)
    return MockBypassDiscretizer(opts)
end

struct MockBypassModeler <: CTSolvers.Modelers.AbstractNLPModeler
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{MockBypassModeler}) = :adnlp
function CTBase.Strategies.metadata(::Type{MockBypassModeler})
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:dense, description="Backend"
        ),
    )
end
CTBase.Strategies.options(s::MockBypassModeler) = s.options
# ⚠️ v2.1.0-beta contract: every strategy must implement `parameter`. The old
# `CTSolvers.Strategies.get_parameter_type` defaulted to `nothing`; the CTBase
# generic throws `NotImplemented` instead, so a mock that omits it makes option
# routing fail rather than treating the strategy as non-parameterized.
CTBase.Strategies.parameter(::Type{<:MockBypassModeler}) = nothing

function MockBypassModeler(; kwargs...)
    opts = CTBase.Strategies.build_strategy_options(MockBypassModeler; kwargs...)
    return MockBypassModeler(opts)
end

struct MockBypassSolver <: CTSolvers.Solvers.AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{MockBypassSolver}) = :ipopt
function CTBase.Strategies.metadata(::Type{MockBypassSolver})
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Options.OptionDefinition(;
            name=:max_iter, type=Int, default=1000, description="Max iterations"
        ),
    )
end
CTBase.Strategies.options(s::MockBypassSolver) = s.options
# ⚠️ v2.1.0-beta contract: every strategy must implement `parameter`. The old
# `CTSolvers.Strategies.get_parameter_type` defaulted to `nothing`; the CTBase
# generic throws `NotImplemented` instead, so a mock that omits it makes option
# routing fail rather than treating the strategy as non-parameterized.
CTBase.Strategies.parameter(::Type{<:MockBypassSolver}) = nothing

function MockBypassSolver(; kwargs...)
    opts = CTBase.Strategies.build_strategy_options(MockBypassSolver; kwargs...)
    return MockBypassSolver(opts)
end

# Registry builder for tests
function build_bypass_mock_registry()
    return CTBase.Strategies.create_registry(
        CTSolvers.DOCP.AbstractDiscretizer => (MockBypassDiscretizer,),
        CTSolvers.Modelers.AbstractNLPModeler => (MockBypassModeler,),
        CTSolvers.Solvers.AbstractNLPSolver => (MockBypassSolver,),
    )
end

# Layer 3 override to intercept options
struct MockBypassSolution <: CTModels.AbstractSolution
    discretizer::CTSolvers.DOCP.AbstractDiscretizer
    modeler::CTSolvers.Modelers.AbstractNLPModeler
    solver::CTSolvers.Solvers.AbstractNLPSolver
end

function CommonSolve.solve(
    ocp::MockBypassOCP,
    init::CTModels.AbstractInitialGuess,
    discretizer::CTSolvers.DOCP.AbstractDiscretizer,
    modeler::CTSolvers.Modelers.AbstractNLPModeler,
    solver::CTSolvers.Solvers.AbstractNLPSolver;
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
                    unknown_opt=CTBase.Strategies.route_to(ipopt=CTBase.Strategies.bypass(42)),
                )
                Test.@test sol isa MockBypassSolution
                # The bypassed option should be inside the solver's options
                # CTSolvers `build_strategy_options` strips the `BypassValue` 
                # and returns the raw value in the options.
                Test.@test CTBase.Strategies.has_option(sol.solver, :unknown_opt)
                Test.@test CTBase.Strategies.option_value(sol.solver, :unknown_opt) == 42
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
                    disc_custom=CTBase.Strategies.route_to(collocation=CTBase.Strategies.bypass(:fine)),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTBase.Strategies.has_option(sol.discretizer, :disc_custom)
                Test.@test CTBase.Strategies.option_value(sol.discretizer, :disc_custom) == :fine
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
                    mod_custom=CTBase.Strategies.route_to(adnlp=CTBase.Strategies.bypass("sparse_mode")),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTBase.Strategies.has_option(sol.modeler, :mod_custom)
                Test.@test CTBase.Strategies.option_value(sol.modeler, :mod_custom) == "sparse_mode"
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
                    shared_opt=CTBase.Strategies.route_to(
                        ipopt=CTBase.Strategies.bypass(100), adnlp=CTBase.Strategies.bypass(:dense)
                    ),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTBase.Strategies.has_option(sol.solver, :shared_opt)
                Test.@test CTBase.Strategies.option_value(sol.solver, :shared_opt) == 100
                Test.@test CTBase.Strategies.has_option(sol.modeler, :shared_opt)
                Test.@test CTBase.Strategies.option_value(sol.modeler, :shared_opt) == :dense
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
                    nullable_opt=CTBase.Strategies.route_to(ipopt=CTBase.Strategies.bypass(nothing)),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTBase.Strategies.has_option(sol.solver, :nullable_opt)
                Test.@test isnothing(CTBase.Strategies.option_value(sol.solver, :nullable_opt))
            end
        end

        # ====================================================================
        # Explicit Mode (`solve_explicit`)
        # ====================================================================
        Test.@testset "Explicit Mode" begin
            Test.@testset "Success with manually bypassed option" begin
                solver = MockBypassSolver(unknown_opt=CTBase.Strategies.bypass("passed"))
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
                Test.@test CTBase.Strategies.has_option(sol.solver, :unknown_opt)
                Test.@test CTBase.Strategies.option_value(sol.solver, :unknown_opt) == "passed"
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
                    custom_backend_opt=CTBase.Strategies.route_to(ipopt=CTBase.Strategies.bypass(99)),
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTBase.Strategies.has_option(sol.solver, :custom_backend_opt)
                Test.@test CTBase.Strategies.option_value(sol.solver, :custom_backend_opt) == 99
            end

            Test.@testset "Explicit via solve" begin
                solver = MockBypassSolver(custom_backend_opt=CTBase.Strategies.bypass(99))
                sol = OptimalControl.solve(
                    ocp;
                    display=false,
                    registry=registry,
                    discretizer=MockBypassDiscretizer(),
                    modeler=MockBypassModeler(),
                    solver=solver,
                )
                Test.@test sol isa MockBypassSolution
                Test.@test CTBase.Strategies.has_option(sol.solver, :custom_backend_opt)
                Test.@test CTBase.Strategies.option_value(sol.solver, :custom_backend_opt) == 99
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_bypass() = TestBypassMechanism.test_bypass()

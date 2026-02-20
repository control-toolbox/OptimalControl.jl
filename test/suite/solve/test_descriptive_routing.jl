# ============================================================================
# Descriptive Routing Helper Tests
# ============================================================================
# This file contains unit tests for the descriptive mode routing helpers 
# (e.g., `_route_descriptive_options`, `_build_components_from_routed`).
# It uses parametric mock strategies to isolate and verify the routing and
# instantiation logic without relying on heavy solver backends.

module TestDescriptiveRouting

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
# TOP-LEVEL: Mock strategy types for routing tests
#
# We define minimal mock strategies with known option metadata so we can test
# routing behaviour without depending on real backend implementations.
# ============================================================================

# --- Abstract families (isolated from real CTDirect/CTSolvers families) ---

abstract type RoutingMockDiscretizer <: CTDirect.AbstractDiscretizer end
abstract type RoutingMockModeler     <: CTSolvers.AbstractNLPModeler end
abstract type RoutingMockSolver      <: CTSolvers.AbstractNLPSolver  end

# --- Concrete mock: Collocation-like discretizer ---

struct MockCollocation <: RoutingMockDiscretizer
    options::CTSolvers.StrategyOptions
end

CTSolvers.Strategies.id(::Type{MockCollocation}) = :collocation
CTSolvers.Strategies.metadata(::Type{MockCollocation}) = CTSolvers.Strategies.StrategyMetadata(
    CTSolvers.Options.OptionDefinition(
        name        = :grid_size,
        type        = Int,
        default     = 100,
        description = "Number of grid points",
    ),
)
CTSolvers.Strategies.options(s::MockCollocation) = s.options

function MockCollocation(; mode::Symbol=:strict, kwargs...)
    opts = CTSolvers.Strategies.build_strategy_options(MockCollocation; mode=mode, kwargs...)
    return MockCollocation(opts)
end

# --- Concrete mock: ADNLP-like modeler (with ambiguous :backend option) ---

struct MockADNLP <: RoutingMockModeler
    options::CTSolvers.StrategyOptions
end

CTSolvers.Strategies.id(::Type{MockADNLP}) = :adnlp
CTSolvers.Strategies.metadata(::Type{MockADNLP}) = CTSolvers.Strategies.StrategyMetadata(
    CTSolvers.Options.OptionDefinition(
        name        = :backend,
        type        = Symbol,
        default     = :dense,
        description = "NLP backend",
        aliases     = (:adnlp_backend,),
    ),
)
CTSolvers.Strategies.options(s::MockADNLP) = s.options

function MockADNLP(; mode::Symbol=:strict, kwargs...)
    opts = CTSolvers.Strategies.build_strategy_options(MockADNLP; mode=mode, kwargs...)
    return MockADNLP(opts)
end

# --- Concrete mock: Ipopt-like solver (with ambiguous :backend + :max_iter) ---

struct MockIpopt <: RoutingMockSolver
    options::CTSolvers.StrategyOptions
end

CTSolvers.Strategies.id(::Type{MockIpopt}) = :ipopt
CTSolvers.Strategies.metadata(::Type{MockIpopt}) = CTSolvers.Strategies.StrategyMetadata(
    CTSolvers.Options.OptionDefinition(
        name        = :max_iter,
        type        = Int,
        default     = 1000,
        description = "Maximum iterations",
    ),
    CTSolvers.Options.OptionDefinition(
        name        = :backend,
        type        = Symbol,
        default     = :cpu,
        description = "Solver backend",
        aliases     = (:ipopt_backend,),
    ),
)
CTSolvers.Strategies.options(s::MockIpopt) = s.options

function MockIpopt(; mode::Symbol=:strict, kwargs...)
    opts = CTSolvers.Strategies.build_strategy_options(MockIpopt; mode=mode, kwargs...)
    return MockIpopt(opts)
end

# --- Registry and method ---

const MOCK_REGISTRY = CTSolvers.create_registry(
    CTDirect.AbstractDiscretizer => (MockCollocation,),
    CTSolvers.AbstractNLPModeler => (MockADNLP,),
    CTSolvers.AbstractNLPSolver  => (MockIpopt,),
)

const MOCK_METHOD = (:collocation, :adnlp, :ipopt)

# ============================================================================
# TOP-LEVEL: Integration test mock types (Layer 3 short-circuit)
# ============================================================================

struct MockOCP2 <: CTModels.AbstractModel end
struct MockInit2 <: CTModels.AbstractInitialGuess end
struct MockSolution2 <: CTModels.AbstractSolution
    discretizer
    modeler
    solver
end

CommonSolve.solve(
    ::MockOCP2, ::CTModels.AbstractInitialGuess,
    d::RoutingMockDiscretizer, m::RoutingMockModeler, s::RoutingMockSolver;
    display::Bool
)::MockSolution2 = MockSolution2(d, m, s)

# ============================================================================
# Test function
# ============================================================================

function test_descriptive_routing()
    Test.@testset "Descriptive Routing Helpers" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS — _descriptive_families
        # ====================================================================

        Test.@testset "_descriptive_families" begin
            fam = OptimalControl._descriptive_families()

            Test.@test fam isa NamedTuple
            Test.@test haskey(fam, :discretizer)
            Test.@test haskey(fam, :modeler)
            Test.@test haskey(fam, :solver)
            Test.@test fam.discretizer === CTDirect.AbstractDiscretizer
            Test.@test fam.modeler     === CTSolvers.AbstractNLPModeler
            Test.@test fam.solver      === CTSolvers.AbstractNLPSolver
        end

        # ====================================================================
        # UNIT TESTS — _descriptive_action_defs
        # ====================================================================

        Test.@testset "_descriptive_action_defs" begin
            defs = OptimalControl._descriptive_action_defs()

            Test.@test defs isa Vector{CTSolvers.Options.OptionDefinition}
            Test.@test isempty(defs)
        end

        # ====================================================================
        # UNIT TESTS — _route_descriptive_options
        # ====================================================================

        Test.@testset "_route_descriptive_options - empty kwargs" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY, pairs(NamedTuple())
            )

            Test.@test haskey(routed, :action)
            Test.@test haskey(routed, :strategies)
            Test.@test isempty(routed.strategies.discretizer)
            Test.@test isempty(routed.strategies.modeler)
            Test.@test isempty(routed.strategies.solver)
        end

        Test.@testset "_route_descriptive_options - unambiguous auto-routing" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; grid_size=200, max_iter=500))
            )

            Test.@test routed.strategies.discretizer[:grid_size] == 200
            Test.@test routed.strategies.solver[:max_iter] == 500
            Test.@test isempty(routed.strategies.modeler)
        end

        Test.@testset "_route_descriptive_options - single strategy disambiguation" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; backend=CTSolvers.route_to(adnlp=:sparse)))
            )

            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test !haskey(routed.strategies.solver, :backend)
        end

        Test.@testset "_route_descriptive_options - multi-strategy disambiguation" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; backend=CTSolvers.route_to(adnlp=:sparse, ipopt=:gpu)))
            )

            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test routed.strategies.solver[:backend]  === :gpu
        end

        Test.@testset "_route_descriptive_options - alias auto-routing" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; adnlp_backend=:sparse))
            )

            Test.@test routed.strategies.modeler[:adnlp_backend] === :sparse
            Test.@test !haskey(routed.strategies.solver, :adnlp_backend)
        end

        Test.@testset "_route_descriptive_options - error on unknown option" begin
            Test.@test_throws CTBase.IncorrectArgument OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; totally_unknown=42))
            )
        end

        Test.@testset "_route_descriptive_options - error on ambiguous option" begin
            Test.@test_throws CTBase.IncorrectArgument OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; backend=:sparse))
            )
        end

        # ====================================================================
        # UNIT TESTS — _build_components_from_routed
        # ====================================================================

        Test.@testset "_build_components_from_routed - default options" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY, pairs(NamedTuple())
            )
            components = OptimalControl._build_components_from_routed(
                MOCK_METHOD, MOCK_REGISTRY, routed
            )

            Test.@test components.discretizer isa RoutingMockDiscretizer
            Test.@test components.modeler     isa RoutingMockModeler
            Test.@test components.solver      isa RoutingMockSolver
            Test.@test components.discretizer isa MockCollocation
            Test.@test components.modeler     isa MockADNLP
            Test.@test components.solver      isa MockIpopt
        end

        Test.@testset "_build_components_from_routed - options passed through" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; grid_size=42, max_iter=7))
            )
            components = OptimalControl._build_components_from_routed(
                MOCK_METHOD, MOCK_REGISTRY, routed
            )

            Test.@test CTSolvers.option_value(components.discretizer, :grid_size) == 42
            Test.@test CTSolvers.option_value(components.solver, :max_iter) == 7
        end

        Test.@testset "_build_components_from_routed - disambiguation passed through" begin
            routed = OptimalControl._route_descriptive_options(
                MOCK_METHOD, MOCK_REGISTRY,
                pairs((; backend=CTSolvers.route_to(adnlp=:sparse, ipopt=:gpu)))
            )
            components = OptimalControl._build_components_from_routed(
                MOCK_METHOD, MOCK_REGISTRY, routed
            )

            Test.@test CTSolvers.option_value(components.modeler, :backend) === :sparse
            Test.@test CTSolvers.option_value(components.solver,  :backend) === :gpu
        end

        # ====================================================================
        # INTEGRATION TESTS — solve_descriptive end-to-end with mocks
        # ====================================================================

        Test.@testset "solve_descriptive - complete description, no options" begin
            ocp  = MockOCP2()
            init = CTModels.build_initial_guess(ocp, MockInit2())

            sol = OptimalControl.solve_descriptive(
                ocp, :collocation, :adnlp, :ipopt;
                initial_guess = init,
                display       = false,
                registry      = MOCK_REGISTRY,
            )

            Test.@test sol isa MockSolution2
            Test.@test sol.discretizer isa MockCollocation
            Test.@test sol.modeler     isa MockADNLP
            Test.@test sol.solver      isa MockIpopt
        end

        Test.@testset "solve_descriptive - partial description completed" begin
            ocp  = MockOCP2()
            init = CTModels.build_initial_guess(ocp, MockInit2())

            sol = OptimalControl.solve_descriptive(
                ocp, :collocation;
                initial_guess = init,
                display       = false,
                registry      = MOCK_REGISTRY,
            )

            Test.@test sol isa MockSolution2
            Test.@test sol.discretizer isa MockCollocation
            Test.@test sol.modeler     isa MockADNLP
            Test.@test sol.solver      isa MockIpopt
        end

        Test.@testset "solve_descriptive - options routed correctly" begin
            ocp  = MockOCP2()
            init = CTModels.build_initial_guess(ocp, MockInit2())

            sol = OptimalControl.solve_descriptive(
                ocp, :collocation, :adnlp, :ipopt;
                initial_guess = init,
                display       = false,
                registry      = MOCK_REGISTRY,
                grid_size     = 42,
                max_iter      = 7,
            )

            Test.@test CTSolvers.option_value(sol.discretizer, :grid_size) == 42
            Test.@test CTSolvers.option_value(sol.solver, :max_iter) == 7
        end

        Test.@testset "solve_descriptive - disambiguation via route_to" begin
            ocp  = MockOCP2()
            init = CTModels.build_initial_guess(ocp, MockInit2())

            sol = OptimalControl.solve_descriptive(
                ocp, :collocation, :adnlp, :ipopt;
                initial_guess = init,
                display       = false,
                registry      = MOCK_REGISTRY,
                backend       = CTSolvers.route_to(adnlp=:sparse, ipopt=:gpu),
            )

            Test.@test CTSolvers.option_value(sol.modeler, :backend) === :sparse
            Test.@test CTSolvers.option_value(sol.solver,  :backend) === :gpu
        end

        Test.@testset "solve_descriptive - error on unknown option" begin
            ocp  = MockOCP2()
            init = CTModels.build_initial_guess(ocp, MockInit2())

            Test.@test_throws CTBase.IncorrectArgument OptimalControl.solve_descriptive(
                ocp, :collocation, :adnlp, :ipopt;
                initial_guess = init,
                display       = false,
                registry      = MOCK_REGISTRY,
                bad_option    = 99,
            )
        end

        Test.@testset "solve_descriptive - error on ambiguous option" begin
            ocp  = MockOCP2()
            init = CTModels.build_initial_guess(ocp, MockInit2())

            Test.@test_throws CTBase.IncorrectArgument OptimalControl.solve_descriptive(
                ocp, :collocation, :adnlp, :ipopt;
                initial_guess = init,
                display       = false,
                registry      = MOCK_REGISTRY,
                backend       = :sparse,
            )
        end

    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_descriptive_routing() = TestDescriptiveRouting.test_descriptive_routing()

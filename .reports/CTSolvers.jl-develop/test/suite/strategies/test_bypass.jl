module TestBypass

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Orchestration
import CTSolvers.Options

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Mock strategy for testing
# ============================================================================

abstract type BypassTestSolver <: Strategies.AbstractStrategy end

struct MockSolver <: BypassTestSolver
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{MockSolver}) = :mock_solver

Strategies.metadata(::Type{MockSolver}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 100,
        description = "Maximum iterations"
    ),
    Options.OptionDefinition(
        name = :tol,
        type = Float64,
        default = 1e-6,
        description = "Tolerance"
    )
)

function MockSolver(; mode::Symbol = :strict, kwargs...)
    options = Strategies.build_strategy_options(MockSolver; mode=mode, kwargs...)
    return MockSolver(options)
end

const BYPASS_REGISTRY = Strategies.create_registry(
    BypassTestSolver => (MockSolver,)
)

const BYPASS_FAMILIES = (solver = BypassTestSolver,)
const BYPASS_METHOD = (:mock_solver,)
const BYPASS_ACTION_DEFS = Options.OptionDefinition[]

# ============================================================================
# Test function
# ============================================================================

function test_bypass()
    Test.@testset "Bypass Mechanism" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - BypassValue type
        # ====================================================================

        Test.@testset "BypassValue construction" begin
            val = Strategies.bypass(42)
            Test.@test val isa Strategies.BypassValue
            Test.@test val.value == 42

            val_str = Strategies.bypass("hello")
            Test.@test val_str isa Strategies.BypassValue{String}
            Test.@test val_str.value == "hello"

            val_sym = Strategies.bypass(:sparse)
            Test.@test val_sym.value === :sparse
        end

        # ====================================================================
        # UNIT TESTS - Explicit construction with bypass(val)
        # ====================================================================

        Test.@testset "Explicit construction - bypass(val)" begin
            # Strict mode rejects unknown options
            Test.@test_throws Exceptions.IncorrectArgument MockSolver(unknown_opt=99)

            # bypass(val) accepted even in strict mode
            strat = MockSolver(unknown_opt=Strategies.bypass(99))
            Test.@test Strategies.has_option(strat, :unknown_opt)
            Test.@test Strategies.option_value(strat, :unknown_opt) == 99
            Test.@test Strategies.option_source(strat, :unknown_opt) === :user

            # Known options still validated normally
            strat2 = MockSolver(max_iter=500)
            Test.@test Strategies.option_value(strat2, :max_iter) == 500

            # Mixed: known + bypassed
            strat3 = MockSolver(max_iter=200, backend=Strategies.bypass(:sparse))
            Test.@test Strategies.option_value(strat3, :max_iter) == 200
            Test.@test Strategies.option_value(strat3, :backend) === :sparse

            # Multiple bypassed options
            strat4 = MockSolver(
                custom_a=Strategies.bypass(1),
                custom_b=Strategies.bypass("x")
            )
            Test.@test Strategies.option_value(strat4, :custom_a) == 1
            Test.@test Strategies.option_value(strat4, :custom_b) == "x"
        end

        # ====================================================================
        # UNIT TESTS - route_to with bypass(val)
        # ====================================================================

        Test.@testset "route_to with bypass(val) - routing" begin
            # Unknown option with bypass → routed as BypassValue, no error
            kwargs = (custom_opt = Strategies.route_to(mock_solver=Strategies.bypass(42)),)
            routed = Orchestration.route_all_options(
                BYPASS_METHOD, BYPASS_FAMILIES, BYPASS_ACTION_DEFS, kwargs, BYPASS_REGISTRY
            )

            Test.@test haskey(routed.strategies.solver, :custom_opt)
            bv = routed.strategies.solver[:custom_opt]
            Test.@test bv isa Strategies.BypassValue
            Test.@test bv.value == 42

            # Unknown option WITHOUT bypass → error
            kwargs_no_bypass = (custom_opt = Strategies.route_to(mock_solver=42),)
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                BYPASS_METHOD, BYPASS_FAMILIES, BYPASS_ACTION_DEFS, kwargs_no_bypass, BYPASS_REGISTRY
            )
        end

        Test.@testset "route_to with bypass(val) - end-to-end" begin
            # Route BypassValue, then build strategy: bypass accepted by constructor
            kwargs = (custom_opt = Strategies.route_to(mock_solver=Strategies.bypass(99)),)
            routed = Orchestration.route_all_options(
                BYPASS_METHOD, BYPASS_FAMILIES, BYPASS_ACTION_DEFS, kwargs, BYPASS_REGISTRY
            )

            # Build strategy with routed options (mode=:strict, bypass handles itself)
            strat = MockSolver(; routed.strategies.solver...)
            Test.@test Strategies.has_option(strat, :custom_opt)
            Test.@test Strategies.option_value(strat, :custom_opt) == 99

            # Known option routed normally (no bypass needed)
            kwargs_known = (max_iter = Strategies.route_to(mock_solver=500),)
            routed_known = Orchestration.route_all_options(
                BYPASS_METHOD, BYPASS_FAMILIES, BYPASS_ACTION_DEFS, kwargs_known, BYPASS_REGISTRY
            )
            strat_known = MockSolver(; routed_known.strategies.solver...)
            Test.@test Strategies.option_value(strat_known, :max_iter) == 500
        end

        # ====================================================================
        # UNIT TESTS - mode=:permissive still works independently
        # ====================================================================

        Test.@testset "mode=:permissive still works" begin
            redirect_stderr(devnull) do
                strat = MockSolver(unknown_opt=42; mode=:permissive)
                Test.@test Strategies.has_option(strat, :unknown_opt)
                Test.@test Strategies.option_value(strat, :unknown_opt) == 42
            end
        end

        # ====================================================================
        # UNIT TESTS - Bypass Validation Power
        # ====================================================================

        Test.@testset "Bypass Validation Power" begin
            # 1. Bypass type validation for known option
            # max_iter is Int, we pass String via bypass
            strat = MockSolver(max_iter=Strategies.bypass("not_an_int"))
            Test.@test Strategies.option_value(strat, :max_iter) == "not_an_int"
            Test.@test Strategies.option_source(strat, :max_iter) === :user

            # 2. Overwrite default with different type
            # tol is Float64 (default 1e-6), we pass Symbol via bypass
            strat2 = MockSolver(tol=Strategies.bypass(:flexible))
            Test.@test Strategies.option_value(strat2, :tol) === :flexible
            Test.@test Strategies.option_source(strat2, :tol) === :user
        end

    end
end

end # module

test_bypass() = TestBypass.test_bypass()

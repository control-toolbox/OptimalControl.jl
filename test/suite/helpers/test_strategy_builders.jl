# ============================================================================
# Strategy Builders Helpers Tests
# ============================================================================
# This file contains unit tests for the core strategy building helpers:
# `_build_partial_description`, `_complete_description`, and `_build_or_use_strategy`.
# It verifies the logic used to analyze provided components, resolve missing
# parts via the registry, and instantiate the required strategies.

module TestStrategyBuilders

import Test
import OptimalControl
import CTDirect
import CTSolvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# TOP-LEVEL MOCKS
# ====================================================================

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.StrategyOptions
end

struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end

struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

CTSolvers.id(::Type{MockDiscretizer}) = :mock_disc
CTSolvers.id(::Type{MockModeler}) = :mock_mod
CTSolvers.id(::Type{MockSolver}) = :mock_sol

function test_strategy_builders()
    Test.@testset "Strategy Builders Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # Create mock instances
        disc = MockDiscretizer(CTSolvers.StrategyOptions())
        mod = MockModeler(CTSolvers.StrategyOptions())
        sol = MockSolver(CTSolvers.StrategyOptions())

        # ================================================================
        # UNIT TESTS - _build_partial_description
        # ================================================================

        Test.@testset "All Components Provided" begin
            result = OptimalControl._build_partial_description(disc, mod, sol)
            Test.@test result == (:mock_disc, :mock_mod, :mock_sol)
            Test.@test length(result) == 3
        end

        Test.@testset "Only Discretizer" begin
            result = OptimalControl._build_partial_description(disc, nothing, nothing)
            Test.@test result == (:mock_disc,)
            Test.@test length(result) == 1
        end

        Test.@testset "Only Modeler" begin
            result = OptimalControl._build_partial_description(nothing, mod, nothing)
            Test.@test result == (:mock_mod,)
            Test.@test length(result) == 1
        end

        Test.@testset "Only Solver" begin
            result = OptimalControl._build_partial_description(nothing, nothing, sol)
            Test.@test result == (:mock_sol,)
            Test.@test length(result) == 1
        end

        Test.@testset "Discretizer and Modeler" begin
            result = OptimalControl._build_partial_description(disc, mod, nothing)
            Test.@test result == (:mock_disc, :mock_mod)
            Test.@test length(result) == 2
        end

        Test.@testset "Modeler and Solver" begin
            result = OptimalControl._build_partial_description(nothing, mod, sol)
            Test.@test result == (:mock_mod, :mock_sol)
            Test.@test length(result) == 2
        end

        Test.@testset "Discretizer and Solver" begin
            result = OptimalControl._build_partial_description(disc, nothing, sol)
            Test.@test result == (:mock_disc, :mock_sol)
            Test.@test length(result) == 2
        end

        Test.@testset "All Nothing" begin
            result = OptimalControl._build_partial_description(nothing, nothing, nothing)
            Test.@test result == ()
            Test.@test length(result) == 0
        end

        Test.@testset "Determinism" begin
            # Same inputs should always give same output
            result1 = OptimalControl._build_partial_description(disc, mod, sol)
            result2 = OptimalControl._build_partial_description(disc, mod, sol)
            Test.@test result1 === result2
        end

        Test.@testset "Type Stability" begin
            Test.@test_nowarn Test.@inferred OptimalControl._build_partial_description(disc, mod, sol)
            Test.@test_nowarn Test.@inferred OptimalControl._build_partial_description(nothing, nothing, nothing)
        end

        Test.@testset "No Allocations" begin
            # Pure function should not allocate (allow small platform differences)
            allocs = @allocated OptimalControl._build_partial_description(disc, mod, sol)
            Test.@test allocs <= 32  # Allow small platform-dependent allocations
        end

        # ================================================================
        # UNIT TESTS - _complete_description
        # ================================================================

        Test.@testset "Complete Description - Empty" begin
            result = OptimalControl._complete_description(())
            Test.@test result isa Tuple{Symbol, Symbol, Symbol}
            Test.@test length(result) == 3
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Partial" begin
            result = OptimalControl._complete_description((:collocation,))
            Test.@test result == (:collocation, :adnlp, :ipopt)
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Two Symbols" begin
            result = OptimalControl._complete_description((:collocation, :exa))
            Test.@test result == (:collocation, :exa, :ipopt)
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Already Complete" begin
            result = OptimalControl._complete_description((:collocation, :adnlp, :ipopt))
            Test.@test result == (:collocation, :adnlp, :ipopt)
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Different Combinations" begin
            # Test various partial combinations
            combos = [
                (:collocation,), (:collocation, :adnlp), (:collocation, :exa),
                (:collocation, :adnlp, :ipopt), (:collocation, :exa, :madnlp)
            ]
            for combo in combos
                result = OptimalControl._complete_description(combo)
                Test.@test result isa Tuple{Symbol, Symbol, Symbol}
                Test.@test result in OptimalControl.methods()
                # Check that the provided symbols are preserved
                for (i, sym) in enumerate(combo)
                    Test.@test result[i] == sym
                end
            end
        end

        Test.@testset "Complete Description - Type Stability" begin
            Test.@test_nowarn Test.@inferred OptimalControl._complete_description(())
            Test.@test_nowarn Test.@inferred OptimalControl._complete_description((:collocation,))
            Test.@test_nowarn Test.@inferred OptimalControl._complete_description((:collocation, :adnlp, :ipopt))
        end

        # ================================================================
        # UNIT TESTS - _build_or_use_strategy
        # ================================================================

        # Create registry for _build_or_use_strategy tests
        registry = OptimalControl.get_strategy_registry()

        Test.@testset "Build or Use Strategy - Provided Path" begin
            # Test discretizer
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), disc, CTDirect.AbstractDiscretizer, registry
            )
            Test.@test result === disc
            Test.@test result isa MockDiscretizer
            
            # Test modeler
            mod = MockModeler(CTSolvers.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), mod, CTSolvers.AbstractNLPModeler, registry
            )
            Test.@test result === mod
            Test.@test result isa MockModeler
            
            # Test solver
            sol = MockSolver(CTSolvers.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), sol, CTSolvers.AbstractNLPSolver, registry
            )
            Test.@test result === sol
            Test.@test result isa MockSolver
        end

        Test.@testset "Build or Use Strategy - Type Stability" begin
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            Test.@test_nowarn Test.@inferred OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), disc, CTDirect.AbstractDiscretizer, registry
            )
        end
    end
end

end # module

test_strategy_builders() = TestStrategyBuilders.test_strategy_builders()

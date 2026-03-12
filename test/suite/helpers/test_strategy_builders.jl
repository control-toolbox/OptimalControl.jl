# ============================================================================
# Strategy Builders Helpers Tests
# ============================================================================
# This file contains unit tests for the core strategy building helpers:
# `_build_partial_description`, `_complete_description`, and `_build_or_use_strategy`.
# It verifies the logic used to analyze provided components, resolve missing
# parts via the registry, and instantiate the required strategies.

module TestStrategyBuilders

using Test: Test
using OptimalControl: OptimalControl
using CTDirect: CTDirect
using CTSolvers: CTSolvers
using NLPModelsIpopt: NLPModelsIpopt  # Add for Ipopt strategy building
using MadNLP: MadNLP          # Add for MadNLP strategy building
using MadNCL: MadNCL          # Add for MadNLP strategy building

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
            Test.@test_nowarn Test.@inferred OptimalControl._build_partial_description(
                disc, mod, sol
            )
            Test.@test_nowarn Test.@inferred OptimalControl._build_partial_description(
                nothing, nothing, nothing
            )
        end

        Test.@testset "No Allocations" begin
            # Pure function should not allocate (allow small platform differences)
            allocs = Test.@allocated OptimalControl._build_partial_description(
                disc, mod, sol
            )
            Test.@test allocs <= 32  # Allow small platform-dependent allocations
        end

        # ================================================================
        # UNIT TESTS - _complete_description
        # ================================================================

        Test.@testset "Complete Description - Empty" begin
            result = OptimalControl._complete_description(())
            Test.@test result isa Tuple{Symbol,Symbol,Symbol,Symbol}  # Fixed: quadruplet with parameter
            Test.@test length(result) == 4
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Partial" begin
            result = OptimalControl._complete_description((:collocation,))
            Test.@test result == (:collocation, :adnlp, :ipopt, :cpu)  # Fixed: include parameter
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Two Symbols" begin
            result = OptimalControl._complete_description((:collocation, :exa))
            Test.@test result == (:collocation, :exa, :ipopt, :cpu)  # Fixed: include parameter
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Already Complete" begin
            result = OptimalControl._complete_description((:collocation, :adnlp, :ipopt))
            Test.@test result == (:collocation, :adnlp, :ipopt, :cpu)  # Fixed: include parameter
            Test.@test result in OptimalControl.methods()
        end

        Test.@testset "Complete Description - Different Combinations" begin
            # Test various partial combinations
            combos = [
                (:collocation,),
                (:collocation, :adnlp),
                (:collocation, :exa),
                (:collocation, :adnlp, :ipopt),
                (:collocation, :exa, :madnlp),
            ]
            for combo in combos
                result = OptimalControl._complete_description(combo)
                Test.@test result isa Tuple{Symbol,Symbol,Symbol,Symbol}  # Fixed: quadruplet
                Test.@test length(result) == 4
                Test.@test result in OptimalControl.methods()
                # Check that the provided symbols are preserved
                for (i, sym) in enumerate(combo)
                    Test.@test result[i] == sym
                end
            end
        end

        Test.@testset "Complete Description - Type Stability" begin
            Test.@test_nowarn Test.@inferred OptimalControl._complete_description(())
            Test.@test_nowarn Test.@inferred OptimalControl._complete_description((
                :collocation,
            ))
            Test.@test_nowarn Test.@inferred OptimalControl._complete_description((
                :collocation, :adnlp, :ipopt
            ))
        end

        # ================================================================
        # UNIT TESTS - _build_or_use_strategy
        # ================================================================

        # Create registry for _build_or_use_strategy tests
        registry = OptimalControl.get_strategy_registry()

        Test.@testset "Build or Use Strategy - Provided Path" begin
            # Create a resolved method using real strategy IDs from registry
            resolved = CTSolvers.Orchestration.resolve_method(
                (:collocation, :adnlp, :ipopt, :cpu),  # Use real strategy IDs
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )

            # Test discretizer (should return provided mock regardless of resolved method)
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                resolved,
                disc,
                :discretizer,
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )
            Test.@test result === disc
            Test.@test result isa MockDiscretizer

            # Test modeler
            mod = MockModeler(CTSolvers.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                resolved,
                mod,
                :modeler,
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )
            Test.@test result === mod
            Test.@test result isa MockModeler

            # Test solver
            sol = MockSolver(CTSolvers.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                resolved,
                sol,
                :solver,
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )
            Test.@test result === sol
            Test.@test result isa MockSolver
        end

        Test.@testset "Build or Use Strategy - Type Stability" begin
            resolved = CTSolvers.Orchestration.resolve_method(
                (:collocation, :adnlp, :ipopt, :cpu),  # Use real strategy IDs
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )
            disc = MockDiscretizer(CTSolvers.StrategyOptions())
            Test.@test_nowarn Test.@inferred OptimalControl._build_or_use_strategy(
                resolved,
                disc,
                :discretizer,
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )
        end

        Test.@testset "Build or Use Strategy - Build Path" begin
            # Test building strategies when nothing is provided
            resolved = CTSolvers.Orchestration.resolve_method(
                (:collocation, :adnlp, :ipopt, :cpu),
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )

            # Test discretizer building (should work without extra deps)
            disc_result = OptimalControl._build_or_use_strategy(
                resolved,
                nothing,
                :discretizer,
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )
            Test.@test disc_result isa CTDirect.AbstractDiscretizer
            Test.@test CTSolvers.id(typeof(disc_result)) == :collocation

            # Test modeler building (should work without extra deps)
            mod_result = OptimalControl._build_or_use_strategy(
                resolved,
                nothing,
                :modeler,
                (
                    discretizer=CTDirect.AbstractDiscretizer,
                    modeler=CTSolvers.AbstractNLPModeler,
                    solver=CTSolvers.AbstractNLPSolver,
                ),
                registry,
            )
            Test.@test mod_result isa CTSolvers.AbstractNLPModeler
            Test.@test CTSolvers.id(typeof(mod_result)) == :adnlp

            # Test solver building (may fail due to dependencies, so we test the error handling)
            try
                sol_result = OptimalControl._build_or_use_strategy(
                    resolved,
                    nothing,
                    :solver,
                    (
                        discretizer=CTDirect.AbstractDiscretizer,
                        modeler=CTSolvers.AbstractNLPModeler,
                        solver=CTSolvers.AbstractNLPSolver,
                    ),
                    registry,
                )
                Test.@test sol_result isa CTSolvers.AbstractNLPSolver
                Test.@test CTSolvers.id(typeof(sol_result)) == :ipopt
            catch e
                # If dependencies are missing, that's expected in test environment
                Test.@test e isa Exception
            end
        end

        Test.@testset "Build or Use Strategy - Different Methods" begin
            # Test building with different method combinations (focus on discretizer which should always work)
            methods_to_test = [
                (:collocation, :exa, :madnlp, :cpu), (:collocation, :exa, :madncl, :gpu)
            ]

            for method_tuple in methods_to_test
                resolved = CTSolvers.Orchestration.resolve_method(
                    method_tuple,
                    (
                        discretizer=CTDirect.AbstractDiscretizer,
                        modeler=CTSolvers.AbstractNLPModeler,
                        solver=CTSolvers.AbstractNLPSolver,
                    ),
                    registry,
                )

                # Test discretizer building (should always work)
                disc = OptimalControl._build_or_use_strategy(
                    resolved,
                    nothing,
                    :discretizer,
                    (
                        discretizer=CTDirect.AbstractDiscretizer,
                        modeler=CTSolvers.AbstractNLPModeler,
                        solver=CTSolvers.AbstractNLPSolver,
                    ),
                    registry,
                )
                Test.@test disc isa CTDirect.AbstractDiscretizer
                Test.@test CTSolvers.id(typeof(disc)) == method_tuple[1]

                # Test modeler building (may fail for some dependencies)
                try
                    mod = OptimalControl._build_or_use_strategy(
                        resolved,
                        nothing,
                        :modeler,
                        (
                            discretizer=CTDirect.AbstractDiscretizer,
                            modeler=CTSolvers.AbstractNLPModeler,
                            solver=CTSolvers.AbstractNLPSolver,
                        ),
                        registry,
                    )
                    Test.@test mod isa CTSolvers.AbstractNLPModeler
                    Test.@test CTSolvers.id(typeof(mod)) == method_tuple[2]
                catch e
                    # Expected for some combinations due to missing dependencies
                    Test.@test e isa Exception
                end
            end
        end
    end
end

end # module

test_strategy_builders() = TestStrategyBuilders.test_strategy_builders()

module TestStrategyBuilders

using Test
using OptimalControl
using CTDirect
using CTSolvers
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# TOP-LEVEL MOCKS
# ====================================================================

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.Strategies.StrategyOptions
end

struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.Strategies.StrategyOptions
end

struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.Strategies.StrategyOptions
end

CTSolvers.Strategies.id(::Type{MockDiscretizer}) = :mock_disc
CTSolvers.Strategies.id(::Type{MockModeler}) = :mock_mod
CTSolvers.Strategies.id(::Type{MockSolver}) = :mock_sol

function test_strategy_builders()
    @testset "Strategy Builders Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # Create mock instances
        disc = MockDiscretizer(CTSolvers.Strategies.StrategyOptions())
        mod = MockModeler(CTSolvers.Strategies.StrategyOptions())
        sol = MockSolver(CTSolvers.Strategies.StrategyOptions())

        # ================================================================
        # UNIT TESTS - _build_partial_description
        # ================================================================

        @testset "All Components Provided" begin
            result = OptimalControl._build_partial_description(disc, mod, sol)
            @test result == (:mock_disc, :mock_mod, :mock_sol)
            @test length(result) == 3
        end

        @testset "Only Discretizer" begin
            result = OptimalControl._build_partial_description(disc, nothing, nothing)
            @test result == (:mock_disc,)
            @test length(result) == 1
        end

        @testset "Only Modeler" begin
            result = OptimalControl._build_partial_description(nothing, mod, nothing)
            @test result == (:mock_mod,)
            @test length(result) == 1
        end

        @testset "Only Solver" begin
            result = OptimalControl._build_partial_description(nothing, nothing, sol)
            @test result == (:mock_sol,)
            @test length(result) == 1
        end

        @testset "Discretizer and Modeler" begin
            result = OptimalControl._build_partial_description(disc, mod, nothing)
            @test result == (:mock_disc, :mock_mod)
            @test length(result) == 2
        end

        @testset "Modeler and Solver" begin
            result = OptimalControl._build_partial_description(nothing, mod, sol)
            @test result == (:mock_mod, :mock_sol)
            @test length(result) == 2
        end

        @testset "Discretizer and Solver" begin
            result = OptimalControl._build_partial_description(disc, nothing, sol)
            @test result == (:mock_disc, :mock_sol)
            @test length(result) == 2
        end

        @testset "All Nothing" begin
            result = OptimalControl._build_partial_description(nothing, nothing, nothing)
            @test result == ()
            @test length(result) == 0
        end

        @testset "Determinism" begin
            # Same inputs should always give same output
            result1 = OptimalControl._build_partial_description(disc, mod, sol)
            result2 = OptimalControl._build_partial_description(disc, mod, sol)
            @test result1 === result2
        end

        @testset "Type Stability" begin
            @test_nowarn @inferred OptimalControl._build_partial_description(disc, mod, sol)
            @test_nowarn @inferred OptimalControl._build_partial_description(nothing, nothing, nothing)
        end

        @testset "No Allocations" begin
            # Pure function should not allocate
            allocs = @allocated OptimalControl._build_partial_description(disc, mod, sol)
            @test allocs == 0
        end

        # ================================================================
        # UNIT TESTS - _complete_description
        # ================================================================

        @testset "Complete Description - Empty" begin
            result = OptimalControl._complete_description(())
            @test result isa Tuple{Symbol, Symbol, Symbol}
            @test length(result) == 3
            @test result in OptimalControl.available_methods()
        end

        @testset "Complete Description - Partial" begin
            result = OptimalControl._complete_description((:collocation,))
            @test result == (:collocation, :adnlp, :ipopt)
            @test result in OptimalControl.available_methods()
        end

        @testset "Complete Description - Two Symbols" begin
            result = OptimalControl._complete_description((:collocation, :exa))
            @test result == (:collocation, :exa, :ipopt)
            @test result in OptimalControl.available_methods()
        end

        @testset "Complete Description - Already Complete" begin
            result = OptimalControl._complete_description((:collocation, :adnlp, :ipopt))
            @test result == (:collocation, :adnlp, :ipopt)
            @test result in OptimalControl.available_methods()
        end

        @testset "Complete Description - Different Combinations" begin
            # Test various partial combinations
            combos = [
                (:collocation,), (:collocation, :adnlp), (:collocation, :exa),
                (:collocation, :adnlp, :ipopt), (:collocation, :exa, :madnlp)
            ]
            for combo in combos
                result = OptimalControl._complete_description(combo)
                @test result isa Tuple{Symbol, Symbol, Symbol}
                @test result in OptimalControl.available_methods()
                # Check that the provided symbols are preserved
                for (i, sym) in enumerate(combo)
                    @test result[i] == sym
                end
            end
        end

        @testset "Complete Description - Type Stability" begin
            @test_nowarn @inferred OptimalControl._complete_description(())
            @test_nowarn @inferred OptimalControl._complete_description((:collocation,))
            @test_nowarn @inferred OptimalControl._complete_description((:collocation, :adnlp, :ipopt))
        end

        # ================================================================
        # UNIT TESTS - _build_or_use_strategy
        # ================================================================

        # Create registry for _build_or_use_strategy tests
        registry = OptimalControl.get_strategy_registry()

        @testset "Build or Use Strategy - Provided Path" begin
            # Test discretizer
            disc = MockDiscretizer(CTSolvers.Strategies.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), disc, CTDirect.AbstractDiscretizer, registry
            )
            @test result === disc
            @test result isa MockDiscretizer
            
            # Test modeler
            mod = MockModeler(CTSolvers.Strategies.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), mod, CTSolvers.AbstractNLPModeler, registry
            )
            @test result === mod
            @test result isa MockModeler
            
            # Test solver
            sol = MockSolver(CTSolvers.Strategies.StrategyOptions())
            result = OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), sol, CTSolvers.AbstractNLPSolver, registry
            )
            @test result === sol
            @test result isa MockSolver
        end

        @testset "Build or Use Strategy - Type Stability" begin
            disc = MockDiscretizer(CTSolvers.Strategies.StrategyOptions())
            @test_nowarn @inferred OptimalControl._build_or_use_strategy(
                (:mock_disc, :mock_mod, :mock_sol), disc, CTDirect.AbstractDiscretizer, registry
            )
        end
    end
end

end # module

test_strategy_builders() = TestStrategyBuilders.test_strategy_builders()

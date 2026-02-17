module TestStrategyBuilders

using Test
using OptimalControl
using CTDirect
using CTSolvers
using Main.TestOptions: VERBOSE, SHOWTIMING

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
    end
end

end # module

test_strategy_builders() = TestStrategyBuilders.test_strategy_builders()

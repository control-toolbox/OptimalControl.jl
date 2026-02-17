module TestRegistry

using Test
import OptimalControl
import CTSolvers
import CTDirect
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_registry()
    @testset "Strategy Registry Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS
        # ====================================================================

        @testset "Registry Creation" begin
            registry = OptimalControl.get_strategy_registry()
            @test registry isa CTSolvers.Strategies.StrategyRegistry
        end

        @testset "Discretizer Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.Strategies.strategy_ids(CTDirect.AbstractDiscretizer, registry)
            @test :collocation in ids
            @test length(ids) >= 1
        end

        @testset "Modeler Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
            @test :adnlp in ids
            @test :exa in ids
            @test length(ids) == 2
        end

        @testset "Solver Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPSolver, registry)
            @test :ipopt in ids
            @test :madnlp in ids
            @test :knitro in ids
            @test length(ids) == 3
        end

        @testset "Determinism" begin
            r1 = OptimalControl.get_strategy_registry()
            r2 = OptimalControl.get_strategy_registry()
            ids1 = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPSolver, r1)
            ids2 = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPSolver, r2)
            @test ids1 == ids2
        end
    end
end

end # module

test_registry() = TestRegistry.test_registry()

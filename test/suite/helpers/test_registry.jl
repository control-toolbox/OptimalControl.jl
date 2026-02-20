# ============================================================================
# Strategy Registry Setup Tests
# ============================================================================
# This file tests the `get_strategy_registry` function. It verifies that
# the global strategy registry is correctly populated with all available
# abstract families and their concrete implementations provided by the solver
# ecosystem (CTDirect, CTSolvers).

module TestRegistry

import Test
import OptimalControl
import CTSolvers
import CTDirect

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_registry()
    Test.@testset "Strategy Registry Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS
        # ====================================================================

        Test.@testset "Registry Creation" begin
            registry = OptimalControl.get_strategy_registry()
            Test.@test registry isa CTSolvers.StrategyRegistry
        end

        Test.@testset "Discretizer Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry)
            Test.@test :collocation in ids
            Test.@test length(ids) >= 1
        end

        Test.@testset "Modeler Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
            Test.@test :adnlp in ids
            Test.@test :exa in ids
            Test.@test length(ids) == 2
        end

        Test.@testset "Solver Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)
            Test.@test :ipopt in ids
            Test.@test :madnlp in ids
            Test.@test :madncl in ids
            Test.@test :knitro in ids
            Test.@test length(ids) == 4
        end

        Test.@testset "Determinism" begin
            r1 = OptimalControl.get_strategy_registry()
            r2 = OptimalControl.get_strategy_registry()
            ids1 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, r1)
            ids2 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, r2)
            Test.@test ids1 == ids2
        end
    end
end

end # module

test_registry() = TestRegistry.test_registry()

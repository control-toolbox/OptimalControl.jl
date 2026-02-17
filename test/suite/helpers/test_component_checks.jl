module TestComponentChecks

import Test
import OptimalControl
import CTDirect
import CTSolvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# TOP-LEVEL: Mock strategies for testing (no side effects)
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

function test_component_checks()
    Test.@testset "Component Checks Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # Create mock instances
        disc = MockDiscretizer(CTSolvers.StrategyOptions())
        mod = MockModeler(CTSolvers.StrategyOptions())
        sol = MockSolver(CTSolvers.StrategyOptions())

        # ================================================================
        # UNIT TESTS - _has_complete_components
        # ================================================================

        Test.@testset "All Components Provided" begin
            Test.@test OptimalControl._has_complete_components(disc, mod, sol) == true
        end

        Test.@testset "Missing Discretizer" begin
            Test.@test OptimalControl._has_complete_components(nothing, mod, sol) == false
        end

        Test.@testset "Missing Modeler" begin
            Test.@test OptimalControl._has_complete_components(disc, nothing, sol) == false
        end

        Test.@testset "Missing Solver" begin
            Test.@test OptimalControl._has_complete_components(disc, mod, nothing) == false
        end

        Test.@testset "All Missing" begin
            Test.@test OptimalControl._has_complete_components(nothing, nothing, nothing) == false
        end

        Test.@testset "Two Missing" begin
            Test.@test OptimalControl._has_complete_components(disc, nothing, nothing) == false
            Test.@test OptimalControl._has_complete_components(nothing, mod, nothing) == false
            Test.@test OptimalControl._has_complete_components(nothing, nothing, sol) == false
        end

        Test.@testset "Determinism" begin
            result1 = OptimalControl._has_complete_components(disc, mod, sol)
            result2 = OptimalControl._has_complete_components(disc, mod, sol)
            Test.@test result1 === result2
        end

        Test.@testset "Type Stability" begin
            Test.@test_nowarn Test.@inferred OptimalControl._has_complete_components(disc, mod, sol)
            Test.@test_nowarn Test.@inferred OptimalControl._has_complete_components(nothing, mod, sol)
        end

        Test.@testset "No Allocations" begin
            allocs = @allocated OptimalControl._has_complete_components(disc, mod, sol)
            Test.@test allocs == 0
        end
    end
end

end # module

test_component_checks() = TestComponentChecks.test_component_checks()

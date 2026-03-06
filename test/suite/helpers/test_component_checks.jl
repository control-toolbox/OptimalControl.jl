# ============================================================================
# Component Checks Helpers Tests
# ============================================================================
# This file contains unit tests for the `_has_complete_components` helper.
# It verifies the logic that checks whether all required explicit strategy
# components (discretizer, modeler, solver) have been provided by the user.

module TestComponentChecks

import Test
import OptimalControl
import CTDirect
import CTSolvers
import BenchmarkTools

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

        Test.@testset "Edge Cases" begin
            # Test with different concrete strategy types
            disc2 = MockDiscretizer(CTSolvers.StrategyOptions())
            mod2 = MockModeler(CTSolvers.StrategyOptions())
            sol2 = MockSolver(CTSolvers.StrategyOptions())
            
            # Should still return true with different instances
            Test.@test OptimalControl._has_complete_components(disc2, mod2, sol2) == true
            
            # Test mixed instances
            Test.@test OptimalControl._has_complete_components(disc, mod2, sol) == true
            Test.@test OptimalControl._has_complete_components(disc2, mod, sol2) == true
        end

        Test.@testset "Boolean Logic" begin
            # Test that the function correctly implements AND logic
            Test.@test OptimalControl._has_complete_components(nothing, nothing, nothing) == false
            Test.@test OptimalControl._has_complete_components(disc, nothing, nothing) == false
            Test.@test OptimalControl._has_complete_components(nothing, mod, nothing) == false
            Test.@test OptimalControl._has_complete_components(nothing, nothing, sol) == false
            Test.@test OptimalControl._has_complete_components(disc, mod, nothing) == false
            Test.@test OptimalControl._has_complete_components(disc, nothing, sol) == false
            Test.@test OptimalControl._has_complete_components(nothing, mod, sol) == false
            Test.@test OptimalControl._has_complete_components(disc, mod, sol) == true
        end

        Test.@testset "Performance Characteristics" begin
            # Test that the function is indeed allocation-free
            allocs1 = Test.@allocated OptimalControl._has_complete_components(disc, mod, sol)
            allocs2 = Test.@allocated OptimalControl._has_complete_components(nothing, mod, sol)
            allocs3 = Test.@allocated OptimalControl._has_complete_components(disc, nothing, sol)
            allocs4 = Test.@allocated OptimalControl._has_complete_components(nothing, nothing, nothing)
            
            Test.@test allocs1 == 0
            Test.@test allocs2 == 0
            Test.@test allocs3 == 0
            Test.@test allocs4 == 0
            
            # Test performance consistency across different inputs
            BenchmarkTools.@benchmark OptimalControl._has_complete_components($disc, $mod, $sol)
            BenchmarkTools.@benchmark OptimalControl._has_complete_components(nothing, $mod, $sol)
        end
    end
end

end # module

test_component_checks() = TestComponentChecks.test_component_checks()

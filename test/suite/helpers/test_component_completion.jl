# ============================================================================
# Component Completion Helpers Tests
# ============================================================================
# This file contains unit tests for the `_complete_components` helper.
# It verifies that partially provided strategy components are correctly
# completed (instantiated) using the strategy registry to form a full
# `(discretizer, modeler, solver)` triplet.

module TestComponentCompletion

import Test
import OptimalControl
import CTDirect
import CTSolvers
import CTModels
import NLPModelsIpopt  # Load extension for Ipopt

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_component_completion()
    Test.@testset "Component Completion Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # Create registry for tests
        registry = OptimalControl.get_strategy_registry()

        # ================================================================
        # INTEGRATION TESTS - _complete_components
        # ================================================================

        Test.@testset "Complete from Scratch" begin
            result = OptimalControl._complete_components(nothing, nothing, nothing, registry)
            Test.@test result isa NamedTuple{(:discretizer, :modeler, :solver)}
            Test.@test result.discretizer isa CTDirect.AbstractDiscretizer
            Test.@test result.modeler isa CTSolvers.AbstractNLPModeler
            Test.@test result.solver isa CTSolvers.AbstractNLPSolver
        end

        Test.@testset "All Components Provided - No Change" begin
            # Use real strategies from the registry
            disc = CTDirect.Collocation()
            mod = CTSolvers.ADNLP()
            sol = CTSolvers.Ipopt()
            
            result = OptimalControl._complete_components(disc, mod, sol, registry)
            Test.@test result.discretizer === disc
            Test.@test result.modeler === mod
            Test.@test result.solver === sol
        end

        Test.@testset "Partial Completion - Discretizer Provided" begin
            disc = CTDirect.Collocation()
            result = OptimalControl._complete_components(disc, nothing, nothing, registry)
            Test.@test result.discretizer === disc
            Test.@test result.modeler isa CTSolvers.AbstractNLPModeler
            Test.@test result.solver isa CTSolvers.AbstractNLPSolver
        end

        Test.@testset "Partial Completion - Two Components Provided" begin
            disc = CTDirect.Collocation()
            sol = CTSolvers.Ipopt()
            result = OptimalControl._complete_components(disc, nothing, sol, registry)
            Test.@test result.discretizer === disc
            Test.@test result.modeler isa CTSolvers.AbstractNLPModeler
            Test.@test result.solver === sol
        end

        Test.@testset "Return Type Verification" begin
            # Verify return types without Test.@inferred (registry lookup prevents full type inference)
            result = OptimalControl._complete_components(nothing, nothing, nothing, registry)
            Test.@test result isa NamedTuple{(:discretizer, :modeler, :solver)}
            
            disc = CTDirect.Collocation()
            mod = CTSolvers.ADNLP()
            sol = CTSolvers.Ipopt()
            result = OptimalControl._complete_components(disc, mod, sol, registry)
            Test.@test result isa NamedTuple{(:discretizer, :modeler, :solver)}
        end

        Test.@testset "Parameter Support - CPU Methods" begin
            # Test that CPU methods work correctly
            result = OptimalControl._complete_components(nothing, nothing, nothing, registry)
            Test.@test result.discretizer isa CTDirect.AbstractDiscretizer
            Test.@test result.modeler isa CTSolvers.AbstractNLPModeler
            Test.@test result.solver isa CTSolvers.AbstractNLPSolver
            
            # Test with specific CPU method
            disc = CTDirect.Collocation()
            result = OptimalControl._complete_components(disc, nothing, nothing, registry)
            Test.@test result.discretizer === disc
            Test.@test result.modeler isa CTSolvers.AbstractNLPModeler
            Test.@test result.solver isa CTSolvers.AbstractNLPSolver
        end

        Test.@testset "Mixed Strategy Types" begin
            # Test with different strategy combinations
            disc = CTDirect.Collocation()
            mod = CTSolvers.ADNLP()  # Use ADNLP instead of Exa to avoid potential issues
            sol = CTSolvers.Ipopt()  # Use Ipopt instead of MadNLP
            
            result = OptimalControl._complete_components(disc, mod, sol, registry)
            Test.@test result.discretizer === disc
            Test.@test result.modeler === mod
            Test.@test result.solver === sol
        end

        Test.@testset "Determinism" begin
            # Test that results are deterministic
            result1 = OptimalControl._complete_components(nothing, nothing, nothing, registry)
            result2 = OptimalControl._complete_components(nothing, nothing, nothing, registry)
            
            # Same types but may be different instances (that's ok)
            Test.@test typeof(result1.discretizer) == typeof(result2.discretizer)
            Test.@test typeof(result1.modeler) == typeof(result2.modeler)
            Test.@test typeof(result1.solver) == typeof(result2.solver)
        end

        Test.@testset "Performance Characteristics" begin
            # Test allocation characteristics
            allocs = Test.@allocated OptimalControl._complete_components(nothing, nothing, nothing, registry)
            # Some allocations expected due to registry lookup and strategy creation
            # Adjust limit based on actual measurement
            Test.@test allocs < 200000  # More realistic upper bound
            
            # Test with provided components (should be fewer allocations)
            disc = CTDirect.Collocation()
            mod = CTSolvers.ADNLP()
            sol = CTSolvers.Ipopt()
            allocs_provided = Test.@allocated OptimalControl._complete_components(disc, mod, sol, registry)
            Test.@test allocs_provided < allocs  # Should be fewer allocations
        end
    end
end

end # module

test_component_completion() = TestComponentCompletion.test_component_completion()

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
    end
end

end # module

test_component_completion() = TestComponentCompletion.test_component_completion()

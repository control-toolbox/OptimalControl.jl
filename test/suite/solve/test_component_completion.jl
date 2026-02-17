module TestComponentCompletion

using Test
using OptimalControl
using CTDirect
using CTSolvers
using CTModels
using NLPModelsIpopt  # Load extension for Ipopt
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_component_completion()
    @testset "Component Completion Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # Create registry for tests
        registry = OptimalControl.get_strategy_registry()

        # ================================================================
        # INTEGRATION TESTS - _complete_components
        # ================================================================

        @testset "Complete from Scratch" begin
            result = OptimalControl._complete_components(nothing, nothing, nothing, registry)
            @test result isa NamedTuple{(:discretizer, :modeler, :solver)}
            @test result.discretizer isa CTDirect.AbstractDiscretizer
            @test result.modeler isa CTSolvers.AbstractNLPModeler
            @test result.solver isa CTSolvers.AbstractNLPSolver
        end

        @testset "All Components Provided - No Change" begin
            # Use real strategies from the registry
            disc = CTDirect.Collocation()
            mod = CTSolvers.Modelers.ADNLP()
            sol = CTSolvers.Solvers.Ipopt()
            
            result = OptimalControl._complete_components(disc, mod, sol, registry)
            @test result.discretizer === disc
            @test result.modeler === mod
            @test result.solver === sol
        end

        @testset "Partial Completion - Discretizer Provided" begin
            disc = CTDirect.Collocation()
            result = OptimalControl._complete_components(disc, nothing, nothing, registry)
            @test result.discretizer === disc
            @test result.modeler isa CTSolvers.AbstractNLPModeler
            @test result.solver isa CTSolvers.AbstractNLPSolver
        end

        @testset "Partial Completion - Two Components Provided" begin
            disc = CTDirect.Collocation()
            sol = CTSolvers.Solvers.Ipopt()
            result = OptimalControl._complete_components(disc, nothing, sol, registry)
            @test result.discretizer === disc
            @test result.modeler isa CTSolvers.AbstractNLPModeler
            @test result.solver === sol
        end

        @testset "Return Type Verification" begin
            # Verify return types without @inferred (registry lookup prevents full type inference)
            result = OptimalControl._complete_components(nothing, nothing, nothing, registry)
            @test result isa NamedTuple{(:discretizer, :modeler, :solver)}
            
            disc = CTDirect.Collocation()
            mod = CTSolvers.Modelers.ADNLP()
            sol = CTSolvers.Solvers.Ipopt()
            result = OptimalControl._complete_components(disc, mod, sol, registry)
            @test result isa NamedTuple{(:discretizer, :modeler, :solver)}
        end
    end
end

end # module

test_component_completion() = TestComponentCompletion.test_component_completion()

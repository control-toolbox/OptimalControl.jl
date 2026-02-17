module TestComponentChecks

using Test
import OptimalControl
import CTDirect
import CTSolvers
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# TOP-LEVEL: Mock strategies for testing (no side effects)
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

function test_component_checks()
    @testset "Component Checks Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # Create mock instances
        disc = MockDiscretizer(CTSolvers.Strategies.StrategyOptions())
        mod = MockModeler(CTSolvers.Strategies.StrategyOptions())
        sol = MockSolver(CTSolvers.Strategies.StrategyOptions())

        # ================================================================
        # UNIT TESTS - _has_complete_components
        # ================================================================

        @testset "All Components Provided" begin
            @test OptimalControl._has_complete_components(disc, mod, sol) == true
        end

        @testset "Missing Discretizer" begin
            @test OptimalControl._has_complete_components(nothing, mod, sol) == false
        end

        @testset "Missing Modeler" begin
            @test OptimalControl._has_complete_components(disc, nothing, sol) == false
        end

        @testset "Missing Solver" begin
            @test OptimalControl._has_complete_components(disc, mod, nothing) == false
        end

        @testset "All Missing" begin
            @test OptimalControl._has_complete_components(nothing, nothing, nothing) == false
        end

        @testset "Two Missing" begin
            @test OptimalControl._has_complete_components(disc, nothing, nothing) == false
            @test OptimalControl._has_complete_components(nothing, mod, nothing) == false
            @test OptimalControl._has_complete_components(nothing, nothing, sol) == false
        end

        @testset "Determinism" begin
            result1 = OptimalControl._has_complete_components(disc, mod, sol)
            result2 = OptimalControl._has_complete_components(disc, mod, sol)
            @test result1 === result2
        end

        @testset "Type Stability" begin
            @test_nowarn @inferred OptimalControl._has_complete_components(disc, mod, sol)
            @test_nowarn @inferred OptimalControl._has_complete_components(nothing, mod, sol)
        end

        @testset "No Allocations" begin
            allocs = @allocated OptimalControl._has_complete_components(disc, mod, sol)
            @test allocs == 0
        end
    end
end

end # module

test_component_checks() = TestComponentChecks.test_component_checks()

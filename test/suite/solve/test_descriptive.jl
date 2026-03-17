# ============================================================================
# Descriptive Mode Tests (Layer 2)
# ============================================================================
# This file tests the `solve_descriptive` function. It verifies that when the user
# provides a symbolic description (e.g., `:collocation, :adnlp, :ipopt`), the
# components are correctly instantiated via the strategy registry before delegating
# to the canonical Layer 3 solve.

module TestDescriptive

using Test: Test
using OptimalControl: OptimalControl
using CTModels: CTModels
using CTDirect: CTDirect
using CTSolvers: CTSolvers
using CTBase: CTBase
using CommonSolve: CommonSolve

# Load solver extensions (import only to trigger extensions, avoid name conflicts)
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP
using MadNCL: MadNCL
using UnoSolver: UnoSolver
using CUDA: CUDA

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_descriptive()
    Test.@testset "solve_descriptive (contract and integration tests)" verbose=VERBOSE showtiming=SHOWTIMING begin
        registry = OptimalControl.get_strategy_registry()

        # ====================================================================
        # CONTRACT TESTS - Basic functionality
        # ====================================================================

        Test.@testset "Complete symbolic description" begin
            ocp = TestProblems.Beam().ocp
            init = OptimalControl.build_initial_guess(ocp, nothing)

            # Test complete description
            result = OptimalControl.solve_descriptive(
                ocp,
                :collocation,
                :adnlp,
                :ipopt;
                initial_guess=init,
                display=false,
                registry=registry,
            )
            Test.@test result isa CTModels.AbstractSolution
            Test.@test OptimalControl.successful(result)
        end

        Test.@testset "Partial symbolic description" begin
            ocp = TestProblems.Goddard().ocp
            init = OptimalControl.build_initial_guess(ocp, nothing)

            # Test partial description (should complete via registry defaults)
            result = OptimalControl.solve_descriptive(
                ocp, :collocation; initial_guess=init, display=false, registry=registry
            )
            Test.@test result isa CTModels.AbstractSolution
            Test.@test OptimalControl.successful(result)
        end

        # ====================================================================
        # INTEGRATION TESTS - Real problems and strategies
        # ====================================================================

        Test.@testset "Integration with real strategies" begin
            ocp = TestProblems.Beam().ocp
            init = OptimalControl.build_initial_guess(ocp, nothing)

            Test.@testset "Complete description - Beam" begin
                result = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                )
                Test.@test result isa CTModels.AbstractSolution
                Test.@test OptimalControl.successful(result)
                Test.@test OptimalControl.objective(result) ≈ TestProblems.Beam().obj rtol=1e-2
            end

            Test.@testset "Partial description - Beam" begin
                result = OptimalControl.solve_descriptive(
                    ocp, :collocation; initial_guess=init, display=false, registry=registry
                )
                Test.@test result isa CTModels.AbstractSolution
                Test.@test OptimalControl.successful(result)
            end

            ocp = TestProblems.Goddard().ocp
            init = OptimalControl.build_initial_guess(ocp, nothing)

            Test.@testset "Complete description - Goddard" begin
                result = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                )
                Test.@test result isa CTModels.AbstractSolution
                Test.@test OptimalControl.successful(result)
                Test.@test OptimalControl.objective(result) ≈ TestProblems.Goddard().obj rtol=1e-2
            end

            Test.@testset "Partial description - Goddard" begin
                result = OptimalControl.solve_descriptive(
                    ocp, :collocation; initial_guess=init, display=false, registry=registry
                )
                Test.@test result isa CTModels.AbstractSolution
                Test.@test OptimalControl.successful(result)
            end

            Test.@testset "Complete description - Goddard with Uno" begin
                result = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :uno;
                    initial_guess=init,
                    display=false,
                    registry=registry,
                )
                Test.@test result isa CTModels.AbstractSolution
                Test.@test OptimalControl.successful(result)
                Test.@test OptimalControl.objective(result) ≈ TestProblems.Goddard().obj rtol=1e-2
            end
        end

        # ====================================================================
        # ALIAS TESTS - Initial guess aliases in descriptive mode
        # ====================================================================

        Test.@testset "Initial guess aliases" begin
            ocp = TestProblems.Beam().ocp

            Test.@testset "alias 'init'" begin
                result = OptimalControl.solve_descriptive(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    init=nothing,
                    display=false,
                    registry=registry,
                )
                Test.@test result isa CTModels.AbstractSolution
                Test.@test OptimalControl.successful(result)
            end
        end

        # ====================================================================
        # ERROR TESTS - Invalid descriptions and error handling
        # ====================================================================

        Test.@testset "Error handling" begin
            ocp = TestProblems.Beam().ocp
            init = OptimalControl.build_initial_guess(ocp, nothing)

            Test.@testset "Unknown strategy" begin
                Test.@test_throws Exception begin
                    OptimalControl.solve_descriptive(
                        ocp,
                        :unknown_strategy,
                        :adnlp,
                        :ipopt;
                        initial_guess=init,
                        display=false,
                        registry=registry,
                    )
                end
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_descriptive() = TestDescriptive.test_descriptive()

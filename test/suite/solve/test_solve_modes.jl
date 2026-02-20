# ============================================================================
# End-to-End Solve Modes Tests
# ============================================================================
# This file tests the high-level `solve` function in both Explicit and
# Descriptive modes using real optimal control problems. 
# It verifies that the complete dispatch and routing chain works correctly
# and produces a valid solution (even if not optimal, since we limit iterations).

module TestSolveModes

import Test
import OptimalControl

# Load solver extensions
import NLPModelsIpopt
import MadNLP
import MadNLPMumps

# Include shared test problems
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_solve_modes()
    Test.@testset "Solve Modes Integration" verbose = VERBOSE showtiming = SHOWTIMING begin

        # Use a simple problem for integration tests
        pb = Beam()

        # ====================================================================
        # Explicit Mode Integration
        # ====================================================================
        Test.@testset "Explicit Mode" begin
            # 1. Instantiate concrete components
            # We use max_iter=0 to just build and evaluate the problem without solving
            disc = OptimalControl.Collocation(grid_size=20, scheme=:midpoint)
            mod  = OptimalControl.ADNLP()
            sol  = OptimalControl.Ipopt(print_level=0, max_iter=0)

            # 2. Call solve explicitly
            sol_explicit = OptimalControl.solve(
                pb.ocp;
                discretizer=disc,
                modeler=mod,
                solver=sol,
                display=false
            )

            Test.@test sol_explicit isa OptimalControl.AbstractSolution
        end

        # ====================================================================
        # Descriptive Mode Integration
        # ====================================================================
        Test.@testset "Descriptive Mode (Complete)" begin
            # 1. Call solve with a complete description and options
            sol_descriptive = OptimalControl.solve(
                pb.ocp,
                :collocation, :adnlp, :ipopt;
                grid_size=20,
                max_iter=0,     # Stop immediately
                print_level=0,
                display=false
            )

            Test.@test sol_descriptive isa OptimalControl.AbstractSolution
        end

        # ====================================================================
        # Descriptive Mode Integration (Partial)
        # ====================================================================
        Test.@testset "Descriptive Mode (Partial)" begin
            # 1. Call solve with a partial description (only discretizer)
            # The registry should auto-complete modeler and solver
            sol_partial = OptimalControl.solve(
                pb.ocp,
                :collocation;
                grid_size=20,
                max_iter=0,     # Stop immediately
                print_level=0,
                display=false
            )

            Test.@test sol_partial isa OptimalControl.AbstractSolution
        end

        # ====================================================================
        # Descriptive Mode Integration (Action Option Aliases)
        # ====================================================================
        Test.@testset "Descriptive Mode (Action Option Aliases)" begin
            Test.@testset "Alias 'init'" begin
                sol_init = OptimalControl.solve(
                    pb.ocp,
                    :collocation;
                    init=pb.init,
                    grid_size=20,
                    max_iter=0,
                    print_level=0,
                    display=false
                )
                Test.@test sol_init isa OptimalControl.AbstractSolution
            end
        end
    end
end

end # module

# Entry point
test_solve_modes() = TestSolveModes.test_solve_modes()

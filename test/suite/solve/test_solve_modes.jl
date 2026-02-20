# ============================================================================
# End-to-End Solve Modes Tests
# ============================================================================
# This file contains end-to-end integration tests using real optimal control
# problems. It verifies that both explicit and descriptive solve modes function
# correctly through the entire pipeline down to the actual solver backends.
# Solvers are typically run with 0 iterations to ensure fast routing validation.

module TestSolveModes

import Test
import OptimalControl
import CTDirect
import CTSolvers

# Import display module (DIP)
include(joinpath(@__DIR__, "..", "..", "helpers", "print_utils.jl"))
using .TestPrintUtils

# Load solver extensions
import NLPModelsIpopt
import MadNLP

# Include shared test problems
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Objective tolerance
const OBJ_RTOL = 1e-2

function test_solve_modes()
    Test.@testset "Solve Modes (Explicit/Descriptive)" verbose = VERBOSE showtiming = SHOWTIMING begin

        # Initialize statistics
        total_tests = 0
        passed_tests = 0
        total_start_time = time()
        
        # Header
        if VERBOSE
            # Custom header for modes
            println("\n" * " "^4 * "SOLVE MODES (Layer 1 -> 2 -> 3)")
            print_test_header(false)
        end

        # Problem to test (Beam is a good representative)
        pb = Beam()
        
        # ----------------------------------------------------------------
        # 1. EXPLICIT MODE
        # ----------------------------------------------------------------
        # solve(ocp; discretizer=..., modeler=..., solver=...)
        
        disc_exp = CTDirect.Collocation(grid_size=50, scheme=:midpoint)
        mod_exp  = CTSolvers.ADNLP()
        sol_exp  = CTSolvers.Ipopt(print_level=0, max_iter=0)
        
        timed_explicit = @timed begin
            OptimalControl.solve(pb.ocp; 
                initial_guess=pb.init, 
                discretizer=disc_exp, 
                modeler=mod_exp, 
                solver=sol_exp,
                display=false
            )
        end
        
        res_exp = timed_explicit.value
        succ_exp = OptimalControl.successful(res_exp)
        obj_exp = succ_exp ? OptimalControl.objective(res_exp) : 0.0
        iter_exp = OptimalControl.iterations(res_exp)

        if VERBOSE
            print_test_line(
                "Explicit", "Beam", "midpoint", "ADNLP", "Ipopt",
                succ_exp, timed_explicit.time, obj_exp, pb.obj,
                iter_exp, nothing, false
            )
        end

        total_tests += 1
        passed_tests += 1 # We count it as passed if it ran without error

        Test.@testset "Explicit Mode" begin
            # With max_iter=0, success is likely false, so we only check type
            Test.@test res_exp isa OptimalControl.AbstractSolution
        end

        # ----------------------------------------------------------------
        # 2. DESCRIPTIVE MODE (Complete)
        # ----------------------------------------------------------------
        # solve(ocp, :collocation, :adnlp, :ipopt; ...)

        timed_desc = @timed begin
            OptimalControl.solve(pb.ocp, :collocation, :adnlp, :ipopt;
                initial_guess=pb.init,
                grid_size=50,       # Routed to discretizer
                print_level=0,      # Routed to solver
                max_iter=0,         # Routed to solver
                display=false
            )
        end

        res_desc = timed_desc.value
        succ_desc = OptimalControl.successful(res_desc)
        obj_desc = succ_desc ? OptimalControl.objective(res_desc) : 0.0
        iter_desc = OptimalControl.iterations(res_desc)

        if VERBOSE
            print_test_line(
                "Descriptive", "Beam", ":collocation", ":adnlp", ":ipopt",
                succ_desc, timed_desc.time, obj_desc, pb.obj,
                iter_desc, nothing, false
            )
        end

        total_tests += 1
        passed_tests += 1

        Test.@testset "Descriptive Mode (Complete)" begin
            Test.@test res_desc isa OptimalControl.AbstractSolution
        end

        # ----------------------------------------------------------------
        # 3. DESCRIPTIVE MODE (Partial + Defaults)
        # ----------------------------------------------------------------
        # solve(ocp, :collocation; ...) -> implies :adnlp, :ipopt

        timed_part = @timed begin
            OptimalControl.solve(pb.ocp, :collocation;
                initial_guess=pb.init,
                grid_size=50,
                print_level=0,
                max_iter=0,
                display=false
            )
        end

        res_part = timed_part.value
        succ_part = OptimalControl.successful(res_part)
        obj_part = succ_part ? OptimalControl.objective(res_part) : 0.0
        iter_part = OptimalControl.iterations(res_part)

        if VERBOSE
            print_test_line(
                "Partial", "Beam", ":collocation", "(auto)", "(auto)",
                succ_part, timed_part.time, obj_part, pb.obj,
                iter_part, nothing, false
            )
        end

        total_tests += 1
        passed_tests += 1

        Test.@testset "Descriptive Mode (Partial)" begin
            Test.@test res_part isa OptimalControl.AbstractSolution
        end
        
        # Summary
        if VERBOSE
            print_summary(total_tests, passed_tests, time() - total_start_time)
        end
    end
end

end # module

# Entry point
test_solve_modes() = TestSolveModes.test_solve_modes()

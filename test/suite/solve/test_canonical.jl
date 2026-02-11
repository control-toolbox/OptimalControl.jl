module TestCanonical

using Test
using OptimalControl

# Load solver extensions (import only to trigger extensions, avoid name conflicts)
import NLPModelsIpopt
import MadNLP
import MadNLPMumps

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Objective tolerance for comparison with reference values
const OBJ_RTOL = 1e-2

function test_canonical()
    @testset "Canonical solve" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ----------------------------------------------------------------
        # Define strategies
        # ----------------------------------------------------------------
        discretizers = [
            ("Collocation/midpoint", Collocation(grid_size=100, scheme=:midpoint)),
            ("Collocation/trapeze", Collocation(grid_size=100, scheme=:trapeze)),
        ]

        modelers = [
            ("ADNLPModeler", ADNLPModeler()),
            ("ExaModeler",   ExaModeler()),
        ]

        solvers = [
            ("Ipopt",  IpoptSolver(print_level=0)),
            ("MadNLP", MadNLPSolver(print_level=MadNLP.ERROR)),
        ]

        problems = [
            ("Beam",    Beam()),
            ("Goddard", Goddard()),
        ]

        # ----------------------------------------------------------------
        # Test all combinations
        # ----------------------------------------------------------------
        for (pname, pb) in problems
            @testset "$pname" begin
                for (dname, disc) in discretizers
                    for (mname, mod) in modelers
                        for (sname, sol) in solvers
                            label = "$pname / $dname / $mname / $sname"
                            print("  Testing: $label ...")
                            @testset "$dname / $mname / $sname" begin
                                ocp_sol = solve(
                                    pb.ocp, disc, mod, sol;
                                    display=false,
                                    initial_guess=pb.init,
                                )
                                @test ocp_sol isa AbstractOptimalControlSolution
                                @test successful(ocp_sol)
                                @test objective(ocp_sol) ≈ pb.obj rtol = OBJ_RTOL
                            end
                            println("  ✓ done.")
                        end
                    end
                end
            end
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_canonical() = TestCanonical.test_canonical()
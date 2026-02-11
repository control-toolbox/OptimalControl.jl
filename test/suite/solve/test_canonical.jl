module TestCanonical

using Test
using OptimalControl

# Load solver extensions (import only to trigger extensions, avoid name conflicts)
import NLPModelsIpopt
import MadNLP
import MadNLPMumps
import MadNLPGPU
import CUDA

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Objective tolerance for comparison with reference values
const OBJ_RTOL = 1e-2

# CUDA availability check
is_cuda_on() = CUDA.functional()
if is_cuda_on()
    println("✓ CUDA functional, GPU tests enabled")
else
    println("⚠️  CUDA not functional, GPU tests will be skipped")
end

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

        # ----------------------------------------------------------------
        # GPU tests (only if CUDA is available)
        # ----------------------------------------------------------------
        if is_cuda_on()
            gpu_modeler  = ("ExaModeler/GPU", ExaModeler(backend=CUDA.CUDABackend()))
            gpu_solver   = ("MadNLP/GPU",    MadNLPSolver(print_level=MadNLP.ERROR, linear_solver=MadNLPGPU.CUDSSSolver))

            for (pname, pb) in problems
                @testset "GPU / $pname" begin
                    for (dname, disc) in discretizers
                        label = "GPU / $pname / $dname / $(gpu_modeler[1]) / $(gpu_solver[1])"
                        print("  Testing: $label ...")
                        @testset "$dname / $(gpu_modeler[1]) / $(gpu_solver[1])" begin
                            ocp_sol = solve(
                                pb.ocp, disc, gpu_modeler[2], gpu_solver[2];
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
        else
            @info "CUDA not functional, skipping GPU tests."
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_canonical() = TestCanonical.test_canonical()
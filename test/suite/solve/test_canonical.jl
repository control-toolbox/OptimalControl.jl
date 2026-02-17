module TestCanonical

using Test
import OptimalControl

# Import du module d'affichage (DIP - dépend de l'abstraction)
include(joinpath(@__DIR__, "..", "..", "helpers", "print_utils.jl"))
using .TestPrintUtils

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

function test_canonical()
    @testset "Canonical solve" verbose = VERBOSE showtiming = SHOWTIMING begin

        # Initialize statistics
        total_tests = 0
        passed_tests = 0
        total_start_time = time()
        
        # Print header with column names
        if VERBOSE
            print_test_header(false)  # show_memory = false par défaut
        end

        # ----------------------------------------------------------------
        # Define strategies
        # ----------------------------------------------------------------
        discretizers = [
            ("Collocation/midpoint", OptimalControl.Collocation(grid_size=100, scheme=:midpoint)),
            ("Collocation/trapeze", OptimalControl.Collocation(grid_size=100, scheme=:trapeze)),
        ]

        modelers = [
            ("ADNLP", OptimalControl.ADNLP()),
            ("Exa",   OptimalControl.Exa()),
        ]

        solvers = [
            ("Ipopt",  OptimalControl.Ipopt(print_level=0)),
            ("MadNLP", OptimalControl.MadNLP(print_level=MadNLP.ERROR)),
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
                            # Extract short names for display
                            d_short = String(split(dname, "/")[2])  # Get "midpoint" or "trapeze"
                            
                            # Normalize initial guess before calling canonical solve (Layer 3)
                            normalized_init = OptimalControl.build_initial_guess(pb.ocp, pb.init)
                            
                            # Execute with timing (DRY - single measurement)
                            timed_result = @timed begin
                                OptimalControl.solve(pb.ocp, normalized_init, disc, mod, sol;
                                      display=false)
                            end
                            
                            # Extract results
                            solve_result = timed_result.value
                            solve_time = timed_result.time
                            memory_bytes = timed_result.bytes
                            
                            success = OptimalControl.successful(solve_result)
                            obj = success ? OptimalControl.objective(solve_result) : 0.0
                            
                            # Extract iterations using CTModels function
                            iters::Union{Nothing, Int} = try
                                OptimalControl.iterations(solve_result)
                            catch
                                nothing
                            end
                            
                            # Display table line (SRP - responsibility delegated)
                            if VERBOSE
                                print_test_line(
                                    "CPU", pname, d_short, mname, sname,
                                    success, solve_time, obj, pb.obj,
                                    iters,
                                    memory_bytes > 0 ? memory_bytes : nothing,
                                    false  # show_memory = false
                                )
                            end
                            
                            # Update statistics
                            total_tests += 1
                            if success
                                passed_tests += 1
                            end
                            
                            # Run the actual test assertions
                            @testset "$dname / $mname / $sname" begin
                                @test success
                                if success
                                    @test solve_result isa OptimalControl.AbstractSolution
                                    @test OptimalControl.objective(solve_result) ≈ pb.obj rtol = OBJ_RTOL
                                end
                            end
                        end
                    end
                end
            end
        end

        # ----------------------------------------------------------------
        # GPU tests (only if CUDA is available)
        # ----------------------------------------------------------------
        if is_cuda_on()
            gpu_modeler  = ("Exa/GPU", OptimalControl.Exa(backend=CUDA.CUDABackend()))
            gpu_solver   = ("MadNLP/GPU",    OptimalControl.MadNLP(print_level=MadNLP.ERROR, linear_solver=MadNLPGPU.CUDSSSolver))

            for (pname, pb) in problems
                @testset "GPU / $pname" begin
                    for (dname, disc) in discretizers
                        # Extract short names for display
                        d_short = String(split(dname, "/")[2])  # Get "midpoint" or "trapeze"
                        
                        # Execute with timing (same structure as CPU tests - DRY)
                        # Normalize initial guess before calling canonical solve (Layer 3)
                        normalized_init = OptimalControl.build_initial_guess(pb.ocp, pb.init)
                        
                        timed_result = @timed begin
                            OptimalControl.solve(pb.ocp, normalized_init, disc, gpu_modeler[2], gpu_solver[2];
                                  display=false)
                        end
                        
                        # Extract results
                        solve_result = timed_result.value
                        solve_time = timed_result.time
                        memory_bytes = timed_result.bytes
                        
                        success = OptimalControl.successful(solve_result)
                        obj = success ? OptimalControl.objective(solve_result) : 0.0
                        
                        # Extract iterations using CTModels function
                        iters::Union{Nothing, Int} = try
                            OptimalControl.iterations(solve_result)
                        catch
                            nothing
                        end
                        
                        # Display table line (SRP - responsibility delegated)
                        if VERBOSE
                            print_test_line(
                                "GPU", pname, d_short, "Exa", "MadNLP",
                                success, solve_time, obj, pb.obj,
                                iters,
                                memory_bytes > 0 ? memory_bytes : nothing,
                                false  # show_memory = false
                            )
                        end
                        
                        # Update statistics
                        total_tests += 1
                        if success
                            passed_tests += 1
                        end
                        
                        # Run the actual test assertions
                        @testset "$dname / $(gpu_modeler[1]) / $(gpu_solver[1])" begin
                            @test success
                            if success
                                @test solve_result isa OptimalControl.AbstractSolution
                                @test OptimalControl.objective(solve_result) ≈ pb.obj rtol = OBJ_RTOL
                            end
                        end
                    end
                end
            end
        else
            @info "CUDA not functional, skipping GPU tests."
        end
        
        # Print summary (SRP - responsibility delegated)
        if VERBOSE
            total_time = time() - total_start_time
            print_summary(total_tests, passed_tests, total_time)
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_canonical() = TestCanonical.test_canonical()
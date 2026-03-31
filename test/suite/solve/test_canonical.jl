# ============================================================================
# Canonical Solve Tests (Layer 3)
# ============================================================================
# This file tests the lowest level of the solve pipeline (Layer 3). It verifies
# that the canonical `solve` function correctly executes the resolution when
# provided with fully concrete, instantiated strategy components (discretizer,
# modeler, solver) and real optimal control problems.

module TestCanonical

using Test: Test
using OptimalControl: OptimalControl

# Import du module d'affichage (DIP - dépend de l'abstraction)
include(joinpath(@__DIR__, "..", "..", "helpers", "print_utils.jl"))
using .TestPrintUtils

# Load solver extensions (import only to trigger extensions, avoid name conflicts)
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP
using MadNLPGPU: MadNLPGPU
using MadNCL: MadNCL
using UnoSolver: UnoSolver
using CUDA: CUDA

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Objective tolerance for comparison with reference values
const OBJ_RTOL = 1e-2

# CUDA availability check
is_cuda_on() = CUDA.functional()

# Generic helper function for test execution (CPU or GPU)
function run_test(
    pb,
    pname,
    dname,
    disc,
    mname,
    mod,
    sname,
    sol,
    total_tests_ref,
    passed_tests_ref,
    device_type::Symbol,
)
    # Extract short names for display
    d_short = String(split(dname, "/")[2])  # Get "midpoint" or "trapeze"

    # Normalize initial guess before calling canonical solve (Layer 3)
    normalized_init = OptimalControl.build_initial_guess(pb.ocp, pb.init)

    # Execute with timing (warmup)
    OptimalControl.solve(pb.ocp, normalized_init, disc, mod, sol; display=false)

    # Timed execution (different for CPU vs GPU)
    if device_type == :CPU
        timed_result = @timed begin
            OptimalControl.solve(pb.ocp, normalized_init, disc, mod, sol; display=false)
        end
        memory_bytes = timed_result.bytes
    else  # :GPU
        timed_result = CUDA.@timed begin
            OptimalControl.solve(pb.ocp, normalized_init, disc, mod, sol; display=false)
        end
        memory_bytes = timed_result.cpu_bytes + timed_result.gpu_bytes
    end

    # Extract results
    solve_result = timed_result.value
    solve_time = timed_result.time

    success = OptimalControl.successful(solve_result)
    obj = success ? OptimalControl.objective(solve_result) : 0.0

    # Extract iterations using CTModels function
    iters = OptimalControl.iterations(solve_result)

    # Display table line (SRP - responsibility delegated)
    if VERBOSE
        print_test_line(
            String(device_type),
            pname,
            d_short,
            mname,
            sname,
            success,
            solve_time,
            obj,
            pb.obj,
            iters,
            memory_bytes > 0 ? memory_bytes : nothing,
            false,  # show_memory = false
        )
    end

    # Update statistics
    total_tests_ref[] += 1
    if success
        passed_tests_ref[] += 1
    end

    # Run the actual test assertions
    Test.@testset "$dname / $mname / $sname" begin
        Test.@test success
        if success
            Test.@test solve_result isa OptimalControl.AbstractSolution
            Test.@test OptimalControl.objective(solve_result) ≈ pb.obj rtol = OBJ_RTOL
        end
    end
end

# Convenience wrappers
function run_cpu_test(
    pb, pname, dname, disc, mname, mod, sname, sol, total_tests_ref, passed_tests_ref
)
    run_test(
        pb,
        pname,
        dname,
        disc,
        mname,
        mod,
        sname,
        sol,
        total_tests_ref,
        passed_tests_ref,
        :CPU,
    )
end

function run_gpu_test(
    pb, pname, dname, disc, mname, mod, sname, sol, total_tests_ref, passed_tests_ref
)
    run_test(
        pb,
        pname,
        dname,
        disc,
        mname,
        mod,
        sname,
        sol,
        total_tests_ref,
        passed_tests_ref,
        :GPU,
    )
end

function test_canonical()
    Test.@testset "Canonical solve" verbose = VERBOSE showtiming = SHOWTIMING begin

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
            (
                "Collocation/midpoint",
                OptimalControl.Collocation(grid_size=100, scheme=:midpoint),
            ),
            (
                "Collocation/trapeze",
                OptimalControl.Collocation(grid_size=100, scheme=:trapeze),
            ),
        ]

        # Define modelers and solvers separately to test all combinations
        modelers = [("ADNLP", OptimalControl.ADNLP()), ("Exa", OptimalControl.Exa())]

        solvers = [
            ("Ipopt", OptimalControl.Ipopt(print_level=0)),
            ("MadNLP", OptimalControl.MadNLP(print_level=MadNLP.ERROR)),
            ("Uno", OptimalControl.Uno(logger="SILENT")),
            # ("MadNCL", OptimalControl.MadNCL(print_level=MadNLP.ERROR)),
        ]

        problems = [
            ("Beam", Beam()),
            ("Goddard", Goddard()),
            # ("Quadrotor", Quadrotor()), # some DomainError some times
            ("DI_Time", DoubleIntegratorTime()),
            ("DI_Energy", DoubleIntegratorEnergy()),
            ("DI_EnergyCons", DoubleIntegratorEnergyConstrained()),
            # ("Transfer", Transfer()), # debug: add later (currently issue with :exa)
        ]

        # Use Refs for statistics to pass to helper functions
        total_tests_ref = Ref(total_tests)
        passed_tests_ref = Ref(passed_tests)

        # ----------------------------------------------------------------
        # Test all combinations
        # ----------------------------------------------------------------
        for (pname, pb) in problems
            Test.@testset "$pname" begin
                for (dname, disc) in discretizers
                    for (mname, mod) in modelers
                        for (sname, sol) in solvers
                            run_cpu_test(
                                pb,
                                pname,
                                dname,
                                disc,
                                mname,
                                mod,
                                sname,
                                sol,
                                total_tests_ref,
                                passed_tests_ref,
                            )
                        end  # end solvers loop
                    end  # end modelers loop
                end  # end discretizers loop
            end  # end problems @testset
        end  # end problems loop

        # Update statistics from Refs
        total_tests = total_tests_ref[]
        passed_tests = passed_tests_ref[]

        # ----------------------------------------------------------------
        # GPU tests (only if CUDA is available)
        # ----------------------------------------------------------------
        if is_cuda_on()
            # Define GPU modelers and solvers as lists (even with single element)
            gpu_modelers = [(
                "Exa", OptimalControl.Exa{OptimalControl.GPU}(backend=CUDA.CUDABackend())
            ),]

            gpu_solvers = [(
                "MadNLP",
                OptimalControl.MadNLP{OptimalControl.GPU}(
                    print_level=MadNLP.ERROR, linear_solver=MadNLPGPU.CUDSSSolver
                ),
            ),]

            # Use Refs for statistics
            total_tests_ref = Ref(total_tests)
            passed_tests_ref = Ref(passed_tests)

            for (pname, pb) in problems
                Test.@testset "GPU / $pname" begin
                    for (dname, disc) in discretizers
                        for (mname, mod) in gpu_modelers
                            for (sname, sol) in gpu_solvers
                                run_gpu_test(
                                    pb,
                                    pname,
                                    dname,
                                    disc,
                                    mname,
                                    mod,
                                    sname,
                                    sol,
                                    total_tests_ref,
                                    passed_tests_ref,
                                )
                            end  # end gpu_solvers loop
                        end  # end gpu_modelers loop
                    end  # end discretizers loop
                end  # end GPU @testset
            end  # end problems loop

            # Update statistics from Refs
            total_tests = total_tests_ref[]
            passed_tests = passed_tests_ref[]
        else
            println("")
            @info "CUDA not functional, skipping GPU tests."
        end

        # Print summary (SRP - responsibility delegated)
        if VERBOSE
            total_time = time() - total_start_time
            print_summary(total_tests, passed_tests, total_time)
        end
    end  # end @testset
end  # end test_canonical function

end # module

# Redefine in outer scope for TestRunner
test_canonical() = TestCanonical.test_canonical()

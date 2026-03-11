# ==============================================================================
# OptimalControl Test Runner
# ==============================================================================
#
# See test/README.md for usage instructions (running specific tests, coverage, etc.)
#
# ==============================================================================

# Test dependencies
using Test
using CTBase
using OptimalControl

# Trigger loading of optional extensions
const TestRunner = Base.get_extension(CTBase, :TestRunner)

# Controls nested testset output formatting (used by individual test files)
module TestOptions
const VERBOSE = true
const SHOWTIMING = true
end
using .TestOptions: VERBOSE, SHOWTIMING

# CUDA availability check
using CUDA
is_cuda_on() = CUDA.functional()
if is_cuda_on()
    @info "✅ CUDA functional, GPU tests enabled"
else
    @info "⚠️  CUDA not functional, GPU tests will be skipped"
end

# Run tests using the TestRunner extension
CTBase.run_tests(;
    args=String.(ARGS),
    testset_name="OptimalControl tests",
    available_tests=(
        "suite/*/test_*",
    ),
    filename_builder=name -> Symbol(:test_, name),
    funcname_builder=name -> Symbol(:test_, name),
    verbose=VERBOSE,
    showtiming=SHOWTIMING,
    test_dir=@__DIR__,
)

# If running with coverage enabled, remind the user to run the post-processing script
# because .cov files are flushed at process exit and cannot be cleaned up by this script.
if Base.JLOptions().code_coverage != 0
    println(
        """

================================================================================
[OptimalControl] Coverage files generated.

To process them, move them to the coverage/ directory, and generate a report,
please run:

    julia --project=@. -e 'using Pkg; Pkg.test("OptimalControl"; coverage=true); include("test/coverage.jl")'
================================================================================
""",
    )
end
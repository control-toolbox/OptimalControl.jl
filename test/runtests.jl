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

# Capability constants computed once, here, where a top-level `using` is guaranteed to bind
# into Main. Test files read `Main.TestCapabilities.*` instead of `isdefined(Main, :X)`
# checks or local predicates: `using X` inside a suite/*/test_*.jl file's own module binds X
# into that submodule, not Main, so such checks are always false regardless of what is loaded.
# Mirrors the `TestCapabilities` pattern in CTSolvers (control-toolbox/CTSolvers.jl#190/#223).
#
#   CUDA_FUNCTIONAL     — is there a functional GPU *device*? The suite's single device
#                         predicate — never define a local `is_cuda_on()` in a test file.
#                         Guard device runs with `Test.@test_skip` on the `else`, never a
#                         silent `if CUDA_FUNCTIONAL` with no branch (see Handbook
#                         philosophy/testing.md §"Capability-gated tests").
#   ON_GPU_RUNNER       — turns the device tier from *skipped* into *required* on the
#                         self-hosted GPU runners. `RUNNER_NAME` is set by the GitHub Actions
#                         runner agent itself (no CI.yml change needed) to the runner's
#                         *registered* name — `kkt-runner` / `occidata-runner` for ours (the
#                         CI.yml `runs_on` label is the bare `kkt`/`occidata`), so match the
#                         `kkt`/`occidata` substring to survive the `-runner` suffix.
#   GPU_EXTENSION_ARMED — is `CTSolversMadNLPGPU` loaded? CPU-runnable: it says nothing about
#                         a device, only that the GPU code path is compiled in. Since
#                         CTSolvers#189 the trigger is `MadNLPGPU` + `CUDA` + `CUDSS` — all
#                         three; loading two of them leaves it inactive, silently.
#
# Enforcement lives centrally in test/suite/environment/test_environment_contract.jl.
module TestCapabilities
using CUDA: CUDA
using CUDSS: CUDSS          # with CUDA + MadNLPGPU, arms CTSolversMadNLPGPU
using MadNLPGPU: MadNLPGPU
using CTSolvers: CTSolvers

const CUDA_FUNCTIONAL = CUDA.functional()
const ON_GPU_RUNNER = any(
    gpu -> occursin(gpu, get(ENV, "RUNNER_NAME", "")), ("kkt", "occidata")
)
const GPU_EXTENSION_ARMED =
    Base.get_extension(CTSolvers, :CTSolversMadNLPGPU) !== nothing
end

if TestCapabilities.CUDA_FUNCTIONAL
    @info "✅ CUDA functional, GPU device tests enabled"
else
    @info "⚠️  CUDA not functional, GPU device tests will skip (Test.@test_skip)"
end

# Run tests using the TestRunner extension
CTBase.run_tests(;
    args=String.(ARGS),
    testset_name="OptimalControl tests",
    available_tests=("suite/*/test_*",),
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

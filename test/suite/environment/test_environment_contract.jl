# ============================================================================
# Test-environment contract
# ============================================================================
# Central enforcement of the Handbook's capability-gated-test policy
# (philosophy/testing.md §"Capability-gated tests"). Mirrors the equivalent
# file in CTSolvers (control-toolbox/CTSolvers.jl#190/#223).
#
# Three things are pinned here so they cannot regress silently:
#
#   1. The GPU solver extension is armed on *every* runner (packages loaded).
#   2. On a self-hosted GPU runner, a missing/broken device fails loudly here
#      rather than being skipped everywhere else.
#   3. Two anti-patterns stay out of the suite: an `isdefined` check against
#      `Main` for a package symbol (always false — `Base.include(Main, file)`
#      only binds each test file's own module into `Main`, not what it `using`s
#      internally), and an unbraced device-predicate guard around the only
#      assertions in a testset (a green testset with zero assertions is
#      indistinguishable from a real pass). This file is excluded from both
#      walks — it necessarily names the patterns it searches for.

module TestEnvironmentContract

using Test: Test

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    _isdefined_main_offenders()

Recursively find, under `test/suite/` (located via `@__DIR__`, not `pwd()`), source lines
matching `isdefined(Main, ...)` for a package symbol other than the two legitimate idioms:

- `TestOptions` — the `VERBOSE`/`SHOWTIMING` idiom at the top of every suite test file;
  `TestOptions` is a module defined directly in `test/runtests.jl`, i.e. genuinely in `Main`.
- `CUDA` — `test/runtests.jl`'s `TestCapabilities` module does `using CUDA`, and a bare
  `using` at that level also leaks the name into `Main`; unlike every other package, which
  is only ever `using`'d *inside* a suite file's own module and so never reaches `Main`.

Any other such check is the anti-pattern this file exists to catch
(control-toolbox/CTSolvers.jl#189): always `false` no matter what is loaded. This file is
excluded from the walk — it names the pattern it searches for.
"""
function _isdefined_main_offenders()
    suite_dir = joinpath(@__DIR__, "..")
    offenders = Tuple{String,Int,String}[]
    pattern = r"isdefined\(Main,\s*:(\w+)\)"
    this_file = basename(@__FILE__)
    for (root, _, files) in walkdir(suite_dir)
        for f in files
            (endswith(f, ".jl") && f != this_file) || continue
            path = joinpath(root, f)
            for (lineno, line) in enumerate(eachline(path))
                m = match(pattern, line)
                if m !== nothing && m.captures[1] ∉ ("TestOptions", "CUDA")
                    push!(offenders, (relpath(path, suite_dir), lineno, m.captures[1]))
                end
            end
        end
    end
    return offenders
end

"""
    _silent_cuda_guard_offenders()

Recursively find, under `test/suite/` (located via `@__DIR__`, not `pwd()`), lines that open
an `if` block directly on a CUDA-device predicate — a local `is_cuda_on()` call or a bare
`CUDA.functional()` call — the anti-pattern that makes a correctly-skipped run (no device,
as expected on a developer machine) and a silently-broken run (device *should* be present
but isn't) produce the same output: a green testset with zero assertions (Handbook
`philosophy/testing.md` §"Capability-gated tests", control-toolbox/CTSolvers.jl#189).

The sanctioned form is `if Main.TestCapabilities.CUDA_FUNCTIONAL ... else Test.@test_skip
... end`, with the device tier made *required* on the GPU runners centrally, in the testset
below. This file is excluded from the walk: it necessarily spells out the very patterns it
searches for.
"""
function _silent_cuda_guard_offenders()
    suite_dir = joinpath(@__DIR__, "..")
    offenders = Tuple{String,Int,String}[]
    # Assembled from two literals so this line does not match itself.
    pattern = Regex("if\\s+(is_cuda_on\\(\\)|CUDA" * "\\.functional\\(\\))")
    this_file = basename(@__FILE__)
    for (root, _, files) in walkdir(suite_dir)
        for f in files
            (endswith(f, ".jl") && f != this_file) || continue
            path = joinpath(root, f)
            for (lineno, line) in enumerate(eachline(path))
                if match(pattern, line) !== nothing
                    push!(offenders, (relpath(path, suite_dir), lineno, strip(line)))
                end
            end
        end
    end
    return offenders
end

function test_environment_contract()
    Test.@testset "Test-environment contract" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "GPU solver extension is armed" begin
            # Runs on every runner, including CPU-only laptops: "armed" comes from packages
            # being loaded (Project.toml + `using` in test/runtests.jl), not from a driver.
            # This is the assertion that catches CTSolvers#189 itself — it fails the moment
            # CUDSS falls out of the extension trigger wiring again.
            Test.@test Main.TestCapabilities.GPU_EXTENSION_ARMED
        end

        Test.@testset "GPU driver required on the GPU runner" begin
            # On a machine that is supposed to have a GPU, a missing/broken device fails
            # loudly here rather than being silently skipped everywhere else.
            #
            # `RUNNER_NAME` is set automatically by the GitHub Actions runner agent to the
            # runner's registered name — `kkt-runner` / `occidata-runner` for our self-hosted
            # GPU runners (the CI.yml `runs_on` label is the bare `kkt`/`occidata`).
            # `ON_GPU_RUNNER` (test/runtests.jl) matches the `kkt`/`occidata` substring, so it
            # survives the `-runner` suffix; past a further rename the check stops firing
            # silently rather than failing loudly — keep it in sync with .github/workflows/CI.yml.
            if Main.TestCapabilities.ON_GPU_RUNNER
                Test.@test Main.TestCapabilities.CUDA_FUNCTIONAL
            end
        end

        Test.@testset "isdefined(Main, ...) anti-pattern has not returned" begin
            offenders = _isdefined_main_offenders()
            Test.@test isempty(offenders)
            for (file, lineno, sym) in offenders
                @warn "isdefined(Main, :$sym) anti-pattern at $file:$lineno — use Main.TestCapabilities instead"
            end
        end

        Test.@testset "silent CUDA-guard anti-pattern has not returned" begin
            offenders = _silent_cuda_guard_offenders()
            Test.@test isempty(offenders)
            for (file, lineno, text) in offenders
                @warn "silent CUDA guard at $file:$lineno — use Main.TestCapabilities.CUDA_FUNCTIONAL with a Test.@test_skip else branch" text
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_environment_contract() = TestEnvironmentContract.test_environment_contract()

# ============================================================================
# Test capabilities
# ============================================================================
# Mirrors the `TestCapabilities` pattern introduced upstream in CTSolvers.
#
# Two questions that are easy to conflate and must not be:
#
#   `gpu_extension_armed()` — is the `CTSolversMadNLPGPU` extension loaded?
#                             CPU-runnable. It is the only local evidence that
#                             the GPU code path is even compiled in.
#   `is_cuda_on()`          — is there a functional GPU *device*?
#                             False on every CI runner we have locally.
#
# ⚠️ Since CTSolvers#189 the extension trigger is
# `CTSolversMadNLPGPU = ["MadNLPGPU", "CUDA", "CUDSS"]` — all three. Loading
# `MadNLPGPU` and `CUDA` without `CUDSS` leaves the extension inactive and
# `MadNLPGPU{GPU}` unregistered as a strategy, silently.
#
# `is_cuda_on()` used to be defined three times independently
# (runtests.jl — unused, test_canonical.jl, test_options_forwarding.jl).
# This file is the single definition.
#
# Included (not `using`-ed) by the test files that need it, since TestRunner
# runs files independently and each must stand alone.

module TestCapabilities

using CUDA: CUDA
using CTSolvers: CTSolvers

"""
    is_cuda_on()

`true` when a functional CUDA device is present. Guards *device* runs only.
Prefer `Test.@test_skip` over a silent `if is_cuda_on()` so skipped assertions
appear in the summary instead of vanishing.
"""
is_cuda_on() = CUDA.functional()

"""
    gpu_extension_armed()

`true` when `CTSolversMadNLPGPU` is loaded — i.e. `MadNLPGPU`, `CUDA` *and*
`CUDSS` are all in the session. CPU-runnable: it says nothing about whether a
device exists.
"""
gpu_extension_armed() = Base.get_extension(CTSolvers, :CTSolversMadNLPGPU) !== nothing

"""
    on_gpu_runner()

`true` on the self-hosted `kkt` GPU runner (`.github/workflows/CI.yml:41`).

`RUNNER_NAME` is set by the GitHub Actions runner agent itself, so this needs no
CI.yml or CTActions change. Its purpose is to turn the device tier from
*skipped* into *required* on the one machine that must have a device: without
it, a `kkt` whose driver broke is indistinguishable from a laptop, and the GPU
job goes green having run nothing — the failure class of CTSolvers#189.

If the runner is ever renamed this check stops firing silently rather than
failing loudly; update the literal alongside CI.yml.
"""
on_gpu_runner() = get(ENV, "RUNNER_NAME", "") == "kkt"

end # module

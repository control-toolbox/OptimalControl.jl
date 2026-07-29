# ============================================================================
# CPU/GPU routing
# ============================================================================
# `:cpu` / `:gpu` means the same thing on both sides of the library after this
# upgrade: `solve(ocp, …, :gpu)` on the direct path and `Flow(…; method=:gpu)`
# on the indirect one. This file checks the *routing* — which strategies get
# resolved — which is entirely CPU-runnable. Nothing here needs a device.
#
# ⚠️ Two things that are easy to conflate, and are kept apart throughout:
#
#   extension armed   — is `CTSolversMadNLPGPU` loaded? CPU-runnable, and the
#                       only local evidence the GPU path is even compiled in.
#   device present    — is there a functional GPU? False on every runner we
#                       have locally.
#
# Since CTSolvers#189 the extension trigger is
# `["MadNLPGPU", "CUDA", "CUDSS"]` — all three. Loading two of them leaves the
# extension inactive and `MadNLP{GPU}` unregistered, with no error anywhere,
# which is exactly the kind of silence a test should break.
#
# The device tier has no honest local green and is deferred to the GPU runner:
# `Test.@test_skip`, so it shows up in the summary rather than vanishing.
#
# Not tested here: CTFlows' own `_flow_description` resolution, which is
# upstream's business (`CTFlows.jl/test/suite/flows/test_gpu_routing.jl`).
# What is ours is that the tokens survive OptimalControl's re-exported surface.

module TestGPURouting

using Test: Test
using OptimalControl
using CTBase: CTBase
using CTSolvers: CTSolvers

# The GPU extension trigger — all three, or it stays inactive.
using MadNLPGPU: MadNLPGPU
using CUDA: CUDA
using CUDSS: CUDSS
using MadNLP: MadNLP
using ExaModels: ExaModels
import OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

include(joinpath(@__DIR__, "..", "..", "helpers", "capabilities.jl"))
using .TestCapabilities: is_cuda_on, gpu_extension_armed, on_gpu_runner

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const S = CTBase.Strategies

function test_gpu_routing()
    Test.@testset "CPU/GPU routing" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # The extension is armed — CPU-runnable
        # ====================================================================

        Test.@testset "GPU extension armed" begin
            Test.@test gpu_extension_armed()
            # The single most load-bearing assertion in this file: it is the
            # only local evidence the GPU code path exists at all, and it
            # passes with `CUDA.functional() == false`.
            Test.@test MadNLPGPU.CUDSSSolver isa Type
        end

        # ====================================================================
        # Direct path — the registry knows which strategies are GPU-capable
        # ====================================================================

        Test.@testset "registry parameter support" begin
            registry = OptimalControl.get_strategy_registry()
            M = CTSolvers.Modelers.AbstractNLPModeler
            N = CTSolvers.Solvers.AbstractNLPSolver

            gpu_capable = Dict(
                :adnlp => false,
                :exa => true,
                :ipopt => false,
                :madnlp => true,
                :uno => false,
                :madncl => true,
                :knitro => false,
            )

            for (id, family) in (
                (:adnlp, M), (:exa, M),
                (:ipopt, N), (:madnlp, N), (:uno, N), (:madncl, N), (:knitro, N),
            )
                Test.@testset "$id" begin
                    params = S.available_parameters(id, family, registry)
                    Test.@test S.CPU in params
                    Test.@test (S.GPU in params) == gpu_capable[id]
                end
            end
        end

        Test.@testset "GPU strategies are constructible without a device" begin
            # Building the parameterized type is routing, not execution — it
            # must not require a functional GPU.
            Test.@test S.parameter(CTSolvers.Modelers.Exa{S.GPU}) === S.GPU
            Test.@test S.parameter(CTSolvers.Solvers.MadNLP{S.GPU}) === S.GPU
            Test.@test S.parameter(CTSolvers.Solvers.MadNCL{S.GPU}) === S.GPU
        end

        # ====================================================================
        # Indirect path — `method=` on flow construction
        # ====================================================================

        Test.@testset "Flow(method=…)" begin
            vf() = VectorField(x -> -x)
            ham() = Hamiltonian((x, p) -> 0.5 * (x[1]^2 + p[1]^2))

            Test.@testset "cpu is the default" begin
                Test.@test typeof(Flow(vf())) === typeof(Flow(vf(); method=:cpu))
            end

            Test.@testset "gpu resolves, on CPU" begin
                # Resolving `:gpu` builds GPU-parameterized strategies; it does
                # not run anything on a device, so it must work here.
                for f in (Flow(vf(); method=:gpu), Flow(ham(); method=:gpu))
                    Test.@test f isa Any
                end
                # …and it must actually be a different resolution from `:cpu`,
                # or the token is being silently ignored.
                Test.@test typeof(Flow(vf(); method=:gpu)) !==
                    typeof(Flow(vf(); method=:cpu))
            end

            Test.@testset "one token resolves both families" begin
                # A single `:gpu` has to reach the AD family *and* the
                # integrator family. Both parameters are encoded in the flow
                # type, so match on each family by name.
                #
                # ⚠️ Match `SciML{GPU` and `DifferentiationInterface{GPU`, not
                # a bare "GPU": the type string also carries this module's own
                # name (`TestGPURouting`), which contains those three letters
                # and makes a naive `occursin("GPU", …)` vacuously true.
                cpu = string(typeof(Flow(ham(); method=:cpu)))
                gpu = string(typeof(Flow(ham(); method=:gpu)))

                Test.@test cpu != gpu
                for family in ("SciML{", "DifferentiationInterface{")
                    Test.@testset "$family" begin
                        Test.@test occursin(family * "GPU", gpu)
                        Test.@test occursin(family * "CPU", cpu)
                        Test.@test !occursin(family * "GPU", cpu)
                    end
                end
            end

            Test.@testset "an unknown method is rejected" begin
                Test.@test_throws CTBase.Exceptions.CTException Flow(
                    vf(); method=:quantum
                )
            end
        end

        # ====================================================================
        # Device tier — no honest local green
        # ====================================================================

        Test.@testset "device runs" begin
            # `@test_skip` rather than a silent `if is_cuda_on()`: a skipped
            # assertion is visible in the summary, an elided branch is not.
            gpu_solve() = begin
                ocp = @def begin
                    t ∈ [0, 1], time
                    x ∈ R², state
                    u ∈ R, control
                    x(0) == [-1, 0]
                    x(1) == [0, 0]
                    ẋ(t) == [x₂(t), u(t)]
                    ∫(0.5u(t)^2) → min
                end
                sol = solve(
                    ocp,
                    :collocation,
                    :exa,
                    :madnlp,
                    :gpu;
                    display=false,
                    grid_size=50,
                    backend=CUDA.CUDABackend(),
                    linear_solver=MadNLPGPU.CUDSSSolver,
                )
                successful(sol)
            end

            # ⚠️ A skip is honest on a laptop and a lie on the GPU runner. The
            # `kkt` runner exists to have a device; if CUDA is not functional
            # *there*, skipping turns the whole GPU job green with nothing run
            # — the failure class CTSolvers#189/#190 was about, one level up.
            # So on that runner the device itself is asserted, not assumed.
            if on_gpu_runner()
                Test.@test is_cuda_on()
            end

            if is_cuda_on()
                Test.@test gpu_solve()
            else
                Test.@test_skip gpu_solve()
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_gpu_routing() = TestGPURouting.test_gpu_routing()

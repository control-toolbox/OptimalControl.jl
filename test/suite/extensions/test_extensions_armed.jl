# ============================================================================
# Extension Arming Tests
# ============================================================================
# A `[deps]` entry arms nothing. Julia fires a package extension when its
# trigger packages are *loaded in the session*, not when they appear in
# `Project.toml`. Since v2.1.0-beta, ADNLPModels/ExaModels/DifferentiationInterface
# sit behind extensions of CTSolvers/CTBase, so OptimalControl must `import`
# them explicitly (see `src/imports/{adnlpmodels,ad,examodels}.jl`).
#
# Without those imports the package still precompiles and most of the suite
# still passes — the capability is simply dead. This file is the guard.

module TestExtensionsArmed

using Test: Test
using OptimalControl
using CTBase: CTBase
using CTSolvers: CTSolvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Extensions that `using OptimalControl` alone must arm, because OptimalControl
# declares the trigger package in its own `[deps]`.
const OWNED_EXTENSIONS = (
    (CTSolvers, :CTSolversADNLPModels),   # ADNLP modeler
    (CTSolvers, :CTSolversExaModels),     # Exa modeler
    (CTSolvers, :CTSolversForwardDiff),   # AD for solve
    (CTBase, :CTBaseDifferentiationInterface),  # Lie / Poisson / Lift / @Lie
)

function test_extensions_armed()
    Test.@testset "Extensions armed" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Owned by OptimalControl" begin
            for (mod, ext) in OWNED_EXTENSIONS
                Test.@test Base.get_extension(mod, ext) !== nothing
            end
        end

        Test.@testset "Trigger packages in scope" begin
            # The imports layer must make the trigger modules reachable.
            Test.@test isdefined(OptimalControl, :ADNLPModels)
            Test.@test isdefined(OptimalControl, :ExaModels)
            Test.@test isdefined(OptimalControl, :DifferentiationInterface)
            Test.@test isdefined(OptimalControl, :ForwardDiff)
        end

        Test.@testset "Differential geometry is live" begin
            # `ad`/`Lift`/`Poisson` are no-ops without CTBaseDifferentiationInterface;
            # this exercises the extension rather than merely asserting it loaded.
            X = VectorField(x -> [x[2], -x[1]])
            H = Lift(X)
            Test.@test H([1.0, 2.0], [3.0, 4.0]) ≈ 3.0 * 2.0 + 4.0 * (-1.0)
        end

        Test.@testset "User-loaded extensions stay inert" begin
            # By design (Q7) the SciML/solver/plotting extensions are the user's
            # `using` to make. They must NOT be armed by `using OptimalControl`.
            Test.@test Base.get_extension(CTBase, :CTBasePlots) === nothing
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_extensions_armed() = TestExtensionsArmed.test_extensions_armed()

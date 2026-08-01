# ============================================================================
# CTLie Reexports Tests
# ============================================================================
# CTLie is new in v2.1.0-beta. It took over the differential-geometry API that
# used to live in CTFlows:
#
#   CTFlows.Lie(X, f)      → CTLie.ad(X, f)
#   CTFlows.Lift           → CTLie.Lift
#   CTFlows.Poisson        → CTLie.Poisson
#   CTFlows.∂ₜ             → CTLie.∂ₜ
#   CTFlows.@Lie           → CTLie.@Lie
#   CTFlows.HamiltonianLift → CTLie.LiftedHamiltonianFunction   (renamed)
#   CTFlows.⋅              → removed, no replacement
#
# Note the constructor keyword spelling also changed: `autonomous`/`variable`
# became `is_autonomous`/`is_variable`, on `@Lie` as well as on the `Data`
# constructors.

module TestCtlie

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
using CTLie: CTLie
using CTBase: CTBase

include(joinpath(@__DIR__, "..", "..", "helpers", "reexport.jl"))
using .ReexportUtils: reexports, imports, is_exported

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtlie

# Module-level operands for the deferred `Core.eval` check below.
const LIE_X1 = VectorField(x -> [x[2], -x[1]])
const LIE_X2 = VectorField(x -> [x[1], x[2]])

function test_ctlie()
    Test.@testset "CTLie reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Generated Code Prefix" begin
            # `@Lie` emits both `CTLie.*` and `CTBase.Traits.*` in its expansion,
            # so both modules must reach the call site.
            Test.@test isdefined(OptimalControl, :CTLie)
            Test.@test isdefined(CurrentModule, :CTLie)
            Test.@test CTLie isa Module
            Test.@test isdefined(CurrentModule, :CTBase)
        end

        Test.@testset "Differential geometry" begin
            for f in (:ad, :Lift, :Poisson, :∂ₜ)
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTLie)
                    Test.@test isdefined(CurrentModule, f)
                end
            end
        end

        Test.@testset "AD backend control" begin
            for f in (:dg_ad_backend, :dg_ad_backend!)
                Test.@test reexports(OptimalControl, f, CTLie)
                Test.@test isdefined(CurrentModule, f)
            end
            # It resolves to a live backend only because
            # `CTBaseDifferentiationInterface` is armed — see
            # suite/extensions/test_extensions_armed.jl.
            Test.@test dg_ad_backend() isa CTBase.Differentiation.AbstractADBackend
        end

        Test.@testset "Macros" begin
            Test.@test reexports(OptimalControl, Symbol("@Lie"), CTLie)
            Test.@test isdefined(CurrentModule, Symbol("@Lie"))
        end

        Test.@testset "Types" begin
            # `LiftedHamiltonianFunction` is imported, not re-exported.
            Test.@test imports(OptimalControl, :LiftedHamiltonianFunction, CTLie)
        end

        Test.@testset "Removed API" begin
            # `Lie` was renamed to `ad`; `⋅` was dropped with no replacement.
            # Both must be gone from the public surface.
            Test.@test !is_exported(OptimalControl, :Lie)
            Test.@test !is_exported(OptimalControl, :⋅)
            Test.@test !isdefined(OptimalControl, :HamiltonianLift)
        end

        # ====================================================================
        # SEMANTICS
        # ====================================================================

        Test.@testset "Type Hierarchy" begin
            # ⚠️ Semantic break, not cosmetic: the old `HamiltonianLift` was a
            # `Hamiltonian`. `LiftedHamiltonianFunction` is a bare `Function`.
            Test.@test OptimalControl.LiftedHamiltonianFunction <: Function
            Test.@test !(OptimalControl.LiftedHamiltonianFunction <: AbstractHamiltonian)
        end

        Test.@testset "Lift" begin
            # `Lift` is overloaded on input type.
            X = VectorField(x -> [x[2], -x[1]])
            H = Lift(X)
            Test.@test H isa Hamiltonian          # from a vector field
            Test.@test H([1.0, 2.0], [3.0, 4.0]) ≈ 3.0 * 2.0 + 4.0 * (-1.0)

            H2 = Lift(x -> [x[2], -x[1]])
            Test.@test H2 isa OptimalControl.LiftedHamiltonianFunction  # from a Function
            Test.@test !(H2 isa AbstractHamiltonian)
            Test.@test H2([1.0, 2.0], [3.0, 4.0]) ≈ H([1.0, 2.0], [3.0, 4.0])
        end

        Test.@testset "ad" begin
            X = VectorField(x -> [x[2], -x[1]])
            Y = VectorField(x -> [x[1], 0.0])
            Z = ad(X, Y)
            Test.@test Z isa VectorField
            Test.@test Z([1.0, 2.0]) ≈ [2.0, 1.0]

            # `ad` on a scalar field is the Lie derivative.
            f = x -> x[1]^2 + x[2]^2
            Test.@test ad(X, f)([1.0, 2.0]) ≈ 0.0  # rotation preserves the norm
        end

        Test.@testset "Poisson" begin
            H1 = Hamiltonian((x, p) -> x[1] * p[1])
            H2 = Hamiltonian((x, p) -> x[2] * p[2])
            Test.@test Poisson(H1, H2) isa Hamiltonian
            Test.@test Poisson(H1, H2)([1.0, 2.0], [3.0, 4.0]) ≈ 0.0
        end

        Test.@testset "∂ₜ" begin
            df = ∂ₜ((t, x) -> t * x)
            Test.@test df isa Function
            Test.@test df(0, 8) ≈ 8
            Test.@test df(2, 3) ≈ 3
            Test.@test ∂ₜ((t, x, p) -> t^2 + x[1] * p[1])(3, [1, 2], [4, 5]) ≈ 6
        end

        Test.@testset "@Lie macro" begin
            Test.@testset "with Data objects" begin
                X1 = VectorField(x -> [x[2], -x[1]])
                X2 = VectorField(x -> [x[1], x[2]])
                Test.@test (@Lie [X1, X2]) isa VectorField
                Test.@test (@Lie [[X1, X2], VectorField(x -> [2x[1], 3x[2]])]) isa VectorField

                H1 = Hamiltonian((x, p) -> x[1] * p[1])
                H2 = Hamiltonian((x, p) -> x[2] * p[2])
                Test.@test (@Lie {H1, H2}) isa Hamiltonian
            end

            Test.@testset "with plain functions — autonomous" begin
                X(x) = [x[2], -x[1]]
                Y(x) = [x[1], x[2]]
                Z = @Lie [X, Y]
                Test.@test Z isa VectorField
                Test.@test Z([1.0, 2.0]) ≈ ad(VectorField(X), VectorField(Y))([1.0, 2.0])
            end

            Test.@testset "with plain functions — is_autonomous=false" begin
                # ⚠️ keyword renamed: `autonomous` → `is_autonomous`
                X(t, x) = [t + x[2], -x[1]]
                Y(t, x) = [x[1], t * x[2]]
                Z = @Lie [X, Y] is_autonomous = false
                Test.@test Z isa VectorField
                Test.@test Z(1.0, [1.0, 2.0]) isa AbstractVector

                Zref = @Lie [
                    VectorField(X; is_autonomous=false), VectorField(Y; is_autonomous=false)
                ]
                Test.@test Z(1.0, [1.0, 2.0]) ≈ Zref(1.0, [1.0, 2.0])
            end

            Test.@testset "with plain functions — is_variable=true" begin
                # ⚠️ keyword renamed: `variable` → `is_variable`
                X(x, v) = [x[2] + v, -x[1]]
                Y(x, v) = [x[1], x[2] + v]
                Z = @Lie [X, Y] is_variable = true
                Test.@test Z isa VectorField
                Test.@test Z([1.0, 2.0], 1.0) isa AbstractVector

                Zref = @Lie [
                    VectorField(X; is_variable=true), VectorField(Y; is_variable=true)
                ]
                Test.@test Z([1.0, 2.0], 1.0) ≈ Zref([1.0, 2.0], 1.0)
            end

            Test.@testset "with plain functions — both" begin
                X(t, x, v) = [t + x[2] + v, -x[1]]
                Y(t, x, v) = [x[1], t * x[2] + v]
                Z = @Lie [X, Y] is_autonomous = false is_variable = true
                Test.@test Z isa VectorField
                Test.@test Z(1.0, [1.0, 2.0], 1.0) isa AbstractVector
            end

            Test.@testset "old keyword spelling is rejected" begin
                # `@Lie` fails at *expansion* time, so the call has to be
                # deferred through `Core.eval` — writing it inline would break
                # the whole file at load.
                Test.@test_throws OptimalControl.IncorrectArgument Core.eval(
                    CurrentModule, :(OptimalControl.@Lie [LIE_X1, LIE_X2] autonomous = false)
                )
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctlie() = TestCtlie.test_ctlie()

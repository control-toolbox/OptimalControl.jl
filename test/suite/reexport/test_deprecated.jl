# ============================================================================
# Deprecation shims tests
# ============================================================================
# Every v2.0 spelling removed in v2.1.0-beta must fail loudly with a
# CTBase.PreconditionError that names its replacement.

module TestDeprecated

using Test: Test
using OptimalControl
using LinearAlgebra: LinearAlgebra

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function check_shim(thunk, expected_old, expected_new)
    e = try
        thunk()
        nothing
    catch err
        err
    end
    Test.@test e isa OptimalControl.PreconditionError
    Test.@test occursin("deprecated", e.msg)
    Test.@test occursin(expected_old, e.msg)
    Test.@test occursin(expected_new, e.suggestion)
    return nothing
end

function test_deprecated()
    Test.@testset "Deprecated v2.0 shims" verbose = VERBOSE showtiming = SHOWTIMING begin
        X = VectorField(x -> [x[2], -x[1]])
        f = x -> x[1]^2 + x[2]^2
        Y = VectorField(x -> [x[1], x[2]])

        Test.@testset "Lie" begin
            check_shim(() -> Lie(X, f), "Lie", "ad")
            check_shim(() -> Lie(X, Y), "Lie", "ad")
        end

        Test.@testset "dot \\cdot" begin
            Test.@test getfield(OptimalControl, :⋅) === LinearAlgebra.dot
            check_shim(() -> X ⋅ f, "\\cdot", "ad")
        end

        Test.@testset "HamiltonianLift" begin
            check_shim(() -> HamiltonianLift(), "HamiltonianLift", "Lift")
            check_shim(() -> HamiltonianLift(X), "HamiltonianLift", "Lift")
        end
    end
end

end # module

test_deprecated() = TestDeprecated.test_deprecated()

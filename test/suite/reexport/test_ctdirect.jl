# ============================================================================
# CTDirect Reexports Tests
# ============================================================================
# ⚠️ CTDirect shrank in v2.1.0-beta. `AbstractDiscretizer` and the `discretize`
# generic are now *owned* by `CTSolvers.DOCP`; CTDirect only implements them.
# Their assertions live in test_ctsolvers.jl.
#
# The names did not change, so the old `isdefined` assertions kept passing
# through the move without noticing it. What is checked here is the part that
# is genuinely CTDirect's — the concrete discretizers — plus the fact that the
# implementation still plugs into the CTSolvers-owned abstraction.

module TestCtdirect

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
using CTDirect: CTDirect
using CTSolvers: CTSolvers

include(joinpath(@__DIR__, "..", "..", "helpers", "reexport.jl"))
using .ReexportUtils: imports, is_exported

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtdirect

function test_ctdirect()
    Test.@testset "CTDirect reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Discretizer types" begin
            Test.@test imports(OptimalControl, :Collocation, CTDirect)
            Test.@test !isdefined(CurrentModule, :Collocation)
            Test.@test OptimalControl.Collocation isa DataType ||
                OptimalControl.Collocation isa UnionAll
        end

        Test.@testset "Ownership after the move" begin
            # The abstraction belongs to CTSolvers now…
            Test.@test parentmodule(OptimalControl.AbstractDiscretizer) === CTSolvers.DOCP
            Test.@test parentmodule(discretize) === CTSolvers.DOCP
            # …and CTDirect implements it.
            Test.@test OptimalControl.Collocation <: OptimalControl.AbstractDiscretizer
            Test.@test any(m -> parentmodule(m) === CTDirect, methods(discretize))
        end

        Test.@testset "Method Signatures" begin
            Test.@test hasmethod(
                discretize, Tuple{OptimalControl.AbstractModel,OptimalControl.Collocation}
            )
        end

        Test.@testset "Discretization works end to end" begin
            ocp = @def begin
                t ∈ [0, 1], time
                x ∈ R², state
                u ∈ R, control
                x(0) == [-1, 0]
                x(1) == [0, 0]
                ẋ(t) == [x₂(t), u(t)]
                ∫(0.5u(t)^2) → min
            end
            docp = discretize(ocp, OptimalControl.Collocation(; grid_size=20))
            Test.@test docp isa OptimalControl.DiscretizedModel
            Test.@test ocp_model(docp) === ocp
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctdirect() = TestCtdirect.test_ctdirect()

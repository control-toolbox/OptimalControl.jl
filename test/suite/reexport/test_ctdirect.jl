# ============================================================================
# CTDirect Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTDirect`. It verifies that
# the expected types and functions related to direct discretization methods
# are properly exported by `OptimalControl`.

module TestCtdirect

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtdirect

function test_ctdirect()
    Test.@testset "CTDirect reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Types" begin
            for T in (OptimalControl.AbstractDiscretizer, OptimalControl.Collocation)
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "Functions" begin
            Test.@test isdefined(OptimalControl, :discretize)
            Test.@test isdefined(CurrentModule, :discretize)
            Test.@test discretize isa Function
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctdirect() = TestCtdirect.test_ctdirect()

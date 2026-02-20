# ============================================================================
# CTParser Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTParser`. It verifies that
# the `@def` macro and related parsing utilities are properly exported by
# `OptimalControl` for user-friendly problem definition.

module TestCtparser

import Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtparser

function test_ctparser()
    Test.@testset "CTParser reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Macros" begin
            Test.@test isdefined(OptimalControl, Symbol("@def"))
            Test.@test isdefined(CurrentModule, Symbol("@def"))
            Test.@test isdefined(OptimalControl, Symbol("@init"))
            Test.@test isdefined(CurrentModule, Symbol("@init"))
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctparser() = TestCtparser.test_ctparser()
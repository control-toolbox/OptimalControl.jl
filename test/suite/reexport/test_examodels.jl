# ============================================================================
# ExaModels Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `ExaModels`. It verifies that
# the expected types and functions related to the ExaModels backend are
# properly exported by `OptimalControl`.

module TestExamodels

import Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestExamodels

function test_examodels()
    Test.@testset "ExaModels reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Generated Code Prefix" begin
            Test.@test isdefined(OptimalControl, :ExaModels)
            Test.@test isdefined(CurrentModule, :ExaModels)
            Test.@test ExaModels isa Module
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_examodels() = TestExamodels.test_examodels()
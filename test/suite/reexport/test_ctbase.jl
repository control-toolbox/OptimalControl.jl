# ============================================================================
# CTBase Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTBase`. It verifies that
# the expected types, functions, and constants are properly exported by
# `OptimalControl` and readily accessible to the end user.

module TestCtbase

import Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtbase

function test_ctbase()
    Test.@testset "CTBase reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        
        Test.@testset "Generated Code Prefix" begin
            Test.@test isdefined(OptimalControl, :CTBase)
            Test.@test isdefined(CurrentModule, :CTBase)
            Test.@test CTBase isa Module
        end

        Test.@testset "Exceptions" begin
            for T in (
                OptimalControl.CTException,
                OptimalControl.IncorrectArgument,
                OptimalControl.PreconditionError,
                OptimalControl.NotImplemented,
                OptimalControl.ParsingError,
                OptimalControl.AmbiguousDescription,
                OptimalControl.ExtensionError,
            )
                Test.@test isdefined(OptimalControl, nameof(T)) # check if defined in OptimalControl
                Test.@test !isdefined(CurrentModule, nameof(T)) # check if exported
                Test.@test T isa DataType
            end
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctbase() = TestCtbase.test_ctbase()
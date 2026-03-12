# ============================================================================
# OptimalControl Specific Exports Tests
# ============================================================================
# This file tests the exports that are specific to the `OptimalControl` package
# itself, ensuring that its native API functions (like `methods`) are correctly
# exposed to the user.

module TestOptimalControl

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestOptimalControl

function test_optimalcontrol()
    Test.@testset "OptimalControl exports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Functions" begin
            for f in (:methods,)
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_optimalcontrol() = TestOptimalControl.test_optimalcontrol()

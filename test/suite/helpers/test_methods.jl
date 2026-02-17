module TestAvailableMethods

import Test
import OptimalControl

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_methods()
    Test.@testset "methods Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS
        # ====================================================================

        Test.@testset "Return Type" begin
            methods = OptimalControl.methods()
            Test.@test methods isa Tuple
            Test.@test all(m -> m isa Tuple{Symbol, Symbol, Symbol}, methods)
        end

        Test.@testset "Content Verification" begin
            methods = OptimalControl.methods()

            Test.@test (:collocation, :adnlp, :ipopt) in methods
            Test.@test (:collocation, :adnlp, :madnlp) in methods
            Test.@test (:collocation, :adnlp, :knitro) in methods
            Test.@test (:collocation, :exa, :ipopt) in methods
            Test.@test (:collocation, :exa, :madnlp) in methods
            Test.@test (:collocation, :exa, :knitro) in methods
            Test.@test length(methods) == 6
        end

        Test.@testset "Uniqueness" begin
            methods = OptimalControl.methods()
            Test.@test length(methods) == length(unique(methods))
        end

        Test.@testset "Determinism" begin
            m1 = OptimalControl.methods()
            m2 = OptimalControl.methods()
            Test.@test m1 === m2
        end
    end
end

end # module

test_methods() = TestAvailableMethods.test_methods()

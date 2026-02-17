module TestAvailableMethods

using Test
using OptimalControl
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_available_methods()
    @testset "available_methods Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS
        # ====================================================================

        @testset "Return Type" begin
            methods = OptimalControl.available_methods()
            @test methods isa Tuple
            @test all(m -> m isa Tuple{Symbol, Symbol, Symbol}, methods)
        end

        @testset "Content Verification" begin
            methods = OptimalControl.available_methods()

            @test (:collocation, :adnlp, :ipopt) in methods
            @test (:collocation, :adnlp, :madnlp) in methods
            @test (:collocation, :adnlp, :knitro) in methods
            @test (:collocation, :exa, :ipopt) in methods
            @test (:collocation, :exa, :madnlp) in methods
            @test (:collocation, :exa, :knitro) in methods
            @test length(methods) == 6
        end

        @testset "Uniqueness" begin
            methods = OptimalControl.available_methods()
            @test length(methods) == length(unique(methods))
        end

        @testset "Determinism" begin
            m1 = OptimalControl.available_methods()
            m2 = OptimalControl.available_methods()
            @test m1 === m2
        end
    end
end

end # module

test_available_methods() = TestAvailableMethods.test_available_methods()

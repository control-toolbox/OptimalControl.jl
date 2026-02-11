module TestExamodels

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_examodels()
    @testset "ExaModels reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        @testset "Generated Code Prefix" begin
            @test isdefined(OptimalControl, :ExaModels)
            @test isdefined(Main, :ExaModels)
            @test ExaModels isa Module
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_examodels() = TestExamodels.test_examodels()
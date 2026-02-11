module TestCtparser

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_ctparser()
    @testset "CTParser reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        @testset "Macros" begin
            @test isdefined(OptimalControl, Symbol("@def"))
            @test isdefined(Main, Symbol("@def"))
            @test isdefined(OptimalControl, Symbol("@init"))
            @test isdefined(Main, Symbol("@init"))
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctparser() = TestCtparser.test_ctparser()
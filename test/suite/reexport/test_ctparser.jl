module TestCtparser

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtparser

function test_ctparser()
    @testset "CTParser reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        @testset "Macros" begin
            @test isdefined(OptimalControl, Symbol("@def"))
            @test isdefined(CurrentModule, Symbol("@def"))
            @test isdefined(OptimalControl, Symbol("@init"))
            @test isdefined(CurrentModule, Symbol("@init"))
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctparser() = TestCtparser.test_ctparser()
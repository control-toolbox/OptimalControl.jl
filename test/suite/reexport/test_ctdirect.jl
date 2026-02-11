module TestCtdirect

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_ctdirect()
    @testset "CTDirect reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        @testset "Types" begin
            for T in (
                AbstractOptimalControlDiscretizer,
                Collocation,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Functions" begin
            @test isdefined(OptimalControl, :discretize)
            @test discretize isa Function
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctdirect() = TestCtdirect.test_ctdirect()
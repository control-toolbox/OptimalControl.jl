module TestCtbase

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_ctbase()
    @testset "CTBase reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        
        @testset "Generated Code Prefix" begin
            @test isdefined(OptimalControl, :CTBase)
            @test isdefined(Main, :CTBase)
            @test CTBase isa Module
        end

        @testset "Exceptions" begin
            for T in (
                CTException,
                IncorrectArgument,
                PreconditionError,
                NotImplemented,
                ParsingError,
                AmbiguousDescription,
                ExtensionError,
            )
                @test isdefined(OptimalControl, nameof(T)) # check if defined in OptimalControl
                @test isdefined(Main, nameof(T)) # check if exported
                @test T isa DataType
            end
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctbase() = TestCtbase.test_ctbase()
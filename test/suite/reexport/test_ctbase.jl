module TestCtbase

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtbase

function test_ctbase()
    @testset "CTBase reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        
        @testset "Generated Code Prefix" begin
            @test isdefined(OptimalControl, :CTBase)
            @test isdefined(CurrentModule, :CTBase)
            @test CTBase isa Module
        end

        @testset "Exceptions" begin
            for T in (
                OptimalControl.CTException,
                OptimalControl.IncorrectArgument,
                OptimalControl.PreconditionError,
                OptimalControl.NotImplemented,
                OptimalControl.ParsingError,
                OptimalControl.AmbiguousDescription,
                OptimalControl.ExtensionError,
            )
                @test isdefined(OptimalControl, nameof(T)) # check if defined in OptimalControl
                @test !isdefined(CurrentModule, nameof(T)) # check if exported
                @test T isa DataType
            end
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctbase() = TestCtbase.test_ctbase()
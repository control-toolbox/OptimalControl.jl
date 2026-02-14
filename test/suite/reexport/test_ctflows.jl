module TestCtflows

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtflows

function test_ctflows()
    @testset "CTFlows reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        @testset "Types" begin
            for T in (
                OptimalControl.Hamiltonian,
                OptimalControl.HamiltonianLift,
                OptimalControl.HamiltonianVectorField,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test !isdefined(CurrentModule, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Functions" begin
            for f in (
                :Lift,
                :Flow,
            )
                @test isdefined(OptimalControl, f)
                @test isdefined(CurrentModule, f)
                @test getfield(OptimalControl, f) isa Function
            end
        end
        @testset "Operators" begin
            for op in (
                :⋅,
                :Lie,
                :Poisson,
                :*,
            )
                @test isdefined(OptimalControl, op)
                @test isdefined(CurrentModule, op)
            end
        end
        @testset "Macros" begin
            @test isdefined(OptimalControl, Symbol("@Lie"))
            @test isdefined(CurrentModule, Symbol("@Lie"))
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctflows() = TestCtflows.test_ctflows()
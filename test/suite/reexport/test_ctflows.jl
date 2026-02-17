module TestCtflows

import Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtflows

function test_ctflows()
    Test.@testset "CTFlows reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Types" begin
            for T in (
                OptimalControl.Hamiltonian,
                OptimalControl.HamiltonianLift,
                OptimalControl.HamiltonianVectorField,
            )
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "Functions" begin
            for f in (
                :Lift,
                :Flow,
            )
                Test.@test isdefined(OptimalControl, f)
                Test.@test isdefined(CurrentModule, f)
                Test.@test getfield(OptimalControl, f) isa Function
            end
        end
        Test.@testset "Operators" begin
            for op in (
                :⋅,
                :Lie,
                :Poisson,
                :*,
            )
                Test.@test isdefined(OptimalControl, op)
                Test.@test isdefined(CurrentModule, op)
            end
        end
        Test.@testset "Macros" begin
            Test.@test isdefined(OptimalControl, Symbol("@Lie"))
            Test.@test isdefined(CurrentModule, Symbol("@Lie"))
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctflows() = TestCtflows.test_ctflows()
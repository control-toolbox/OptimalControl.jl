# ============================================================================
# CTFlows Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTFlows`. It verifies that
# the expected types and functions for Hamiltonian flows and dynamics
# are properly exported by `OptimalControl`.

module TestCtflows

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
import CTFlows # needed for abstract type checks

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
            for f in (:Lift, :Flow)
                Test.@test isdefined(OptimalControl, f)
                Test.@test isdefined(CurrentModule, f)
                Test.@test getfield(OptimalControl, f) isa Function
            end
        end
        Test.@testset "Operators" begin
            for op in (:⋅, :Lie, :Poisson, :*)
                Test.@test isdefined(OptimalControl, op)
                Test.@test isdefined(CurrentModule, op)
            end
        end
        Test.@testset "Macros" begin
            Test.@test isdefined(OptimalControl, Symbol("@Lie"))
            Test.@test isdefined(CurrentModule, Symbol("@Lie"))
        end

        Test.@testset "Type Hierarchy" begin
            Test.@test OptimalControl.Hamiltonian <: CTFlows.AbstractHamiltonian
            Test.@test OptimalControl.HamiltonianLift <: CTFlows.AbstractHamiltonian
            Test.@test OptimalControl.HamiltonianVectorField <: CTFlows.AbstractVectorField
        end

        Test.@testset "Method Signatures" begin
            Test.@testset "Lift" begin
                Test.@test hasmethod(Lift, Tuple{CTFlows.VectorField})
                Test.@test hasmethod(Lift, Tuple{Function})
            end
            Test.@testset "Flow" begin
                Test.@test hasmethod(Flow, Tuple{Vararg{Any}})
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctflows() = TestCtflows.test_ctflows()

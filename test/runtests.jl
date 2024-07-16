using OptimalControl
using Test
using LinearAlgebra
using SciMLBase
using NonlinearSolve
using OrdinaryDiffEq
using NLPModelsIpopt

include("Goddard.jl")

#
@testset verbose = true showtiming = true "Optimal control tests" begin
    for name ∈ (
        :basic,
        :goddard_direct,
        :goddard_indirect,
        :grid,
        :init,
        )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            println("\nTesting: "*string(name))
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end
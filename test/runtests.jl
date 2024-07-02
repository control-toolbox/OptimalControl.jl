using OptimalControl
using Test
using LinearAlgebra
using CTProblems
using SciMLBase
using NonlinearSolve

using NLPModelsIpopt # for direct solve
using HSL # for direct solve
using DifferentialEquations # for indirect and goddard from CTProblems; quite slow, maybe use ony in related test scripts instead of here ?

#
@testset verbose = true showtiming = true "Optimal control tests" begin
    for name ∈ (
        :basic,
        :goddard_direct,
        :goddard_indirect,
        :init,
        )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end

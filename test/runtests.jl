using OptimalControl
using Test
using LinearAlgebra
using MINPACK
using CTProblems

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

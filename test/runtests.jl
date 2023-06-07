using OptimalControl
using Test
using LinearAlgebra
using MINPACK
using CTProblems

#
@testset verbose = true showtiming = true "Optimal control tests" begin
    for name in (
        "goddard_direct",
        "goddard_indirect",
        )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end

using Test
using OptimalControl
using NLPModelsIpopt
using LinearAlgebra
using OrdinaryDiffEq
using MINPACK
using DifferentiationInterface
import ForwardDiff
using SplitApplyCombine # for flatten in some tests

@testset verbose = true showtiming = true "Optimal control tests" begin

#= debug
    # ctdirect tests
    @testset verbose = true showtiming = true "CTDirect tests" begin
        # run all scripts in subfolder suite/
        include.(filter(contains(r".jl$"), readdir("./ctdirect/suite"; join=true)))
    end
=#
    # other tests: indirect
    include("./indirect/Goddard.jl")
    for name in (:goddard_indirect,)
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            println("Testing: " * string(name))
            include("./indirect/$(test_name).jl")
            @eval $test_name()
        end
    end
end
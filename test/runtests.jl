using Test
using OptimalControl
using NLPModelsIpopt
using MadNLP
using LinearAlgebra
using OrdinaryDiffEq
using MINPACK
using DifferentiationInterface
using ForwardDiff: ForwardDiff
using SplitApplyCombine # for flatten in some tests

# NB some direct tests use functional definition and are `using CTModels`

@testset verbose = true showtiming = true "Optimal control tests" begin

    # ctdirect tests
    @testset verbose = true showtiming = true "CTDirect tests" begin
        # run all scripts in subfolder suite/
        include.(filter(contains(r"test_exa.jl$"), readdir("./ctdirect/suite"; join=true)))
    end

    # # other tests: indirect
    # include("./indirect/Goddard.jl")
    # for name in (:goddard_indirect,)
    #     @testset "$(name)" begin
    #         test_name = Symbol(:test_, name)
    #         println("Testing: " * string(name))
    #         include("./indirect/$(test_name).jl")
    #         @eval $test_name()
    #     end
    # end
end

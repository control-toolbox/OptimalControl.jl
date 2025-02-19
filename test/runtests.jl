using OptimalControl
using Test

using LinearAlgebra
using SciMLBase
using NonlinearSolve
using OrdinaryDiffEq

using CTDirect
using NLPModelsIpopt
using MadNLP
using SplitApplyCombine # for flatten in some tests

include("Goddard.jl")

@testset verbose = true showtiming = true "Optimal control tests" begin
    
    # ctdirect tests
    @testset verbose = true showtiming = true "CTDirect tests" begin
        # run all scripts in subfolder suite/
        include.(filter(contains(r".jl$"), readdir("./suite"; join = true)))
    end

    # other tests
    for name in (
        :goddard_indirect,
        )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            println("Testing: " * string(name))
            include("$(test_name).jl")
            @eval $test_name()
        end
    end

end

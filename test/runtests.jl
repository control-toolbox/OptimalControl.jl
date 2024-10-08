using OptimalControl
using Test
using LinearAlgebra
using SciMLBase
using NonlinearSolve
using OrdinaryDiffEq
using NLPModelsIpopt
using CTDirect

include("Goddard.jl")
include("problems/goddard.jl")

#
@testset verbose = true showtiming = true "Optimal control tests" begin
    for name in (
        :abstract_ocp,
        :basic,
        :continuation,
        :goddard_direct,
        :goddard_indirect,
        :grid,
        :initial_guess,
        :objective,
    )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            println("Testing: " * string(name))
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end

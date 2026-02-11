using Test
using ADNLPModels
using CommonSolve
using CTBase
using CTDirect
using CTModels
using CTSolvers
using OptimalControl
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using NLPModels
using LinearAlgebra
using OrdinaryDiffEq
using DifferentiationInterface
using ForwardDiff: ForwardDiff
using NonlinearSolve
using SolverCore
using SplitApplyCombine # for flatten in some tests

# NB some direct tests use functional definition and are `using CTModels`

# @testset verbose = true showtiming = true "Optimal control tests" begin

#     # ctdirect tests
#     @testset verbose = true showtiming = true "CTDirect tests" begin
#         # run all scripts in subfolder suite/
#         include.(filter(contains(r".jl$"), readdir("./ctdirect/suite"; join=true)))
#     end

#     # other tests: indirect
#     include("./indirect/Goddard.jl")
#     for name in (:goddard_indirect,)
#         @testset "$(name)" begin
#             test_name = Symbol(:test_, name)
#             println("Testing: " * string(name))
#             include("./indirect/$(test_name).jl")
#             @eval $test_name()
#         end
#     end
# end

const VERBOSE = true
const SHOWTIMING = true

include(joinpath(@__DIR__, "problems", "beam.jl"))
include(joinpath(@__DIR__, "problems", "goddard.jl"))

@testset verbose = VERBOSE showtiming = SHOWTIMING "Optimal control tests" begin
    include(joinpath(@__DIR__, "test_optimalcontrol_solve_api.jl"))
    test_optimalcontrol_solve_api()
end
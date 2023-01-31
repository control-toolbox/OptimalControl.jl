using OptimalControl
using Test
using Plots
using LinearAlgebra

# functions and types that are not exported
const convert               = OptimalControl.convert
const __grid_size           = OptimalControl.__grid_size
const __init                = OptimalControl.__init
const __grid                = OptimalControl.__grid
const __init_interpolation  = OptimalControl.__init_interpolation
const vec2vec               = OptimalControl.vec2vec
const make_udss_init        = OptimalControl.make_udss_init
const convert_init          = OptimalControl.convert_init

#
@testset verbose = true showtiming = true "Optimal control tests" begin
    for name in (
        #"utils", 
        #"optimal_control", 
        #"udss", # unconstrained direct simple shooting
        #"model",
        "model_goddard",
        )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end

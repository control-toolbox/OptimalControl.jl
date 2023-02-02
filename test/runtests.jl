using OptimalControl
using Test
using Plots
using LinearAlgebra
using LabelledArrays
using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using MINPACK

# method to compute gradient and Jacobian
∇(f::Function, x) = ForwardDiff.gradient(f, x)
Jac(f::Function, x) = ForwardDiff.jacobian(f, x)

# functions and types that are not exported
const convert               = OptimalControl.convert
const __grid_size           = OptimalControl.__grid_size
const __init                = OptimalControl.__init
const __grid                = OptimalControl.__grid
const __init_interpolation  = OptimalControl.__init_interpolation
const vec2vec               = OptimalControl.vec2vec
const make_udss_init        = OptimalControl.make_udss_init
const convert_init          = OptimalControl.convert_init
const nlp_constraints       = OptimalControl.nlp_constraints

#
@testset verbose = true showtiming = true "Optimal control tests" begin
    for name in (
        #"utils", 
        #"optimal_control", 
        #"udss", # unconstrained direct simple shooting
        "basic",
        "goddard",
        )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end

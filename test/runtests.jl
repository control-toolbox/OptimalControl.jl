using OptimalControl
using Test
using Plots
using LinearAlgebra
using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using MINPACK

# method to compute gradient and Jacobian
∇(f::Function, x) = ForwardDiff.gradient(f, x)
Jac(f::Function, x) = ForwardDiff.jacobian(f, x)

# functions and types that are not exported
const __grid_size_direct_shooting = OptimalControl.__grid_size_direct_shooting
const __init                = OptimalControl.__init
const __grid                = OptimalControl.__grid
const __init_interpolation  = OptimalControl.__init_interpolation
const CTOptimizationInit    = OptimalControl.CTOptimizationInit
const DirectShootingSolution = OptimalControl.DirectShootingSolution
const convert_init          = OptimalControl.convert_init
const vec2vec               = OptimalControl.vec2vec
const nlp_constraints       = OptimalControl.nlp_constraints

#
@testset verbose = true showtiming = true "Optimal control tests" begin
    for name in (
        "utils", 
        "direct_shooting_CTOptimization", # unconstrained direct simple shooting
        "basic",
        "goddard_direct",
        "goddard_indirect",
        )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end

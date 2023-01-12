using OptimalControl
using Test
using Plots
using LinearAlgebra

# functions and types that are not exported
const DescentProblem        = OptimalControl.DescentProblem
const DescentOCPSol         = OptimalControl.DescentOCPSol
const DescentInit           = OptimalControl.DescentInit
const descent_solver        = OptimalControl.descent_solver
const descent_read          = OptimalControl.descent_read
const convert               = OptimalControl.convert
const ocp2descent_init      = OptimalControl.ocp2descent_init
const __grid_size           = OptimalControl.__grid_size
const __init                = OptimalControl.__init
const __grid                = OptimalControl.__grid
const __init_interpolation  = OptimalControl.__init_interpolation
const vec2vec               = OptimalControl.vec2vec

#
@testset verbose = true showtiming = true "Control Toolbox" begin
    for name in (
        "utils", 
        "callbacks", 
        "exceptions", 
        "optimal_control", 
        "convert", 
        "descent"
        )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end

using OptimalControl
using Test
using Plots
using LinearAlgebra
using MINPACK
using CTProblemLibrary

# functions and types that are not exported

# CTDirectShooting
const CTOptimizationInit = OptimalControl.CTDirectShooting.CTOptimizationInit
const convert_init = OptimalControl.CTDirectShooting.convert_init
const __init = OptimalControl.CTDirectShooting.__init
const __grid = OptimalControl.CTDirectShooting.__grid

# CTBase
const vec2vec  = OptimalControl.CTBase.vec2vec
const __grid_size_direct_shooting = OptimalControl.CTBase.__grid_size_direct_shooting
const __init_interpolation = OptimalControl.CTBase.__init_interpolation
const __display = OptimalControl.CTBase.__display

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

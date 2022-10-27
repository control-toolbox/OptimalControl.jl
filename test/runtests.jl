using ControlToolbox
using Plots
using Test
using LinearAlgebra

@testset verbose=true showtiming=true "Control Toolbox" begin
    for name in (
        "utils",
        "description",
        "callbacks",
        "exceptions",
        "ocp",
        "convert",
        "descent",
    )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end
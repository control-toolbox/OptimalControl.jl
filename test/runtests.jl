using ControlToolbox
using Plots
using Test
using LinearAlgebra
#using Logging

@testset verbose=true showtiming=true "Control Toolbox" begin
    for name in (
        #"utils",
        #"description",
        #"callbacks",
        #"exceptions",
        #"ocp",
        #"convert",
        "descent",
        #"flows",
    )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end
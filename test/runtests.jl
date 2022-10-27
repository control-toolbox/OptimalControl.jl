using ControlToolbox
using Plots
using Test

for name in (
    "utils",
    "descent",
    "ocp-def",
    "exceptions",
)
    @testset "$name" begin
        include("test_$name.jl")
    end
end
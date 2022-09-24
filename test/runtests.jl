using ControlToolbox
using Test

for name in (
    "utils",
)
    @testset "$name" begin
        include("test_$name.jl")
    end
end
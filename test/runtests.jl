using ControlToolbox
using Test

@testset "ControlToolbox.jl" begin
    @test ControlToolbox.hello() == "Hello ControlToolbox"
    @test ControlToolbox.hello() != "Hello world!"
end
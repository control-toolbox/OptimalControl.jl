@testset "Hello" begin
    @test ControlToolbox.hello() == "Hello ControlToolbox"
    @test ControlToolbox.hello() != "Hello world!"
end
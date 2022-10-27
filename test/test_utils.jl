#@testset "Hello" begin
    @test ControlToolbox.hello() == "Hello Control Toolbox!"
    @test ControlToolbox.hello() != "Hello world!"
#end
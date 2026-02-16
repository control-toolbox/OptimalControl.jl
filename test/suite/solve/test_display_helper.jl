module TestDisplayHelper

using Test
import OptimalControl
import NLPModelsIpopt

# Entry point
function test_display_helper()
    @testset "Display helper - compact default" begin
        disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
        mod = OptimalControl.ADNLPModeler()
        sol = OptimalControl.IpoptSolver(print_level=0)

        io = IOBuffer()
        OptimalControl.display_ocp_configuration(io, disc, mod, sol;
            display=true, show_options=false, show_sources=false)
        out = String(take!(io))

        @test occursin("Discretizer: collocation", out)
        @test occursin("Modeler: adnlp", out)
        @test occursin("Solver: ipopt", out)
        @test !occursin("[user]", out)  # compact mode without sources
    end

    @testset "Display helper - hide options" begin
        disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
        mod = OptimalControl.ADNLPModeler()
        sol = OptimalControl.IpoptSolver(print_level=0)

        io = IOBuffer()
        OptimalControl.display_ocp_configuration(io, disc, mod, sol;
            display=true, show_options=false, show_sources=false)
        out = String(take!(io))

        @test !occursin("grid_size", out)
        @test !occursin("print_level", out)
    end

    @testset "Display helper - sources flag" begin
        disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
        mod = OptimalControl.ADNLPModeler()
        sol = OptimalControl.IpoptSolver(print_level=0)

        io = IOBuffer()
        OptimalControl.display_ocp_configuration(io, disc, mod, sol;
            display=true, show_options=true, show_sources=true)
        out = String(take!(io))

        # Just ensure it runs and still prints the ids
        @test occursin("Discretizer: collocation", out)
        @test occursin("Modeler: adnlp", out)
        @test occursin("Solver: ipopt", out)
    end
end

end # module

# Expose entry point
test_display_helper() = TestDisplayHelper.test_display_helper()

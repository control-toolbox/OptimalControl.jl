# ============================================================================
# Display and Printing Helpers Tests
# ============================================================================
# This file tests the `display_ocp_configuration` function and other printing
# utilities. It ensures that the current strategy configuration (components
# and their options) is formatted and displayed correctly to the user.

module TestPrint

import Test
import OptimalControl
import NLPModelsIpopt

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Entry point
function test_print()
    Test.@testset "Display helper - compact default" begin
        disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
        mod = OptimalControl.ADNLP()
        sol = OptimalControl.Ipopt(print_level=0)

        io = IOBuffer()
        OptimalControl.display_ocp_configuration(io, disc, mod, sol;
            display=true, show_options=false, show_sources=false)
        out = String(take!(io))

        Test.@test occursin("Discretizer: collocation", out)
        Test.@test occursin("Modeler: adnlp", out)
        Test.@test occursin("Solver: ipopt", out)
        Test.@test !occursin("[user]", out)  # compact mode without sources
    end

    Test.@testset "Display helper - hide options" begin
        disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
        mod = OptimalControl.ADNLP()
        sol = OptimalControl.Ipopt(print_level=0)

        io = IOBuffer()
        OptimalControl.display_ocp_configuration(io, disc, mod, sol;
            display=true, show_options=false, show_sources=false)
        out = String(take!(io))

        Test.@test !occursin("grid_size", out)
        Test.@test !occursin("print_level", out)
    end

    Test.@testset "Display helper - sources flag" begin
        disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
        mod = OptimalControl.ADNLP()
        sol = OptimalControl.Ipopt(print_level=0)

        io = IOBuffer()
        OptimalControl.display_ocp_configuration(io, disc, mod, sol;
            display=true, show_options=true, show_sources=true)
        out = String(take!(io))

        # Just ensure it runs and still prints the ids
        Test.@test occursin("Discretizer: collocation", out)
        Test.@test occursin("Modeler: adnlp", out)
        Test.@test occursin("Solver: ipopt", out)
    end
end

end # module

# Expose entry point
test_print() = TestPrint.test_print()

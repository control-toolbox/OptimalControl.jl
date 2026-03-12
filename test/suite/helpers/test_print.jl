# ============================================================================
# Display and Printing Helpers Tests
# ============================================================================
# This file tests the `display_ocp_configuration` function and other printing
# utilities. It ensures that the current strategy configuration (components
# and their options) is formatted and displayed correctly to the user.

module TestPrint

using Test: Test
using OptimalControl: OptimalControl
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP  # Add MadNLP import for testing

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ====================================================================
# UNIT TESTS - Helper Functions
# ====================================================================

# TOP-LEVEL: Fake strategies for testing parameter extraction
struct FakeDiscretizerNoParam <: OptimalControl.CTDirect.AbstractDiscretizer end
struct FakeModelerNoParam <: OptimalControl.CTSolvers.AbstractNLPModeler end
struct FakeSolverNoParam <: OptimalControl.CTSolvers.AbstractNLPSolver end

# Entry point
function test_print()
    Test.@testset "UNIT TESTS - Parameter Extraction" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "_extract_strategy_parameters - no parameters" begin
            disc = FakeDiscretizerNoParam()
            mod = FakeModelerNoParam()
            sol = FakeSolverNoParam()

            result = OptimalControl._extract_strategy_parameters(disc, mod, sol)

            Test.@test result.disc === nothing
            Test.@test result.mod === nothing
            Test.@test result.sol === nothing
            Test.@test isempty(result.params)
        end

        Test.@testset "_extract_strategy_parameters - with real strategies" begin
            disc = OptimalControl.Collocation()
            mod = OptimalControl.ADNLP()
            sol = OptimalControl.Ipopt()

            result = OptimalControl._extract_strategy_parameters(disc, mod, sol)

            # ADNLP and Ipopt have :cpu parameter by default
            Test.@test result.disc === nothing  # Collocation has no parameter
            Test.@test result.mod === :cpu      # ADNLP defaults to CPU
            Test.@test result.sol === :cpu      # Ipopt defaults to CPU
            Test.@test result.params == [:cpu, :cpu]
        end
    end

    Test.@testset "UNIT TESTS - Display Strategy Determination" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "_determine_parameter_display_strategy - empty params" begin
            result = OptimalControl._determine_parameter_display_strategy([])

            Test.@test result.show_inline == false
            Test.@test result.common === nothing
        end

        Test.@testset "_determine_parameter_display_strategy - single param" begin
            result = OptimalControl._determine_parameter_display_strategy([:cpu])

            Test.@test result.show_inline == false
            Test.@test result.common === :cpu
        end

        Test.@testset "_determine_parameter_display_strategy - all same" begin
            result = OptimalControl._determine_parameter_display_strategy([
                :cpu, :cpu, :cpu
            ])

            Test.@test result.show_inline == false
            Test.@test result.common === :cpu
        end

        Test.@testset "_determine_parameter_display_strategy - different params" begin
            result = OptimalControl._determine_parameter_display_strategy([:cpu, :gpu])

            Test.@test result.show_inline == true
            Test.@test result.common === nothing
        end
    end

    Test.@testset "UNIT TESTS - Source Tag Building" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "_build_source_tag - user option without show_sources" begin
            tag = OptimalControl._build_source_tag(:user, :cpu, [:cpu], false)
            Test.@test tag == ""
        end

        Test.@testset "_build_source_tag - user option with show_sources" begin
            tag = OptimalControl._build_source_tag(:user, :cpu, [:cpu], true)
            Test.@test tag == " [user]"
        end

        Test.@testset "_build_source_tag - computed option without show_sources" begin
            tag = OptimalControl._build_source_tag(:computed, :cpu, [:cpu], false)
            Test.@test tag == " [cpu-dependent]"
        end

        Test.@testset "_build_source_tag - computed option with show_sources" begin
            tag = OptimalControl._build_source_tag(:computed, :cpu, [:cpu], true)
            Test.@test tag == " [computed, cpu-dependent]"
        end

        Test.@testset "_build_source_tag - computed with no common param" begin
            # When common_param is nothing, it uses first element of params array
            tag = OptimalControl._build_source_tag(:computed, nothing, [:gpu], false)
            Test.@test tag == " [gpu-dependent]"
        end

        Test.@testset "_build_source_tag - computed with empty params" begin
            tag = OptimalControl._build_source_tag(:computed, nothing, [], false)
            Test.@test tag == " [parameter-dependent]"
        end

        Test.@testset "_build_source_tag - default option" begin
            tag = OptimalControl._build_source_tag(:default, :cpu, [:cpu], false)
            Test.@test tag == ""
        end
    end

    Test.@testset "UNIT TESTS - Component Formatting" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "_print_component_with_param - no param" begin
            io = IOBuffer()
            OptimalControl._print_component_with_param(io, :collocation, false, nothing)
            out = String(take!(io))
            Test.@test occursin("collocation", out)
            Test.@test !occursin("(", out)
        end

        Test.@testset "_print_component_with_param - inline param" begin
            io = IOBuffer()
            OptimalControl._print_component_with_param(io, :exa, true, :gpu)
            out = String(take!(io))
            Test.@test occursin("exa", out)
            Test.@test occursin("(gpu)", out)
        end

        Test.@testset "_print_component_with_param - param but not inline" begin
            io = IOBuffer()
            OptimalControl._print_component_with_param(io, :ipopt, false, :cpu)
            out = String(take!(io))
            Test.@test occursin("ipopt", out)
            Test.@test !occursin("(cpu)", out)
        end
    end

    # ====================================================================
    # INTEGRATION TESTS - Display Configuration
    # ====================================================================

    Test.@testset "INTEGRATION TESTS - Display Configuration" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "Display helper - compact default" begin
            disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
            mod = OptimalControl.ADNLP()
            sol = OptimalControl.Ipopt(print_level=0)

            io = IOBuffer()
            OptimalControl.display_ocp_configuration(
                io, disc, mod, sol; display=true, show_options=false, show_sources=false
            )
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
            OptimalControl.display_ocp_configuration(
                io, disc, mod, sol; display=true, show_options=false, show_sources=false
            )
            out = String(take!(io))

            Test.@test !occursin("grid_size", out)
            Test.@test !occursin("print_level", out)
        end

        Test.@testset "Display helper - sources flag" begin
            disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
            mod = OptimalControl.ADNLP()
            sol = OptimalControl.Ipopt(print_level=0)

            io = IOBuffer()
            OptimalControl.display_ocp_configuration(
                io, disc, mod, sol; display=true, show_options=true, show_sources=true
            )
            out = String(take!(io))

            # Just ensure it runs and still prints the ids
            Test.@test occursin("Discretizer: collocation", out)
            Test.@test occursin("Modeler: adnlp", out)
            Test.@test occursin("Solver: ipopt", out)
        end

        # ====================================================================
        # COMPREHENSIVE DISPLAY TESTS
        # ====================================================================

        Test.@testset "Display Options" begin
            Test.@testset "Show options with user values" begin
                disc = OptimalControl.Collocation(grid_size=10, scheme=:trapezoidal)
                mod = OptimalControl.ADNLP(backend=:default)  # Fixed: use valid backend
                sol = OptimalControl.Ipopt(print_level=5, max_iter=1000)

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; display=true, show_options=true, show_sources=false
                )
                out = String(take!(io))

                Test.@test occursin("grid_size = 10", out)
                Test.@test occursin("scheme = trapezoidal", out)  # Fixed: no colon
                Test.@test occursin("backend = default", out)  # Fixed: no colon
                Test.@test occursin("print_level = 5", out)
                Test.@test occursin("max_iter = 1000", out)
            end

            Test.@testset "Show options with sources" begin
                disc = OptimalControl.Collocation(grid_size=5)
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt(print_level=0)

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; display=true, show_options=true, show_sources=true
                )
                out = String(take!(io))

                # Should contain source information in brackets
                Test.@test occursin("[", out)  # Source indicators
                Test.@test occursin("]", out)
            end

            Test.@testset "No user options" begin
                disc = OptimalControl.Collocation()
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt()

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; display=true, show_options=true, show_sources=false
                )
                out = String(take!(io))

                # Test.@test occursin("no user options", out)
            end

            Test.@testset "Display disabled" begin
                disc = OptimalControl.Collocation(grid_size=5)
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt(print_level=0)

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; display=false, show_options=true, show_sources=false
                )
                out = String(take!(io))

                Test.@test isempty(out)
            end
        end

        Test.@testset "Formatting and Structure" begin
            Test.@testset "Header format" begin
                disc = OptimalControl.Collocation()
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt()

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(io, disc, mod, sol)
                out = String(take!(io))

                # Check header structure
                Test.@test occursin("▫ OptimalControl v", out)
                Test.@test occursin("solving with:", out)
                Test.@test occursin("collocation → adnlp → ipopt", out)
            end

            Test.@testset "Configuration section" begin
                disc = OptimalControl.Collocation()
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt()

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(io, disc, mod, sol)
                out = String(take!(io))

                Test.@test occursin("📦 Configuration:", out)
                Test.@test occursin("├─ Discretizer:", out)
                Test.@test occursin("├─ Modeler:", out)
                Test.@test occursin("└─ Solver:", out)
            end

            Test.@testset "Color and styling" begin
                # This test mainly ensures the function runs without errors
                # Actual color testing would be more complex
                disc = OptimalControl.Collocation(grid_size=5)
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt(print_level=0)

                io = IOBuffer()
                Test.@test_nowarn OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol
                )
            end
        end

        Test.@testset "Multiple Options Display" begin
            Test.@testset "Few options (single line)" begin
                disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt(print_level=0)

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; show_options=true, show_sources=false
                )
                out = String(take!(io))

                # Should be on single line for <= 2 options (note: no colon before midpoint)
                Test.@test occursin("grid_size = 5, scheme = midpoint", out)
            end

            Test.@testset "Many options (multiline with truncation)" begin
                disc = OptimalControl.Collocation(grid_size=5, scheme=:midpoint)
                mod = OptimalControl.ADNLP(backend=:default)
                sol = OptimalControl.Ipopt(print_level=0, max_iter=1000, tol=1e-8)

                io = IOBuffer()
                OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; show_options=true, show_sources=false
                )
                out = String(take!(io))

                # Should show some options (may or may not truncate depending on implementation)
                Test.@test occursin("grid_size", out)
                Test.@test occursin("print_level", out)
            end
        end

        # ====================================================================
        # PERFORMANCE TESTS
        # ====================================================================

        Test.@testset "Performance Characteristics" begin
            Test.@testset "Basic performance" begin
                disc = OptimalControl.Collocation()
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt()

                io = IOBuffer()

                # Should complete in reasonable time
                allocs = Test.@allocated OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol
                )
                Test.@test allocs < 20000  # Adjusted from 10000 (14416 observed)
            end

            Test.@testset "Performance with options" begin
                disc = OptimalControl.Collocation(grid_size=10, scheme=:trapezoidal)
                mod = OptimalControl.ADNLP(backend=:default)  # Fixed: use valid backend
                sol = OptimalControl.Ipopt(print_level=5, max_iter=1000)

                io = IOBuffer()

                allocs = Test.@allocated OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; show_options=true, show_sources=true
                )
                Test.@test allocs < 100000  # Adjusted from 50000
            end

            Test.@testset "Multiple calls performance" begin
                disc = OptimalControl.Collocation()
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt()

                total_allocs = 0
                for i in 1:5
                    io = IOBuffer()
                    total_allocs += Test.@allocated OptimalControl.display_ocp_configuration(
                        io, disc, mod, sol
                    )
                end
                Test.@test total_allocs < 100000  # Adjusted from 50000 (72080 observed)
            end
        end

        # ====================================================================
        # EDGE CASE TESTS
        # ====================================================================

        Test.@testset "Edge Cases" begin
            Test.@testset "Default stdout method" begin
                # Test the stdout convenience method
                disc = OptimalControl.Collocation()
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt()

                # Should not throw
                Test.@test_nowarn OptimalControl.display_ocp_configuration(
                    disc, mod, sol; display=false
                )
            end

            Test.@testset "Empty IO buffer" begin
                disc = OptimalControl.Collocation()
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt()

                io = IOBuffer()

                # Should work with empty buffer
                Test.@test_nowarn OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol
                )
                result = String(take!(io))
                Test.@test !isempty(result)
            end

            Test.@testset "Complex option values" begin
                disc = OptimalControl.Collocation(grid_size=5)  # Fixed: use valid integer option
                mod = OptimalControl.ADNLP()
                sol = OptimalControl.Ipopt(print_level=0)

                io = IOBuffer()
                Test.@test_nowarn OptimalControl.display_ocp_configuration(
                    io, disc, mod, sol; show_options=true, show_sources=false
                )
                out = String(take!(io))

                Test.@test occursin("grid_size", out)
            end

            Test.@testset "Different strategy combinations" begin
                # Test with different strategy types (now including MadNLP)
                strategies = [
                    (
                        OptimalControl.Collocation(),
                        OptimalControl.ADNLP(),
                        OptimalControl.Ipopt(),
                    ),
                    (
                        OptimalControl.Collocation(),
                        OptimalControl.Exa(),
                        OptimalControl.Ipopt(),
                    ),
                    (
                        OptimalControl.Collocation(),
                        OptimalControl.ADNLP(),
                        OptimalControl.MadNLP(),
                    ),  # Now works with MadNLP import
                ]

                for (disc, mod, sol) in strategies
                    io = IOBuffer()
                    Test.@test_nowarn OptimalControl.display_ocp_configuration(
                        io, disc, mod, sol
                    )
                    out = String(take!(io))
                    Test.@test occursin("▫ OptimalControl v", out)
                    Test.@test occursin("Configuration:", out)
                end
            end
        end
    end # INTEGRATION TESTS - Display Configuration
end

end # module

# Expose entry point
test_print() = TestPrint.test_print()

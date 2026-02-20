module TestOptionsExtractionAPI

import Test
import CTBase
import CTSolvers
import CTSolvers.Options
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Helper types and functions
# ============================================================================

# Simple validator for testing
positive_validator(x::Int) = x > 0 || throw(ArgumentError("$x must be positive"))

# Range validator for testing
range_validator(x::Int) = (1 <= x <= 100) || throw(ArgumentError("$x must be between 1 and 100"))

# String validator for testing
nonempty_validator(s::String) = !isempty(s) || throw(ArgumentError("String must not be empty"))

# ============================================================================
# Test entry point
# ============================================================================

function test_extraction_api()
    
# ============================================================================
# UNIT TESTS
# ============================================================================

    Test.@testset "Extraction API" verbose = VERBOSE showtiming = SHOWTIMING begin

        Test.@testset "extract_option - Basic functionality" begin
            # Test with exact name match
            def = Options.OptionDefinition(
                name=:grid_size,
                type=Int,
                default=100,
                description="Grid size"
            )
            kwargs = (grid_size=200, tol=1e-6)

            opt_value, remaining = Options.extract_option(kwargs, def)

            Test.@test opt_value.value == 200
            Test.@test opt_value.source == :user
            Test.@test remaining == (tol=1e-6,)
        end

        Test.@testset "extract_option - Alias resolution" begin
            # Test with alias
            def = Options.OptionDefinition(
                name=:grid_size,
                type=Int,
                default=100,
                description="Grid size",
                aliases=(:n, :size)
            )
            kwargs = (n=200, tol=1e-6)

            opt_value, remaining = Options.extract_option(kwargs, def)

            Test.@test opt_value.value == 200
            Test.@test opt_value.source == :user
            Test.@test remaining == (tol=1e-6,)

            # Test with different alias
            kwargs = (size=300, max_iter=1000)
            opt_value, remaining = Options.extract_option(kwargs, def)

            Test.@test opt_value.value == 300
            Test.@test opt_value.source == :user
            Test.@test remaining == (max_iter=1000,)
        end

        Test.@testset "extract_option - Default values" begin
            # Test when option not found
            def = Options.OptionDefinition(
                name=:grid_size,
                type=Int,
                default=100,
                description="Grid size"
            )
            kwargs = (tol=1e-6, max_iter=1000)

            opt_value, remaining = Options.extract_option(kwargs, def)

            Test.@test opt_value.value == 100
            Test.@test opt_value.source == :default
            Test.@test remaining == kwargs  # Unchanged
        end

        Test.@testset "extract_option - Validation" begin
            # Test with successful validation
            def = Options.OptionDefinition(
                name=:grid_size,
                type=Int,
                default=100,
                description="Grid size",
                validator=x -> x > 0 || throw(ArgumentError("$x must be positive"))
            )
            kwargs = (grid_size=200,)

            opt_value, remaining = Options.extract_option(kwargs, def)

            Test.@test opt_value.value == 200
            Test.@test opt_value.source == :user

            # Test with failed validation (redirect stderr to hide @error logs)
            kwargs = (grid_size=-5,)
            Test.@test_throws ArgumentError redirect_stderr(devnull) do
                Options.extract_option(kwargs, def)
            end
        end

        Test.@testset "extract_option - Type checking" begin
            # Test type mismatch (should throw IncorrectArgument)
            def = Options.OptionDefinition(
                name=:grid_size,
                type=Int,
                default=100,
                description="Grid size"
            )
            kwargs = (grid_size="200",)  # String instead of Int

            Test.@test_throws CTBase.Exceptions.IncorrectArgument Options.extract_option(kwargs, def)
        end

        Test.@testset "extract_options - Vector version" begin
            defs = [
                Options.OptionDefinition(name=:grid_size, type=Int, default=100, description="Grid size"),
                Options.OptionDefinition(name=:tol, type=Float64, default=1e-6, description="Tolerance"),
                Options.OptionDefinition(name=:max_iter, type=Int, default=1000, description="Max iterations")
            ]
            kwargs = (grid_size=200, tol=1e-8, other_option="ignored")

            extracted, remaining = Options.extract_options(kwargs, defs)

            Test.@test extracted[:grid_size].value == 200
            Test.@test extracted[:grid_size].source == :user
            Test.@test extracted[:tol].value == 1e-8
            Test.@test extracted[:tol].source == :user
            Test.@test extracted[:max_iter].value == 1000
            Test.@test extracted[:max_iter].source == :default
            Test.@test remaining == (other_option="ignored",)
        end

        Test.@testset "extract_options - NamedTuple version" begin
            defs = (
                grid_size=Options.OptionDefinition(name=:grid_size, type=Int, default=100, description="Grid size"),
                tol=Options.OptionDefinition(name=:tol, type=Float64, default=1e-6, description="Tolerance")
            )
            kwargs = (grid_size=200, tol=1e-8, max_iter=1000)

            extracted, remaining = Options.extract_options(kwargs, defs)

            Test.@test extracted.grid_size.value == 200
            Test.@test extracted.grid_size.source == :user
            Test.@test extracted.tol.value == 1e-8
            Test.@test extracted.tol.source == :user
            Test.@test remaining == (max_iter=1000,)
        end

        Test.@testset "extract_options - Complex scenario with aliases" begin
            defs = [
                Options.OptionDefinition(name=:grid_size, type=Int, default=100, description="Grid size", aliases=(:n, :size), validator=positive_validator),
                Options.OptionDefinition(name=:tolerance, type=Float64, default=1e-6, description="Tolerance", aliases=(:tol,)),
                Options.OptionDefinition(name=:max_iterations, type=Int, default=1000, description="Max iterations", aliases=(:max_iter, :iterations))
            ]
            kwargs = (n=50, tol=1e-8, iterations=500, unused="value")

            extracted, remaining = Options.extract_options(kwargs, defs)

            Test.@test extracted[:grid_size].value == 50
            Test.@test extracted[:grid_size].source == :user
            Test.@test extracted[:tolerance].value == 1e-8
            Test.@test extracted[:tolerance].source == :user
            Test.@test extracted[:max_iterations].value == 500
            Test.@test extracted[:max_iterations].source == :user
            Test.@test remaining == (unused="value",)
        end

        Test.@testset "Performance - Type stability" begin
            # Focus on functional correctness
            def = Options.OptionDefinition(name=:test, type=Int, default=42, description="Test")
            kwargs = (test=100,)

            result = Options.extract_option(kwargs, def)
            Test.@test result[1] isa Options.OptionValue
            Test.@test result[2] isa NamedTuple

            defs = [def]
            result = Options.extract_options(kwargs, defs)
            Test.@test result[1] isa Dict{Symbol,Options.OptionValue}
            Test.@test result[2] isa NamedTuple
        end

        Test.@testset "Error handling" begin
            # Validator that accepts default but rejects other values
            def = Options.OptionDefinition(
                name=:test,
                type=Int,
                default=42,
                description="Test",
                validator=x -> x == 42 || throw(ArgumentError("$x must be 42"))
            )
            kwargs = (test=100,)

            # Test validation error propagation (redirect stderr to hide @error logs)
            Test.@test_throws ArgumentError redirect_stderr(devnull) do
                Options.extract_option(kwargs, def)
            end

            # Test with multiple definitions, one fails
            defs = [
                Options.OptionDefinition(name=:good, type=Int, default=42, description="Good"),
                Options.OptionDefinition(
                    name=:bad,
                    type=Int,
                    default=42,
                    description="Bad",
                    validator=x -> x == 42 || throw(ArgumentError("$x must be 42"))
                )
            ]
            kwargs = (good=100, bad=200)

            Test.@test_throws ArgumentError redirect_stderr(devnull) do
                Options.extract_options(kwargs, defs)
            end
        end

    end # UNIT TESTS

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

    Test.@testset "Extraction API Integration" verbose = VERBOSE showtiming = SHOWTIMING begin

        Test.@testset "Integration with OptionValue and OptionDefinition" begin
            # Test complete workflow
            defs = (
                size=Options.OptionDefinition(name=:grid_size, type=Int, default=100, description="Grid size", aliases=(:n, :size), validator=positive_validator),
                tolerance=Options.OptionDefinition(name=:tolerance, type=Float64, default=1e-6, description="Tolerance", aliases=(:tol,)),
                verbose=Options.OptionDefinition(name=:verbose, type=Bool, default=false, description="Verbose")
            )

            # Test with mixed aliases and validation
            kwargs = (n=50, tol=1e-8, verbose=true, extra="ignored")

            extracted, remaining = Options.extract_options(kwargs, defs)

            # Verify all options extracted correctly
            Test.@test extracted.size.value == 50
            Test.@test extracted.size.source == :user
            Test.@test extracted.tolerance.value == 1e-8
            Test.@test extracted.tolerance.source == :user
            Test.@test extracted.verbose.value == true
            Test.@test extracted.verbose.source == :user

            # Verify only unused options remain
            Test.@test remaining == (extra="ignored",)

            # Test OptionValue functionality
            Test.@test string(extracted.size) == "50 (user)"
            Test.@test extracted.size.value isa Int
            Test.@test extracted.tolerance.value isa Float64
            Test.@test extracted.verbose.value isa Bool
        end

        Test.@testset "Realistic tool configuration scenario" begin
            # Simulate a realistic tool configuration
            tool_defs = [
                Options.OptionDefinition(name=:grid_size, type=Int, default=100, description="Grid size", aliases=(:n, :size)),
                Options.OptionDefinition(name=:tolerance, type=Float64, default=1e-6, description="Tolerance", aliases=(:tol,)),
                Options.OptionDefinition(name=:max_iterations, type=Int, default=1000, description="Max iterations", aliases=(:max_iter, :iterations)),
                Options.OptionDefinition(name=:solver, type=String, default="ipopt", description="Solver", aliases=(:algorithm,)),
                Options.OptionDefinition(name=:verbose, type=Bool, default=false, description="Verbose"),
                Options.OptionDefinition(name=:output_file, type=String, default=nothing, description="Output file", aliases=(:out, :output))
            ]

            # Test configuration with various options
            config = (
                n=200,
                tol=1e-8,
                max_iter=500,
                algorithm="knitro",
                verbose=true,
                output="results.txt",
                debug_mode=true  # Extra option not in schemas
            )

            extracted, remaining = Options.extract_options(config, tool_defs)

            # Verify extraction
            Test.@test extracted[:grid_size].value == 200
            Test.@test extracted[:tolerance].value == 1e-8
            Test.@test extracted[:max_iterations].value == 500
            Test.@test extracted[:solver].value == "knitro"
            Test.@test extracted[:verbose].value == true
            Test.@test extracted[:output_file].value == "results.txt"

            # Verify only non-schema options remain
            Test.@test remaining == (debug_mode=true,)

            # Test all sources are correct
            for (name, opt_value) in extracted
                Test.@test opt_value.source == :user  # All were provided
            end
        end

        Test.@testset "Edge cases and boundary conditions" begin
            # Test with empty kwargs
            def = Options.OptionDefinition(name=:test, type=Int, default=42, description="Test")
            empty_kwargs = NamedTuple()

            opt_value, remaining = Options.extract_option(empty_kwargs, def)
            Test.@test opt_value.value == 42
            Test.@test opt_value.source == :default
            Test.@test remaining == NamedTuple()

            # Test with empty definitions
            empty_defs = Options.OptionDefinition[]
            kwargs = (a=1, b=2)

            extracted, remaining = Options.extract_options(kwargs, empty_defs)
            Test.@test isempty(extracted)
            Test.@test remaining == kwargs

            # Test with nothing default
            def_no_default = Options.OptionDefinition(name=:optional, type=String, default=nothing, description="Optional")
            kwargs_no_match = (other="value",)

            opt_value, remaining = Options.extract_option(kwargs_no_match, def_no_default)
            Test.@test opt_value.value === nothing
            Test.@test opt_value.source == :default
        end

    end # INTEGRATION TESTS

end # test_extraction_api()

end # module

test_extraction_api() = TestOptionsExtractionAPI.test_extraction_api()

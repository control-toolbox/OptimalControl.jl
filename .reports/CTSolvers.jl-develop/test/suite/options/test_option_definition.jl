module TestOptionsOptionDefinition

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Options
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_option_definition()
    Test.@testset "OptionDefinition" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ========================================================================
        # Basic construction
        # ========================================================================
        
        Test.@testset "Basic construction" begin
            # Minimal constructor
            def = Options.OptionDefinition(
                name = :test_option,
                type = Int,
                default = 42,
                description = "Test option"
            )
            Test.@test Options.name(def) == :test_option
            Test.@test Options.type(def) == Int
            Test.@test Options.default(def) == 42
            Test.@test Options.description(def) == "Test option"
            Test.@test Options.aliases(def) == ()
            Test.@test Options.validator(def) === nothing
        end
        
        # ========================================================================
        # Full construction with aliases and validator
        # ========================================================================
        
        Test.@testset "Full construction" begin
            validator = x -> x > 0
            def = Options.OptionDefinition(
                name = :max_iter,
                type = Int,
                default = 100,
                description = "Maximum iterations",
                aliases = (:max, :maxiter),
                validator = validator
            )
            Test.@test Options.name(def) == :max_iter
            Test.@test Options.type(def) == Int
            Test.@test Options.default(def) == 100
            Test.@test Options.description(def) == "Maximum iterations"
            Test.@test Options.aliases(def) == (:max, :maxiter)
            Test.@test Options.validator(def) === validator
        end
        
        # ========================================================================
        # Minimal construction
        # ========================================================================
        
        Test.@testset "Minimal construction" begin
            def = Options.OptionDefinition(
                name = :test,
                type = String,
                default = "default",
                description = "Test option"
            )
            Test.@test Options.name(def) == :test
            Test.@test Options.type(def) == String
            Test.@test Options.default(def) == "default"
            Test.@test Options.description(def) == "Test option"
            Test.@test Options.aliases(def) == ()
            Test.@test Options.validator(def) === nothing
        end
        
        # ========================================================================
        # Validation
        # ========================================================================
        
        Test.@testset "Validation" begin
            # Valid default value type
            Test.@test_nowarn Options.OptionDefinition(
                name = :test,
                type = Int,
                default = 42,
                description = "Test"
            )
            
            # Invalid default value type
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionDefinition(
                name = :test,
                type = Int,
                default = "not an int",
                description = "Test"
            )
            
            # Valid validator with valid default
            Test.@test_nowarn Options.OptionDefinition(
                name = :test,
                type = Int,
                default = 42,
                description = "Test",
                validator = x -> x > 0
            )
            
            # Invalid validator with invalid default (redirect stderr to hide @error logs)
            Test.@test_throws ErrorException redirect_stderr(devnull) do
                Options.OptionDefinition(
                    name = :test,
                    type = Int,
                    default = -5,
                    description = "Test",
                    validator = x -> x > 0 || error("Must be positive")
                )
            end
        end
        
        # ========================================================================
        # all_names function
        # ========================================================================
        
        Test.@testset "all_names function" begin
            def = Options.OptionDefinition(
                name = :max_iter,
                type = Int,
                default = 100,
                description = "Test",
                aliases = (:max, :maxiter)
            )
            names = Options.all_names(def)
            Test.@test names == (:max_iter, :max, :maxiter)
        end
        
        # ========================================================================
        # Edge cases
        # ========================================================================
        
        Test.@testset "Edge cases" begin
            # nothing default (allowed)
            def = Options.OptionDefinition(
                name = :test,
                type = Any,
                default = nothing,
                description = "Test"
            )
            Test.@test def.default === nothing
            
            # nothing validator (allowed)
            def = Options.OptionDefinition(
                name = :test,
                type = Int,
                default = 42,
                description = "Test",
                validator = nothing
            )
            Test.@test def.validator === nothing
        end

        # ========================================================================
        # Getters and introspection
        # ========================================================================

        Test.@testset "Getters and introspection" begin
            validator = x -> x > 0
            def = Options.OptionDefinition(
                name = :max_iter,
                type = Int,
                default = 100,
                description = "Maximum iterations",
                aliases = (:max, :maxiter),
                validator = validator
            )

            Test.@test Options.name(def) === :max_iter
            Test.@test Options.type(def) === Int
            Test.@test Options.default(def) === 100
            Test.@test Options.description(def) == "Maximum iterations"
            Test.@test Options.aliases(def) == (:max, :maxiter)
            Test.@test Options.validator(def) === validator
            Test.@test Options.has_default(def) === true
            Test.@test Options.is_required(def) === false
            Test.@test Options.has_validator(def) === true

            required_def = Options.OptionDefinition(
                name = :input,
                type = String,
                default = Options.NotProvided,
                description = "Input file"
            )
            Test.@test Options.has_default(required_def) === false
            Test.@test Options.is_required(required_def) === true
            Test.@test Options.has_validator(required_def) === false
        end
        
        # ========================================================================
        # Type stability tests
        # ========================================================================
        
        Test.@testset "Type stability" begin
            # Test that OptionDefinition is parameterized correctly
            def_int = Options.OptionDefinition(
                name = :test_int,
                type = Int,
                default = 42,
                description = "Test"
            )
            Test.@test def_int isa Options.OptionDefinition{Int64}
            
            def_float = Options.OptionDefinition(
                name = :test_float,
                type = Float64,
                default = 3.14,
                description = "Test"
            )
            Test.@test def_float isa Options.OptionDefinition{Float64}
            
            def_string = Options.OptionDefinition(
                name = :test_string,
                type = String,
                default = "hello",
                description = "Test"
            )
            Test.@test def_string isa Options.OptionDefinition{String}
            
            # Test type-stable access to default field via function
            function get_default(def::Options.OptionDefinition{T}) where T
                return def.default
            end
            
            Test.@inferred get_default(def_int)
            Test.@test typeof(def_int.default) === Int64
            Test.@test get_default(def_int) === 42
            
            Test.@inferred get_default(def_float)
            Test.@test typeof(def_float.default) === Float64
            Test.@test get_default(def_float) === 3.14
            
            Test.@inferred get_default(def_string)
            Test.@test typeof(def_string.default) === String
            Test.@test get_default(def_string) === "hello"
            
            # Test heterogeneous collections (Vector{OptionDefinition{<:Any}})
            defs = Options.OptionDefinition[def_int, def_float, def_string]
            Test.@test length(defs) == 3
            Test.@test defs[1] isa Options.OptionDefinition{Int64}
            Test.@test defs[2] isa Options.OptionDefinition{Float64}
            Test.@test defs[3] isa Options.OptionDefinition{String}
            
            # Test that accessing defaults in a loop maintains type information
            function sum_int_defaults(defs::Vector{<:Options.OptionDefinition})
                total = 0
                for def in defs
                    if def isa Options.OptionDefinition{Int}
                        total += def.default  # Type-stable within branch
                    end
                end
                return total
            end
            
            int_defs = [
                Options.OptionDefinition(name=Symbol("opt$i"), type=Int, default=i, description="test")
                for i in 1:5
            ]
            Test.@test sum_int_defaults(int_defs) == 15
        end
        
        # ========================================================================
        # Display functionality
        # ========================================================================
        
        Test.@testset "Display" begin
            # Test with minimal OptionDefinition
            def_min = Options.OptionDefinition(
                name = :test,
                type = Int,
                default = 42,
                description = "Test option"
            )
            
            # Test with full OptionDefinition
            def_full = Options.OptionDefinition(
                name = :max_iter,
                type = Int,
                default = 100,
                description = "Maximum iterations",
                aliases = (:max, :maxiter),
                validator = x -> x > 0
            )
            
            # Test default display format (custom format)
            io_min = IOBuffer()
            println(io_min, def_min)
            output_min = String(take!(io_min))
            
            io_full = IOBuffer()
            println(io_full, def_full)
            output_full = String(take!(io_full))
            
            # Check that custom display contains expected elements
            Test.@test occursin("test :: Int64", output_min)
            Test.@test occursin("(default: 42)", output_min)
            
            Test.@test occursin("max_iter (max, maxiter) :: Int64", output_full)
            Test.@test occursin("(default: 100)", output_full)
        end
    end
end

end # module

test_option_definition() = TestOptionsOptionDefinition.test_option_definition()

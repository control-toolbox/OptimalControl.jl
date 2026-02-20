module TestOptionsNotProvided

import Test
import CTSolvers.Options
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_not_provided()

Test the NotProvided type and its behavior in the option system.
"""
function test_not_provided()
    Test.@testset "NotProvided Type Tests" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "NotProvided Basic Properties" begin
            Test.@test Options.NotProvided isa Options.NotProvidedType
            Test.@test typeof(Options.NotProvided) == Options.NotProvidedType
            Test.@test string(Options.NotProvided) == "NotProvided"
        end
        
        Test.@testset "OptionDefinition with NotProvided" begin
            # Option with NotProvided default
            def_not_provided = Options.OptionDefinition(
                name = :optional_param,
                type = Union{Int, Nothing},
                default=Options.NotProvided,
                description = "Optional parameter"
            )
            
            Test.@test Options.default(def_not_provided) === Options.NotProvided
            Test.@test Options.default(def_not_provided) isa Options.NotProvidedType
            
            # Option with nothing default (different!)
            def_nothing = Options.OptionDefinition(
                name = :nullable_param,
                type = Union{Int, Nothing},
                default = nothing,
                description = "Nullable parameter"
            )
            
            Test.@test Options.default(def_nothing) === nothing
            Test.@test !(Options.default(def_nothing) isa Options.NotProvidedType)
        end
        
        Test.@testset "extract_option with NotProvided" begin
            def = Options.OptionDefinition(
                name = :optional,
                type = Union{Int, Nothing},
                default=Options.NotProvided,
                description = "Optional"
            )
            
            # Case 1: User provides value
            kwargs_provided = (optional = 42, other = "test")
            opt_val, remaining = Options.extract_option(kwargs_provided, def)
            
            Test.@test opt_val !== nothing  # Should return OptionValue
            Test.@test opt_val isa Options.OptionValue
            Test.@test Options.value(opt_val) == 42
            Test.@test Options.source(opt_val) == :user
            Test.@test !haskey(remaining, :optional)
            
            # Case 2: User does NOT provide value
            kwargs_not_provided = (other = "test",)
            opt_val2, remaining2 = Options.extract_option(kwargs_not_provided, def)
            
            Test.@test opt_val2 isa Options.NotStoredType  # Should return NotStored (signal "don't store")
            Test.@test remaining2 == kwargs_not_provided
        end
        
        Test.@testset "extract_options filters NotProvided" begin
            defs = [
                Options.OptionDefinition(
                    name = :required,
                    type = Int,
                    default = 100,
                    description = "Required with default"
                ),
                Options.OptionDefinition(
                    name = :optional,
                    type = Union{Int, Nothing},
                    default=Options.NotProvided,
                    description = "Optional"
                ),
                Options.OptionDefinition(
                    name = :nullable,
                    type = Union{Int, Nothing},
                    default = nothing,
                    description = "Nullable with nothing default"
                )
            ]
            
            # User provides only 'required'
            kwargs = (required = 200,)
            extracted, remaining = Options.extract_options(kwargs, defs)
            
            # Check what's stored
            Test.@test haskey(extracted, :required)
            Test.@test !haskey(extracted, :optional)  # NotProvided + not provided = not stored
            Test.@test haskey(extracted, :nullable)   # nothing default = always stored
            
            Test.@test Options.value(extracted[:required]) == 200
            Test.@test Options.value(extracted[:nullable]) === nothing
            
            # Verify NO NotProvidedType in extracted values
            for (k, v) in pairs(extracted)
                Test.@test !(Options.value(v) isa Options.NotProvidedType)
            end
        end
        
        Test.@testset "extract_options stores nothing defaults correctly" begin
            # Test that options with explicit nothing default are stored
            defs = [
                Options.OptionDefinition(
                    name = :backend,
                    type = Union{Nothing, Symbol},
                    default = nothing,
                    description = "Backend with nothing default"
                ),
                Options.OptionDefinition(
                    name = :minimize,
                    type = Union{Bool, Nothing},
                    default=Options.NotProvided,
                    description = "Minimize with NotProvided"
                )
            ]
            
            # User provides neither option
            kwargs = (other = "test",)
            extracted, remaining = Options.extract_options(kwargs, defs)
            
            # backend should be stored with nothing value
            Test.@test haskey(extracted, :backend)
            Test.@test Options.value(extracted[:backend]) === nothing
            Test.@test Options.source(extracted[:backend]) == :default
            
            # minimize should NOT be stored
            Test.@test !haskey(extracted, :minimize)
            
            # Now test when user provides backend = nothing explicitly
            kwargs2 = (backend = nothing,)
            extracted2, _ = Options.extract_options(kwargs2, defs)
            
            # backend should be stored with nothing value from user
            Test.@test haskey(extracted2, :backend)
            Test.@test Options.value(extracted2[:backend]) === nothing
            Test.@test Options.source(extracted2[:backend]) == :user  # User provided it
            
            # minimize still not stored
            Test.@test !haskey(extracted2, :minimize)
        end
        
        Test.@testset "extract_raw_options should never see NotProvided" begin
            # Simulate what would be stored in an instance
            stored_options = (
                backend=Options.OptionValue(:optimized, :default),
                show_time=Options.OptionValue(false, :user),
                nullable_opt=Options.OptionValue(nothing, :default)
                # Note: optional with NotProvided is NOT here (not stored)
            )
            
            raw = Options.extract_raw_options(stored_options)
            
            # Verify all values are unwrapped
            Test.@test raw.backend == :optimized
            Test.@test raw.show_time == false
            Test.@test raw.nullable_opt === nothing
            
            # Verify NO NotProvidedType in raw values
            for (k, v) in pairs(stored_options)
                Test.@test !(Options.value(v) isa Options.NotProvidedType)
            end
        end
        
        Test.@testset "Complete workflow: NotProvided never stored" begin
            # Define options like Modelers.Exa
            defs_nt = (
                base_type=Options.OptionDefinition(
                    name = :base_type,
                    type = DataType,
                    default = Float64,
                    description = "Base type"
                ),
                minimize=Options.OptionDefinition(
                    name = :minimize,
                    type = Union{Bool, Nothing},
                    default=Options.NotProvided,
                    description = "Minimize flag"
                ),
                backend=Options.OptionDefinition(
                    name = :backend,
                    type = Any,
                    default = nothing,
                    description = "Backend"
                )
            )
            
            # User provides only base_type
            user_kwargs = (base_type = Float32,)
            
            # Extract options (what gets stored in instance)
            extracted, _ = Options.extract_options(user_kwargs, defs_nt)
            
            # Verify minimize is NOT stored (NotProvided + not provided)
            Test.@test haskey(extracted, :base_type)
            Test.@test !haskey(extracted, :minimize)  # ✅ Key point!
            Test.@test haskey(extracted, :backend)    # nothing default = stored
            
            # Verify NO NotProvidedType in extracted
            for (k, v) in pairs(extracted)
                Test.@test !(v.value isa Options.NotProvidedType)
            end
            
            # Extract raw options (what gets passed to builder)
            raw = Options.extract_raw_options(extracted)
            
            # Verify minimize is NOT in raw options
            Test.@test haskey(raw, :base_type)
            Test.@test !haskey(raw, :minimize)  # ✅ Not passed to builder
            Test.@test haskey(raw, :backend)
            
            # Verify NO NotProvidedType in raw
            for (k, v) in pairs(raw)
                Test.@test !(v isa Options.NotProvidedType)
            end
        end
    end
end

end # module

test_not_provided() = TestOptionsNotProvided.test_not_provided()

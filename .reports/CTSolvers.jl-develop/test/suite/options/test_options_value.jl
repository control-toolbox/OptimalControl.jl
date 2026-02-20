module TestOptionsValue

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Options
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_options_value()
    Test.@testset "Options module" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Test OptionValue construction and basic properties
        Test.@testset "OptionValue construction" begin
            # Test with explicit source
            opt_user = Options.OptionValue(42, :user)
            Test.@test opt_user.value == 42
            Test.@test opt_user.source == :user
            Test.@test typeof(opt_user) == Options.OptionValue{Int}
            
            # Test with default source (note: default source is :user in current implementation)
            opt_default = Options.OptionValue(3.14)
            Test.@test opt_default.value == 3.14
            Test.@test opt_default.source == :user
            Test.@test typeof(opt_default) == Options.OptionValue{Float64}
            
            # Test with different types
            opt_str = Options.OptionValue("hello", :default)
            Test.@test opt_str.value == "hello"
            Test.@test opt_str.source == :default
            
            opt_bool = Options.OptionValue(true, :computed)
            Test.@test opt_bool.value == true
            Test.@test opt_bool.source == :computed
        end
        
        # Test OptionValue validation
        Test.@testset "OptionValue validation" begin
            # Test invalid sources
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(42, :invalid)
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(42, :wrong)
            Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(42, :DEFAULT)  # case sensitive
        end
        
        # Test OptionValue display
        Test.@testset "OptionValue display" begin
            opt = Options.OptionValue(100, :user)
            io = IOBuffer()
            Base.show(io, opt)
            Test.@test String(take!(io)) == "100 (user)"
            
            opt_default = Options.OptionValue(3.14, :default)
            io = IOBuffer()
            Base.show(io, opt_default)
            Test.@test String(take!(io)) == "3.14 (default)"
        end
        
        # Test OptionValue type stability
        Test.@testset "OptionValue type stability" begin
            opt_int = Options.OptionValue(42, :user)
            opt_float = Options.OptionValue(3.14, :user)
            
            # Test that types are preserved
            Test.@test typeof(opt_int.value) == Int
            Test.@test typeof(opt_float.value) == Float64
            
            # Test that the struct is parameterized correctly
            Test.@test typeof(opt_int) == Options.OptionValue{Int}
            Test.@test typeof(opt_float) == Options.OptionValue{Float64}
        end

        # ========================================================================
        # Getters and introspection
        # ========================================================================

        Test.@testset "Getters and introspection" begin
            opt_user = Options.OptionValue(42, :user)
            opt_default = Options.OptionValue(3.14, :default)
            opt_computed = Options.OptionValue(true, :computed)

            Test.@test Options.value(opt_user) === 42
            Test.@test Options.source(opt_user) === :user
            Test.@test Options.is_user(opt_user) === true
            Test.@test Options.is_default(opt_user) === false
            Test.@test Options.is_computed(opt_user) === false

            Test.@test Options.value(opt_default) === 3.14
            Test.@test Options.source(opt_default) === :default
            Test.@test Options.is_user(opt_default) === false
            Test.@test Options.is_default(opt_default) === true
            Test.@test Options.is_computed(opt_default) === false

            Test.@test Options.value(opt_computed) === true
            Test.@test Options.source(opt_computed) === :computed
            Test.@test Options.is_user(opt_computed) === false
            Test.@test Options.is_default(opt_computed) === false
            Test.@test Options.is_computed(opt_computed) === true
        end
    end
end

end # module

test_options_value() = TestOptionsValue.test_options_value()
module TestStrategiesStrategyOptions

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test function
# ============================================================================

"""
    test_strategy_options()

Tests for strategy-specific options handling.
"""
function test_strategy_options()
    Test.@testset "Strategy Options" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ========================================================================
        # UNIT TESTS
        # ========================================================================
        
        Test.@testset "Unit Tests" begin
            
            Test.@testset "Construction" begin
                # Valid construction with keyword arguments
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-6, :default)
                )
                
                Test.@test opts isa Strategies.StrategyOptions
                Test.@test length(opts) == 2
            end
            
            Test.@testset "Validation - OptionValue required" begin
                # Should error if not OptionValue
                Test.@test_throws Exceptions.IncorrectArgument Strategies.StrategyOptions(
                    max_iter = 200  # Not an OptionValue
                )
            end
            
            Test.@testset "Validation - valid sources" begin
                # Valid sources are validated by OptionValue constructor
                for source in (:user, :default, :computed)
                    opts = Strategies.StrategyOptions(
                        max_iter = Options.OptionValue(200, source)
                    )
                    Test.@test Strategies.source(opts, :max_iter) == source
                end
                
                # Invalid source throws in OptionValue constructor
                Test.@test_throws Exceptions.IncorrectArgument Options.OptionValue(200, :invalid)
            end
            
            Test.@testset "Value access" begin
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default),
                    display = Options.OptionValue(true, :computed)
                )
                
                # Test getindex - returns unwrapped value
                Test.@test opts[:max_iter] == 200
                Test.@test opts[:tol] == 1e-8
                Test.@test opts[:display] == true
            end
            
            Test.@testset "OptionValue access" begin
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default)
                )
                
                # Test getproperty - returns full OptionValue
                Test.@test opts.max_iter isa Options.OptionValue
                Test.@test opts.max_iter.value == 200
                Test.@test opts.max_iter.source == :user
                
                Test.@test opts.tol.value == 1e-8
                Test.@test opts.tol.source == :default
            end
            
            Test.@testset "Source access helpers" begin
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default),
                    step = Options.OptionValue(0.01, :computed)
                )
                
                # Test source() helper
                Test.@test Strategies.source(opts, :max_iter) == :user
                Test.@test Strategies.source(opts, :tol) == :default
                Test.@test Strategies.source(opts, :step) == :computed

                # Test Options-level helpers on StrategyOptions
                Test.@test Options.value(opts, :max_iter) == 200
                Test.@test Options.value(opts, :tol) == 1e-8
                Test.@test Options.value(opts, :step) == 0.01
                Test.@test Options.source(opts, :max_iter) == :user
                Test.@test Options.source(opts, :tol) == :default
                Test.@test Options.source(opts, :step) == :computed
                
                # Test is_user() helper
                Test.@test Strategies.is_user(opts, :max_iter) == true
                Test.@test Strategies.is_user(opts, :tol) == false
                Test.@test Options.is_user(opts, :max_iter) == true
                Test.@test Options.is_user(opts, :tol) == false
                
                # Test is_default() helper
                Test.@test Strategies.is_default(opts, :tol) == true
                Test.@test Strategies.is_default(opts, :max_iter) == false
                Test.@test Options.is_default(opts, :tol) == true
                Test.@test Options.is_default(opts, :max_iter) == false
                
                # Test is_computed() helper
                Test.@test Strategies.is_computed(opts, :step) == true
                Test.@test Strategies.is_computed(opts, :tol) == false
                Test.@test Options.is_computed(opts, :step) == true
                Test.@test Options.is_computed(opts, :tol) == false
            end
            
            Test.@testset "Collection interface" begin
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default),
                    display = Options.OptionValue(true, :computed)
                )
                
                # Test keys
                Test.@test collect(keys(opts)) == [:max_iter, :tol, :display]
                
                # Test values (unwrapped)
                Test.@test collect(values(opts)) == [200, 1e-8, true]
                
                # Test pairs (unwrapped values)
                pairs_collected = collect(pairs(opts))
                Test.@test length(pairs_collected) == 3
                Test.@test pairs_collected[1] == (:max_iter => 200)
                Test.@test pairs_collected[2] == (:tol => 1e-8)
                Test.@test pairs_collected[3] == (:display => true)
                
                # Test iteration (unwrapped values)
                iterated_values = []
                for value in opts
                    push!(iterated_values, value)
                end
                Test.@test iterated_values == [200, 1e-8, true]
                
                # Test length, isempty, haskey
                Test.@test length(opts) == 3
                Test.@test !isempty(opts)
                Test.@test haskey(opts, :max_iter)
                Test.@test !haskey(opts, :nonexistent)
            end
            
            Test.@testset "Edge cases" begin
                # Empty options
                opts = Strategies.StrategyOptions()
                Test.@test length(opts) == 0
                Test.@test isempty(opts)
                Test.@test collect(keys(opts)) == []
                
                # Single option
                opts = Strategies.StrategyOptions(
                    only_option = Options.OptionValue(42, :user)
                )
                Test.@test opts[:only_option] == 42
                Test.@test Strategies.source(opts, :only_option) == :user
            end
        end
        
        # ========================================================================
        # INTEGRATION TESTS
        # ========================================================================
        
        Test.@testset "Integration Tests" begin
            
            Test.@testset "Display functionality" begin
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default),
                    computed_val = Options.OptionValue(3.14, :computed)
                )
                
                # Test MIME display
                io = IOBuffer()
                show(io, MIME"text/plain"(), opts)
                output = String(take!(io))
                
                # Check that output contains expected elements
                Test.@test occursin("StrategyOptions with 3 options:", output)
                Test.@test occursin("max_iter = 200  [user]", output)
                Test.@test occursin("tol = 1.0e-8  [default]", output)
                Test.@test occursin("computed_val = 3.14  [computed]", output)
            end
            
            Test.@testset "Integration with OptionDefinition" begin
                # Create OptionDefinition
                opt_def = Options.OptionDefinition(
                    name = :max_iter,
                    type = Int,
                    default = 100,
                    description = "Maximum iterations",
                    aliases = (:max, :maxiter)
                )
                
                # Create StrategyOptions from user input
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user)
                )
                
                # Test integration
                Test.@test opts[:max_iter] == 200
                Test.@test typeof(opts[:max_iter]) == Int  # Type matches OptionDefinition
                
                # Test that we can access the source
                Test.@test Strategies.source(opts, :max_iter) == :user
            end
            
            Test.@testset "Complex option scenarios" begin
                # Strategy with mixed sources
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default),
                    backend = Options.OptionValue(:sparse, :user),
                    verbose = Options.OptionValue(false, :default),
                    computed_step = Options.OptionValue(0.01, :computed)
                )
                
                # Test all functionality works with complex scenario
                Test.@test length(opts) == 5
                Test.@test opts[:max_iter] == 200
                Test.@test opts[:backend] == :sparse
                Test.@test Strategies.source(opts, :computed_step) == :computed
                
                # Test display with complex scenario
                io = IOBuffer()
                show(io, MIME"text/plain"(), opts)
                output = String(take!(io))
                
                Test.@test occursin("max_iter = 200  [user]", output)
                Test.@test occursin("tol = 1.0e-8  [default]", output)
                Test.@test occursin("backend = sparse  [user]", output)
                Test.@test occursin("computed_step = 0.01  [computed]", output)
            end
            
            Test.@testset "Performance and type stability" begin
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default)
                )
                
                # Test basic functionality works
                Test.@test opts[:max_iter] == 200
                Test.@test length(opts) == 2
                Test.@test length(collect(values(opts))) == 2
            end
        end
    end
end

end # module

test_strategy_options() = TestStrategiesStrategyOptions.test_strategy_options()

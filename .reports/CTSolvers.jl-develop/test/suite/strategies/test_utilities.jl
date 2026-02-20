module TestStrategiesUtilities

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options: OptionDefinition
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test strategy for suggestions
# ============================================================================

abstract type AbstractTestUtilStrategy <: Strategies.AbstractStrategy end

struct TestUtilStrategy <: AbstractTestUtilStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{TestUtilStrategy}) = :test_util

Strategies.metadata(::Type{TestUtilStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 100,
        description = "Maximum iterations",
        aliases = (:max, :maxiter)
    ),
    OptionDefinition(
        name = :tolerance,
        type = Float64,
        default = 1e-6,
        description = "Convergence tolerance",
        aliases = (:tol,)
    ),
    OptionDefinition(
        name = :verbose,
        type = Bool,
        default = false,
        description = "Verbose output"
    )
)

Strategies.options(s::TestUtilStrategy) = s.options

# ============================================================================
# Test function
# ============================================================================

"""
    test_utilities()

Tests for strategy utilities.
"""
function test_utilities()
    Test.@testset "Strategy Utilities" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # filter_options - Single key
        # ====================================================================
        
        Test.@testset "filter_options - single key" begin
            opts = (max_iter=100, tolerance=1e-6, verbose=true, debug=false)
            
            # Filter single key
            filtered = Strategies.filter_options(opts, :debug)
            Test.@test filtered == (max_iter=100, tolerance=1e-6, verbose=true)
            Test.@test !haskey(filtered, :debug)
            Test.@test haskey(filtered, :max_iter)
            Test.@test haskey(filtered, :tolerance)
            Test.@test haskey(filtered, :verbose)
            
            # Filter another key
            filtered2 = Strategies.filter_options(opts, :verbose)
            Test.@test filtered2 == (max_iter=100, tolerance=1e-6, debug=false)
            Test.@test !haskey(filtered2, :verbose)
            
            # Filter non-existent key (should not error)
            filtered3 = Strategies.filter_options(opts, :nonexistent)
            Test.@test filtered3 == opts
            Test.@test length(filtered3) == 4
        end
        
        # ====================================================================
        # filter_options - Multiple keys
        # ====================================================================
        
        Test.@testset "filter_options - multiple keys" begin
            opts = (max_iter=100, tolerance=1e-6, verbose=true, debug=false)
            
            # Filter two keys
            filtered1 = Strategies.filter_options(opts, (:debug, :verbose))
            Test.@test filtered1 == (max_iter=100, tolerance=1e-6)
            Test.@test !haskey(filtered1, :debug)
            Test.@test !haskey(filtered1, :verbose)
            Test.@test length(filtered1) == 2
            
            # Filter three keys
            filtered2 = Strategies.filter_options(opts, (:debug, :verbose, :tolerance))
            Test.@test filtered2 == (max_iter=100,)
            Test.@test length(filtered2) == 1
            
            # Filter all keys
            filtered3 = Strategies.filter_options(opts, (:max_iter, :tolerance, :verbose, :debug))
            Test.@test filtered3 == NamedTuple()
            Test.@test length(filtered3) == 0
            Test.@test isempty(filtered3)
            
            # Filter with some non-existent keys
            filtered4 = Strategies.filter_options(opts, (:debug, :nonexistent))
            Test.@test filtered4 == (max_iter=100, tolerance=1e-6, verbose=true)
        end
        
        # ====================================================================
        # suggest_options
        # ====================================================================
        
        Test.@testset "suggest_options - structured results" begin
            # Similar to existing option
            suggestions1 = Strategies.suggest_options(:max_it, TestUtilStrategy)
            Test.@test !isempty(suggestions1)
            Test.@test suggestions1[1].primary == :max_iter
            # Distance should be min over primary and all aliases
            expected_dist1 = min(
                Strategies.levenshtein_distance("max_it", "max_iter"),
                Strategies.levenshtein_distance("max_it", "max"),
                Strategies.levenshtein_distance("max_it", "maxiter")
            )
            Test.@test suggestions1[1].distance == expected_dist1
            Test.@test suggestions1[1].aliases == (:max, :maxiter)
            
            # Similar to alias - alias proximity should help
            suggestions2 = Strategies.suggest_options(:tolrance, TestUtilStrategy)
            Test.@test suggestions2[1].primary == :tolerance
            Test.@test suggestions2[1].aliases == (:tol,)
            # Distance should be min of dist to "tolerance" and dist to "tol"
            expected_dist = min(
                Strategies.levenshtein_distance("tolrance", "tolerance"),
                Strategies.levenshtein_distance("tolrance", "tol")
            )
            Test.@test suggestions2[1].distance == expected_dist
            
            # Very different key
            suggestions3 = Strategies.suggest_options(:xyz, TestUtilStrategy)
            Test.@test length(suggestions3) <= 3  # Default max_suggestions
            Test.@test !isempty(suggestions3)
            
            # Limit suggestions
            suggestions4 = Strategies.suggest_options(:x, TestUtilStrategy; max_suggestions=2)
            Test.@test length(suggestions4) <= 2
            
            # Single suggestion
            suggestions5 = Strategies.suggest_options(:unknown, TestUtilStrategy; max_suggestions=1)
            Test.@test length(suggestions5) == 1
            Test.@test haskey(suggestions5[1], :primary)
            Test.@test haskey(suggestions5[1], :aliases)
            Test.@test haskey(suggestions5[1], :distance)
            
            # Exact match should be first suggestion with distance 0
            suggestions6 = Strategies.suggest_options(:max_iter, TestUtilStrategy)
            Test.@test suggestions6[1].primary == :max_iter
            Test.@test suggestions6[1].distance == 0
            
            # Exact alias match should give distance 0
            suggestions7 = Strategies.suggest_options(:tol, TestUtilStrategy)
            Test.@test suggestions7[1].primary == :tolerance
            Test.@test suggestions7[1].distance == 0
        end
        
        # ====================================================================
        # suggest_options - alias proximity advantage
        # ====================================================================
        
        Test.@testset "suggest_options - alias proximity advantage" begin
            # KEY TEST: keyword close to an alias but far from primary name
            # :maxiter is an alias of :max_iter
            # :maxite is close to :maxiter (distance 1) but farther from :max_iter (distance 2)
            suggestions = Strategies.suggest_options(:maxite, TestUtilStrategy)
            Test.@test suggestions[1].primary == :max_iter
            # Without alias awareness, distance would be levenshtein("maxite", "max_iter") = 3
            # With alias awareness, distance is min(3, levenshtein("maxite", "maxiter")) = min(3, 1) = 1
            dist_to_primary = Strategies.levenshtein_distance("maxite", "max_iter")
            dist_to_alias = Strategies.levenshtein_distance("maxite", "maxiter")
            Test.@test dist_to_alias < dist_to_primary  # Alias is closer
            Test.@test suggestions[1].distance == dist_to_alias  # Uses alias distance
            
            # :to is close to :tol (distance 1) but far from :tolerance (distance 7)
            suggestions2 = Strategies.suggest_options(:to, TestUtilStrategy)
            # :tol alias should bring :tolerance closer
            dist_to_primary2 = Strategies.levenshtein_distance("to", "tolerance")
            dist_to_alias2 = Strategies.levenshtein_distance("to", "tol")
            Test.@test dist_to_alias2 < dist_to_primary2
            # Find the tolerance entry
            tol_entry = nothing
            for s in suggestions2
                if s.primary == :tolerance
                    tol_entry = s
                    break
                end
            end
            Test.@test tol_entry !== nothing
            Test.@test tol_entry.distance == dist_to_alias2
        end
        
        # ====================================================================
        # format_suggestion
        # ====================================================================
        
        Test.@testset "format_suggestion" begin
            # Without aliases
            s1 = (primary=:verbose, aliases=(), distance=2)
            formatted1 = Strategies.format_suggestion(s1)
            Test.@test occursin(":verbose", formatted1)
            Test.@test occursin("[distance: 2]", formatted1)
            Test.@test !occursin("alias", formatted1)
            
            # With single alias
            s2 = (primary=:backend, aliases=(:adnlp_backend,), distance=1)
            formatted2 = Strategies.format_suggestion(s2)
            Test.@test occursin(":backend", formatted2)
            Test.@test occursin("adnlp_backend", formatted2)
            Test.@test occursin("alias:", formatted2)
            Test.@test occursin("[distance: 1]", formatted2)
            
            # With multiple aliases
            s3 = (primary=:max_iter, aliases=(:max, :maxiter), distance=0)
            formatted3 = Strategies.format_suggestion(s3)
            Test.@test occursin(":max_iter", formatted3)
            Test.@test occursin("max", formatted3)
            Test.@test occursin("maxiter", formatted3)
            Test.@test occursin("aliases:", formatted3)
            Test.@test occursin("[distance: 0]", formatted3)
        end
        
        # ====================================================================
        # levenshtein_distance
        # ====================================================================
        
        Test.@testset "levenshtein_distance" begin
            # Identical strings
            Test.@test Strategies.levenshtein_distance("test", "test") == 0
            Test.@test Strategies.levenshtein_distance("", "") == 0
            Test.@test Strategies.levenshtein_distance("hello", "hello") == 0
            
            # Single character difference - substitution
            Test.@test Strategies.levenshtein_distance("test", "best") == 1
            Test.@test Strategies.levenshtein_distance("test", "text") == 1
            Test.@test Strategies.levenshtein_distance("cat", "bat") == 1
            
            # Single character difference - insertion
            Test.@test Strategies.levenshtein_distance("test", "tests") == 1
            Test.@test Strategies.levenshtein_distance("cat", "cart") == 1
            
            # Single character difference - deletion
            Test.@test Strategies.levenshtein_distance("tests", "test") == 1
            Test.@test Strategies.levenshtein_distance("cart", "cat") == 1
            
            # Multiple differences
            Test.@test Strategies.levenshtein_distance("kitten", "sitting") == 3
            Test.@test Strategies.levenshtein_distance("saturday", "sunday") == 3
            
            # Empty strings
            Test.@test Strategies.levenshtein_distance("test", "") == 4
            Test.@test Strategies.levenshtein_distance("", "test") == 4
            Test.@test Strategies.levenshtein_distance("hello", "") == 5
            
            # Relevant for option names
            Test.@test Strategies.levenshtein_distance("max_iter", "max_it") == 2
            Test.@test Strategies.levenshtein_distance("tolerance", "tolrance") == 1
            Test.@test Strategies.levenshtein_distance("verbose", "verbos") == 1
            
            # Symmetry property
            Test.@test Strategies.levenshtein_distance("abc", "def") == 
                       Strategies.levenshtein_distance("def", "abc")
            Test.@test Strategies.levenshtein_distance("hello", "world") == 
                       Strategies.levenshtein_distance("world", "hello")
        end
        
        # ====================================================================
        # options_dict
        # ====================================================================
        
        Test.@testset "options_dict" begin
            # Create a strategy with options
            strategy = TestUtilStrategy(
                Strategies.build_strategy_options(
                    TestUtilStrategy;
                    max_iter=500,
                    tolerance=1e-8,
                    verbose=true
                )
            )
            
            # Extract options as Dict
            options = Strategies.options_dict(strategy)
            
            # Verify it's a Dict
            Test.@test options isa Dict{Symbol, Any}
            
            # Verify all options are present
            Test.@test haskey(options, :max_iter)
            Test.@test haskey(options, :tolerance)
            Test.@test haskey(options, :verbose)
            
            # Verify values are correct (unwrapped from OptionValue)
            Test.@test options[:max_iter] == 500
            Test.@test options[:tolerance] == 1e-8
            Test.@test options[:verbose] == true
            
            # Verify it's mutable (can modify)
            options[:max_iter] = 1000
            Test.@test options[:max_iter] == 1000
            
            # Verify can add new keys
            options[:new_option] = :test
            Test.@test options[:new_option] == :test
            
            # Verify can delete keys
            delete!(options, :verbose)
            Test.@test !haskey(options, :verbose)
            Test.@test haskey(options, :max_iter)
            Test.@test haskey(options, :tolerance)
        end
        
        # ====================================================================
        # Integration: Utilities pipeline
        # ====================================================================
        
        Test.@testset "Integration: Utilities pipeline" begin
            # Create options and filter
            opts = (max_iter=100, tolerance=1e-6, verbose=true, debug=false, extra=:value)
            
            # Filter debug options
            filtered = Strategies.filter_options(opts, (:debug, :extra))
            Test.@test filtered == (max_iter=100, tolerance=1e-6, verbose=true)
            
            # Get suggestions for typo
            suggestions = Strategies.suggest_options(:max_itr, TestUtilStrategy)
            Test.@test suggestions[1].primary == :max_iter
            
            # Verify distance calculation
            dist = Strategies.levenshtein_distance("max_itr", "max_iter")
            Test.@test dist == 1  # One character difference
        end
        
        # ====================================================================
        # Integration: options_dict workflow
        # ====================================================================
        
        Test.@testset "Integration: options_dict workflow" begin
            # Create strategy
            strategy = TestUtilStrategy(
                Strategies.build_strategy_options(
                    TestUtilStrategy;
                    max_iter=100,
                    tolerance=1e-6
                )
            )
            
            # Extract and modify options (typical solver extension pattern)
            options = Strategies.options_dict(strategy)
            options[:verbose] = true  # Modify
            options[:max_iter] = 200  # Override
            
            # Verify modifications
            Test.@test options[:verbose] == true
            Test.@test options[:max_iter] == 200
            Test.@test options[:tolerance] == 1e-6
            
            # Original strategy options unchanged
            orig_opts = Strategies.options(strategy)
            Test.@test orig_opts[:max_iter] == 100
            Test.@test orig_opts[:verbose] == false
        end
    end
end

end # module

test_utilities() = TestStrategiesUtilities.test_utilities()

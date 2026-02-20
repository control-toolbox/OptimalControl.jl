module TestStrategiesConfiguration

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options: OptionDefinition, OptionValue
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test strategies with metadata
# ============================================================================

abstract type AbstractTestStrategy <: Strategies.AbstractStrategy end

struct TestStrategyA <: AbstractTestStrategy
    options::Strategies.StrategyOptions
end

struct TestStrategyB <: AbstractTestStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{TestStrategyA}) = :test_a
Strategies.id(::Type{TestStrategyB}) = :test_b

Strategies.metadata(::Type{TestStrategyA}) = Strategies.StrategyMetadata(
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

Strategies.metadata(::Type{TestStrategyB}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :default,
        description = "Backend to use"
    ),
    OptionDefinition(
        name = :precision,
        type = Int,
        default = 64,
        description = "Numerical precision",
        validator = x -> x in (32, 64, 128)
    )
)

Strategies.options(s::Union{TestStrategyA, TestStrategyB}) = s.options

# ============================================================================
# Test function
# ============================================================================

"""
    test_configuration()

Tests for strategy configuration.
"""
function test_configuration()
    Test.@testset "Strategy Configuration" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # build_strategy_options
        # ====================================================================
        
        Test.@testset "build_strategy_options" begin
            # Basic construction with defaults
            opts = Strategies.build_strategy_options(TestStrategyA)
            Test.@test opts isa Strategies.StrategyOptions
            Test.@test opts[:max_iter] == 100
            Test.@test opts[:tolerance] == 1e-6
            Test.@test opts[:verbose] == false
            
            # Override with user values
            opts2 = Strategies.build_strategy_options(TestStrategyA; max_iter=200)
            Test.@test opts2[:max_iter] == 200
            Test.@test opts2[:tolerance] == 1e-6
            
            # Multiple user values
            opts3 = Strategies.build_strategy_options(
                TestStrategyA; max_iter=300, tolerance=1e-8, verbose=true
            )
            Test.@test opts3[:max_iter] == 300
            Test.@test opts3[:tolerance] == 1e-8
            Test.@test opts3[:verbose] == true
            
            # Alias resolution
            opts4 = Strategies.build_strategy_options(TestStrategyA; max=150)
            Test.@test opts4[:max_iter] == 150
            
            opts5 = Strategies.build_strategy_options(TestStrategyA; tol=1e-10)
            Test.@test opts5[:tolerance] == 1e-10
            
            # Different strategy
            opts6 = Strategies.build_strategy_options(TestStrategyB; backend=:sparse)
            Test.@test opts6[:backend] == :sparse
            Test.@test opts6[:precision] == 64
        end
        
        # ====================================================================
        # BypassValue in build_strategy_options
        # ====================================================================
        
        Test.@testset "BypassValue in build_strategy_options" begin
            # Bypass unknown option
            opts = Strategies.build_strategy_options(
                TestStrategyA;
                unknown=Strategies.bypass(42)
            )
            Test.@test opts[:unknown] == 42
            Test.@test Strategies.source(opts, :unknown) == :user
            
            # Bypass type validation (max_iter is Int)
            opts2 = Strategies.build_strategy_options(
                TestStrategyA;
                max_iter=Strategies.bypass("not_an_int")
            )
            Test.@test opts2[:max_iter] == "not_an_int"
            
            # Bypass overwrites default (tolerance is 1e-6)
            opts3 = Strategies.build_strategy_options(
                TestStrategyA;
                tolerance=Strategies.bypass(1e-8)
            )
            Test.@test opts3[:tolerance] == 1e-8
        end
        
        # ====================================================================
        # resolve_alias
        # ====================================================================
        
        Test.@testset "resolve_alias" begin
            meta = Strategies.metadata(TestStrategyA)
            
            # Primary name returns itself
            Test.@test Strategies.resolve_alias(meta, :max_iter) == :max_iter
            Test.@test Strategies.resolve_alias(meta, :tolerance) == :tolerance
            Test.@test Strategies.resolve_alias(meta, :verbose) == :verbose
            
            # Aliases resolve to primary name
            Test.@test Strategies.resolve_alias(meta, :max) == :max_iter
            Test.@test Strategies.resolve_alias(meta, :maxiter) == :max_iter
            Test.@test Strategies.resolve_alias(meta, :tol) == :tolerance
            
            # Unknown key returns nothing
            Test.@test Strategies.resolve_alias(meta, :unknown) === nothing
            Test.@test Strategies.resolve_alias(meta, :invalid) === nothing
        end
        
        # ====================================================================
        # filter_options
        # ====================================================================
        
        Test.@testset "filter_options" begin
            opts = (max_iter=100, tolerance=1e-6, verbose=true, debug=false)
            
            # Filter single key
            filtered1 = Strategies.filter_options(opts, :debug)
            Test.@test filtered1 == (max_iter=100, tolerance=1e-6, verbose=true)
            Test.@test !haskey(filtered1, :debug)
            
            # Filter multiple keys
            filtered2 = Strategies.filter_options(opts, (:debug, :verbose))
            Test.@test filtered2 == (max_iter=100, tolerance=1e-6)
            Test.@test !haskey(filtered2, :debug)
            Test.@test !haskey(filtered2, :verbose)
            
            # Filter all keys
            filtered3 = Strategies.filter_options(opts, (:max_iter, :tolerance, :verbose, :debug))
            Test.@test filtered3 == NamedTuple()
            Test.@test length(filtered3) == 0
            
            # Filter non-existent key (should not error)
            filtered4 = Strategies.filter_options(opts, :nonexistent)
            Test.@test filtered4 == opts
        end
        
        # ====================================================================
        # suggest_options
        # ====================================================================
        
        Test.@testset "suggest_options" begin
            # Similar to existing option
            suggestions1 = Strategies.suggest_options(:max_it, TestStrategyA)
            Test.@test suggestions1[1].primary == :max_iter
            
            # Similar to alias
            suggestions2 = Strategies.suggest_options(:tolrance, TestStrategyA)
            Test.@test suggestions2[1].primary == :tolerance
            
            # Limit suggestions
            suggestions3 = Strategies.suggest_options(:x, TestStrategyA; max_suggestions=2)
            Test.@test length(suggestions3) <= 2
            
            # Returns structured results
            suggestions4 = Strategies.suggest_options(:unknown, TestStrategyA)
            Test.@test !isempty(suggestions4)
            Test.@test haskey(suggestions4[1], :primary)
            Test.@test haskey(suggestions4[1], :aliases)
            Test.@test haskey(suggestions4[1], :distance)
        end
        
        # ====================================================================
        # levenshtein_distance (internal utility)
        # ====================================================================
        
        Test.@testset "levenshtein_distance" begin
            # Identical strings
            Test.@test Strategies.levenshtein_distance("test", "test") == 0
            
            # Single character difference
            Test.@test Strategies.levenshtein_distance("test", "best") == 1
            Test.@test Strategies.levenshtein_distance("test", "text") == 1
            
            # Multiple differences
            Test.@test Strategies.levenshtein_distance("kitten", "sitting") == 3
            
            # Empty strings
            Test.@test Strategies.levenshtein_distance("", "") == 0
            Test.@test Strategies.levenshtein_distance("test", "") == 4
            Test.@test Strategies.levenshtein_distance("", "test") == 4
            
            # Relevant for option names
            Test.@test Strategies.levenshtein_distance("max_iter", "max_it") == 2
            Test.@test Strategies.levenshtein_distance("tolerance", "tolrance") == 1
        end
        
        # ====================================================================
        # Integration: Full pipeline
        # ====================================================================
        
        Test.@testset "Integration: Configuration pipeline" begin
            # Build options with aliases
            opts = Strategies.build_strategy_options(
                TestStrategyA;
                max=250,  # Alias for max_iter
                tol=1e-9  # Alias for tolerance
            )
            
            Test.@test opts[:max_iter] == 250
            Test.@test opts[:tolerance] == 1e-9
            Test.@test opts[:verbose] == false  # Default
            
            # Filter and verify
            raw_opts = (max_iter=250, tolerance=1e-9, verbose=false)
            filtered = Strategies.filter_options(raw_opts, :verbose)
            Test.@test filtered == (max_iter=250, tolerance=1e-9)
        end
    end
end

end # module

test_configuration() = TestStrategiesConfiguration.test_configuration()

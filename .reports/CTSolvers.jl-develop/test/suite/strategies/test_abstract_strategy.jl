module TestStrategiesAbstractStrategy

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake strategy types for testing (must be at module top-level)
# ============================================================================

struct FakeStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

struct IncompleteStrategy <: Strategies.AbstractStrategy
    # Missing options field - should trigger error path
end

# ============================================================================
# Implement required contract methods for FakeStrategy
# ============================================================================

Strategies.id(::Type{<:FakeStrategy}) = :fake
Strategies.id(::Type{<:IncompleteStrategy}) = :incomplete

Strategies.metadata(::Type{<:FakeStrategy}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 100,
        description = "Maximum iterations",
        aliases = (:max, :maxiter)
    ),
    Options.OptionDefinition(
        name = :tol,
        type = Float64,
        default = 1e-6,
        description = "Tolerance"
    )
)

Strategies.metadata(::Type{<:IncompleteStrategy}) = Strategies.StrategyMetadata()

Strategies.options(strategy::FakeStrategy) = strategy.options

# Additional test struct for error handling
struct UnimplementedStrategy <: Strategies.AbstractStrategy end

# ============================================================================
# Test function
# ============================================================================

"""
    test_abstract_strategy()

Tests for abstract strategy contract.
"""
function test_abstract_strategy()
    Test.@testset "Abstract Strategy" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ========================================================================
        # UNIT TESTS
        # ========================================================================
        
        Test.@testset "Unit Tests" begin
            
            Test.@testset "AbstractStrategy type" begin
                Test.@test FakeStrategy <: Strategies.AbstractStrategy
                Test.@test IncompleteStrategy <: Strategies.AbstractStrategy
            end
            
            Test.@testset "id() type-level" begin
                Test.@test Strategies.id(FakeStrategy) == :fake
                Test.@test Strategies.id(IncompleteStrategy) == :incomplete
            end
            
            Test.@testset "id() with typeof" begin
                fake_opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user)
                )
                fake_strategy = FakeStrategy(fake_opts)
                
                Test.@test Strategies.id(typeof(fake_strategy)) == :fake
                Test.@test Strategies.id(typeof(fake_strategy)) == Strategies.id(FakeStrategy)
            end
            
            Test.@testset "metadata function" begin
                fake_meta = Strategies.metadata(FakeStrategy)
                Test.@test fake_meta isa Strategies.StrategyMetadata
                Test.@test length(fake_meta) == 2
                Test.@test :max_iter in keys(fake_meta)
                Test.@test :tol in keys(fake_meta)
                
                incomplete_meta = Strategies.metadata(IncompleteStrategy)
                Test.@test incomplete_meta isa Strategies.StrategyMetadata
                Test.@test length(incomplete_meta) == 0
            end
            
            Test.@testset "options function" begin
                fake_opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user)
                )
                fake_strategy = FakeStrategy(fake_opts)
                
                retrieved_opts = Strategies.options(fake_strategy)
                Test.@test retrieved_opts === fake_opts
                Test.@test retrieved_opts[:max_iter] == 200
            end
            
            Test.@testset "Error handling" begin
                # Test NotImplemented errors for unimplemented methods
                Test.@test_throws Exceptions.NotImplemented Strategies.id(UnimplementedStrategy)
                Test.@test_throws Exceptions.NotImplemented Strategies.metadata(UnimplementedStrategy)
                
                # Test options error for strategy without options field
                incomplete_strategy = IncompleteStrategy()
                Test.@test_throws Exceptions.NotImplemented Strategies.options(incomplete_strategy)
            end
        end
        
        # ========================================================================
        # INTEGRATION TESTS
        # ========================================================================
        
        Test.@testset "Integration Tests" begin
            
            Test.@testset "Complete strategy workflow" begin
                # Create strategy with options
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :user)
                )
                strategy = FakeStrategy(opts)
                
                # Test complete contract
                Test.@test Strategies.id(typeof(strategy)) == :fake
                Test.@test Strategies.metadata(typeof(strategy)) isa Strategies.StrategyMetadata
                Test.@test Strategies.options(strategy) === opts
                
                # Verify metadata contains expected options
                meta = Strategies.metadata(typeof(strategy))
                Test.@test :max_iter in keys(meta)
                Test.@test meta[:max_iter].type == Int
                Test.@test meta[:max_iter].default == 100
            end
            
            Test.@testset "Strategy with aliases" begin
                # Test that metadata correctly handles aliases
                meta = Strategies.metadata(FakeStrategy)
                max_iter_def = meta[:max_iter]
                
                Test.@test max_iter_def.aliases == (:max, :maxiter)
                Test.@test :max_iter in keys(meta)
                Test.@test :tol in keys(meta)
            end
            
            Test.@testset "Strategy display" begin
                opts = Strategies.StrategyOptions(
                    max_iter = Options.OptionValue(200, :user),
                    tol = Options.OptionValue(1e-8, :default)
                )
                strategy = FakeStrategy(opts)
                
                # Test that strategy components can be displayed
                redirect_stdout(devnull) do
                    Test.@test_nowarn show(stdout, Strategies.metadata(typeof(strategy)))
                    Test.@test_nowarn show(stdout, Strategies.options(strategy))
                end
            end
        end
    end
end

end # module

test_abstract_strategy() = TestStrategiesAbstractStrategy.test_abstract_strategy()

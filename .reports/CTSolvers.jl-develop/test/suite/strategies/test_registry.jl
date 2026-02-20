module TestStrategiesRegistry

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

abstract type AbstractTestFamily <: Strategies.AbstractStrategy end
abstract type AbstractOtherFamily <: Strategies.AbstractStrategy end

struct TestStrategyA <: AbstractTestFamily
    options::Strategies.StrategyOptions
end

struct TestStrategyB <: AbstractTestFamily
    options::Strategies.StrategyOptions
end

struct TestStrategyC <: AbstractOtherFamily
    options::Strategies.StrategyOptions
end

struct WrongTypeStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

# ============================================================================
# Implement contract methods
# ============================================================================

Strategies.id(::Type{<:TestStrategyA}) = :strategy_a
Strategies.id(::Type{<:TestStrategyB}) = :strategy_b
Strategies.id(::Type{<:TestStrategyC}) = :strategy_c
Strategies.id(::Type{<:WrongTypeStrategy}) = :wrong

Strategies.metadata(::Type{<:TestStrategyA}) = Strategies.StrategyMetadata()
Strategies.metadata(::Type{<:TestStrategyB}) = Strategies.StrategyMetadata()
Strategies.metadata(::Type{<:TestStrategyC}) = Strategies.StrategyMetadata()
Strategies.metadata(::Type{<:WrongTypeStrategy}) = Strategies.StrategyMetadata()

# ============================================================================
# Test function
# ============================================================================

"""
    test_registry()

Tests for strategy registry API.
"""
function test_registry()
    Test.@testset "Strategy Registry" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ========================================================================
        # UNIT TESTS
        # ========================================================================
        
        Test.@testset "Unit Tests" begin
            
            Test.@testset "StrategyRegistry type" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB)
                )
                Test.@test registry isa Strategies.StrategyRegistry
                Test.@test hasfield(typeof(registry), :families)
            end
            
            Test.@testset "create_registry - basic creation" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB),
                    AbstractOtherFamily => (TestStrategyC,)
                )
                
                Test.@test registry isa Strategies.StrategyRegistry
                Test.@test length(registry.families) == 2
                Test.@test haskey(registry.families, AbstractTestFamily)
                Test.@test haskey(registry.families, AbstractOtherFamily)
            end
            
            Test.@testset "create_registry - empty registry" begin
                registry = Strategies.create_registry()
                Test.@test registry isa Strategies.StrategyRegistry
                Test.@test length(registry.families) == 0
            end
            
            Test.@testset "create_registry - single family" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA,)
                )
                Test.@test length(registry.families) == 1
                Test.@test length(registry.families[AbstractTestFamily]) == 1
            end
            
            Test.@testset "create_registry - validation: duplicate IDs" begin
                # Create a duplicate ID by reusing TestStrategyA
                Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyA)
                )
            end
            
            Test.@testset "create_registry - validation: wrong type hierarchy" begin
                # WrongTypeStrategy is not a subtype of AbstractTestFamily
                Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, WrongTypeStrategy)
                )
            end
            
            Test.@testset "create_registry - validation: duplicate family" begin
                Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA,),
                    AbstractTestFamily => (TestStrategyB,)
                )
            end
            
            Test.@testset "strategy_ids - basic lookup" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB),
                    AbstractOtherFamily => (TestStrategyC,)
                )
                
                ids = Strategies.strategy_ids(AbstractTestFamily, registry)
                Test.@test ids isa Tuple
                Test.@test length(ids) == 2
                Test.@test :strategy_a in ids
                Test.@test :strategy_b in ids
                
                other_ids = Strategies.strategy_ids(AbstractOtherFamily, registry)
                Test.@test length(other_ids) == 1
                Test.@test :strategy_c in other_ids
            end
            
            Test.@testset "strategy_ids - empty family" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => ()
                )
                ids = Strategies.strategy_ids(AbstractTestFamily, registry)
                Test.@test ids isa Tuple
                Test.@test length(ids) == 0
            end
            
            Test.@testset "strategy_ids - unknown family" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA,)
                )
                Test.@test_throws Exceptions.IncorrectArgument Strategies.strategy_ids(
                    AbstractOtherFamily, registry
                )
            end
            
            Test.@testset "type_from_id - basic lookup" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB)
                )
                
                T = Strategies.type_from_id(:strategy_a, AbstractTestFamily, registry)
                Test.@test T === TestStrategyA
                
                T2 = Strategies.type_from_id(:strategy_b, AbstractTestFamily, registry)
                Test.@test T2 === TestStrategyB
            end
            
            Test.@testset "type_from_id - unknown ID" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA,)
                )
                Test.@test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                    :nonexistent, AbstractTestFamily, registry
                )
            end
            
            Test.@testset "type_from_id - unknown family" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA,)
                )
                Test.@test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                    :strategy_a, AbstractOtherFamily, registry
                )
            end
            
            Test.@testset "Display - show(io, registry)" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB)
                )
                io = IOBuffer()
                show(io, registry)
                output = String(take!(io))
                Test.@test occursin("StrategyRegistry", output)
                Test.@test occursin("families", output) || occursin("family", output)
            end
            
            Test.@testset "Display - show(io, MIME, registry)" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB),
                    AbstractOtherFamily => (TestStrategyC,)
                )
                io = IOBuffer()
                show(io, MIME("text/plain"), registry)
                output = String(take!(io))
                Test.@test occursin("StrategyRegistry", output)
                Test.@test occursin("AbstractTestFamily", output)
                Test.@test occursin("AbstractOtherFamily", output)
            end
        end
        
        # ========================================================================
        # INTEGRATION TESTS
        # ========================================================================
        
        Test.@testset "Integration Tests" begin
            
            Test.@testset "Registry with multiple families" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB),
                    AbstractOtherFamily => (TestStrategyC,)
                )
                
                # Lookup across families
                T1 = Strategies.type_from_id(:strategy_a, AbstractTestFamily, registry)
                T2 = Strategies.type_from_id(:strategy_c, AbstractOtherFamily, registry)
                
                Test.@test T1 === TestStrategyA
                Test.@test T2 === TestStrategyC
                Test.@test T1 !== T2
                
                # IDs are scoped to families
                ids1 = Strategies.strategy_ids(AbstractTestFamily, registry)
                ids2 = Strategies.strategy_ids(AbstractOtherFamily, registry)
                Test.@test length(ids1) == 2
                Test.@test length(ids2) == 1
            end
            
            Test.@testset "Round-trip: type -> id -> type" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA, TestStrategyB)
                )
                
                original_type = TestStrategyA
                strategy_id = Strategies.id(original_type)
                retrieved_type = Strategies.type_from_id(
                    strategy_id, AbstractTestFamily, registry
                )
                
                Test.@test retrieved_type === original_type
            end
            
            Test.@testset "Registry immutability" begin
                registry = Strategies.create_registry(
                    AbstractTestFamily => (TestStrategyA,)
                )
                
                # Registry should be immutable - cannot add families after creation
                Test.@test !ismutable(registry)
            end
        end
    end
end

end # module

test_registry() = TestStrategiesRegistry.test_registry()

"""
Unit tests for option disambiguation with RoutedOption and route_to().

Tests the behavior of the route_to() helper function and RoutedOption type
for creating disambiguated option values with strategy routing.
"""
module TestDisambiguation

import Test
import CTSolvers
import CTSolvers.Strategies

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_disambiguation()
    Test.@testset "Option Disambiguation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - RoutedOption Type
        # ====================================================================
        
        Test.@testset "RoutedOption Type" begin
            # Create RoutedOption directly
            routes = (solver=100,)
            opt = Strategies.RoutedOption(routes)
            Test.@test opt isa Strategies.RoutedOption
            Test.@test collect(pairs(opt)) == collect(pairs(routes))
            
            # Empty routes should throw
            Test.@test_throws Exception Strategies.RoutedOption(NamedTuple())
        end
        
        # ====================================================================
        # UNIT TESTS - route_to() Basic Functionality
        # ====================================================================
        
        Test.@testset "route_to() Single Strategy" begin
            result = Strategies.route_to(solver=100)
            Test.@test result isa Strategies.RoutedOption
            Test.@test length(result) == 1
            Test.@test result[:solver] == 100
        end
        
        Test.@testset "route_to() Multiple Strategies" begin
            result = Strategies.route_to(solver=100, modeler=50)
            Test.@test result isa Strategies.RoutedOption
            Test.@test length(result) == 2
            Test.@test result[:solver] == 100
            Test.@test result[:modeler] == 50
        end
        
        Test.@testset "route_to() No Arguments Error" begin
            Test.@test_throws Exception Strategies.route_to()
        end
        
        # ====================================================================
        # UNIT TESTS - Different Value Types
        # ====================================================================
        
        Test.@testset "Different Value Types" begin
            # Integer value
            result = Strategies.route_to(modeler=42)
            Test.@test result[:modeler] == 42
            
            # Float value
            result = Strategies.route_to(solver=1.5e-6)
            Test.@test result[:solver] == 1.5e-6
            
            # String value
            result = Strategies.route_to(optimizer="ipopt")
            Test.@test result[:optimizer] == "ipopt"
            
            # Boolean value
            result = Strategies.route_to(solver=true)
            Test.@test result[:solver] == true
            
            # Symbol value
            result = Strategies.route_to(modeler=:auto)
            Test.@test result[:modeler] == :auto
        end
        
        Test.@testset "Different Strategy Identifiers" begin
            # Common strategy identifiers
            Test.@test Strategies.route_to(solver=100)[:solver] == 100
            Test.@test Strategies.route_to(modeler=100)[:modeler] == 100
            Test.@test Strategies.route_to(optimizer=100)[:optimizer] == 100
            Test.@test Strategies.route_to(discretizer=100)[:discretizer] == 100
        end
        
        # ====================================================================
        # UNIT TESTS - Complex Values
        # ====================================================================
        
        Test.@testset "Complex Value Types" begin
            # Array value
            result = Strategies.route_to(solver=[1, 2, 3])
            Test.@test result[:solver] == [1, 2, 3]
            
            # Tuple value
            result = Strategies.route_to(modeler=(1, 2))
            Test.@test result[:modeler] == (1, 2)
            
            # NamedTuple value
            result = Strategies.route_to(solver=(a=1, b=2))
            Test.@test result[:solver] == (a=1, b=2)
        end
        
        # ====================================================================
        # UNIT TESTS - Multiple Strategies Use Cases
        # ====================================================================
        
        Test.@testset "Multiple Strategies with Same Option" begin
            # Different values for different strategies
            result = Strategies.route_to(solver=100, modeler=50, discretizer=200)
            Test.@test length(result) == 3
            Test.@test result[:solver] == 100
            Test.@test result[:modeler] == 50
            Test.@test result[:discretizer] == 200
        end
        
        # ====================================================================
        # UNIT TESTS - Edge Cases
        # ====================================================================
        
        Test.@testset "Edge Cases" begin
            # Nothing value
            result = Strategies.route_to(solver=nothing)
            Test.@test result[:solver] === nothing
            
            # Missing value
            result = Strategies.route_to(solver=missing)
            Test.@test result[:solver] === missing
        end

        # ====================================================================
        # UNIT TESTS - Collection Interface
        # ====================================================================

        Test.@testset "Collection Interface - Iteration" begin
            opt = Strategies.route_to(solver=100, modeler=50)

            # Test keys()
            Test.@test :solver in keys(opt)
            Test.@test :modeler in keys(opt)
            Test.@test collect(keys(opt)) == [:solver, :modeler]

            # Test values()
            Test.@test 100 in values(opt)
            Test.@test 50 in values(opt)
            Test.@test collect(values(opt)) == [100, 50]

            # Test pairs()
            pairs_collected = collect(pairs(opt))
            Test.@test length(pairs_collected) == 2
            Test.@test pairs_collected[1] == (:solver => 100)
            Test.@test pairs_collected[2] == (:modeler => 50)

            # Test direct iteration (should yield pairs)
            for (id, val) in opt
                Test.@test id in (:solver, :modeler)
                Test.@test val in (100, 50)
            end

            # Test getindex[]
            Test.@test opt[:solver] == 100
            Test.@test opt[:modeler] == 50

            # Test haskey
            Test.@test haskey(opt, :solver)
            Test.@test haskey(opt, :modeler)
            Test.@test !haskey(opt, :discretizer)

            # Test length
            Test.@test length(opt) == 2
            Test.@test length(Strategies.route_to(solver=1)) == 1
        end
    end
end

end # module

# Export test function to outer scope
test_disambiguation() = TestDisambiguation.test_disambiguation()

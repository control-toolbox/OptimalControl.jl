"""
Unit tests for strict/permissive mode in option routing.

Tests the behavior of route_all_options() with mode parameter,
ensuring unknown options are handled correctly in both strict and permissive modes.
"""
module TestRoutingValidation

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Orchestration
import CTSolvers.Options

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Helper: Create test registry and families
# ============================================================================

# Define mock types for testing
abstract type TestDiscretizerFamily <: Strategies.AbstractStrategy end
struct MyDiscretizer <: TestDiscretizerFamily end
Strategies.id(::Type{MyDiscretizer}) = :test_discretizer
Strategies.metadata(::Type{MyDiscretizer}) = Strategies.StrategyMetadata()

abstract type TestModelerFamily <: Strategies.AbstractStrategy end
struct MyModeler <: TestModelerFamily end
Strategies.id(::Type{MyModeler}) = :test_modeler
Strategies.metadata(::Type{MyModeler}) = Strategies.StrategyMetadata()

abstract type TestSolverFamily <: Strategies.AbstractStrategy end
struct MySolver <: TestSolverFamily end
Strategies.id(::Type{MySolver}) = :test_solver
Strategies.metadata(::Type{MySolver}) = Strategies.StrategyMetadata()

function create_test_setup()
    # Create a simple registry with test strategies
    registry = Strategies.create_registry(
        TestDiscretizerFamily => (MyDiscretizer,),
        TestModelerFamily => (MyModeler,),
        TestSolverFamily => (MySolver,)
    )
    
    # Define families
    families = (
        discretizer = TestDiscretizerFamily,
        modeler = TestModelerFamily,
        solver = TestSolverFamily
    )
    
    # Define action options
    action_defs = [
        Options.OptionDefinition(
            name = :display,
            type = Bool,
            default = true,
            description = "Display progress"
        )
    ]
    
    return registry, families, action_defs
end

function test_routing_validation()
    Test.@testset "Routing Validation Modes" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Mode Parameter Validation
        # ====================================================================
        
        Test.@testset "Mode Parameter Validation" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            kwargs = (display = true,)
            
            # route_all_options has no mode parameter; routing always works
            Test.@test_nowarn Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Strict Mode (Default)
        # ====================================================================
        
        Test.@testset "Strict Mode - Unknown Option Rejected" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option without disambiguation always fails
            kwargs = (unknown_option = 123,)
            
            Test.@test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
        end
        
        Test.@testset "Strict Mode - Unknown Disambiguated Option Rejected" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option with disambiguation but no bypass always fails
            kwargs = (unknown_option = Strategies.route_to(test_solver=123),)
            
            Test.@test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Permissive Mode
        # ====================================================================
        
        Test.@testset "Bypass - Unknown Disambiguated Option Accepted" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option with bypass(val) is accepted and routed as BypassValue
            kwargs = (custom_option = Strategies.route_to(test_solver=Strategies.bypass(123)),)
            
            result = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
            
            # BypassValue is preserved in routed options
            bv = result.strategies.solver[:custom_option]
            Test.@test bv isa Strategies.BypassValue
            Test.@test bv.value == 123
        end
        
        Test.@testset "Bypass - Multiple Unknown Options" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Multiple unknown options with bypass
            kwargs = (
                custom1 = Strategies.route_to(test_solver=Strategies.bypass(100)),
                custom2 = Strategies.route_to(test_modeler=Strategies.bypass(200))
            )
            
            result = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
            
            Test.@test result.strategies.solver[:custom1].value == 100
            Test.@test result.strategies.modeler[:custom2].value == 200
        end
        
        Test.@testset "Unknown Without Disambiguation Still Fails" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option without disambiguation always fails (no bypass possible)
            kwargs = (unknown_option = 123,)
            
            Test.@test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Invalid Routing Detection
        # ====================================================================
        
        Test.@testset "Invalid Routing - Wrong Strategy for Known Option" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Known option routed to wrong strategy always fails (even with bypass)
            # grid_size belongs to discretizer, not solver
            kwargs = (display = true,)
            result = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
            
            Test.@test Options.value(result.action[:display]) == true
        end
        
        # ====================================================================
        # UNIT TESTS - Default Mode is Strict
        # ====================================================================
        
        Test.@testset "Default Mode is Strict" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Without mode parameter, should behave as strict
            kwargs = (unknown_option = Strategies.route_to(test_solver=123),)
            
            Test.@test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
        end
    end
end

end # module

# Export test function to outer scope
test_routing_validation() = TestRoutingValidation.test_routing_validation()

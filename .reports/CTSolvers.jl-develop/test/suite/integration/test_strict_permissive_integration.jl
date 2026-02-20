"""
Integration tests for strict/permissive validation system.

Tests complete workflows combining option validation, routing, and disambiguation
to ensure the system works correctly end-to-end.
"""

module TestStrictPermissiveIntegration

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Orchestration

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Fake types for integration testing
# ============================================================================

# Define distinct abstract families for testing
# This allows proper routing and disambiguation tests
"""Abstract family for test solvers."""
abstract type AbstractTestSolver <: Strategies.AbstractStrategy end

"""Abstract family for test modelers."""
abstract type AbstractTestModeler <: Strategies.AbstractStrategy end

"""Abstract family for test discretizers."""
abstract type AbstractTestDiscretizer <: Strategies.AbstractStrategy end

"""Fake solver strategy for testing."""
struct FakeSolver <: AbstractTestSolver
    options::Strategies.StrategyOptions
end

"""Fake modeler strategy for testing."""
struct FakeModeler <: AbstractTestModeler
    options::Strategies.StrategyOptions
end

"""Fake discretizer strategy for testing."""
struct FakeDiscretizer <: AbstractTestDiscretizer
    options::Strategies.StrategyOptions
end

# Strategy IDs
Strategies.id(::Type{FakeSolver}) = :fake_solver
Strategies.id(::Type{FakeModeler}) = :fake_modeler
Strategies.id(::Type{FakeDiscretizer}) = :fake_discretizer

# Metadata for FakeSolver
function Strategies.metadata(::Type{FakeSolver})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:max_iter,
            type=Int,
            default=1000,
            description="Maximum iterations"
        ),
        Options.OptionDefinition(
            name=:tol,
            type=Float64,
            default=1e-6,
            description="Tolerance"
        )
    )
end

# Metadata for FakeModeler
function Strategies.metadata(::Type{FakeModeler})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:backend,
            type=Symbol,
            default=:sparse,
            description="Backend type"
        ),
        Options.OptionDefinition(
            name=:max_iter,
            type=Int,
            default=500,
            description="Maximum iterations"
        )
    )
end

# Metadata for FakeDiscretizer
function Strategies.metadata(::Type{FakeDiscretizer})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:grid_size,
            type=Int,
            default=100,
            description="Grid size"
        )
    )
end

# Constructors
function FakeSolver(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeSolver; mode=mode, kwargs...)
    return FakeSolver(opts)
end

function FakeModeler(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeModeler; mode=mode, kwargs...)
    return FakeModeler(opts)
end

function FakeDiscretizer(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeDiscretizer; mode=mode, kwargs...)
    return FakeDiscretizer(opts)
end

# ============================================================================
# Test Function
# ============================================================================

function test_strict_permissive_integration()
    Test.@testset "Strict/Permissive Integration" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TESTS - Single Strategy Workflows
        # ====================================================================
        
        Test.@testset "Single Strategy Workflows" begin
            
            Test.@testset "Strict workflow with valid options" begin
                # Create solver with valid options
                solver = FakeSolver(max_iter=2000, tol=1e-8)
                
                Test.@test solver isa FakeSolver
                Test.@test Strategies.option_value(solver, :max_iter) == 2000
                Test.@test Strategies.option_value(solver, :tol) == 1e-8
                Test.@test Strategies.option_source(solver, :max_iter) == :user
                Test.@test Strategies.option_source(solver, :tol) == :user
            end
            
            Test.@testset "Strict workflow rejects invalid options" begin
                # Should reject unknown option
                Test.@test_throws Exception FakeSolver(max_iter=2000, unknown=123)
                
                # Should reject invalid type
                redirect_stderr(devnull) do
                    Test.@test_throws Exception FakeSolver(max_iter="invalid")
                end
            end
            
            Test.@testset "Permissive workflow with mixed options" begin
                # Create solver with mix of known and unknown options
                redirect_stderr(devnull) do
                    solver = FakeSolver(
                        max_iter=2000,
                        tol=1e-8,
                        custom_linear_solver="ma57",
                        mu_strategy="adaptive";
                        mode=:permissive
                    )
                    
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.option_value(solver, :max_iter) == 2000
                    Test.@test Strategies.option_value(solver, :tol) == 1e-8
                    Test.@test Strategies.has_option(solver, :custom_linear_solver)
                    Test.@test Strategies.option_value(solver, :custom_linear_solver) == "ma57"
                    Test.@test Strategies.has_option(solver, :mu_strategy)
                end
            end
            
            Test.@testset "Permissive still validates known options" begin
                # Type validation should still work
                redirect_stderr(devnull) do
                    Test.@test_throws Exception FakeSolver(
                        max_iter="invalid",
                        custom_option=123;
                        mode=:permissive
                    )
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Multiple Strategy Workflows
        # ====================================================================
        
        Test.@testset "Multiple Strategy Workflows" begin
            
            Test.@testset "Multiple strategies with different modes" begin
                # Solver in strict mode
                solver = FakeSolver(max_iter=2000)
                Test.@test solver isa FakeSolver
                
                # Modeler in permissive mode
                redirect_stderr(devnull) do
                    modeler = FakeModeler(
                        backend=:dense,
                        custom_option="test";
                        mode=:permissive
                    )
                    Test.@test modeler isa FakeModeler
                    Test.@test Strategies.has_option(modeler, :custom_option)
                end
                
                # Discretizer in strict mode
                discretizer = FakeDiscretizer(grid_size=200)
                Test.@test discretizer isa FakeDiscretizer
            end
            
            Test.@testset "Ambiguous option with disambiguation" begin
                # Both solver and modeler have max_iter option
                # Test with route_to() for disambiguation
                
                routed_solver = Strategies.route_to(solver=3000)
                routed_modeler = Strategies.route_to(modeler=1500)
                
                Test.@test routed_solver isa Strategies.RoutedOption
                Test.@test routed_modeler isa Strategies.RoutedOption
                Test.@test length(routed_solver.routes) == 1
                Test.@test length(routed_modeler.routes) == 1
            end
            
            Test.@testset "Multiple strategies with route_to()" begin
                # Create routed option for multiple strategies
                routed = Strategies.route_to(
                    solver=3000,
                    modeler=1500,
                    discretizer=250
                )
                
                Test.@test routed isa Strategies.RoutedOption
                Test.@test length(routed.routes) == 3
                Test.@test routed.routes.solver == 3000
                Test.@test routed.routes.modeler == 1500
                Test.@test routed.routes.discretizer == 250
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Registry-Based Workflows
        # ====================================================================
        
        Test.@testset "Registry-Based Workflows" begin
            # Create registry with distinct families
            registry = Strategies.create_registry(
                AbstractTestSolver => (FakeSolver,),
                AbstractTestModeler => (FakeModeler,),
                AbstractTestDiscretizer => (FakeDiscretizer,)
            )
            
            Test.@testset "Build from ID in strict mode" begin
                solver = Strategies.build_strategy(
                    :fake_solver,
                    AbstractTestSolver,
                    registry;
                    max_iter=2000
                )
                Test.@test solver isa FakeSolver
                Test.@test Strategies.option_value(solver, :max_iter) == 2000
            end
            
            Test.@testset "Build from ID in permissive mode" begin
                redirect_stderr(devnull) do
                    solver = Strategies.build_strategy(
                        :fake_solver,
                        AbstractTestSolver,
                        registry;
                        max_iter=2000,
                        custom_option=123,
                        mode=:permissive
                    )
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.has_option(solver, :custom_option)
                end
            end
            
            Test.@testset "Build from method tuple" begin
                method = (:fake_solver, :fake_modeler, :fake_discretizer)
                
                # Build solver from method (first family in tuple)
                solver = Strategies.build_strategy_from_method(
                    method,
                    AbstractTestSolver,
                    registry;
                    max_iter=2000
                )
                Test.@test solver isa FakeSolver
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Routing Workflows
        # ====================================================================
        
        Test.@testset "Option Routing Workflows" begin
            registry = Strategies.create_registry(
                AbstractTestSolver => (FakeSolver,),
                AbstractTestModeler => (FakeModeler,)
            )
            
            method = (:fake_solver, :fake_modeler)
            
            Test.@testset "Routing with strict mode" begin
                # Create families map (must be NamedTuple, not Dict)
                families = (
                    solver=AbstractTestSolver,
                    modeler=AbstractTestModeler
                )
                
                # Action definitions (empty for this test)
                action_defs = Options.OptionDefinition[]
                
                # Options with disambiguation (use strategy IDs, not family names)
                kwargs = (
                    max_iter=Strategies.route_to(fake_solver=3000, fake_modeler=1500),
                    tol = 0.5e-6,
                    backend = :dense
                )
                
                # Route options (strict is the only mode now)
                routed = Orchestration.route_all_options(
                    method,
                    families,
                    action_defs,
                    kwargs,
                    registry
                )
                
                Test.@test haskey(routed.strategies, :solver)
                Test.@test haskey(routed.strategies, :modeler)
            end
            
            Test.@testset "Routing with bypass(val) for unknown options" begin
                # Create families map (must be NamedTuple, not Dict)
                families = (
                    solver=AbstractTestSolver,
                    modeler=AbstractTestModeler
                )
                
                action_defs = Options.OptionDefinition[]
                
                # Unknown options use bypass(val) to pass through validation
                kwargs = (
                    max_iter=Strategies.route_to(fake_solver=3000),
                    custom_solver_option=Strategies.route_to(fake_solver=Strategies.bypass("advanced")),
                )
                
                routed = Orchestration.route_all_options(
                    method,
                    families,
                    action_defs,
                    kwargs,
                    registry
                )
                
                Test.@test haskey(routed.strategies, :solver)
                # BypassValue is preserved in routed options
                bv = routed.strategies.solver[:custom_solver_option]
                Test.@test bv isa Strategies.BypassValue
                Test.@test bv.value == "advanced"
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Error Recovery Workflows
        # ====================================================================
        
        Test.@testset "Error Recovery Workflows" begin
            
            Test.@testset "Graceful degradation to permissive" begin
                # Try strict first, fall back to permissive
                function create_solver_safe(; kwargs...)
                    try
                        return FakeSolver(; kwargs...)
                    catch e
                        if occursin("Unknown", string(e)) || occursin("Unrecognized", string(e))
                            return FakeSolver(; kwargs..., mode=:permissive)
                        else
                            rethrow(e)
                        end
                    end
                end
                
                # Should work with unknown option via fallback
                redirect_stderr(devnull) do
                    solver = create_solver_safe(max_iter=2000, unknown=123)
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.has_option(solver, :unknown)
                end
            end
            
            Test.@testset "Validation errors not masked" begin
                # Type errors should not be caught by permissive mode
                redirect_stderr(devnull) do
                    Test.@test_throws Exception FakeSolver(
                        max_iter="invalid";
                        mode=:permissive
                    )
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Real-World Scenarios
        # ====================================================================
        
        Test.@testset "Real-World Scenarios" begin
            
            Test.@testset "Development workflow (strict)" begin
                # Developer wants early error detection
                Test.@test_throws Exception FakeSolver(
                    max_itter=2000  # Typo
                )
                
                # Error message should suggest correct option
                try
                    FakeSolver(max_itter=2000)
                    Test.@test false
                catch e
                    msg = string(e)
                    # Should suggest max_iter
                    Test.@test occursin("max_iter", msg) || occursin("Unrecognized", msg)
                end
            end
            
            Test.@testset "Production workflow (permissive)" begin
                # Production needs backend-specific options
                redirect_stderr(devnull) do
                    solver = FakeSolver(
                        max_iter=2000,
                        tol=1e-8,
                        # Backend-specific options
                        linear_solver="ma57",
                        mu_strategy="adaptive",
                        warm_start_init_point="yes";
                        mode=:permissive
                    )
                    
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.option_value(solver, :max_iter) == 2000
                    Test.@test Strategies.has_option(solver, :linear_solver)
                    Test.@test Strategies.has_option(solver, :mu_strategy)
                    Test.@test Strategies.has_option(solver, :warm_start_init_point)
                end
            end
            
            Test.@testset "Migration workflow" begin
                # Old code with deprecated options
                function create_legacy_solver()
                    # Use permissive mode for gradual migration
                    return FakeSolver(
                        max_iter=2000,
                        old_option="legacy",
                        deprecated_flag=true;
                        mode=:permissive
                    )
                end
                
                redirect_stderr(devnull) do
                    solver = create_legacy_solver()
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.has_option(solver, :old_option)
                    Test.@test Strategies.has_option(solver, :deprecated_flag)
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Performance Scenarios
        # ====================================================================
        
        Test.@testset "Performance Scenarios" begin
            
            Test.@testset "Many options in strict mode" begin
                # Should handle many known options efficiently
                solver = FakeSolver(
                    max_iter=2000,
                    tol=1e-8
                )
                Test.@test solver isa FakeSolver
            end
            
            Test.@testset "Many options in permissive mode" begin
                # Should handle many unknown options efficiently
                redirect_stderr(devnull) do
                    solver = FakeSolver(
                        max_iter=2000,
                        tol=1e-8,
                        opt1="a", opt2="b", opt3="c", opt4="d", opt5="e",
                        opt6="f", opt7="g", opt8="h", opt9="i", opt10="j";
                        mode=:permissive
                    )
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.has_option(solver, :opt1)
                    Test.@test Strategies.has_option(solver, :opt10)
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Edge Cases
        # ====================================================================
        
        Test.@testset "Edge Cases" begin
            
            Test.@testset "Empty options" begin
                # Should work with no options
                solver = FakeSolver()
                Test.@test solver isa FakeSolver
                Test.@test Strategies.option_source(solver, :max_iter) == :default
            end
            
            Test.@testset "Only unknown options in permissive" begin
                # Should work with only unknown options
                redirect_stderr(devnull) do
                    solver = FakeSolver(
                        unknown1=1,
                        unknown2=2,
                        unknown3=3;
                        mode=:permissive
                    )
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.has_option(solver, :unknown1)
                    Test.@test Strategies.has_option(solver, :unknown2)
                    Test.@test Strategies.has_option(solver, :unknown3)
                end
            end
            
            Test.@testset "Complex value types" begin
                # Should handle various value types
                redirect_stderr(devnull) do
                    solver = FakeSolver(
                        max_iter=2000,
                        array_option=[1, 2, 3],
                        dict_option=Dict(:a => 1),
                        tuple_option=(1, 2, 3),
                        function_option=x -> x^2;
                        mode=:permissive
                    )
                    Test.@test solver isa FakeSolver
                    Test.@test Strategies.has_option(solver, :array_option)
                    Test.@test Strategies.has_option(solver, :dict_option)
                    Test.@test Strategies.has_option(solver, :tuple_option)
                    Test.@test Strategies.has_option(solver, :function_option)
                end
            end
        end
    end
end

end # module

# Export test function to outer scope
test_strict_permissive_integration() = TestStrictPermissiveIntegration.test_strict_permissive_integration()

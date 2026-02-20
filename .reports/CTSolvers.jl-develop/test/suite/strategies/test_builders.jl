module TestStrategiesBuilders

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test strategy types (reuse from test_abstract_strategy.jl)
# ============================================================================

# Define test strategy families
abstract type AbstractTestModeler <: Strategies.AbstractStrategy end
abstract type AbstractTestSolver <: Strategies.AbstractStrategy end

# Concrete test strategies
struct TestModelerA <: AbstractTestModeler
    options::Strategies.StrategyOptions
end

struct TestModelerB <: AbstractTestModeler
    options::Strategies.StrategyOptions
end

struct TestSolverX <: AbstractTestSolver
    options::Strategies.StrategyOptions
end

struct TestSolverY <: AbstractTestSolver
    options::Strategies.StrategyOptions
end

# Implement contract methods
Strategies.id(::Type{<:TestModelerA}) = :modeler_a
Strategies.id(::Type{<:TestModelerB}) = :modeler_b
Strategies.id(::Type{<:TestSolverX}) = :solver_x
Strategies.id(::Type{<:TestSolverY}) = :solver_y

Strategies.metadata(::Type{<:TestModelerA}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :dense,
        description = "Backend type"
    ),
    Options.OptionDefinition(
        name = :verbose,
        type = Bool,
        default = false,
        description = "Verbose output"
    )
)

Strategies.metadata(::Type{<:TestModelerB}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :precision,
        type = Int,
        default = 64,
        description = "Precision bits"
    )
)

Strategies.metadata(::Type{<:TestSolverX}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 100,
        description = "Maximum iterations"
    )
)

Strategies.metadata(::Type{<:TestSolverY}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :tol,
        type = Float64,
        default = 1e-6,
        description = "Tolerance"
    )
)

Strategies.options(s::Union{TestModelerA, TestModelerB, TestSolverX, TestSolverY}) = s.options

# Helper function to convert Dict{Symbol, OptionValue} to NamedTuple
function dict_to_namedtuple(d::Dict{Symbol, <:Any})
    return (; (k => v for (k, v) in d)...)
end

# Constructors with kwargs
function TestModelerA(; kwargs...)
    meta = Strategies.metadata(TestModelerA)
    defs = collect(values(meta))
    extracted, _ = Options.extract_options((; kwargs...), defs)
    opts = Strategies.StrategyOptions(dict_to_namedtuple(extracted))
    return TestModelerA(opts)
end

function TestModelerB(; kwargs...)
    meta = Strategies.metadata(TestModelerB)
    defs = collect(values(meta))
    extracted, _ = Options.extract_options((; kwargs...), defs)
    opts = Strategies.StrategyOptions(dict_to_namedtuple(extracted))
    return TestModelerB(opts)
end

function TestSolverX(; kwargs...)
    meta = Strategies.metadata(TestSolverX)
    defs = collect(values(meta))
    extracted, _ = Options.extract_options((; kwargs...), defs)
    opts = Strategies.StrategyOptions(dict_to_namedtuple(extracted))
    return TestSolverX(opts)
end

function TestSolverY(; kwargs...)
    meta = Strategies.metadata(TestSolverY)
    defs = collect(values(meta))
    extracted, _ = Options.extract_options((; kwargs...), defs)
    opts = Strategies.StrategyOptions(dict_to_namedtuple(extracted))
    return TestSolverY(opts)
end

# ============================================================================
# Test function
# ============================================================================

"""
    test_builders()

Tests for strategy builders.
"""
function test_builders()
    Test.@testset "Strategy Builders" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # Create test registry
        registry = Strategies.create_registry(
            AbstractTestModeler => (TestModelerA, TestModelerB),
            AbstractTestSolver => (TestSolverX, TestSolverY)
        )
        
        # ====================================================================
        # build_strategy
        # ====================================================================
        
        Test.@testset "build_strategy" begin
            # Build with default options
            modeler = Strategies.build_strategy(:modeler_a, AbstractTestModeler, registry)
            Test.@test modeler isa TestModelerA
            Test.@test Strategies.option_value(modeler, :backend) == :dense
            Test.@test Strategies.option_value(modeler, :verbose) == false
            
            # Build with custom options
            solver = Strategies.build_strategy(:solver_x, AbstractTestSolver, registry; max_iter=200)
            Test.@test solver isa TestSolverX
            Test.@test Strategies.option_value(solver, :max_iter) == 200
            
            # Build different strategy in same family
            modeler_b = Strategies.build_strategy(:modeler_b, AbstractTestModeler, registry; precision=32)
            Test.@test modeler_b isa TestModelerB
            Test.@test Strategies.option_value(modeler_b, :precision) == 32
            
            # Test error on unknown ID
            Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy(:unknown, AbstractTestModeler, registry)
        end
        
        # ====================================================================
        # extract_id_from_method
        # ====================================================================
        
        Test.@testset "extract_id_from_method" begin
            # Single ID for family
            method = (:modeler_a, :solver_x)
            id = Strategies.extract_id_from_method(method, AbstractTestModeler, registry)
            Test.@test id == :modeler_a
            
            # Extract different family from same method
            id2 = Strategies.extract_id_from_method(method, AbstractTestSolver, registry)
            Test.@test id2 == :solver_x
            
            # Method with multiple strategies
            method2 = (:modeler_b, :solver_y)
            id3 = Strategies.extract_id_from_method(method2, AbstractTestModeler, registry)
            Test.@test id3 == :modeler_b
            
            # Error: No ID for family
            method_no_modeler = (:solver_x, :solver_y)
            Test.@test_throws Exceptions.IncorrectArgument Strategies.extract_id_from_method(
                method_no_modeler, AbstractTestModeler, registry
            )
            
            # Error: Multiple IDs for same family
            method_duplicate = (:modeler_a, :modeler_b, :solver_x)
            Test.@test_throws Exceptions.IncorrectArgument Strategies.extract_id_from_method(
                method_duplicate, AbstractTestModeler, registry
            )
        end
        
        # ====================================================================
        # option_names_from_method
        # ====================================================================
        
        Test.@testset "option_names_from_method" begin
            method = (:modeler_a, :solver_x)
            
            # Get option names for modeler
            names = Strategies.option_names_from_method(method, AbstractTestModeler, registry)
            Test.@test names isa Tuple
            Test.@test :backend in names
            Test.@test :verbose in names
            Test.@test length(names) == 2
            
            # Get option names for solver
            names2 = Strategies.option_names_from_method(method, AbstractTestSolver, registry)
            Test.@test names2 isa Tuple
            Test.@test :max_iter in names2
            Test.@test length(names2) == 1
            
            # Different method
            method2 = (:modeler_b, :solver_y)
            names3 = Strategies.option_names_from_method(method2, AbstractTestModeler, registry)
            Test.@test :precision in names3
            Test.@test length(names3) == 1
        end
        
        # ====================================================================
        # build_strategy_from_method
        # ====================================================================
        
        Test.@testset "build_strategy_from_method" begin
            method = (:modeler_a, :solver_x)
            
            # Build modeler from method
            modeler = Strategies.build_strategy_from_method(
                method, AbstractTestModeler, registry; backend=:sparse
            )
            Test.@test modeler isa TestModelerA
            Test.@test Strategies.option_value(modeler, :backend) == :sparse
            
            # Build solver from same method
            solver = Strategies.build_strategy_from_method(
                method, AbstractTestSolver, registry; max_iter=500
            )
            Test.@test solver isa TestSolverX
            Test.@test Strategies.option_value(solver, :max_iter) == 500
            
            # Build with default options
            modeler2 = Strategies.build_strategy_from_method(
                method, AbstractTestModeler, registry
            )
            Test.@test modeler2 isa TestModelerA
            Test.@test Strategies.option_value(modeler2, :backend) == :dense
            
            # Different method
            method2 = (:modeler_b, :solver_y)
            modeler_b = Strategies.build_strategy_from_method(
                method2, AbstractTestModeler, registry; precision=128
            )
            Test.@test modeler_b isa TestModelerB
            Test.@test Strategies.option_value(modeler_b, :precision) == 128
        end
        
        # ====================================================================
        # Integration test
        # ====================================================================
        
        Test.@testset "Integration: Full pipeline" begin
            # Simulate a complete workflow
            method = (:modeler_a, :solver_x)
            
            # 1. Extract IDs
            modeler_id = Strategies.extract_id_from_method(method, AbstractTestModeler, registry)
            solver_id = Strategies.extract_id_from_method(method, AbstractTestSolver, registry)
            Test.@test modeler_id == :modeler_a
            Test.@test solver_id == :solver_x
            
            # 2. Get option names
            modeler_opts = Strategies.option_names_from_method(method, AbstractTestModeler, registry)
            solver_opts = Strategies.option_names_from_method(method, AbstractTestSolver, registry)
            Test.@test :backend in modeler_opts
            Test.@test :max_iter in solver_opts
            
            # 3. Build strategies
            modeler = Strategies.build_strategy_from_method(
                method, AbstractTestModeler, registry; backend=:sparse, verbose=true
            )
            solver = Strategies.build_strategy_from_method(
                method, AbstractTestSolver, registry; max_iter=1000
            )
            
            Test.@test modeler isa TestModelerA
            Test.@test solver isa TestSolverX
            Test.@test Strategies.option_value(modeler, :backend) == :sparse
            Test.@test Strategies.option_value(modeler, :verbose) == true
            Test.@test Strategies.option_value(solver, :max_iter) == 1000
        end
    end
end

end # module

test_builders() = TestStrategiesBuilders.test_builders()

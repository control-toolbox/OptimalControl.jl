# ============================================================================
# Solve Dispatch Logic Tests
# ============================================================================
# This file contains unit tests for the top-level `solve` dispatch mechanism.
# It uses a dynamically generated mock registry to verify that the entry point
# correctly analyzes arguments and routes the call to either `solve_explicit`
# or `solve_descriptive`, ensuring the dispatch logic is robust and isolated.

module TestDispatchLogic

import Test
import OptimalControl
import CTModels
import CTDirect
import CTSolvers
import CTBase
import CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Parametric Mock types
# ============================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution 
    components::Tuple
end

# Parametric mocks to simulate ANY strategy ID found in methods.jl
struct MockDiscretizer{ID} <: CTDirect.AbstractDiscretizer
    options::CTSolvers.StrategyOptions
end

struct MockModeler{ID} <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end

struct MockSolver{ID} <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

# Parametric mocks for parameterized strategies (CPU/GPU)
struct MockModelerParam{ID, PARAM} <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end

struct MockSolverParam{ID, PARAM} <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

# ----------------------------------------------------------------------------
# Strategies Interface Implementation
# ----------------------------------------------------------------------------

# ID accessors
CTSolvers.Strategies.id(::Type{MockDiscretizer{ID}}) where {ID} = ID
CTSolvers.Strategies.id(::Type{MockModeler{ID}})     where {ID} = ID
CTSolvers.Strategies.id(::Type{MockSolver{ID}})      where {ID} = ID
CTSolvers.Strategies.id(::Type{MockModelerParam{ID, PARAM}}) where {ID, PARAM} = ID
CTSolvers.Strategies.id(::Type{MockSolverParam{ID, PARAM}}) where {ID, PARAM} = ID

# Metadata (required by registry)
CTSolvers.Strategies.metadata(::Type{<:MockDiscretizer}) = CTSolvers.Strategies.StrategyMetadata()
CTSolvers.Strategies.metadata(::Type{<:MockModeler})     = CTSolvers.Strategies.StrategyMetadata()
CTSolvers.Strategies.metadata(::Type{<:MockSolver})      = CTSolvers.Strategies.StrategyMetadata()
CTSolvers.Strategies.metadata(::Type{<:MockModelerParam}) = CTSolvers.Strategies.StrategyMetadata()
CTSolvers.Strategies.metadata(::Type{<:MockSolverParam})  = CTSolvers.Strategies.StrategyMetadata()

# Options accessors
CTSolvers.Strategies.options(d::MockDiscretizer) = d.options
CTSolvers.Strategies.options(m::MockModeler)     = m.options
CTSolvers.Strategies.options(s::MockSolver)      = s.options
CTSolvers.Strategies.options(m::MockModelerParam) = m.options
CTSolvers.Strategies.options(s::MockSolverParam) = s.options

# Constructors (required by _build_or_use_strategy)
function MockDiscretizer{ID}(; mode::Symbol=:strict, kwargs...) where {ID}
    opts = CTSolvers.Strategies.build_strategy_options(MockDiscretizer{ID}; mode=mode, kwargs...)
    return MockDiscretizer{ID}(opts)
end

function MockModeler{ID}(; mode::Symbol=:strict, kwargs...) where {ID}
    opts = CTSolvers.Strategies.build_strategy_options(MockModeler{ID}; mode=mode, kwargs...)
    return MockModeler{ID}(opts)
end

function MockSolver{ID}(; mode::Symbol=:strict, kwargs...) where {ID}
    opts = CTSolvers.Strategies.build_strategy_options(MockSolver{ID}; mode=mode, kwargs...)
    return MockSolver{ID}(opts)
end

function MockModelerParam{ID, PARAM}(; mode::Symbol=:strict, kwargs...) where {ID, PARAM}
    opts = CTSolvers.Strategies.build_strategy_options(MockModelerParam{ID, PARAM}; mode=mode, kwargs...)
    return MockModelerParam{ID, PARAM}(opts)
end

function MockSolverParam{ID, PARAM}(; mode::Symbol=:strict, kwargs...) where {ID, PARAM}
    opts = CTSolvers.Strategies.build_strategy_options(MockSolverParam{ID, PARAM}; mode=mode, kwargs...)
    return MockSolverParam{ID, PARAM}(opts)
end

# ----------------------------------------------------------------------------
# Mock Registry Builder
# ----------------------------------------------------------------------------

function build_mock_registry_from_methods()::CTSolvers.StrategyRegistry
    # 1. Get all valid triplets from methods()
    #    e.g. ((:collocation, :adnlp, :ipopt), ...)
    valid_methods = OptimalControl.methods()
    
    # 2. Extract unique symbols for each category
    disc_ids = unique(m[1] for m in valid_methods)
    mod_ids  = unique(m[2] for m in valid_methods)
    sol_ids  = unique(m[3] for m in valid_methods)
    
    # 3. Create tuple of Mock types for each ID
    #    We need to map AbstractType => (MockType{ID1}, MockType{ID2}, ...)
    disc_types = Tuple(MockDiscretizer{id} for id in disc_ids)
    mod_types  = Tuple(MockModeler{id}     for id in mod_ids)
    sol_types  = Tuple(MockSolver{id}      for id in sol_ids)
    
    # 4. Create registry
    return CTSolvers.create_registry(
        CTDirect.AbstractDiscretizer => disc_types,
        CTSolvers.AbstractNLPModeler => mod_types,
        CTSolvers.AbstractNLPSolver  => sol_types
    )
end

# ----------------------------------------------------------------------------
# Layer 3 Overrides (Mock Resolution)
# ----------------------------------------------------------------------------

# Override CommonSolve.solve (Explicit Mode final step)
# This intercepts the call after components have been completed/instantiated.
function CommonSolve.solve(
    ::MockOCP, ::MockInit,
    d::MockDiscretizer, m::MockModeler, s::MockSolver;
    display::Bool
)::MockSolution
    return MockSolution((d, m, s))
end

# Override OptimalControl.solve_descriptive (Descriptive Mode final step)
# This intercepts the call after mode detection.
function OptimalControl.solve_descriptive(
    ocp::MockOCP, description::Symbol...;
    initial_guess, display::Bool, registry::CTSolvers.StrategyRegistry, kwargs...
)::MockSolution
    # For testing purposes, we return a MockSolution containing the description symbols
    # and the registry itself to verify they were passed correctly.
    return MockSolution((description, registry))
end

# ============================================================================
# TESTS
# ============================================================================

function test_dispatch_logic()
    Test.@testset "Dispatch Logic & Completion" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        ocp = MockOCP()
        init = MockInit()
        mock_registry = build_mock_registry_from_methods()
        
        # Iterate over all valid methods defined in OptimalControl
        # This ensures we cover every supported combination
        for (d_id, m_id, s_id) in OptimalControl.methods()
            
            method_str = "($d_id, $m_id, $s_id)"
            
            # ----------------------------------------------------------------
            # TEST 1: Explicit Mode with FULL Components
            # ----------------------------------------------------------------
            # Verify that we can explicitly target EVERY method supported.
            
            Test.@testset "Explicit Full: $method_str" begin
                
                d_instance = MockDiscretizer{d_id}(CTSolvers.StrategyOptions())
                m_instance = MockModeler{m_id}(CTSolvers.StrategyOptions())
                s_instance = MockSolver{s_id}(CTSolvers.StrategyOptions())
                
                sol = OptimalControl.solve(
                    ocp;
                    initial_guess=init,
                    display=false,
                    registry=mock_registry,
                    discretizer=d_instance,
                    modeler=m_instance,
                    solver=s_instance
                )
                
                Test.@test sol isa MockSolution
                (d_res, m_res, s_res) = sol.components
                
                Test.@test d_res isa MockDiscretizer{d_id}
                Test.@test m_res isa MockModeler{m_id}
                Test.@test s_res isa MockSolver{s_id}
            end
            
            # ----------------------------------------------------------------
            # TEST 2: Descriptive Mode
            # ----------------------------------------------------------------
            # We pass symbols (:collocation, :adnlp, :ipopt)
            # Should dispatch to solve_descriptive with these symbols
            
            Test.@testset "Descriptive: $method_str" begin
                
                sol = OptimalControl.solve(
                    ocp, d_id, m_id, s_id;
                    initial_guess=init,
                    display=false,
                    registry=mock_registry
                )
                
                Test.@test sol isa MockSolution
                (desc_res, reg_res) = sol.components
                
                # Check that description was passed correctly
                Test.@test desc_res == (d_id, m_id, s_id)
                
                # Check that registry was passed correctly
                Test.@test reg_res === mock_registry
            end
        end

        # ----------------------------------------------------------------
        # TEST 3: Partial Explicit (Defaults)
        # ----------------------------------------------------------------
        # Verify that providing partial components triggers completion
        # to a valid default (usually the first match).
        
        Test.@testset "Explicit Partial (Defaults)" begin
            # Case: Only Discretizer(:collocation) provided
            # Expectation: Defaults to :adnlp, :ipopt (based on methods order)
            
            d_instance = MockDiscretizer{:collocation}(CTSolvers.StrategyOptions())
            
            sol = OptimalControl.solve(
                ocp;
                initial_guess=init,
                display=false,
                registry=mock_registry,
                discretizer=d_instance
            )
            
            Test.@test sol isa MockSolution
            (d_res, m_res, s_res) = sol.components
            
            Test.@test d_res isa MockDiscretizer{:collocation}
            # Verify it filled in valid components
            Test.@test m_res isa MockModeler
            Test.@test s_res isa MockSolver
        end

        # ----------------------------------------------------------------
        # TEST 5: Parameter Type Validation
        # ----------------------------------------------------------------
        # Test that CTSolvers parameter functions work correctly with our mocks
        
        Test.@testset "Parameter Type Validation" begin
            # Test parameter type identification
            Test.@test CTSolvers.Strategies.is_parameter_type(CTSolvers.CPU)
            Test.@test CTSolvers.Strategies.is_parameter_type(CTSolvers.GPU)
            Test.@test !CTSolvers.Strategies.is_parameter_type(Int)
            
            # Test parameter extraction from non-parameterized mocks
            # Our mocks don't have type parameters in the way CTSolvers expects
            # so get_parameter_type should return nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(MockModeler{:adnlp}) === nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(MockSolver{:ipopt}) === nothing
            
            # Test parameter extraction from parameterized mocks
            # Even with parameters, our mocks don't follow the CTSolvers convention
            # so get_parameter_type should still return nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(MockModelerParam{:exa, CTSolvers.CPU}) === nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(MockSolverParam{:madnlp, CTSolvers.GPU}) === nothing
            
            # Test that is_parameter_type works correctly for real CTSolvers types
            Test.@test CTSolvers.Strategies.is_parameter_type(CTSolvers.CPU)
            Test.@test CTSolvers.Strategies.is_parameter_type(CTSolvers.GPU)
            Test.@test !CTSolvers.Strategies.is_parameter_type(CTSolvers.ADNLP)
            Test.@test !CTSolvers.Strategies.is_parameter_type(CTSolvers.Ipopt)
        end

        # ----------------------------------------------------------------
        # TEST 6: Default Registry Fallback
        # ----------------------------------------------------------------
        # Verify that if we don't pass `registry`, it falls back to the real one.
        
        Test.@testset "Default Registry Fallback" begin
             sol = OptimalControl.solve(
                 ocp, :foo, :bar; 
                 initial_guess=init,
                 display=false
             )
             
             (_, reg_res) = sol.components
             # It should NOT be our mock registry
             Test.@test reg_res !== mock_registry
             
             # It should look like the real registry (checking internal families)
             # Real registry has CTDirect.AbstractDiscretizer, etc.
             families = reg_res.families
             Test.@test haskey(families, CTDirect.AbstractDiscretizer)
             Test.@test haskey(families, CTSolvers.AbstractNLPModeler)
        end

    end
end

end # module

# Entry point for TestRunner
test_dispatch_logic() = TestDispatchLogic.test_dispatch_logic()

# ============================================================================
# Solve Dispatch Logic Tests
# ============================================================================
# This file contains unit tests for the top-level `solve` dispatch mechanism.
# It uses a dynamically generated mock registry to verify that the entry point
# correctly analyzes arguments and routes the call to either `solve_explicit`
# or `solve_descriptive`, ensuring the dispatch logic is robust and isolated.

module TestDispatchLogic

using Test: Test
using OptimalControl: OptimalControl
using CTModels: CTModels
using CTDirect: CTDirect
using CTSolvers: CTSolvers
using CTBase: CTBase
using CommonSolve: CommonSolve

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
struct MockDiscretizer{ID} <: CTSolvers.DOCP.AbstractDiscretizer
    options::CTBase.Strategies.StrategyOptions
end

struct MockModeler{ID} <: CTSolvers.Modelers.AbstractNLPModeler
    options::CTBase.Strategies.StrategyOptions
end

struct MockSolver{ID} <: CTSolvers.Solvers.AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end

# Parametric mocks for parameterized strategies (CPU/GPU)
struct MockModelerParam{ID,PARAM} <: CTSolvers.Modelers.AbstractNLPModeler
    options::CTBase.Strategies.StrategyOptions
end

struct MockSolverParam{ID,PARAM} <: CTSolvers.Solvers.AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end

# ----------------------------------------------------------------------------
# Strategies Interface Implementation
# ----------------------------------------------------------------------------

# ID accessors
CTBase.Strategies.id(::Type{MockDiscretizer{ID}}) where {ID} = ID
CTBase.Strategies.id(::Type{MockModeler{ID}}) where {ID} = ID
CTBase.Strategies.id(::Type{MockSolver{ID}}) where {ID} = ID
CTBase.Strategies.id(::Type{MockModelerParam{ID,PARAM}}) where {ID,PARAM} = ID
CTBase.Strategies.id(::Type{MockSolverParam{ID,PARAM}}) where {ID,PARAM} = ID

# Metadata (required by registry)
function CTBase.Strategies.metadata(::Type{<:MockDiscretizer})
    return CTBase.Strategies.StrategyMetadata()
end
function CTBase.Strategies.metadata(::Type{<:MockModeler})
    return CTBase.Strategies.StrategyMetadata()
end
function CTBase.Strategies.metadata(::Type{<:MockSolver})
    return CTBase.Strategies.StrategyMetadata()
end
function CTBase.Strategies.metadata(::Type{<:MockModelerParam})
    return CTBase.Strategies.StrategyMetadata()
end
function CTBase.Strategies.metadata(::Type{<:MockSolverParam})
    return CTBase.Strategies.StrategyMetadata()
end

# Options accessors
CTBase.Strategies.options(d::MockDiscretizer) = d.options
CTBase.Strategies.options(m::MockModeler) = m.options
CTBase.Strategies.options(s::MockSolver) = s.options
CTBase.Strategies.options(m::MockModelerParam) = m.options
CTBase.Strategies.options(s::MockSolverParam) = s.options

# Parameter accessors
#
# ⚠️ v2.1.0-beta contract: every strategy must implement `parameter`. The old
# `CTSolvers.Strategies.get_parameter_type` returned `nothing` by default; the
# CTBase generic throws `NotImplemented` instead, so a mock that omits it makes
# option routing fail rather than being treated as non-parameterized.
CTBase.Strategies.parameter(::Type{<:MockDiscretizer}) = nothing
CTBase.Strategies.parameter(::Type{<:MockModeler}) = nothing
CTBase.Strategies.parameter(::Type{<:MockSolver}) = nothing
CTBase.Strategies.parameter(::Type{MockModelerParam{ID,PARAM}}) where {ID,PARAM} = PARAM
CTBase.Strategies.parameter(::Type{MockSolverParam{ID,PARAM}}) where {ID,PARAM} = PARAM

# Constructors (required by _build_or_use_strategy)
function MockDiscretizer{ID}(; mode::Symbol=:strict, kwargs...) where {ID}
    opts = CTBase.Strategies.build_strategy_options(
        MockDiscretizer{ID}; mode=mode, kwargs...
    )
    return MockDiscretizer{ID}(opts)
end

function MockModeler{ID}(; mode::Symbol=:strict, kwargs...) where {ID}
    opts = CTBase.Strategies.build_strategy_options(MockModeler{ID}; mode=mode, kwargs...)
    return MockModeler{ID}(opts)
end

function MockSolver{ID}(; mode::Symbol=:strict, kwargs...) where {ID}
    opts = CTBase.Strategies.build_strategy_options(MockSolver{ID}; mode=mode, kwargs...)
    return MockSolver{ID}(opts)
end

function MockModelerParam{ID,PARAM}(; mode::Symbol=:strict, kwargs...) where {ID,PARAM}
    opts = CTBase.Strategies.build_strategy_options(
        MockModelerParam{ID,PARAM}; mode=mode, kwargs...
    )
    return MockModelerParam{ID,PARAM}(opts)
end

function MockSolverParam{ID,PARAM}(; mode::Symbol=:strict, kwargs...) where {ID,PARAM}
    opts = CTBase.Strategies.build_strategy_options(
        MockSolverParam{ID,PARAM}; mode=mode, kwargs...
    )
    return MockSolverParam{ID,PARAM}(opts)
end

# ----------------------------------------------------------------------------
# Mock Registry Builder
# ----------------------------------------------------------------------------

function build_mock_registry_from_methods()::CTBase.Strategies.StrategyRegistry
    # 1. Get all valid triplets from methods()
    #    e.g. ((:collocation, :adnlp, :ipopt), ...)
    valid_methods = OptimalControl.methods()

    # 2. Extract unique symbols for each category
    disc_ids = unique(m[1] for m in valid_methods)
    mod_ids = unique(m[2] for m in valid_methods)
    sol_ids = unique(m[3] for m in valid_methods)

    # 3. Create tuple of Mock types for each ID
    #    We need to map AbstractType => (MockType{ID1}, MockType{ID2}, ...)
    disc_types = Tuple(MockDiscretizer{id} for id in disc_ids)
    mod_types = Tuple(MockModeler{id} for id in mod_ids)
    sol_types = Tuple(MockSolver{id} for id in sol_ids)

    # 4. Create registry
    return CTBase.Strategies.create_registry(
        CTSolvers.DOCP.AbstractDiscretizer => disc_types,
        CTSolvers.Modelers.AbstractNLPModeler => mod_types,
        CTSolvers.Solvers.AbstractNLPSolver => sol_types,
    )
end

# ----------------------------------------------------------------------------
# Layer 3 Overrides (Mock Resolution)
# ----------------------------------------------------------------------------

# Override CommonSolve.solve (Explicit Mode final step)
# This intercepts the call after components have been completed/instantiated.
function CommonSolve.solve(
    ::MockOCP, ::MockInit, d::MockDiscretizer, m::MockModeler, s::MockSolver; display::Bool
)::MockSolution
    return MockSolution((d, m, s))
end

# Override OptimalControl.solve_descriptive (Descriptive Mode final step)
# This intercepts the call after mode detection.
function OptimalControl.solve_descriptive(
    ocp::MockOCP,
    description::Symbol...;
    initial_guess,
    display::Bool,
    registry::CTBase.Strategies.StrategyRegistry,
    kwargs...,
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
                d_instance = MockDiscretizer{d_id}(CTBase.Strategies.StrategyOptions())
                m_instance = MockModeler{m_id}(CTBase.Strategies.StrategyOptions())
                s_instance = MockSolver{s_id}(CTBase.Strategies.StrategyOptions())

                sol = OptimalControl.solve(
                    ocp;
                    initial_guess=init,
                    display=false,
                    registry=mock_registry,
                    discretizer=d_instance,
                    modeler=m_instance,
                    solver=s_instance,
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
                    ocp,
                    d_id,
                    m_id,
                    s_id;
                    initial_guess=init,
                    display=false,
                    registry=mock_registry,
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

            d_instance = MockDiscretizer{:collocation}(CTBase.Strategies.StrategyOptions())

            sol = OptimalControl.solve(
                ocp;
                initial_guess=init,
                display=false,
                registry=mock_registry,
                discretizer=d_instance,
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
            Test.@test CTBase.Strategies.is_a_parameter(CTBase.Strategies.CPU)
            Test.@test CTBase.Strategies.is_a_parameter(CTBase.Strategies.GPU)
            Test.@test !CTBase.Strategies.is_a_parameter(Int)

            # Parameter extraction from non-parameterized mocks.
            # `MockModeler{ID}`'s type parameter is its *id*, not a strategy
            # parameter, so it declares `parameter(...) = nothing`.
            Test.@test CTBase.Strategies.parameter(MockModeler{:adnlp}) === nothing
            Test.@test CTBase.Strategies.parameter(MockSolver{:ipopt}) === nothing

            # Parameter extraction from parameterized mocks.
            # ⚠️ Changed in v2.1.0-beta: `parameter` is a contract every
            # strategy must implement (the CTBase generic throws
            # `NotImplemented` by default, where the old
            # `CTSolvers.Strategies.get_parameter_type` silently returned
            # `nothing`). Now that `MockXParam` declares it, it reports the
            # parameter it actually carries.
            Test.@test CTBase.Strategies.parameter(
                MockModelerParam{:exa,CTBase.Strategies.CPU}
            ) === CTBase.Strategies.CPU
            Test.@test CTBase.Strategies.parameter(
                MockSolverParam{:madnlp,CTBase.Strategies.GPU}
            ) === CTBase.Strategies.GPU

            # Test that is_a_parameter works correctly for real CTSolvers types
            Test.@test CTBase.Strategies.is_a_parameter(CTBase.Strategies.CPU)
            Test.@test CTBase.Strategies.is_a_parameter(CTBase.Strategies.GPU)
            Test.@test !CTBase.Strategies.is_a_parameter(CTSolvers.Modelers.ADNLP)
            Test.@test !CTBase.Strategies.is_a_parameter(CTSolvers.Solvers.Ipopt)
        end

        # ----------------------------------------------------------------
        # TEST 6: Default Registry Fallback
        # ----------------------------------------------------------------
        # Verify that if we don't pass `registry`, it falls back to the real one.

        Test.@testset "Default Registry Fallback" begin
            sol = OptimalControl.solve(ocp, :foo, :bar; initial_guess=init, display=false)

            (_, reg_res) = sol.components
            # It should NOT be our mock registry
            Test.@test reg_res !== mock_registry

            # It should look like the real registry (checking internal families)
            # Real registry has CTSolvers.DOCP.AbstractDiscretizer, etc.
            families = reg_res.families
            Test.@test haskey(families, CTSolvers.DOCP.AbstractDiscretizer)
            Test.@test haskey(families, CTSolvers.Modelers.AbstractNLPModeler)
        end
    end
end

end # module

# Entry point for TestRunner
test_dispatch_logic() = TestDispatchLogic.test_dispatch_logic()

module TestOrchestrationDisambiguation

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Orchestration
import CTSolvers.Strategies
import CTSolvers.Options
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test fixtures (minimal strategy setup)
# ============================================================================

abstract type TestDiscretizer <: Strategies.AbstractStrategy end
abstract type TestModeler <: Strategies.AbstractStrategy end
abstract type TestSolver <: Strategies.AbstractStrategy end

struct CollocationMock <: TestDiscretizer end
Strategies.id(::Type{CollocationMock}) = :collocation
Strategies.metadata(::Type{CollocationMock}) = Strategies.StrategyMetadata()

struct ADNLPMock <: TestModeler end
Strategies.id(::Type{ADNLPMock}) = :adnlp
Strategies.metadata(::Type{ADNLPMock}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :dense,
        description = "Backend type",
        aliases = (:adnlp_backend,)
    )
)

struct IpoptMock <: TestSolver end
Strategies.id(::Type{IpoptMock}) = :ipopt
Strategies.metadata(::Type{IpoptMock}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 1000,
        description = "Maximum iterations"
    ),
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :cpu,
        description = "Solver backend",
        aliases = (:ipopt_backend,)
    )
)

const TEST_REGISTRY = Strategies.create_registry(
    TestDiscretizer => (CollocationMock,),
    TestModeler => (ADNLPMock,),
    TestSolver => (IpoptMock,)
)

const TEST_METHOD = (:collocation, :adnlp, :ipopt)

const TEST_FAMILIES = (
    discretizer = TestDiscretizer,
    modeler = TestModeler,
    solver = TestSolver
)

# ============================================================================
# Test function
# ============================================================================

function test_orchestration_disambiguation()
    Test.@testset "Orchestration Disambiguation" verbose = VERBOSE showtiming = SHOWTIMING begin
        
        # ====================================================================
        # extract_strategy_ids - Unit Tests
        # ====================================================================
        
        Test.@testset "extract_strategy_ids" begin
            # No disambiguation - plain value
            Test.@test Orchestration.extract_strategy_ids(:sparse, TEST_METHOD) === nothing
            Test.@test Orchestration.extract_strategy_ids(100, TEST_METHOD) === nothing
            Test.@test Orchestration.extract_strategy_ids("string", TEST_METHOD) === nothing
            
            # Single strategy disambiguation
            result = Orchestration.extract_strategy_ids(Strategies.route_to(adnlp=:sparse), TEST_METHOD)
            Test.@test result isa Vector{Tuple{Any,Symbol}}
            Test.@test length(result) == 1
            Test.@test result[1] == (:sparse, :adnlp)
            
            # Multi-strategy disambiguation
            result = Orchestration.extract_strategy_ids(
                Strategies.route_to(adnlp=:sparse, ipopt=:cpu),
                TEST_METHOD
            )
            Test.@test result isa Vector{Tuple{Any,Symbol}}
            Test.@test length(result) == 2
            Test.@test result[1] == (:sparse, :adnlp)
            Test.@test result[2] == (:cpu, :ipopt)
            
            # Invalid strategy ID in single disambiguation
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.extract_strategy_ids(
                Strategies.route_to(unknown=:sparse),
                TEST_METHOD
            )
            
            # Invalid strategy ID in multi disambiguation
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.extract_strategy_ids(
                Strategies.route_to(adnlp=:sparse, unknown=:cpu),
                TEST_METHOD
            )
            
            # Non-disambiguated values should return nothing
            result = Orchestration.extract_strategy_ids(
                :plain_value,
                TEST_METHOD
            )
            Test.@test result === nothing
            
            # Another non-disambiguated case
            result2 = Orchestration.extract_strategy_ids(
                100,
                TEST_METHOD
            )
            Test.@test result2 === nothing
            
            # Empty tuple
            Test.@test Orchestration.extract_strategy_ids((), TEST_METHOD) === nothing
        end
        
        # ====================================================================
        # build_strategy_to_family_map - Unit Tests
        # ====================================================================
        
        Test.@testset "build_strategy_to_family_map" begin
            map = Orchestration.build_strategy_to_family_map(
                TEST_METHOD, TEST_FAMILIES, TEST_REGISTRY
            )
            
            Test.@test map isa Dict{Symbol,Symbol}
            Test.@test length(map) == 3
            Test.@test map[:collocation] == :discretizer
            Test.@test map[:adnlp] == :modeler
            Test.@test map[:ipopt] == :solver
        end
        
        # ====================================================================
        # build_option_ownership_map - Unit Tests
        # ====================================================================
        
        Test.@testset "build_option_ownership_map" begin
            map = Orchestration.build_option_ownership_map(
                TEST_METHOD, TEST_FAMILIES, TEST_REGISTRY
            )
            
            Test.@test map isa Dict{Symbol,Set{Symbol}}
            
            # max_iter only in solver
            Test.@test haskey(map, :max_iter)
            Test.@test map[:max_iter] == Set([:solver])
            
            # backend in both modeler and solver (ambiguous!)
            Test.@test haskey(map, :backend)
            Test.@test map[:backend] == Set([:modeler, :solver])
            Test.@test length(map[:backend]) == 2
        end
        
        # ====================================================================
        # Ambiguous option error includes aliases
        # ====================================================================
        
        Test.@testset "Ambiguous option error shows aliases" begin
            # backend is ambiguous between adnlp and ipopt
            # The error message should mention the aliases adnlp_backend and ipopt_backend
            try
                Orchestration.route_all_options(
                    TEST_METHOD,
                    TEST_FAMILIES,
                    Options.OptionDefinition[],
                    (; backend = :sparse),
                    TEST_REGISTRY;
                    source_mode = :description
                )
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                msg = sprint(showerror, e)
                # Check that route_to suggestion is present
                Test.@test occursin("route_to", msg)
                # Check that aliases are mentioned
                Test.@test occursin("adnlp_backend", msg)
                Test.@test occursin("ipopt_backend", msg)
                # Check that the alias section header is present
                Test.@test occursin("aliases", msg)
            end
        end
        
        # ====================================================================
        # Integration test
        # ====================================================================
        
        Test.@testset "Integration: Disambiguation workflow" begin
            # Build both maps
            strategy_map = Orchestration.build_strategy_to_family_map(
                TEST_METHOD, TEST_FAMILIES, TEST_REGISTRY
            )
            option_map = Orchestration.build_option_ownership_map(
                TEST_METHOD, TEST_FAMILIES, TEST_REGISTRY
            )
            
            # Simulate disambiguation detection
            disamb = Orchestration.extract_strategy_ids(Strategies.route_to(adnlp=:sparse), TEST_METHOD)
            Test.@test disamb !== nothing
            Test.@test length(disamb) == 1
            
            value, strategy_id = disamb[1]
            Test.@test value == :sparse
            Test.@test strategy_id == :adnlp
            
            # Verify routing would work
            family = strategy_map[strategy_id]
            Test.@test family == :modeler
            
            # Verify option ownership
            Test.@test :backend in keys(option_map)
            Test.@test family in option_map[:backend]
        end
    end
end

end # module

test_orchestration_disambiguation() = TestOrchestrationDisambiguation.test_orchestration_disambiguation()

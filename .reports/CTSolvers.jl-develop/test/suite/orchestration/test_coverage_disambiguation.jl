module TestCoverageDisambiguation

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

abstract type CovDiscretizer <: Strategies.AbstractStrategy end
abstract type CovModeler <: Strategies.AbstractStrategy end
abstract type CovSolver <: Strategies.AbstractStrategy end

struct CovCollocation <: CovDiscretizer
    options::Strategies.StrategyOptions
end
Strategies.id(::Type{CovCollocation}) = :collocation
Strategies.metadata(::Type{CovCollocation}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :grid_size,
        type = Int,
        default = 100,
        description = "Grid size"
    )
)

struct CovADNLP <: CovModeler
    options::Strategies.StrategyOptions
end
Strategies.id(::Type{CovADNLP}) = :adnlp
Strategies.metadata(::Type{CovADNLP}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :dense,
        description = "Backend type",
        aliases = (:adnlp_backend,)
    )
)

struct CovIpopt <: CovSolver
    options::Strategies.StrategyOptions
end
Strategies.id(::Type{CovIpopt}) = :ipopt
Strategies.metadata(::Type{CovIpopt}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 1000,
        description = "Maximum iterations",
        aliases = (:maxiter,)
    ),
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :cpu,
        description = "Solver backend",
        aliases = (:ipopt_backend,)
    )
)

const COV_REGISTRY = Strategies.create_registry(
    CovDiscretizer => (CovCollocation,),
    CovModeler => (CovADNLP,),
    CovSolver => (CovIpopt,)
)

const COV_METHOD = (:collocation, :adnlp, :ipopt)

const COV_FAMILIES = (
    discretizer = CovDiscretizer,
    modeler = CovModeler,
    solver = CovSolver
)

const COV_ACTION_DEFS = [
    Options.OptionDefinition(
        name = :display,
        type = Bool,
        default = true,
        description = "Display progress"
    )
]

# ============================================================================
# Test function
# ============================================================================

function test_coverage_disambiguation()
    Test.@testset "Coverage: Disambiguation & Routing" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - build_alias_to_primary_map (disambiguation.jl)
        # ====================================================================

        Test.@testset "build_alias_to_primary_map" begin
            alias_map = Orchestration.build_alias_to_primary_map(
                COV_METHOD, COV_FAMILIES, COV_REGISTRY
            )

            Test.@test alias_map isa Dict{Symbol, Symbol}
            Test.@test alias_map[:adnlp_backend] == :backend
            Test.@test alias_map[:ipopt_backend] == :backend
            Test.@test alias_map[:maxiter] == :max_iter
            Test.@test !haskey(alias_map, :grid_size)
            Test.@test !haskey(alias_map, :backend)
        end

        # ====================================================================
        # UNIT TESTS - route_all_options (routing.jl)
        # ====================================================================

        Test.@testset "route_all_options - auto-route unambiguous" begin
            result = Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; grid_size=200, max_iter=500, display=false),
                COV_REGISTRY
            )

            Test.@test Options.value(result.action.display) == false
            Test.@test result.strategies.discretizer.grid_size == 200
            Test.@test result.strategies.solver.max_iter == 500
        end

        Test.@testset "route_all_options - disambiguated option" begin
            result = Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; backend=Strategies.route_to(adnlp=:sparse)),
                COV_REGISTRY
            )

            Test.@test result.strategies.modeler.backend == :sparse
        end

        Test.@testset "route_all_options - multi-strategy disambiguation" begin
            result = Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; backend=Strategies.route_to(adnlp=:sparse, ipopt=:gpu)),
                COV_REGISTRY
            )

            Test.@test result.strategies.modeler.backend == :sparse
            Test.@test result.strategies.solver.backend == :gpu
        end

        Test.@testset "route_all_options - unknown option error" begin
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; totally_unknown=42),
                COV_REGISTRY
            )
        end

        Test.@testset "route_all_options - ambiguous option error (description mode)" begin
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; backend=:sparse),
                COV_REGISTRY;
                source_mode=:description
            )
        end

        Test.@testset "route_all_options - ambiguous option error (explicit mode)" begin
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; backend=:sparse),
                COV_REGISTRY;
                source_mode=:explicit
            )
        end

        Test.@testset "route_all_options - invalid mode" begin
            # mode parameter no longer exists in route_all_options
            # invalid keyword arguments throw MethodError, not IncorrectArgument
            Test.@test_throws Exception Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (;),
                COV_REGISTRY;
                mode=:invalid_mode
            )
        end

        Test.@testset "route_all_options - invalid routing target" begin
            # Route backend to discretizer (which doesn't own backend)
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; backend=Strategies.route_to(collocation=:sparse)),
                COV_REGISTRY
            )
        end

        Test.@testset "route_all_options - bypass unknown disambiguated" begin
            # Use bypass(val) to route unknown options
            result = Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; unknown_opt=Strategies.route_to(adnlp=Strategies.bypass(42))),
                COV_REGISTRY
            )

            bv = result.strategies.modeler[:unknown_opt]
            Test.@test bv isa Strategies.BypassValue
            Test.@test bv.value == 42
        end

        Test.@testset "route_all_options - strict mode unknown disambiguated" begin
            # Without bypass, unknown options always fail
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; unknown_opt=Strategies.route_to(adnlp=42)),
                COV_REGISTRY
            )
        end

        Test.@testset "route_all_options - empty kwargs" begin
            result = Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (;),
                COV_REGISTRY
            )

            Test.@test Options.value(result.action.display) == true
            Test.@test isempty(result.strategies.discretizer)
            Test.@test isempty(result.strategies.modeler)
            Test.@test isempty(result.strategies.solver)
        end

        # ====================================================================
        # UNIT TESTS - alias routing via ownership map
        # ====================================================================

        Test.@testset "route_all_options - alias auto-route" begin
            result = Orchestration.route_all_options(
                COV_METHOD, COV_FAMILIES, COV_ACTION_DEFS,
                (; maxiter=500),
                COV_REGISTRY
            )

            Test.@test result.strategies.solver.maxiter == 500
        end
    end
end

end # module

test_coverage_disambiguation() = TestCoverageDisambiguation.test_coverage_disambiguation()

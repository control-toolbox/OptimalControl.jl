module TestOrchestrationRouting

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Orchestration
import CTSolvers.Strategies
import CTSolvers.Options
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test fixtures
# ============================================================================

abstract type RoutingTestDiscretizer <: Strategies.AbstractStrategy end
abstract type RoutingTestModeler <: Strategies.AbstractStrategy end
abstract type RoutingTestSolver <: Strategies.AbstractStrategy end

struct RoutingCollocation <: RoutingTestDiscretizer end
Strategies.id(::Type{RoutingCollocation}) = :collocation
Strategies.metadata(::Type{RoutingCollocation}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :grid_size,
        type = Int,
        default = 100,
        description = "Grid size"
    )
)

struct RoutingADNLP <: RoutingTestModeler end
Strategies.id(::Type{RoutingADNLP}) = :adnlp
Strategies.metadata(::Type{RoutingADNLP}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :dense,
        description = "Backend type",
        aliases = (:adnlp_backend,)
    )
)

struct RoutingIpopt <: RoutingTestSolver end
Strategies.id(::Type{RoutingIpopt}) = :ipopt
Strategies.metadata(::Type{RoutingIpopt}) = Strategies.StrategyMetadata(
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

const ROUTING_REGISTRY = Strategies.create_registry(
    RoutingTestDiscretizer => (RoutingCollocation,),
    RoutingTestModeler => (RoutingADNLP,),
    RoutingTestSolver => (RoutingIpopt,)
)

const ROUTING_METHOD = (:collocation, :adnlp, :ipopt)

const ROUTING_FAMILIES = (
    discretizer = RoutingTestDiscretizer,
    modeler = RoutingTestModeler,
    solver = RoutingTestSolver
)

const ROUTING_ACTION_DEFS = [
    Options.OptionDefinition(
        name = :display,
        type = Bool,
        default = true,
        description = "Display progress"
    ),
    Options.OptionDefinition(
        name = :initial_guess,
        type = Any,
        default = nothing,
        description = "Initial guess"
    )
]

# ============================================================================
# Test function
# ============================================================================

function test_routing()
    Test.@testset "Orchestration Routing" verbose = VERBOSE showtiming = SHOWTIMING begin
        
        # ====================================================================
        # Auto-routing (unambiguous options)
        # ====================================================================
        
        Test.@testset "Auto-routing unambiguous options" begin
            kwargs = (
                grid_size = 200,
                max_iter = 2000,
                display = false
            )
            
            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
            
            # Check action options (Dict of OptionValue wrappers)
            Test.@test haskey(routed.action, :display)
            Test.@test Options.value(routed.action[:display]) === false
            Test.@test Options.source(routed.action[:display]) === :user
            
            # Check strategy options (raw NamedTuples)
            Test.@test haskey(routed.strategies, :discretizer)
            Test.@test haskey(routed.strategies, :modeler)
            Test.@test haskey(routed.strategies, :solver)
            
            # Access raw values from NamedTuples
            Test.@test haskey(routed.strategies.discretizer, :grid_size)
            Test.@test routed.strategies.discretizer[:grid_size] == 200
            Test.@test haskey(routed.strategies.solver, :max_iter)
            Test.@test routed.strategies.solver[:max_iter] == 2000
        end
        
        # ====================================================================
        # Single strategy disambiguation
        # ====================================================================
        
        Test.@testset "Single strategy disambiguation" begin
            kwargs = (
                backend = Strategies.route_to(adnlp=:sparse),
                display = true
            )
            
            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
            
            # backend should be routed to modeler only
            Test.@test haskey(routed.strategies.modeler, :backend)
            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test !haskey(routed.strategies.solver, :backend)
        end
        
        # ====================================================================
        # Multi-strategy disambiguation
        # ====================================================================
        
        Test.@testset "Multi-strategy disambiguation" begin
            kwargs = (
                backend = Strategies.route_to(adnlp=:sparse, ipopt=:cpu),
            )
            
            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
            
            # backend should be routed to both
            Test.@test haskey(routed.strategies.modeler, :backend)
            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test haskey(routed.strategies.solver, :backend)
            Test.@test routed.strategies.solver[:backend] === :cpu
        end
        
        # ====================================================================
        # Error: Unknown option
        # ====================================================================
        
        Test.@testset "Error on unknown option" begin
            kwargs = (unknown_option = 123,)
            
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
        end
        
        # ====================================================================
        # Error: Ambiguous option without disambiguation
        # ====================================================================
        
        Test.@testset "Error on ambiguous option" begin
            kwargs = (backend = :sparse,)  # No disambiguation
            
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
        end
        
        # ====================================================================
        # Error: Invalid disambiguation target
        # ====================================================================
        
        Test.@testset "Error on invalid disambiguation" begin
            # Try to route max_iter to modeler (wrong family)
            kwargs = (max_iter = Strategies.route_to(adnlp=1000),)
            
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
        end
        
        # ====================================================================
        # Routing via aliases (unambiguous)
        # ====================================================================
        
        Test.@testset "Auto-routing via alias (unambiguous)" begin
            # adnlp_backend is an alias for backend, only in modeler => unambiguous
            kwargs = (adnlp_backend = :sparse,)
            
            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
            
            # adnlp_backend should be routed to modeler
            Test.@test haskey(routed.strategies.modeler, :adnlp_backend)
            Test.@test routed.strategies.modeler[:adnlp_backend] === :sparse
            # solver should NOT have it
            Test.@test !haskey(routed.strategies.solver, :adnlp_backend)
        end
        
        Test.@testset "Auto-routing via solver alias (unambiguous)" begin
            # ipopt_backend is an alias for backend, only in solver => unambiguous
            kwargs = (ipopt_backend = :gpu,)
            
            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
            
            # ipopt_backend should be routed to solver
            Test.@test haskey(routed.strategies.solver, :ipopt_backend)
            Test.@test routed.strategies.solver[:ipopt_backend] === :gpu
            # modeler should NOT have it
            Test.@test !haskey(routed.strategies.modeler, :ipopt_backend)
        end
        
        Test.@testset "Mixed alias and primary routing" begin
            # Use alias for one strategy and primary for another
            kwargs = (
                adnlp_backend = :sparse,
                max_iter = 500,
                grid_size = 200
            )
            
            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
            
            Test.@test routed.strategies.modeler[:adnlp_backend] === :sparse
            Test.@test routed.strategies.solver[:max_iter] == 500
            Test.@test routed.strategies.discretizer[:grid_size] == 200
        end
        
        Test.@testset "Ownership map includes aliases" begin
            map = Orchestration.build_option_ownership_map(
                ROUTING_METHOD, ROUTING_FAMILIES, ROUTING_REGISTRY
            )
            
            # Primary names
            Test.@test haskey(map, :backend)
            Test.@test length(map[:backend]) == 2  # modeler + solver
            Test.@test haskey(map, :max_iter)
            Test.@test length(map[:max_iter]) == 1  # solver only
            
            # Aliases should be in the map too
            Test.@test haskey(map, :adnlp_backend)
            Test.@test length(map[:adnlp_backend]) == 1  # modeler only
            Test.@test :modeler in map[:adnlp_backend]
            
            Test.@test haskey(map, :ipopt_backend)
            Test.@test length(map[:ipopt_backend]) == 1  # solver only
            Test.@test :solver in map[:ipopt_backend]
        end
        
        # ====================================================================
        # Integration: Mixed routing
        # ====================================================================
        
        Test.@testset "Integration: Mixed routing" begin
            kwargs = (
                grid_size = 150,
                backend = Strategies.route_to(adnlp=:sparse, ipopt=:gpu),
                max_iter = 500,
                display = false,
                initial_guess = :warm
            )
            
            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY
            )
            
            # Action options (Dict of OptionValue wrappers)
            Test.@test Options.value(routed.action[:display]) === false
            Test.@test Options.value(routed.action[:initial_guess]) === :warm
            
            # Strategy options (raw NamedTuples)
            Test.@test routed.strategies.discretizer[:grid_size] == 150
            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test routed.strategies.solver[:backend] === :gpu
            Test.@test routed.strategies.solver[:max_iter] == 500
        end
        # ====================================================================
        # Unknown option error suggests closest options (alias-aware)
        # ====================================================================
        
        Test.@testset "Unknown option error suggests closest (alias-aware)" begin
            # adnlp_backen is close to alias adnlp_backend (distance 1)
            # but far from primary name backend (distance 7)
            # The error should suggest :backend (alias: adnlp_backend)
            try
                Orchestration.route_all_options(
                    ROUTING_METHOD,
                    ROUTING_FAMILIES,
                    ROUTING_ACTION_DEFS,
                    (; adnlp_backen = :sparse),
                    ROUTING_REGISTRY
                )
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                msg = sprint(showerror, e)
                # Should suggest backend via alias proximity
                Test.@test occursin("Did you mean?", msg)
                Test.@test occursin("backend", msg)
                Test.@test occursin("adnlp_backend", msg)
            end
            
            # ipopt_backen is close to alias ipopt_backend (distance 1)
            try
                Orchestration.route_all_options(
                    ROUTING_METHOD,
                    ROUTING_FAMILIES,
                    ROUTING_ACTION_DEFS,
                    (; ipopt_backen = :gpu),
                    ROUTING_REGISTRY
                )
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                msg = sprint(showerror, e)
                Test.@test occursin("Did you mean?", msg)
                Test.@test occursin("backend", msg)
                Test.@test occursin("ipopt_backend", msg)
            end
            
            # max_ite is close to primary max_iter (distance 1), no alias needed
            try
                Orchestration.route_all_options(
                    ROUTING_METHOD,
                    ROUTING_FAMILIES,
                    ROUTING_ACTION_DEFS,
                    (; max_ite = 500),
                    ROUTING_REGISTRY
                )
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                msg = sprint(showerror, e)
                Test.@test occursin("Did you mean?", msg)
                Test.@test occursin("max_iter", msg)
            end
        end
    end
end

end # module

test_routing() = TestOrchestrationRouting.test_routing()

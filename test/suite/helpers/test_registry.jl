# ============================================================================
# Strategy Registry Setup Tests
# ============================================================================
# This file tests the `get_strategy_registry` function. It verifies that
# the global strategy registry is correctly populated with all available
# abstract families and their concrete implementations with parameter support
# provided by the solver ecosystem (CTDirect, CTSolvers).

module TestRegistry

using Test: Test
using OptimalControl: OptimalControl
using CTBase: CTBase
using CTSolvers: CTSolvers
using CTDirect: CTDirect

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_registry()
    Test.@testset "Strategy Registry Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS
        # ====================================================================

        Test.@testset "Registry Creation" begin
            registry = OptimalControl.get_strategy_registry()
            Test.@test registry isa CTBase.Strategies.StrategyRegistry
        end

        Test.@testset "Discretizer Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTBase.Strategies.strategy_ids(CTSolvers.DOCP.AbstractDiscretizer, registry)
            Test.@test :collocation in ids
            Test.@test length(ids) >= 1
        end

        Test.@testset "Modeler Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTBase.Strategies.strategy_ids(CTSolvers.Modelers.AbstractNLPModeler, registry)
            Test.@test :adnlp in ids
            Test.@test :exa in ids
            Test.@test length(ids) == 2
        end

        Test.@testset "Solver Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry)
            Test.@test :ipopt in ids
            Test.@test :madnlp in ids
            Test.@test :uno in ids
            Test.@test :madncl in ids
            Test.@test :knitro in ids
            Test.@test length(ids) == 5
        end

        Test.@testset "Parameter Support - Modelers" begin
            registry = OptimalControl.get_strategy_registry()

            # Test parameter availability using CTSolvers functions
            adnlp_params = CTBase.Strategies.available_parameters(
                :modeler, CTSolvers.Modelers.AbstractNLPModeler, registry
            )
            exa_params = CTBase.Strategies.available_parameters(
                :modeler, CTSolvers.Modelers.AbstractNLPModeler, registry
            )

            # Filter parameters for specific strategies
            adnlp_filtered = CTBase.Strategies.available_parameters(
                :adnlp, CTSolvers.Modelers.AbstractNLPModeler, registry
            )
            exa_filtered = CTBase.Strategies.available_parameters(
                :exa, CTSolvers.Modelers.AbstractNLPModeler, registry
            )

            # ADNLP should only support CPU
            Test.@test CTBase.Strategies.CPU in adnlp_filtered
            Test.@test CTBase.Strategies.GPU ∉ adnlp_filtered

            # Exa should support both CPU and GPU
            Test.@test CTBase.Strategies.CPU in exa_filtered
            Test.@test CTBase.Strategies.GPU in exa_filtered

            # Test parameter type extraction
            #
            # ⚠️ v2.1.0-beta semantic change, not a rename. The old
            # `CTSolvers.Strategies.get_parameter_type(ADNLP)` returned
            # `nothing` for a bare `UnionAll`; `CTBase.Strategies.parameter`
            # throws `NotImplemented` there instead — a bare `ADNLP` genuinely
            # does not determine a parameter. It is the *instantiated* type
            # that carries one.
            Test.@test CTBase.Strategies.parameter(
                CTSolvers.Modelers.ADNLP{CTBase.Strategies.CPU}
            ) === CTBase.Strategies.CPU
            Test.@test CTBase.Strategies.parameter(
                CTSolvers.Modelers.Exa{CTBase.Strategies.GPU}
            ) === CTBase.Strategies.GPU
            Test.@test_throws CTBase.Exceptions.NotImplemented CTBase.Strategies.parameter(
                CTSolvers.Modelers.ADNLP
            )
            Test.@test_throws CTBase.Exceptions.NotImplemented CTBase.Strategies.parameter(
                CTSolvers.Modelers.Exa
            )
        end

        Test.@testset "Parameter Support - Solvers" begin
            registry = OptimalControl.get_strategy_registry()

            # Test parameter availability using CTSolvers functions with abstract types
            # Filter parameters for specific strategies
            ipopt_filtered = CTBase.Strategies.available_parameters(
                :ipopt, CTSolvers.Solvers.AbstractNLPSolver, registry
            )
            madnlp_filtered = CTBase.Strategies.available_parameters(
                :madnlp, CTSolvers.Solvers.AbstractNLPSolver, registry
            )
            madncl_filtered = CTBase.Strategies.available_parameters(
                :madncl, CTSolvers.Solvers.AbstractNLPSolver, registry
            )
            knitro_filtered = CTBase.Strategies.available_parameters(
                :knitro, CTSolvers.Solvers.AbstractNLPSolver, registry
            )
            uno_filtered = CTBase.Strategies.available_parameters(
                :uno, CTSolvers.Solvers.AbstractNLPSolver, registry
            )

            # CPU-only solvers
            Test.@test CTBase.Strategies.CPU in ipopt_filtered
            Test.@test CTBase.Strategies.GPU ∉ ipopt_filtered

            Test.@test CTBase.Strategies.CPU in uno_filtered
            Test.@test CTBase.Strategies.GPU ∉ uno_filtered

            Test.@test CTBase.Strategies.CPU in knitro_filtered
            Test.@test CTBase.Strategies.GPU ∉ knitro_filtered

            # GPU-capable solvers
            Test.@test CTBase.Strategies.CPU in madnlp_filtered
            Test.@test CTBase.Strategies.GPU in madnlp_filtered

            Test.@test CTBase.Strategies.CPU in madncl_filtered
            Test.@test CTBase.Strategies.GPU in madncl_filtered

            # Test parameter type extraction — see the note in
            # "Parameter Support - Modelers" above: the instantiated type
            # carries the parameter, the bare `UnionAll` does not.
            for S in (
                CTSolvers.Solvers.Ipopt,
                CTSolvers.Solvers.MadNLP,
                CTSolvers.Solvers.Uno,
                CTSolvers.Solvers.MadNCL,
                CTSolvers.Solvers.Knitro,
            )
                Test.@test CTBase.Strategies.parameter(S{CTBase.Strategies.CPU}) ===
                    CTBase.Strategies.CPU
                Test.@test_throws CTBase.Exceptions.NotImplemented CTBase.Strategies.parameter(
                    S
                )
            end
        end

        Test.@testset "Parameter Type Validation" begin
            # Test that parameter types are correctly identified
            # Use available CTSolvers functions for parameter validation
            registry = OptimalControl.get_strategy_registry()

            # Test that registry contains expected families
            Test.@test registry isa CTBase.Strategies.StrategyRegistry

            # Test that CPU and GPU are distinct parameters
            Test.@test CTBase.Strategies.CPU !== CTBase.Strategies.GPU
            Test.@test CTBase.Strategies.CPU != CTBase.Strategies.GPU

            # Test that strategies are not parameters
            Test.@test CTSolvers.Modelers.Exa !== CTBase.Strategies.CPU
            Test.@test CTSolvers.Solvers.Ipopt !== CTBase.Strategies.GPU

            # Test parameter type identification using CTSolvers functions
            Test.@test CTBase.Strategies.is_a_parameter(CTBase.Strategies.CPU)
            Test.@test CTBase.Strategies.is_a_parameter(CTBase.Strategies.GPU)
            Test.@test !CTBase.Strategies.is_a_parameter(CTSolvers.Modelers.Exa)
            Test.@test !CTBase.Strategies.is_a_parameter(CTSolvers.Solvers.Ipopt)
            Test.@test !CTBase.Strategies.is_a_parameter(Int)
            Test.@test !CTBase.Strategies.is_a_parameter(String)
        end

        Test.@testset "Determinism" begin
            r1 = OptimalControl.get_strategy_registry()
            r2 = OptimalControl.get_strategy_registry()
            ids1 = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, r1)
            ids2 = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, r2)
            Test.@test ids1 == ids2
        end

        # ====================================================================
        # PARAMETER SUPPORT TESTS
        # ====================================================================

        Test.@testset "Parameter Support - Detailed" begin
            Test.@testset "CPU/GPU Parameter Availability" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that CPU and GPU parameters exist and are distinct
                Test.@test CTBase.Strategies.CPU !== nothing
                Test.@test CTBase.Strategies.GPU !== nothing
                Test.@test CTBase.Strategies.CPU !== CTBase.Strategies.GPU
                Test.@test CTBase.Strategies.CPU != CTBase.Strategies.GPU
            end

            Test.@testset "Strategy Parameter Mapping" begin
                registry = OptimalControl.get_strategy_registry()

                # Test discretizer parameter support (should be parameter-agnostic)
                discretizer_ids = CTBase.Strategies.strategy_ids(
                    CTSolvers.DOCP.AbstractDiscretizer, registry
                )
                Test.@test :collocation in discretizer_ids

                # Test modeler parameter support
                modeler_ids = CTBase.Strategies.strategy_ids(CTSolvers.Modelers.AbstractNLPModeler, registry)
                Test.@test :adnlp in modeler_ids  # CPU-only
                Test.@test :exa in modeler_ids     # CPU+GPU

                # Test solver parameter support  
                solver_ids = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry)
                Test.@test :ipopt in solver_ids    # CPU-only
                Test.@test :madnlp in solver_ids   # CPU+GPU
                Test.@test :uno in solver_ids      # CPU-only
                Test.@test :madncl in solver_ids   # CPU+GPU
                Test.@test :knitro in solver_ids   # CPU-only
            end

            Test.@testset "Registry Structure Validation" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that registry has the expected structure through strategy queries
                discretizer_ids = CTBase.Strategies.strategy_ids(
                    CTSolvers.DOCP.AbstractDiscretizer, registry
                )
                modeler_ids = CTBase.Strategies.strategy_ids(CTSolvers.Modelers.AbstractNLPModeler, registry)
                solver_ids = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry)

                # Test that each family has strategies
                Test.@test length(discretizer_ids) >= 1
                Test.@test length(modeler_ids) >= 1
                Test.@test length(solver_ids) >= 1

                # Test that expected strategies are present
                Test.@test :collocation in discretizer_ids
                Test.@test :adnlp in modeler_ids
                Test.@test :exa in modeler_ids
                Test.@test :ipopt in solver_ids
            end
        end

        # ====================================================================
        # PERFORMANCE TESTS
        # ====================================================================

        Test.@testset "Performance Characteristics" begin
            Test.@testset "Registry Creation Performance" begin
                # Registry creation should be fast
                allocs = Test.@allocated OptimalControl.get_strategy_registry()
                Test.@test allocs < 50000  # Reasonable allocation limit

                # Type stability
                Test.@test_nowarn Test.@inferred OptimalControl.get_strategy_registry()
            end

            Test.@testset "Strategy Query Performance" begin
                registry = OptimalControl.get_strategy_registry()

                # Strategy ID queries should be fast
                allocs = Test.@allocated CTBase.Strategies.strategy_ids(
                    CTSolvers.Solvers.AbstractNLPSolver, registry
                )
                Test.@test allocs < 10000

                # Multiple queries should not accumulate excessive allocations
                total_allocs = 0
                for i in 1:10
                    total_allocs += Test.@allocated CTBase.Strategies.strategy_ids(
                        CTSolvers.Modelers.AbstractNLPModeler, registry
                    )
                end
                Test.@test total_allocs < 50000
            end

            Test.@testset "Multiple Registry Access" begin
                # Multiple registry accesses should be efficient
                total_allocs = 0
                for i in 1:5
                    registry = OptimalControl.get_strategy_registry()
                    total_allocs += Test.@allocated CTBase.Strategies.strategy_ids(
                        CTSolvers.DOCP.AbstractDiscretizer, registry
                    )
                    total_allocs += Test.@allocated CTBase.Strategies.strategy_ids(
                        CTSolvers.Modelers.AbstractNLPModeler, registry
                    )
                    total_allocs += Test.@allocated CTBase.Strategies.strategy_ids(
                        CTSolvers.Solvers.AbstractNLPSolver, registry
                    )
                end
                Test.@test total_allocs < 100000
            end
        end

        # ====================================================================
        # EDGE CASE TESTS
        # ====================================================================

        Test.@testset "Edge Cases" begin
            Test.@testset "Registry Immutability" begin
                # Test that registry returns consistent results
                registry1 = OptimalControl.get_strategy_registry()
                registry2 = OptimalControl.get_strategy_registry()

                # Test that strategy IDs are consistent across registry calls
                discretizer_ids1 = CTBase.Strategies.strategy_ids(
                    CTSolvers.DOCP.AbstractDiscretizer, registry1
                )
                discretizer_ids2 = CTBase.Strategies.strategy_ids(
                    CTSolvers.DOCP.AbstractDiscretizer, registry2
                )
                Test.@test discretizer_ids1 == discretizer_ids2

                modeler_ids1 = CTBase.Strategies.strategy_ids(
                    CTSolvers.Modelers.AbstractNLPModeler, registry1
                )
                modeler_ids2 = CTBase.Strategies.strategy_ids(
                    CTSolvers.Modelers.AbstractNLPModeler, registry2
                )
                Test.@test modeler_ids1 == modeler_ids2

                solver_ids1 = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry1)
                solver_ids2 = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry2)
                Test.@test solver_ids1 == solver_ids2
            end

            Test.@testset "Strategy Consistency" begin
                registry = OptimalControl.get_strategy_registry()

                # All strategy IDs should be symbols
                for family_type in [
                    CTSolvers.DOCP.AbstractDiscretizer,
                    CTSolvers.Modelers.AbstractNLPModeler,
                    CTSolvers.Solvers.AbstractNLPSolver,
                ]
                    ids = CTBase.Strategies.strategy_ids(family_type, registry)
                    Test.@test all(id -> id isa Symbol, ids)
                end

                # Strategy IDs should be unique within each family
                for family_type in [
                    CTSolvers.DOCP.AbstractDiscretizer,
                    CTSolvers.Modelers.AbstractNLPModeler,
                    CTSolvers.Solvers.AbstractNLPSolver,
                ]
                    ids = CTBase.Strategies.strategy_ids(family_type, registry)
                    Test.@test length(ids) == length(unique(ids))
                end
            end

            Test.@testset "Parameter Consistency" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that CPU and GPU parameters are distinct and valid
                Test.@test CTBase.Strategies.CPU !== CTBase.Strategies.GPU
                Test.@test CTBase.Strategies.CPU != CTBase.Strategies.GPU

                # Test that parameters are not strategies
                Test.@test CTBase.Strategies.CPU !== CTSolvers.Modelers.Exa
                Test.@test CTBase.Strategies.GPU !== CTSolvers.Solvers.Ipopt
            end

            Test.@testset "Registry Completeness" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that all expected families are present through strategy queries
                discretizer_ids = CTBase.Strategies.strategy_ids(
                    CTSolvers.DOCP.AbstractDiscretizer, registry
                )
                modeler_ids = CTBase.Strategies.strategy_ids(CTSolvers.Modelers.AbstractNLPModeler, registry)
                solver_ids = CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry)

                Test.@test length(discretizer_ids) >= 1
                Test.@test length(modeler_ids) >= 1
                Test.@test length(solver_ids) >= 1

                # Test that expected strategies are present
                Test.@test :collocation in discretizer_ids
                Test.@test :adnlp in modeler_ids
                Test.@test :exa in modeler_ids
                Test.@test :ipopt in solver_ids
                Test.@test :madnlp in solver_ids
                Test.@test :uno in solver_ids
                Test.@test :madncl in solver_ids
                Test.@test :knitro in solver_ids
            end
        end
    end
end

end # module

test_registry() = TestRegistry.test_registry()

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
            Test.@test registry isa CTSolvers.StrategyRegistry
        end

        Test.@testset "Discretizer Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry)
            Test.@test :collocation in ids
            Test.@test length(ids) >= 1
        end

        Test.@testset "Modeler Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
            Test.@test :adnlp in ids
            Test.@test :exa in ids
            Test.@test length(ids) == 2
        end

        Test.@testset "Solver Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)
            Test.@test :ipopt in ids
            Test.@test :madnlp in ids
            Test.@test :madncl in ids
            Test.@test :knitro in ids
            Test.@test length(ids) == 4
        end

        Test.@testset "Parameter Support - Modelers" begin
            registry = OptimalControl.get_strategy_registry()

            # Test parameter availability using CTSolvers functions
            adnlp_params = CTSolvers.Strategies.available_parameters(
                :modeler, CTSolvers.AbstractNLPModeler, registry
            )
            exa_params = CTSolvers.Strategies.available_parameters(
                :modeler, CTSolvers.AbstractNLPModeler, registry
            )

            # Filter parameters for specific strategies
            adnlp_filtered = CTSolvers.Strategies.available_parameters(
                :adnlp, CTSolvers.AbstractNLPModeler, registry
            )
            exa_filtered = CTSolvers.Strategies.available_parameters(
                :exa, CTSolvers.AbstractNLPModeler, registry
            )

            # ADNLP should only support CPU
            Test.@test CTSolvers.CPU in adnlp_filtered
            Test.@test CTSolvers.GPU ∉ adnlp_filtered

            # Exa should support both CPU and GPU
            Test.@test CTSolvers.CPU in exa_filtered
            Test.@test CTSolvers.GPU in exa_filtered

            # Test parameter type extraction
            Test.@test CTSolvers.Strategies.get_parameter_type(CTSolvers.ADNLP) === nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(CTSolvers.Exa) === nothing
        end

        Test.@testset "Parameter Support - Solvers" begin
            registry = OptimalControl.get_strategy_registry()

            # Test parameter availability using CTSolvers functions with abstract types
            # Filter parameters for specific strategies
            ipopt_filtered = CTSolvers.Strategies.available_parameters(
                :ipopt, CTSolvers.AbstractNLPSolver, registry
            )
            madnlp_filtered = CTSolvers.Strategies.available_parameters(
                :madnlp, CTSolvers.AbstractNLPSolver, registry
            )
            madncl_filtered = CTSolvers.Strategies.available_parameters(
                :madncl, CTSolvers.AbstractNLPSolver, registry
            )
            knitro_filtered = CTSolvers.Strategies.available_parameters(
                :knitro, CTSolvers.AbstractNLPSolver, registry
            )

            # CPU-only solvers
            Test.@test CTSolvers.CPU in ipopt_filtered
            Test.@test CTSolvers.GPU ∉ ipopt_filtered

            Test.@test CTSolvers.CPU in knitro_filtered
            Test.@test CTSolvers.GPU ∉ knitro_filtered

            # GPU-capable solvers
            Test.@test CTSolvers.CPU in madnlp_filtered
            Test.@test CTSolvers.GPU in madnlp_filtered

            Test.@test CTSolvers.CPU in madncl_filtered
            Test.@test CTSolvers.GPU in madncl_filtered

            # Test parameter type extraction
            Test.@test CTSolvers.Strategies.get_parameter_type(CTSolvers.Ipopt) === nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(CTSolvers.MadNLP) === nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(CTSolvers.MadNCL) === nothing
            Test.@test CTSolvers.Strategies.get_parameter_type(CTSolvers.Knitro) === nothing
        end

        Test.@testset "Parameter Type Validation" begin
            # Test that parameter types are correctly identified
            # Use available CTSolvers functions for parameter validation
            registry = OptimalControl.get_strategy_registry()

            # Test that registry contains expected families
            Test.@test registry isa CTSolvers.StrategyRegistry

            # Test that CPU and GPU are distinct parameters
            Test.@test CTSolvers.CPU !== CTSolvers.GPU
            Test.@test CTSolvers.CPU != CTSolvers.GPU

            # Test that strategies are not parameters
            Test.@test CTSolvers.Exa !== CTSolvers.CPU
            Test.@test CTSolvers.Ipopt !== CTSolvers.GPU

            # Test parameter type identification using CTSolvers functions
            Test.@test CTSolvers.Strategies.is_parameter_type(CTSolvers.CPU)
            Test.@test CTSolvers.Strategies.is_parameter_type(CTSolvers.GPU)
            Test.@test !CTSolvers.Strategies.is_parameter_type(CTSolvers.Exa)
            Test.@test !CTSolvers.Strategies.is_parameter_type(CTSolvers.Ipopt)
            Test.@test !CTSolvers.Strategies.is_parameter_type(Int)
            Test.@test !CTSolvers.Strategies.is_parameter_type(String)
        end

        Test.@testset "Determinism" begin
            r1 = OptimalControl.get_strategy_registry()
            r2 = OptimalControl.get_strategy_registry()
            ids1 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, r1)
            ids2 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, r2)
            Test.@test ids1 == ids2
        end

        # ====================================================================
        # PARAMETER SUPPORT TESTS
        # ====================================================================

        Test.@testset "Parameter Support - Detailed" begin
            Test.@testset "CPU/GPU Parameter Availability" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that CPU and GPU parameters exist and are distinct
                Test.@test CTSolvers.CPU !== nothing
                Test.@test CTSolvers.GPU !== nothing
                Test.@test CTSolvers.CPU !== CTSolvers.GPU
                Test.@test CTSolvers.CPU != CTSolvers.GPU
            end

            Test.@testset "Strategy Parameter Mapping" begin
                registry = OptimalControl.get_strategy_registry()

                # Test discretizer parameter support (should be parameter-agnostic)
                discretizer_ids = CTSolvers.strategy_ids(
                    CTDirect.AbstractDiscretizer, registry
                )
                Test.@test :collocation in discretizer_ids

                # Test modeler parameter support
                modeler_ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
                Test.@test :adnlp in modeler_ids  # CPU-only
                Test.@test :exa in modeler_ids     # CPU+GPU

                # Test solver parameter support  
                solver_ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)
                Test.@test :ipopt in solver_ids    # CPU-only
                Test.@test :madnlp in solver_ids   # CPU+GPU
                Test.@test :madncl in solver_ids   # CPU+GPU
                Test.@test :knitro in solver_ids   # CPU-only
            end

            Test.@testset "Registry Structure Validation" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that registry has the expected structure through strategy queries
                discretizer_ids = CTSolvers.strategy_ids(
                    CTDirect.AbstractDiscretizer, registry
                )
                modeler_ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
                solver_ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)

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
                allocs = Test.@allocated CTSolvers.strategy_ids(
                    CTSolvers.AbstractNLPSolver, registry
                )
                Test.@test allocs < 10000

                # Multiple queries should not accumulate excessive allocations
                total_allocs = 0
                for i in 1:10
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(
                        CTSolvers.AbstractNLPModeler, registry
                    )
                end
                Test.@test total_allocs < 50000
            end

            Test.@testset "Multiple Registry Access" begin
                # Multiple registry accesses should be efficient
                total_allocs = 0
                for i in 1:5
                    registry = OptimalControl.get_strategy_registry()
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(
                        CTDirect.AbstractDiscretizer, registry
                    )
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(
                        CTSolvers.AbstractNLPModeler, registry
                    )
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(
                        CTSolvers.AbstractNLPSolver, registry
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
                discretizer_ids1 = CTSolvers.strategy_ids(
                    CTDirect.AbstractDiscretizer, registry1
                )
                discretizer_ids2 = CTSolvers.strategy_ids(
                    CTDirect.AbstractDiscretizer, registry2
                )
                Test.@test discretizer_ids1 == discretizer_ids2

                modeler_ids1 = CTSolvers.strategy_ids(
                    CTSolvers.AbstractNLPModeler, registry1
                )
                modeler_ids2 = CTSolvers.strategy_ids(
                    CTSolvers.AbstractNLPModeler, registry2
                )
                Test.@test modeler_ids1 == modeler_ids2

                solver_ids1 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry1)
                solver_ids2 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry2)
                Test.@test solver_ids1 == solver_ids2
            end

            Test.@testset "Strategy Consistency" begin
                registry = OptimalControl.get_strategy_registry()

                # All strategy IDs should be symbols
                for family_type in [
                    CTDirect.AbstractDiscretizer,
                    CTSolvers.AbstractNLPModeler,
                    CTSolvers.AbstractNLPSolver,
                ]
                    ids = CTSolvers.strategy_ids(family_type, registry)
                    Test.@test all(id -> id isa Symbol, ids)
                end

                # Strategy IDs should be unique within each family
                for family_type in [
                    CTDirect.AbstractDiscretizer,
                    CTSolvers.AbstractNLPModeler,
                    CTSolvers.AbstractNLPSolver,
                ]
                    ids = CTSolvers.strategy_ids(family_type, registry)
                    Test.@test length(ids) == length(unique(ids))
                end
            end

            Test.@testset "Parameter Consistency" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that CPU and GPU parameters are distinct and valid
                Test.@test CTSolvers.CPU !== CTSolvers.GPU
                Test.@test CTSolvers.CPU != CTSolvers.GPU

                # Test that parameters are not strategies
                Test.@test CTSolvers.CPU !== CTSolvers.Exa
                Test.@test CTSolvers.GPU !== CTSolvers.Ipopt
            end

            Test.@testset "Registry Completeness" begin
                registry = OptimalControl.get_strategy_registry()

                # Test that all expected families are present through strategy queries
                discretizer_ids = CTSolvers.strategy_ids(
                    CTDirect.AbstractDiscretizer, registry
                )
                modeler_ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
                solver_ids = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)

                Test.@test length(discretizer_ids) >= 1
                Test.@test length(modeler_ids) >= 1
                Test.@test length(solver_ids) >= 1

                # Test that expected strategies are present
                Test.@test :collocation in discretizer_ids
                Test.@test :adnlp in modeler_ids
                Test.@test :exa in modeler_ids
                Test.@test :ipopt in solver_ids
                Test.@test :madnlp in solver_ids
                Test.@test :madncl in solver_ids
                Test.@test :knitro in solver_ids
            end
        end
    end
end

end # module

test_registry() = TestRegistry.test_registry()

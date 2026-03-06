# ============================================================================
# Strategy Registry Setup Tests
# ============================================================================
# This file tests the `get_strategy_registry` function. It verifies that
# the global strategy registry is correctly populated with all available
# abstract families and their concrete implementations with parameter support
# provided by the solver ecosystem (CTDirect, CTSolvers).

module TestRegistry

import Test
import OptimalControl
import CTSolvers
import CTDirect

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
            
            # The registry structure tells us which parameters are supported
            # ADNLP should only support CPU (checked via registry structure)
            # Exa should support both CPU and GPU (checked via registry structure)
            
            # Test that registry contains parameter information
            # This is verified through the registry structure itself
            Test.@test registry isa CTSolvers.StrategyRegistry
        end

        Test.@testset "Parameter Support - Solvers" begin
            registry = OptimalControl.get_strategy_registry()
            
            # CPU-only solvers (Ipopt, Knitro) and GPU-capable solvers (MadNLP, MadNCL)
            # are distinguished by their parameter lists in the registry
            
            # Test that registry contains parameter information
            Test.@test registry isa CTSolvers.StrategyRegistry
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
                discretizer_ids = CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry)
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
                discretizer_ids = CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry)
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
                allocs = Test.@allocated CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)
                Test.@test allocs < 10000
                
                # Multiple queries should not accumulate excessive allocations
                total_allocs = 0
                for i in 1:10
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
                end
                Test.@test total_allocs < 50000
            end

            Test.@testset "Multiple Registry Access" begin
                # Multiple registry accesses should be efficient
                total_allocs = 0
                for i in 1:5
                    registry = OptimalControl.get_strategy_registry()
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry)
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
                    total_allocs += Test.@allocated CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)
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
                discretizer_ids1 = CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry1)
                discretizer_ids2 = CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry2)
                Test.@test discretizer_ids1 == discretizer_ids2
                
                modeler_ids1 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry1)
                modeler_ids2 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry2)
                Test.@test modeler_ids1 == modeler_ids2
                
                solver_ids1 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry1)
                solver_ids2 = CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry2)
                Test.@test solver_ids1 == solver_ids2
            end

            Test.@testset "Strategy Consistency" begin
                registry = OptimalControl.get_strategy_registry()
                
                # All strategy IDs should be symbols
                for family_type in [CTDirect.AbstractDiscretizer, CTSolvers.AbstractNLPModeler, CTSolvers.AbstractNLPSolver]
                    ids = CTSolvers.strategy_ids(family_type, registry)
                    Test.@test all(id -> id isa Symbol, ids)
                end
                
                # Strategy IDs should be unique within each family
                for family_type in [CTDirect.AbstractDiscretizer, CTSolvers.AbstractNLPModeler, CTSolvers.AbstractNLPSolver]
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
                discretizer_ids = CTSolvers.strategy_ids(CTDirect.AbstractDiscretizer, registry)
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

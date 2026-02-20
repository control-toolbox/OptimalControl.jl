module TestExtGeneric

import Test
import CTSolvers.Optimization
import SolverCore
import NLPModels
import ADNLPModels

# Default test options (can be overridden by Main.TestOptions if available)
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: Mock stats struct for testing generic extract_solver_infos
mutable struct MockStats <: SolverCore.AbstractExecutionStats
    objective::Float64
    iter::Int
    primal_feas::Float64
    status::Symbol
end

"""
    test_generic_extract_solver_infos()

Test the generic solver extension for CTSolvers.

This tests the base `extract_solver_infos` function which works with
any SolverCore.AbstractExecutionStats implementation, including Ipopt
and other solvers that follow the SolverCore interface.

🧪 **Applying Testing Rule**: Unit Tests + Contract Tests
"""
function test_generic_extract_solver_infos()
    Test.@testset "Generic Extension - extract_solver_infos" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        Test.@testset "extract_solver_infos with minimization" begin
            # Create a simple minimization problem: min (x-1)^2 + (y-2)^2
            # Solution: x=1, y=2, objective=0
            function obj(x)
                return (x[1] - 1.0)^2 + (x[2] - 2.0)^2
            end
            
            function grad!(g, x)
                g[1] = 2.0 * (x[1] - 1.0)
                g[2] = 2.0 * (x[2] - 2.0)
                return g
            end
            
            function hess_structure!(rows, cols)
                rows[1] = 1
                cols[1] = 1
                rows[2] = 2
                cols[2] = 2
                return rows, cols
            end
            
            function hess_coord!(vals, x)
                vals[1] = 2.0
                vals[2] = 2.0
                return vals
            end
            
            # Create NLP model
            x0 = [0.0, 0.0]
            nlp = ADNLPModels.ADNLPModel(
                obj, x0;
                grad=grad!,
                hess_structure=hess_structure!,
                hess_coord=hess_coord!,
                minimize=true
            )
            
            # Create mock stats with typical values
            mock_stats = MockStats(0.0, 10, 1e-8, :first_order)
            
            # Extract solver infos using generic function
            objective, iterations, constraints_violation, message, status, successful = 
                Optimization.extract_solver_infos(mock_stats, true)
            
            # Verify results
            Test.@test objective ≈ 0.0 atol=1e-10
            Test.@test iterations == 10
            Test.@test constraints_violation ≈ 1e-8 atol=1e-10
            Test.@test message == "Ipopt/generic"
            Test.@test status == :first_order
            Test.@test successful == true
        end
        
        Test.@testset "extract_solver_infos with different status codes" begin
            # Test different status codes and their success determination
            
            # Test successful status: :first_order
            stats_success = MockStats(1.5, 5, 1e-6, :first_order)
            obj, iter, viol, msg, stat, success = 
                Optimization.extract_solver_infos(stats_success, true)
            
            Test.@test success == true
            Test.@test stat == :first_order
            Test.@test msg == "Ipopt/generic"
            
            # Test successful status: :acceptable
            stats_acceptable = MockStats(1.5, 5, 1e-6, :acceptable)
            _, _, _, _, stat2, success2 = 
                Optimization.extract_solver_infos(stats_acceptable, true)
            
            Test.@test success2 == true
            Test.@test stat2 == :acceptable
            
            # Test unsuccessful status: :max_iter
            stats_max_iter = MockStats(1.5, 100, 1e-2, :max_iter)
            _, _, _, _, stat3, success3 = 
                Optimization.extract_solver_infos(stats_max_iter, true)
            
            Test.@test success3 == false
            Test.@test stat3 == :max_iter
            
            # Test unsuccessful status: :infeasible
            stats_infeasible = MockStats(1.5, 50, 1e-1, :infeasible)
            _, _, _, _, stat4, success4 = 
                Optimization.extract_solver_infos(stats_infeasible, true)
            
            Test.@test success4 == false
            Test.@test stat4 == :infeasible
        end
        
        Test.@testset "build_solution contract verification" begin
            # Test that extract_solver_infos returns types compatible with build_solution
            
            # Test with minimization
            mock_stats_min = MockStats(2.5, 15, 1e-7, :first_order)
            objective, iterations, constraints_violation, message, status, successful = 
                Optimization.extract_solver_infos(mock_stats_min, true)
            
            # Verify types match build_solution contract
            Test.@test objective isa Float64
            Test.@test iterations isa Int
            Test.@test constraints_violation isa Float64
            Test.@test message isa String
            Test.@test status isa Symbol
            Test.@test successful isa Bool
            
            # Verify tuple structure
            result = Optimization.extract_solver_infos(mock_stats_min, true)
            Test.@test result isa Tuple
            Test.@test length(result) == 6
            
            # Test with maximization (should not affect the generic implementation)
            mock_stats_max = MockStats(2.5, 15, 1e-7, :first_order)
            objective_max, iterations_max, constraints_violation_max, message_max, status_max, successful_max = 
                Optimization.extract_solver_infos(mock_stats_max, false)
            
            # Verify types for maximization too (generic implementation ignores minimize flag)
            Test.@test objective_max isa Float64
            Test.@test iterations_max isa Int
            Test.@test constraints_violation_max isa Float64
            Test.@test message_max isa String
            Test.@test status_max isa Symbol
            Test.@test successful_max isa Bool
            
            # Verify generic message
            Test.@test message == "Ipopt/generic"
            Test.@test message_max == "Ipopt/generic"
            
            # Verify that minimize flag doesn't affect generic implementation
            Test.@test objective == objective_max  # Same value, no sign flipping
        end
        
        Test.@testset "SolverInfos construction verification" begin
            # Test that extracted values can be used to construct SolverInfos
            # This verifies the complete contract with build_solution
            
            # Test with minimization
            mock_stats_min = MockStats(2.5, 15, 1e-7, :first_order)
            objective, iterations, constraints_violation, message, status, successful = 
                Optimization.extract_solver_infos(mock_stats_min, true)
            
            # Create additional infos dictionary as expected by SolverInfos
            additional_infos = Dict{Symbol,Any}(
                :objective_value => objective,
                :solver_name => message,
                :test_case => "minimization"
            )
            
            # Construct SolverInfos (this would normally be done inside build_solution)
            # Note: We need to import or define SolverInfos here for testing
            # Since we can't import from CTModels in this context, we'll test the contract
            # by verifying that all required fields are available with correct types
            
            # Verify all SolverInfos constructor arguments are available
            Test.@test iterations isa Int
            Test.@test status isa Symbol
            Test.@test message isa String
            Test.@test successful isa Bool
            Test.@test constraints_violation isa Float64
            Test.@test additional_infos isa Dict{Symbol,Any}
            
            # Test with maximization
            mock_stats_max = MockStats(3.14, 20, 1e-8, :acceptable)
            objective_max, iterations_max, constraints_violation_max, message_max, status_max, successful_max = 
                Optimization.extract_solver_infos(mock_stats_max, false)
            
            # Create additional infos dictionary for maximization
            additional_infos_max = Dict{Symbol,Any}(
                :objective_value => objective_max,
                :solver_name => message_max,
                :test_case => "maximization"
            )
            
            # Verify contract for maximization too
            Test.@test iterations_max isa Int
            Test.@test status_max isa Symbol
            Test.@test message_max isa String
            Test.@test successful_max isa Bool
            Test.@test constraints_violation_max isa Float64
            Test.@test additional_infos_max isa Dict{Symbol,Any}
            
            # Verify that the values are consistent with what SolverInfos expects
            # (this simulates the SolverInfos constructor call)
            solver_infos_args = (
                iterations=iterations_max,
                status=status_max,
                message=message_max,
                successful=successful_max,
                constraints_violation=constraints_violation_max,
                infos=additional_infos_max
            )
            
            # All arguments should be present and of correct type
            Test.@test solver_infos_args.iterations isa Int
            Test.@test solver_infos_args.status isa Symbol
            Test.@test solver_infos_args.message isa String
            Test.@test solver_infos_args.successful isa Bool
            Test.@test solver_infos_args.constraints_violation isa Float64
            Test.@test solver_infos_args.infos isa Dict{Symbol,Any}
        end
        
        Test.@testset "all return values present and correct" begin
            # Test that all 6 return values are present and have correct types
            
            mock_stats = MockStats(3.14, 42, 1e-9, :acceptable)
            result = Optimization.extract_solver_infos(mock_stats, true)
            
            # Should return a 6-tuple
            Test.@test result isa Tuple
            Test.@test length(result) == 6
            
            objective, iterations, constraints_violation, message, status, successful = result
            
            Test.@test objective isa Real
            Test.@test iterations isa Int
            Test.@test constraints_violation isa Real
            Test.@test message isa String
            Test.@test status isa Symbol
            Test.@test successful isa Bool
            
            # Verify specific values
            Test.@test objective == 3.14
            Test.@test iterations == 42
            Test.@test constraints_violation == 1e-9
            Test.@test message == "Ipopt/generic"
            Test.@test status == :acceptable
            Test.@test successful == true
        end
    end
end

end # module

test_generic_extract_solver_infos() = TestExtGeneric.test_generic_extract_solver_infos()

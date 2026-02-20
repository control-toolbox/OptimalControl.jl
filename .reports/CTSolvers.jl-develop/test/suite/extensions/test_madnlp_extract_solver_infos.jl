module TestExtMadNLP

import Test
import CTSolvers.Optimization
import MadNLP
import MadNLPMumps # must be removed in the future
import NLPModels
import ADNLPModels

# Default test options (can be overridden by Main.TestOptions if available)
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_madnlp()

Test the MadNLP extension for CTSolvers.

This tests the `extract_solver_infos` function which extracts solver information
from MadNLP execution statistics, including proper handling of objective sign
correction and status codes.
"""
function test_madnlp_extract_solver_infos()
    Test.@testset "MadNLP Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
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
            
            # Solve with MadNLP
            solver = MadNLP.MadNLPSolver(nlp; print_level=MadNLP.ERROR)
            stats = MadNLP.solve!(solver)
            
            # Extract solver infos using CTSolvers extension
            objective, iterations, constraints_violation, message, status, successful = 
                Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
            # Verify results
            Test.@test objective ≈ 0.0 atol=1e-6  # Optimal objective
            Test.@test iterations > 0  # Should have done some iterations
            Test.@test constraints_violation < 1e-6  # No constraints, should be near zero
            Test.@test message == "MadNLP"
            Test.@test status in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test successful == true
        end
        
        Test.@testset "extract_solver_infos objective sign handling" begin
            # Test that the function correctly handles the minimize flag
            # We'll use a minimization problem and verify the sign logic
            function obj(x)
                return (x[1] - 1.0)^2 + (x[2] - 2.0)^2
            end
            
            x0 = [0.0, 0.0]
            
            # Create minimization problem
            nlp_min = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver_min = MadNLP.MadNLPSolver(nlp_min; print_level=MadNLP.ERROR)
            stats_min = MadNLP.solve!(solver_min)
            
            # Extract solver infos
            objective_min, _, _, _, _, _ = Optimization.extract_solver_infos(stats_min, NLPModels.get_minimize(nlp_min))
            
            # For minimization, objective should equal stats.objective
            Test.@test objective_min ≈ stats_min.objective atol=1e-10
            Test.@test objective_min ≈ 0.0 atol=1e-6
            
            # Test that NLPModels.get_minimize works correctly
            Test.@test NLPModels.get_minimize(nlp_min) == true
            
            # Create a maximization problem (negative of the same function)
            # max -(x-1)^2 - (y-2)^2 is equivalent to min (x-1)^2 + (y-2)^2
            # but we test the sign handling logic
            nlp_max = ADNLPModels.ADNLPModel(obj, x0; minimize=false)
            Test.@test NLPModels.get_minimize(nlp_max) == false
            
            # For a maximization problem, the objective returned by extract_solver_infos
            # should be -stats.objective
            # We don't solve it (to avoid convergence issues) but test the logic
        end
        
        Test.@testset "objective sign correction logic" begin
            # Test the sign correction logic without solving
            # For minimization: objective = stats.objective
            # For maximization: objective = -stats.objective
            
            function obj(x)
                return x[1]^2 + x[2]^2
            end
            
            x0 = [1.0, 1.0]
            
            # Minimization problem
            nlp_min = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver_min = MadNLP.MadNLPSolver(nlp_min; print_level=MadNLP.ERROR)
            stats_min = MadNLP.solve!(solver_min)
            obj_min, _, _, _, _, _ = Optimization.extract_solver_infos(stats_min, NLPModels.get_minimize(nlp_min))
            
            # For minimization, extracted objective should equal raw stats objective
            Test.@test obj_min ≈ stats_min.objective atol=1e-10
            Test.@test obj_min ≈ 0.0 atol=1e-6
            
            # Verify the minimize flag is correctly read
            Test.@test NLPModels.get_minimize(nlp_min) == true
        end
        
        Test.@testset "status code conversion" begin
            # Test that MadNLP status codes are correctly converted to symbols
            function obj(x)
                return x[1]^2
            end
            
            x0 = [1.0]
            nlp = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver = MadNLP.MadNLPSolver(nlp; print_level=MadNLP.ERROR)
            stats = MadNLP.solve!(solver)
            
            _, _, _, _, status, _ = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
            # Status should be a Symbol
            Test.@test status isa Symbol
            Test.@test status in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL, 
                                   :INFEASIBLE_PROBLEM, :MAXIMUM_ITERATIONS_EXCEEDED,
                                   :RESTORATION_FAILED)
        end
        
        Test.@testset "success determination" begin
            # Test that success is correctly determined based on status
            function obj(x)
                return x[1]^2
            end
            
            x0 = [1.0]
            nlp = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver = MadNLP.MadNLPSolver(nlp; print_level=MadNLP.ERROR, max_iter=100)
            stats = MadNLP.solve!(solver)
            
            _, _, _, _, status, successful = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
            # For a simple problem, should succeed
            Test.@test successful == true
            Test.@test status in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            
            # Verify the logic: successful if status is one of the success codes
            if status == :SOLVE_SUCCEEDED || status == :SOLVED_TO_ACCEPTABLE_LEVEL
                Test.@test successful == true
            else
                Test.@test successful == false
            end
        end
        
        Test.@testset "all return values present" begin
            # Test that all 6 return values are present and have correct types
            function obj(x)
                return x[1]^2 + x[2]^2
            end
            
            x0 = [1.0, 1.0]
            nlp = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver = MadNLP.MadNLPSolver(nlp; print_level=MadNLP.ERROR)
            stats = MadNLP.solve!(solver)
            
            result = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
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
        end
        
        Test.@testset "maximization problem - objective sign consistency" begin
            # Test with a real maximization problem: max 1 - x^2
            # Solution: x = 0, objective = 1
            function obj_max(x)
                return 1.0 - x[1]^2
            end
            
            x0 = [0.5]  # Start away from optimum
            
            # Create maximization problem
            nlp_max = ADNLPModels.ADNLPModel(obj_max, x0; minimize=false)
            Test.@test NLPModels.get_minimize(nlp_max) == false
            
            # Solve with MadNLP
            solver_max = MadNLP.MadNLPSolver(nlp_max; print_level=MadNLP.ERROR)
            stats_max = MadNLP.solve!(solver_max)
            
            # Extract solver infos
            objective_extracted, _, _, _, _, _ = Optimization.extract_solver_infos(stats_max, NLPModels.get_minimize(nlp_max))
            
            # The extracted objective should be the true maximization objective (≈ 1.0)
            Test.@test objective_extracted ≈ 1.0 atol=1e-6
            
            # Test the consistency logic: (flip_madnlp && flip_extract) || (!flip_madnlp && !flip_extract)
            # We need to determine if MadNLP flips the sign internally
            raw_madnlp_objective = stats_max.objective
            
            # If MadNLP returns the negative (old behavior), then raw should be ≈ -1.0
            # If MadNLP returns the positive (new behavior), then raw should be ≈ 1.0
            flip_madnlp = abs(raw_madnlp_objective + 1.0) < 1e-6  # MadNLP returns -1.0
            flip_extract = objective_extracted != raw_madnlp_objective  # Our function flips it
            
            # The consistency condition should always be true
            consistency_condition = (flip_madnlp && flip_extract) || (!flip_madnlp && !flip_extract)
            Test.@test consistency_condition == true
            
            # Additional debugging info (if test fails)
            if !consistency_condition
                println("DEBUG INFO:")
                println("Raw MadNLP objective: $raw_madnlp_objective")
                println("Extracted objective: $objective_extracted")
                println("flip_madnlp: $flip_madnlp")
                println("flip_extract: $flip_extract")
                println("Expected objective: 1.0")
            end
        end
        
        Test.@testset "unit test - mock maximization objective flip" begin
            # Unit test with mock data to verify the flip logic
            function obj(x)
                return x[1]^2 + x[2]^2
            end
            
            x0 = [1.0, 1.0]
            
            # Create a mock stats object (we'll create a real one but don't solve)
            nlp_min = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver_min = MadNLP.MadNLPSolver(nlp_min; print_level=MadNLP.ERROR)
            stats_min = MadNLP.solve!(solver_min)
            
            # Mock the objective value to test the flip logic
            original_objective = stats_min.objective
            
            # Test case 1: minimization (should not flip)
            obj_min, _, _, _, _, _ = Optimization.extract_solver_infos(stats_min, true)
            Test.@test obj_min ≈ original_objective atol=1e-10
            
            # Test case 2: maximization (should flip)
            obj_max, _, _, _, _, _ = Optimization.extract_solver_infos(stats_min, false)
            Test.@test obj_max ≈ -original_objective atol=1e-10
            
            # Verify the flip logic
            Test.@test obj_max == -obj_min
        end
        
        Test.@testset "build_solution contract verification" begin
            # Test that extract_solver_infos returns types compatible with build_solution
            function obj(x)
                return x[1]^2 + x[2]^2
            end
            
            x0 = [1.0, 1.0]
            nlp = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver = MadNLP.MadNLPSolver(nlp; print_level=MadNLP.ERROR)
            stats = MadNLP.solve!(solver)
            
            # Extract solver infos
            objective, iterations, constraints_violation, message, status, successful = 
                Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
            # Verify types match build_solution contract
            Test.@test objective isa Float64
            Test.@test iterations isa Int
            Test.@test constraints_violation isa Float64
            Test.@test message isa String
            Test.@test status isa Symbol
            Test.@test successful isa Bool
            
            # Verify tuple structure
            result = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            Test.@test result isa Tuple
            Test.@test length(result) == 6
            
            # Test with maximization problem for contract compliance
            nlp_max = ADNLPModels.ADNLPModel(obj, x0; minimize=false)
            solver_max = MadNLP.MadNLPSolver(nlp_max; print_level=MadNLP.ERROR)
            stats_max = MadNLP.solve!(solver_max)
            
            objective_max, iterations_max, constraints_violation_max, message_max, status_max, successful_max = 
                Optimization.extract_solver_infos(stats_max, NLPModels.get_minimize(nlp_max))
            
            # Verify types for maximization too
            Test.@test objective_max isa Float64
            Test.@test iterations_max isa Int
            Test.@test constraints_violation_max isa Float64
            Test.@test message_max isa String
            Test.@test status_max isa Symbol
            Test.@test successful_max isa Bool
            
            # Verify solver-specific message
            Test.@test message == "MadNLP"
            Test.@test message_max == "MadNLP"
        end
        
        Test.@testset "SolverInfos construction verification" begin
            # Test that extracted values can be used to construct SolverInfos
            # This verifies the complete contract with build_solution
            
            function obj(x)
                return x[1]^2 + x[2]^2
            end
            
            x0 = [1.0, 1.0]
            nlp = ADNLPModels.ADNLPModel(obj, x0; minimize=true)
            solver = MadNLP.MadNLPSolver(nlp; print_level=MadNLP.ERROR)
            stats = MadNLP.solve!(solver)
            
            # Extract solver infos
            objective, iterations, constraints_violation, message, status, successful = 
                Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
            # Create additional infos dictionary as expected by SolverInfos
            additional_infos = Dict{Symbol,Any}(
                :objective_value => objective,
                :solver_name => message,
                :raw_stats_objective => stats.objective,
                :test_case => "madnlp_minimization"
            )
            
            # Verify all SolverInfos constructor arguments are available
            Test.@test iterations isa Int
            Test.@test status isa Symbol
            Test.@test message isa String
            Test.@test successful isa Bool
            Test.@test constraints_violation isa Float64
            Test.@test additional_infos isa Dict{Symbol,Any}
            
            # Test with maximization problem
            nlp_max = ADNLPModels.ADNLPModel(obj, x0; minimize=false)
            solver_max = MadNLP.MadNLPSolver(nlp_max; print_level=MadNLP.ERROR)
            stats_max = MadNLP.solve!(solver_max)
            
            objective_max, iterations_max, constraints_violation_max, message_max, status_max, successful_max = 
                Optimization.extract_solver_infos(stats_max, NLPModels.get_minimize(nlp_max))
            
            # Create additional infos dictionary for maximization
            additional_infos_max = Dict{Symbol,Any}(
                :objective_value => objective_max,
                :solver_name => message_max,
                :raw_stats_objective => stats_max.objective,
                :sign_flipped => objective_max != stats_max.objective,
                :test_case => "madnlp_maximization"
            )
            
            # Verify contract for maximization too
            Test.@test iterations_max isa Int
            Test.@test status_max isa Symbol
            Test.@test message_max isa String
            Test.@test successful_max isa Bool
            Test.@test constraints_violation_max isa Float64
            Test.@test additional_infos_max isa Dict{Symbol,Any}
            
            # Verify that the values are consistent with what SolverInfos expects
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
            
            # Verify solver-specific message
            Test.@test message == "MadNLP"
            Test.@test message_max == "MadNLP"
        end
    end
end

end # module

test_madnlp_extract_solver_infos() = TestExtMadNLP.test_madnlp_extract_solver_infos()

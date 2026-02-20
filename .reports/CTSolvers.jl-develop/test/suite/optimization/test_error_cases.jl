module TestOptimizationErrorCases

import Test
import CTBase.Exceptions
import CTSolvers
import NLPModels
import SolverCore
import ADNLPModels
import ExaModels
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Import from Optimization module
import CTSolvers.Optimization

# ============================================================================
# FAKE TYPES FOR ERROR TESTING (TOP-LEVEL)
# ============================================================================

"""
Minimal problem that doesn't implement the contract.
"""
struct MinimalProblemForErrors <: Optimization.AbstractOptimizationProblem end

"""
Problem with only partial contract implementation.
"""
struct PartialProblem <: Optimization.AbstractOptimizationProblem end

# Implement only ADNLP builder
Optimization.get_adnlp_model_builder(::PartialProblem) = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))

"""
Mock stats for testing.
"""
mutable struct MockStats <: SolverCore.AbstractExecutionStats
    objective::Float64
end

"""
Edge case stats for testing.
"""
mutable struct EdgeCaseStats <: SolverCore.AbstractExecutionStats
    objective::Float64
    iter::Int
    primal_feas::Float64
    status::Symbol
end

"""
Type test stats for testing.
"""
mutable struct TypeTestStats <: SolverCore.AbstractExecutionStats
    objective::Float64
    status::Symbol
end

# ============================================================================
# TEST FUNCTION
# ============================================================================

"""
    test_error_cases()

Tests for error cases and edge cases in Optimization module.

This function tests error handling, NotImplemented errors, and edge cases
to ensure the module fails gracefully with clear error messages.
"""
function test_error_cases()
    Test.@testset "Error Cases and Edge Cases" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # CONTRACT NOT IMPLEMENTED ERRORS
        # ====================================================================
        
        Test.@testset "NotImplemented Errors" begin
            prob = MinimalProblemForErrors()
            
            Test.@testset "get_adnlp_model_builder - NotImplemented" begin
                Test.@test_throws Exceptions.NotImplemented Optimization.get_adnlp_model_builder(prob)
            end
            
            Test.@testset "get_exa_model_builder - NotImplemented" begin
                Test.@test_throws Exceptions.NotImplemented Optimization.get_exa_model_builder(prob)
            end
            
            Test.@testset "get_adnlp_solution_builder - NotImplemented" begin
                Test.@test_throws Exceptions.NotImplemented Optimization.get_adnlp_solution_builder(prob)
            end
            
            Test.@testset "get_exa_solution_builder - NotImplemented" begin
                Test.@test_throws Exceptions.NotImplemented Optimization.get_exa_solution_builder(prob)
            end
        end

        # ====================================================================
        # PARTIAL CONTRACT IMPLEMENTATION
        # ====================================================================
        
        Test.@testset "Partial Contract Implementation" begin
            prob = PartialProblem()
            
            Test.@testset "Implemented builder works" begin
                builder = Optimization.get_adnlp_model_builder(prob)
                Test.@test builder isa Optimization.ADNLPModelBuilder
                
                # Can build model with implemented builder
                x0 = [1.0, 2.0]
                nlp = builder(x0)
                Test.@test nlp isa ADNLPModels.ADNLPModel
            end
            
            Test.@testset "Non-implemented builders throw NotImplemented" begin
                Test.@test_throws Exceptions.NotImplemented Optimization.get_exa_model_builder(prob)
                Test.@test_throws Exceptions.NotImplemented Optimization.get_adnlp_solution_builder(prob)
                Test.@test_throws Exceptions.NotImplemented Optimization.get_exa_solution_builder(prob)
            end
        end

        # ====================================================================
        # BUILDER ERRORS
        # ====================================================================
        
        Test.@testset "Builder Errors" begin
            Test.@testset "ADNLPModelBuilder with failing function" begin
                # Builder that throws an error
                failing_builder = Optimization.ADNLPModelBuilder(x -> error("Intentional error"))
                
                Test.@test_throws ErrorException failing_builder([1.0, 2.0])
            end
            
            Test.@testset "ExaModelBuilder with failing function" begin
                # Builder that throws an error
                failing_builder = Optimization.ExaModelBuilder((T, x) -> error("Intentional error"))
                
                Test.@test_throws ErrorException failing_builder(Float64, [1.0, 2.0])
            end
            
            Test.@testset "ADNLPSolutionBuilder with failing function" begin
                # Builder that throws an error
                failing_builder = Optimization.ADNLPSolutionBuilder(s -> error("Intentional error"))
                
                # Mock stats
                stats = MockStats(1.0)
                
                Test.@test_throws ErrorException failing_builder(stats)
            end
        end

        # ====================================================================
        # EDGE CASES
        # ====================================================================
        
        Test.@testset "Edge Cases" begin
            # Note: Empty initial guess (nvar=0) is not supported by ADNLPModels
            # ADNLPModels requires nvar > 0, so we skip this edge case
            
            Test.@testset "Single variable problem" begin
                builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> z[1]^2, x))
                
                x0 = [1.0]
                nlp = builder(x0)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.nvar == 1
                Test.@test NLPModels.obj(nlp, x0) ≈ 1.0
            end
            
            Test.@testset "Large dimension problem" begin
                n = 1000
                builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
                
                x0 = ones(n)
                nlp = builder(x0)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.nvar == n
            end
            
            Test.@testset "Different numeric types" begin
                # Float32
                builder32 = Optimization.ExaModelBuilder((T, x) -> begin
                    m = ExaModels.ExaCore(T)
                    x_var = ExaModels.variable(m, length(x); start=x)
                    ExaModels.objective(m, sum(x_var[i]^2 for i=1:length(x)))
                    ExaModels.ExaModel(m)
                end)
                
                x0_32 = Float32[1.0, 2.0]
                nlp32 = builder32(Float32, x0_32)
                Test.@test nlp32 isa ExaModels.ExaModel{Float32}
                Test.@test eltype(nlp32.meta.x0) == Float32
                
                # Float64
                x0_64 = Float64[1.0, 2.0]
                nlp64 = builder32(Float64, x0_64)
                Test.@test nlp64 isa ExaModels.ExaModel{Float64}
                Test.@test eltype(nlp64.meta.x0) == Float64
            end
        end

        # ====================================================================
        # SOLVER INFO EDGE CASES
        # ====================================================================
        
        Test.@testset "Solver Info Edge Cases" begin
            Test.@testset "Zero iterations" begin
                stats = EdgeCaseStats(0.0, 0, 0.0, :first_order)
                nlp = ADNLPModels.ADNLPModel(x -> x[1]^2, [1.0])
                
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                Test.@test iter == 0
                Test.@test success == true
            end
            
            Test.@testset "Very large objective" begin
                stats = EdgeCaseStats(1e100, 10, 1e-6, :first_order)
                nlp = ADNLPModels.ADNLPModel(x -> x[1]^2, [1.0])
                
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                Test.@test obj ≈ 1e100
                Test.@test success == true
            end
            
            Test.@testset "Very small constraint violation" begin
                stats = EdgeCaseStats(1.0, 10, 1e-15, :first_order)
                nlp = ADNLPModels.ADNLPModel(x -> x[1]^2, [1.0])
                
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                Test.@test viol ≈ 1e-15
                Test.@test success == true
            end
            
            Test.@testset "Unknown status" begin
                stats = EdgeCaseStats(1.0, 10, 1e-6, :unknown_status)
                nlp = ADNLPModels.ADNLPModel(x -> x[1]^2, [1.0])
                
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                Test.@test status == :unknown_status
                Test.@test success == false  # Not :first_order or :acceptable
            end
        end

        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================
        
        Test.@testset "Type Stability" begin
            Test.@testset "Builder return types" begin
                adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
                x0 = [1.0, 2.0]
                
                nlp = adnlp_builder(x0)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test typeof(nlp) <: ADNLPModels.ADNLPModel
            end
            
            Test.@testset "Solution builder return types" begin
                sol_builder = Optimization.ADNLPSolutionBuilder(s -> (obj=s.objective, status=s.status))
                
                stats = TypeTestStats(1.0, :first_order)
                
                sol = sol_builder(stats)
                Test.@test sol isa NamedTuple
                Test.@test haskey(sol, :obj)
                Test.@test haskey(sol, :status)
            end
        end
    end
end

end # module

test_error_cases() = TestOptimizationErrorCases.test_error_cases()

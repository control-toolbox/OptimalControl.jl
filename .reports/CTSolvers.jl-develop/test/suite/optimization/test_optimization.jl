module TestOptimization

import Test
import CTBase.Exceptions
import CTSolvers
import NLPModels
import SolverCore
import ADNLPModels
import ExaModels
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Import from Optimization module to avoid name conflicts
import CTSolvers.Optimization

# ============================================================================
# FAKE TYPES FOR CONTRACT TESTING (TOP-LEVEL)
# ============================================================================

"""
Fake optimization problem for testing the contract interface.
"""
struct FakeOptimizationProblem <: Optimization.AbstractOptimizationProblem
    adnlp_builder::Optimization.ADNLPModelBuilder
    exa_builder::Optimization.ExaModelBuilder
    adnlp_solution_builder::Optimization.ADNLPSolutionBuilder
    exa_solution_builder::Optimization.ExaSolutionBuilder
end

# Implement contract for FakeOptimizationProblem
Optimization.get_adnlp_model_builder(prob::FakeOptimizationProblem) = prob.adnlp_builder
Optimization.get_exa_model_builder(prob::FakeOptimizationProblem) = prob.exa_builder
Optimization.get_adnlp_solution_builder(prob::FakeOptimizationProblem) = prob.adnlp_solution_builder
Optimization.get_exa_solution_builder(prob::FakeOptimizationProblem) = prob.exa_solution_builder

"""
Minimal problem for testing NotImplemented errors.
"""
struct MinimalProblem <: Optimization.AbstractOptimizationProblem end

"""
Fake modeler for testing building functions.
"""
struct FakeModeler
    backend::Symbol
end

function (modeler::FakeModeler)(prob::Optimization.AbstractOptimizationProblem, initial_guess)
    if modeler.backend == :adnlp
        builder = Optimization.get_adnlp_model_builder(prob)
        return builder(initial_guess)
    else
        builder = Optimization.get_exa_model_builder(prob)
        return builder(Float64, initial_guess)
    end
end

function (modeler::FakeModeler)(prob::Optimization.AbstractOptimizationProblem, nlp_solution::SolverCore.AbstractExecutionStats)
    if modeler.backend == :adnlp
        builder = Optimization.get_adnlp_solution_builder(prob)
        return builder(nlp_solution)
    else
        builder = Optimization.get_exa_solution_builder(prob)
        return builder(nlp_solution)
    end
end

"""
Mock execution statistics for testing.
"""
mutable struct MockExecutionStats <: SolverCore.AbstractExecutionStats
    objective::Float64
    iter::Int
    primal_feas::Float64
    status::Symbol
end

# ============================================================================
# TEST FUNCTION
# ============================================================================

"""
    test_optimization()

Tests for Optimization module.

This function tests the complete Optimization module including:
- Abstract types (AbstractOptimizationProblem, AbstractBuilder, etc.)
- Concrete builder types (ADNLPModelBuilder, ExaModelBuilder, etc.)
- Contract interface (get_*_builder functions)
- Building functions (build_model, build_solution)
- Solver utilities (extract_solver_infos)
"""
function test_optimization()
    Test.@testset "Optimization Module" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================
        
        Test.@testset "Abstract Types" begin
            Test.@testset "Type hierarchy" begin
                Test.@test Optimization.AbstractOptimizationProblem <: Any
                Test.@test Optimization.AbstractBuilder <: Any
                Test.@test Optimization.AbstractModelBuilder <: Optimization.AbstractBuilder
                Test.@test Optimization.AbstractSolutionBuilder <: Optimization.AbstractBuilder
                Test.@test Optimization.AbstractOCPSolutionBuilder <: Optimization.AbstractSolutionBuilder
            end
            
            Test.@testset "Contract interface - NotImplemented errors" begin
                prob = MinimalProblem()
                
                Test.@test_throws Exceptions.NotImplemented Optimization.get_adnlp_model_builder(prob)
                Test.@test_throws Exceptions.NotImplemented Optimization.get_exa_model_builder(prob)
                Test.@test_throws Exceptions.NotImplemented Optimization.get_adnlp_solution_builder(prob)
                Test.@test_throws Exceptions.NotImplemented Optimization.get_exa_solution_builder(prob)
            end
        end

        # ====================================================================
        # UNIT TESTS - Concrete Builder Types
        # ====================================================================
        
        Test.@testset "Concrete Builder Types" begin
            Test.@testset "ADNLPModelBuilder" begin
                # Test construction
                calls = Ref(0)
                function test_builder(x; show_time=false)
                    calls[] += 1
                    return ADNLPModels.ADNLPModel(z -> sum(z.^2), x; show_time=show_time)
                end
                
                builder = Optimization.ADNLPModelBuilder(test_builder)
                Test.@test builder isa Optimization.ADNLPModelBuilder
                Test.@test builder isa Optimization.AbstractModelBuilder
                
                # Test callable
                x0 = [1.0, 2.0]
                nlp = builder(x0)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test calls[] == 1
                Test.@test nlp.meta.x0 == x0
                
                # Test with kwargs
                redirect_stdout(devnull) do
                    nlp2 = builder(x0; show_time=true)
                    Test.@test calls[] == 2
                end
            end
            
            Test.@testset "ExaModelBuilder" begin
                # Test construction
                calls = Ref(0)
                function test_exa_builder(::Type{T}, x; backend=nothing) where T
                    calls[] += 1
                    # Use correct ExaModels syntax (like in Rosenbrock)
                    m = ExaModels.ExaCore(T; backend=backend)
                    x_var = ExaModels.variable(m, length(x); start=x)
                    ExaModels.objective(m, sum(x_var[i]^2 for i=1:length(x)))
                    return ExaModels.ExaModel(m)
                end
                
                builder = Optimization.ExaModelBuilder(test_exa_builder)
                Test.@test builder isa Optimization.ExaModelBuilder
                Test.@test builder isa Optimization.AbstractModelBuilder
                
                # Test callable
                x0 = [1.0, 2.0]
                nlp = builder(Float64, x0)
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test calls[] == 1
                
                # Test with different base type
                nlp32 = builder(Float32, x0)
                Test.@test nlp32 isa ExaModels.ExaModel{Float32}
                Test.@test calls[] == 2
            end
            
            Test.@testset "ADNLPSolutionBuilder" begin
                # Test construction
                calls = Ref(0)
                function test_solution_builder(stats)
                    calls[] += 1
                    return (objective=stats.objective, status=stats.status)
                end
                
                builder = Optimization.ADNLPSolutionBuilder(test_solution_builder)
                Test.@test builder isa Optimization.ADNLPSolutionBuilder
                Test.@test builder isa Optimization.AbstractOCPSolutionBuilder
                
                # Test callable
                stats = MockExecutionStats(1.23, 10, 1e-6, :first_order)
                sol = builder(stats)
                Test.@test calls[] == 1
                Test.@test sol.objective ≈ 1.23
                Test.@test sol.status == :first_order
            end
            
            Test.@testset "ExaSolutionBuilder" begin
                # Test construction
                calls = Ref(0)
                function test_exa_solution_builder(stats)
                    calls[] += 1
                    return (objective=stats.objective, iterations=stats.iter)
                end
                
                builder = Optimization.ExaSolutionBuilder(test_exa_solution_builder)
                Test.@test builder isa Optimization.ExaSolutionBuilder
                Test.@test builder isa Optimization.AbstractOCPSolutionBuilder
                
                # Test callable
                stats = MockExecutionStats(2.34, 15, 1e-5, :acceptable)
                sol = builder(stats)
                Test.@test calls[] == 1
                Test.@test sol.objective ≈ 2.34
                Test.@test sol.iterations == 15
            end
        end

        # ====================================================================
        # UNIT TESTS - Contract Implementation
        # ====================================================================
        
        Test.@testset "Contract Implementation" begin
            # Create builders
            adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
            exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                m = ExaModels.ExaCore(T)
                x_var = ExaModels.variable(m, length(x); start=x)
                # Define objective using ExaModels syntax (like Rosenbrock)
                obj_func(v) = sum(v[i]^2 for i=1:length(x))
                ExaModels.objective(m, obj_func(x_var))
                ExaModels.ExaModel(m)
            end)
            adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (obj=s.objective,))
            exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (obj=s.objective,))
            
            # Create fake problem
            prob = FakeOptimizationProblem(
                adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
            )
            
            Test.@testset "get_adnlp_model_builder" begin
                builder = Optimization.get_adnlp_model_builder(prob)
                Test.@test builder === adnlp_builder
                Test.@test builder isa Optimization.ADNLPModelBuilder
            end
            
            Test.@testset "get_exa_model_builder" begin
                builder = Optimization.get_exa_model_builder(prob)
                Test.@test builder === exa_builder
                Test.@test builder isa Optimization.ExaModelBuilder
            end
            
            Test.@testset "get_adnlp_solution_builder" begin
                builder = Optimization.get_adnlp_solution_builder(prob)
                Test.@test builder === adnlp_sol_builder
                Test.@test builder isa Optimization.ADNLPSolutionBuilder
            end
            
            Test.@testset "get_exa_solution_builder" begin
                builder = Optimization.get_exa_solution_builder(prob)
                Test.@test builder === exa_sol_builder
                Test.@test builder isa Optimization.ExaSolutionBuilder
            end
        end

        # ====================================================================
        # UNIT TESTS - Building Functions
        # ====================================================================
        
        Test.@testset "Building Functions" begin
            # Setup
            adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
            exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                m = ExaModels.ExaCore(T)
                x_var = ExaModels.variable(m, length(x); start=x)
                # Define objective using ExaModels syntax (like Rosenbrock)
                obj_func(v) = sum(v[i]^2 for i=1:length(x))
                ExaModels.objective(m, obj_func(x_var))
                ExaModels.ExaModel(m)
            end)
            adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (obj=s.objective, status=s.status))
            exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (obj=s.objective, iter=s.iter))
            
            prob = FakeOptimizationProblem(
                adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
            )
            
            Test.@testset "build_model with ADNLP" begin
                modeler = FakeModeler(:adnlp)
                x0 = [1.0, 2.0]
                
                nlp = Optimization.build_model(prob, x0, modeler)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.x0 == x0
            end
            
            Test.@testset "build_model with Exa" begin
                modeler = FakeModeler(:exa)
                x0 = [1.0, 2.0]
                
                nlp = Optimization.build_model(prob, x0, modeler)
                Test.@test nlp isa ExaModels.ExaModel{Float64}
            end
            
            Test.@testset "build_solution with ADNLP" begin
                modeler = FakeModeler(:adnlp)
                stats = MockExecutionStats(1.23, 10, 1e-6, :first_order)
                
                sol = Optimization.build_solution(prob, stats, modeler)
                Test.@test sol.obj ≈ 1.23
                Test.@test sol.status == :first_order
            end
            
            Test.@testset "build_solution with Exa" begin
                modeler = FakeModeler(:exa)
                stats = MockExecutionStats(2.34, 15, 1e-5, :acceptable)
                
                sol = Optimization.build_solution(prob, stats, modeler)
                Test.@test sol.obj ≈ 2.34
                Test.@test sol.iter == 15
            end
        end

        # ====================================================================
        # UNIT TESTS - Solver Info Extraction
        # ====================================================================
        
        Test.@testset "Solver Info Extraction" begin
            Test.@testset "extract_solver_infos - first_order status" begin
                stats = MockExecutionStats(1.23, 15, 1.0e-6, :first_order)
                nlp = ADNLPModels.ADNLPModel(x -> x[1]^2, [1.0])
                
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                
                Test.@test obj ≈ 1.23
                Test.@test iter == 15
                Test.@test viol ≈ 1.0e-6
                Test.@test msg == "Ipopt/generic"
                Test.@test status == :first_order
                Test.@test success == true
            end
            
            Test.@testset "extract_solver_infos - acceptable status" begin
                stats = MockExecutionStats(2.34, 20, 1.0e-5, :acceptable)
                nlp = ADNLPModels.ADNLPModel(x -> x[1]^2, [1.0])
                
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                
                Test.@test obj ≈ 2.34
                Test.@test iter == 20
                Test.@test viol ≈ 1.0e-5
                Test.@test msg == "Ipopt/generic"
                Test.@test status == :acceptable
                Test.@test success == true
            end
            
            Test.@testset "extract_solver_infos - failure status" begin
                stats = MockExecutionStats(3.45, 5, 1.0e-3, :max_iter)
                nlp = ADNLPModels.ADNLPModel(x -> x[1]^2, [1.0])
                
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                
                Test.@test obj ≈ 3.45
                Test.@test iter == 5
                Test.@test viol ≈ 1.0e-3
                Test.@test msg == "Ipopt/generic"
                Test.@test status == :max_iter
                Test.@test success == false
            end
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Integration Tests" begin
            Test.@testset "Complete workflow - ADNLP" begin
                # Create builders
                adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
                exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                    c = ExaModels.ExaCore(T)
                    ExaModels.variable(c, 1 <= x[i=1:length(x)] <= 3, start=x[i])
                    ExaModels.objective(c, sum(x[i]^2 for i=1:length(x)))
                    ExaModels.ExaModel(c)
                end)
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective, status=s.status))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective, iter=s.iter))
                
                # Create problem
                prob = FakeOptimizationProblem(
                    adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
                )
                
                # Build model
                modeler = FakeModeler(:adnlp)
                x0 = [1.0, 2.0]
                nlp = Optimization.build_model(prob, x0, modeler)
                
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0
                
                # Build solution
                stats = MockExecutionStats(5.0, 10, 1e-6, :first_order)
                sol = Optimization.build_solution(prob, stats, modeler)
                
                Test.@test sol.objective ≈ 5.0
                Test.@test sol.status == :first_order
                
                # Extract solver info
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
                Test.@test obj ≈ 5.0
                Test.@test success == true
            end
            
            Test.@testset "Complete workflow - Exa" begin
                # Create builders
                adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
                exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                    n = length(x)
                    m = ExaModels.ExaCore(T)
                    x_var = ExaModels.variable(m, n; start=x)
                    # Define objective directly (like Rosenbrock does with F(x))
                    ExaModels.objective(m, sum(x_var[i]^2 for i=1:n))
                    ExaModels.ExaModel(m)
                end)
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective, status=s.status))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective, iter=s.iter))
                
                # Create problem
                prob = FakeOptimizationProblem(
                    adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
                )
                
                # Build model
                modeler = FakeModeler(:exa)
                x0 = [1.0, 2.0]
                nlp = Optimization.build_model(prob, x0, modeler)
                
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0
                
                # Build solution
                stats = MockExecutionStats(5.0, 15, 1e-5, :acceptable)
                sol = Optimization.build_solution(prob, stats, modeler)
                
                Test.@test sol.objective ≈ 5.0
                Test.@test sol.iter == 15
            end
        end
    end
end

end # module

test_optimization() = TestOptimization.test_optimization()

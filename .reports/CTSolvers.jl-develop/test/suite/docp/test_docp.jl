module TestDOCP

import Test
import CTModels
import CTSolvers.DOCP
import CTBase
import NLPModels
import SolverCore
import ADNLPModels
import ExaModels
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Import from Optimization module to avoid name conflicts
import CTSolvers.Optimization
import CTSolvers.Modelers

# ============================================================================
# FAKE TYPES FOR TESTING (TOP-LEVEL)
# ============================================================================

"""
Fake OCP for testing DOCP construction.
"""
struct FakeOCP <: CTModels.AbstractModel
    name::String
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

"""
Fake modeler for testing building functions.
Subtypes Modelers.AbstractNLPModeler to satisfy the type annotation on nlp_model/ocp_solution.
"""
struct FakeModelerDOCP <: Modelers.AbstractNLPModeler
    backend::Symbol
end

function (modeler::FakeModelerDOCP)(prob::DOCP.DiscretizedModel, initial_guess)
    if modeler.backend == :adnlp
        builder = Optimization.get_adnlp_model_builder(prob)
        return builder(initial_guess)
    else
        builder = Optimization.get_exa_model_builder(prob)
        return builder(Float64, initial_guess)
    end
end

function (modeler::FakeModelerDOCP)(prob::DOCP.DiscretizedModel, nlp_solution::SolverCore.AbstractExecutionStats)
    if modeler.backend == :adnlp
        builder = Optimization.get_adnlp_solution_builder(prob)
        return builder(nlp_solution)
    else
        builder = Optimization.get_exa_solution_builder(prob)
        return builder(nlp_solution)
    end
end

# ============================================================================
# TEST FUNCTION
# ============================================================================

function test_docp()
    Test.@testset "DOCP Module" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - DOCP.DiscretizedModel Type
        # ====================================================================
        
        Test.@testset "DOCP.DiscretizedModel Type" begin
            Test.@testset "Construction" begin
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
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective,))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective,))
                
                # Create fake OCP
                ocp = FakeOCP("test_ocp")
                
                # Create DOCP
                docp = DOCP.DiscretizedModel(
                    ocp,
                    adnlp_builder,
                    exa_builder,
                    adnlp_sol_builder,
                    exa_sol_builder
                )
                
                Test.@test docp isa DOCP.DiscretizedModel
                Test.@test docp isa Optimization.AbstractOptimizationProblem
                Test.@test docp.optimal_control_problem === ocp
                Test.@test docp.adnlp_model_builder === adnlp_builder
                Test.@test docp.exa_model_builder === exa_builder
                Test.@test docp.adnlp_solution_builder === adnlp_sol_builder
                Test.@test docp.exa_solution_builder === exa_sol_builder
            end
            
            Test.@testset "Type parameters" begin
                ocp = FakeOCP("test")
                adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
                exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                    m = ExaModels.ExaCore(T)
                    x_var = ExaModels.variable(m, length(x); start=x)
                    # Define objective using ExaModels syntax (like Rosenbrock)
                    obj_func(v) = sum(v[i]^2 for i=1:length(x))
                    ExaModels.objective(m, obj_func(x_var))
                    ExaModels.ExaModel(m)
                end)
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective,))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective,))
                
                docp = DOCP.DiscretizedModel(
                    ocp, adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
                )
                
                Test.@test typeof(docp.optimal_control_problem) == FakeOCP
                Test.@test typeof(docp.adnlp_model_builder) <: Optimization.ADNLPModelBuilder
                Test.@test typeof(docp.exa_model_builder) <: Optimization.ExaModelBuilder
                Test.@test typeof(docp.adnlp_solution_builder) <: Optimization.ADNLPSolutionBuilder
                Test.@test typeof(docp.exa_solution_builder) <: Optimization.ExaSolutionBuilder
            end
        end

        # ====================================================================
        # UNIT TESTS - Contract Implementation
        # ====================================================================
        
        Test.@testset "Contract Implementation" begin
            # Setup
            ocp = FakeOCP("test_ocp")
            adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
            exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                n = length(x)
                m = ExaModels.ExaCore(T)
                x_var = ExaModels.variable(m, n; start=x)
                ExaModels.objective(m, sum(x_var[i]^2 for i=1:n))
                ExaModels.ExaModel(m)
            end)
            adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective,))
            exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective,))
            
            docp = DOCP.DiscretizedModel(
                ocp, adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
            )
            
            Test.@testset "Optimization.get_adnlp_model_builder" begin
                builder = Optimization.get_adnlp_model_builder(docp)
                Test.@test builder === adnlp_builder
                Test.@test builder isa Optimization.ADNLPModelBuilder
            end
            
            Test.@testset "Optimization.get_exa_model_builder" begin
                builder = Optimization.get_exa_model_builder(docp)
                Test.@test builder === exa_builder
                Test.@test builder isa Optimization.ExaModelBuilder
            end
            
            Test.@testset "Optimization.get_adnlp_solution_builder" begin
                builder = Optimization.get_adnlp_solution_builder(docp)
                Test.@test builder === adnlp_sol_builder
                Test.@test builder isa Optimization.ADNLPSolutionBuilder
            end
            
            Test.@testset "Optimization.get_exa_solution_builder" begin
                builder = Optimization.get_exa_solution_builder(docp)
                Test.@test builder === exa_sol_builder
                Test.@test builder isa Optimization.ExaSolutionBuilder
            end
        end

        # ====================================================================
        # UNIT TESTS - Accessors
        # ====================================================================
        
        Test.@testset "Accessors" begin
            Test.@testset "ocp_model" begin
                ocp = FakeOCP("my_ocp")
                adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
                exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                    m = ExaModels.ExaCore(T)
                    x_var = ExaModels.variable(m, length(x); start=x)
                    # Define objective using ExaModels syntax (like Rosenbrock)
                    obj_func(v) = sum(v[i]^2 for i=1:length(x))
                    ExaModels.objective(m, obj_func(x_var))
                    ExaModels.ExaModel(m)
                end)
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective,))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective,))
                
                docp = DOCP.DiscretizedModel(
                    ocp, adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
                )
                
                retrieved_ocp = DOCP.ocp_model(docp)
                Test.@test retrieved_ocp === ocp
                Test.@test retrieved_ocp.name == "my_ocp"
            end
        end

        # ====================================================================
        # UNIT TESTS - Building Functions
        # ====================================================================
        
        Test.@testset "Building Functions" begin
            # Setup
            ocp = FakeOCP("test_ocp")
            adnlp_builder = Optimization.ADNLPModelBuilder(x -> ADNLPModels.ADNLPModel(z -> sum(z.^2), x))
            exa_builder = Optimization.ExaModelBuilder((T, x) -> begin
                n = length(x)
                m = ExaModels.ExaCore(T)
                x_var = ExaModels.variable(m, n; start=x)
                ExaModels.objective(m, sum(x_var[i]^2 for i=1:n))
                ExaModels.ExaModel(m)
            end)
            adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective, status=s.status))
            exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective, iter=s.iter))
            
            docp = DOCP.DiscretizedModel(
                ocp, adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
            )
            
            Test.@testset "nlp_model with ADNLP" begin
                modeler = FakeModelerDOCP(:adnlp)
                x0 = [1.0, 2.0]
                
                nlp = DOCP.nlp_model(docp, x0, modeler)
                Test.@test nlp isa NLPModels.AbstractNLPModel
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.x0 == x0
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0
            end
            
            Test.@testset "nlp_model with Exa" begin
                modeler = FakeModelerDOCP(:exa)
                x0 = [1.0, 2.0]
                
                nlp = DOCP.nlp_model(docp, x0, modeler)
                Test.@test nlp isa NLPModels.AbstractNLPModel
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0
            end
            
            Test.@testset "ocp_solution with ADNLP" begin
                modeler = FakeModelerDOCP(:adnlp)
                stats = MockExecutionStats(1.23, 10, 1e-6, :first_order)
                
                sol = DOCP.ocp_solution(docp, stats, modeler)
                Test.@test sol.objective ≈ 1.23
                Test.@test sol.status == :first_order
            end
            
            Test.@testset "ocp_solution with Exa" begin
                modeler = FakeModelerDOCP(:exa)
                stats = MockExecutionStats(2.34, 15, 1e-5, :acceptable)
                
                sol = DOCP.ocp_solution(docp, stats, modeler)
                Test.@test sol.objective ≈ 2.34
                Test.@test sol.iter == 15
            end
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Integration Tests" begin
            Test.@testset "Complete DOCP workflow - ADNLP" begin
                # Create OCP
                ocp = FakeOCP("integration_test_ocp")
                
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
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (
                    objective=s.objective,
                    iterations=s.iter,
                    status=s.status,
                    success=(s.status == :first_order || s.status == :acceptable)
                ))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective, iter=s.iter))
                
                # Create DOCP
                docp = DOCP.DiscretizedModel(
                    ocp, adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
                )
                
                # Verify OCP retrieval
                Test.@test DOCP.ocp_model(docp) === ocp
                
                # Build NLP model
                modeler = FakeModelerDOCP(:adnlp)
                x0 = [1.0, 2.0, 3.0]
                nlp = DOCP.nlp_model(docp, x0, modeler)
                
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test NLPModels.obj(nlp, x0) ≈ 14.0
                
                # Build solution
                stats = MockExecutionStats(14.0, 20, 1e-8, :first_order)
                sol = DOCP.ocp_solution(docp, stats, modeler)
                
                Test.@test sol.objective ≈ 14.0
                Test.@test sol.iterations == 20
                Test.@test sol.status == :first_order
                Test.@test sol.success == true
            end
            
            Test.@testset "Complete DOCP workflow - Exa" begin
                # Create OCP
                ocp = FakeOCP("integration_test_exa")
                
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
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective,))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (
                    objective=s.objective,
                    iterations=s.iter,
                    status=s.status
                ))
                
                # Create DOCP
                docp = DOCP.DiscretizedModel(
                    ocp, adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
                )
                
                # Verify OCP retrieval
                Test.@test DOCP.ocp_model(docp) === ocp
                
                # Build NLP model
                modeler = FakeModelerDOCP(:exa)
                x0 = [1.0, 2.0, 3.0]
                nlp = DOCP.nlp_model(docp, x0, modeler)
                
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test NLPModels.obj(nlp, x0) ≈ 14.0
                
                # Build solution
                stats = MockExecutionStats(14.0, 25, 1e-7, :acceptable)
                sol = DOCP.ocp_solution(docp, stats, modeler)
                
                Test.@test sol.objective ≈ 14.0
                Test.@test sol.iterations == 25
                Test.@test sol.status == :acceptable
            end
            
            Test.@testset "DOCP with different base types" begin
                ocp = FakeOCP("base_type_test")
                
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
                adnlp_sol_builder = Optimization.ADNLPSolutionBuilder(s -> (objective=s.objective,))
                exa_sol_builder = Optimization.ExaSolutionBuilder(s -> (objective=s.objective,))
                
                docp = DOCP.DiscretizedModel(
                    ocp, adnlp_builder, exa_builder, adnlp_sol_builder, exa_sol_builder
                )
                
                # Test with Float64
                builder64 = Optimization.get_exa_model_builder(docp)
                x0_64 = [1.0, 2.0]
                nlp64 = builder64(Float64, x0_64)
                Test.@test nlp64 isa ExaModels.ExaModel{Float64}
                
                # Test with Float32
                builder32 = Optimization.get_exa_model_builder(docp)
                x0_32 = Float32[1.0, 2.0]
                nlp32 = builder32(Float32, x0_32)
                Test.@test nlp32 isa ExaModels.ExaModel{Float32}
            end
        end
    end
end

end # module

test_docp() = TestDOCP.test_docp()

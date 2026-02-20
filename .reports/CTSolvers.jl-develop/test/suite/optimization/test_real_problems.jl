module TestRealProblems

import Test
import CTSolvers
import CTBase
import NLPModels
import SolverCore
import ADNLPModels
import ExaModels

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Import from Optimization module
import CTSolvers.Optimization

# ============================================================================
# TEST FUNCTION
# ============================================================================

function test_real_problems()
    Test.@testset "Optimization with Real Problems" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # TESTS WITH ROSENBROCK PROBLEM
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem" begin
            # Load Rosenbrock problem from TestProblems module
            ros = TestProblems.Rosenbrock()
            
            Test.@testset "ADNLPModelBuilder with Rosenbrock" begin
                # Get the builder from the problem
                builder = Optimization.get_adnlp_model_builder(ros.prob)
                Test.@test builder isa Optimization.ADNLPModelBuilder
                
                # Build the NLP model
                nlp = builder(ros.init; show_time=false)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.x0 == ros.init
                Test.@test nlp.meta.minimize == true
                
                # Test objective evaluation
                obj_val = NLPModels.obj(nlp, ros.init)
                expected_obj = TestProblems.rosenbrock_objective(ros.init)
                Test.@test obj_val ≈ expected_obj
                
                # Test constraint evaluation
                cons_val = NLPModels.cons(nlp, ros.init)
                expected_cons = TestProblems.rosenbrock_constraint(ros.init)
                Test.@test cons_val[1] ≈ expected_cons
            end
            
            Test.@testset "ExaModelBuilder with Rosenbrock" begin
                # Get the builder from the problem
                builder = Optimization.get_exa_model_builder(ros.prob)
                Test.@test builder isa Optimization.ExaModelBuilder
                
                # Build the NLP model with Float64
                nlp64 = builder(Float64, ros.init)
                Test.@test nlp64 isa ExaModels.ExaModel{Float64}
                Test.@test nlp64.meta.x0 == Float64.(ros.init)
                Test.@test nlp64.meta.minimize == true
                
                # Test objective evaluation
                obj_val = NLPModels.obj(nlp64, nlp64.meta.x0)
                expected_obj = TestProblems.rosenbrock_objective(Float64.(ros.init))
                Test.@test obj_val ≈ expected_obj
                
                # Test constraint evaluation
                cons_val = NLPModels.cons(nlp64, nlp64.meta.x0)
                expected_cons = TestProblems.rosenbrock_constraint(Float64.(ros.init))
                Test.@test cons_val[1] ≈ expected_cons
            end
            
            Test.@testset "ExaModelBuilder with Rosenbrock - Float32" begin
                # Get the builder from the problem
                builder = Optimization.get_exa_model_builder(ros.prob)
                
                # Build the NLP model with Float32
                nlp32 = builder(Float32, ros.init)
                Test.@test nlp32 isa ExaModels.ExaModel{Float32}
                Test.@test nlp32.meta.x0 == Float32.(ros.init)
                Test.@test eltype(nlp32.meta.x0) == Float32
                Test.@test nlp32.meta.minimize == true
                
                # Test objective evaluation
                obj_val = NLPModels.obj(nlp32, nlp32.meta.x0)
                expected_obj = TestProblems.rosenbrock_objective(Float32.(ros.init))
                Test.@test obj_val ≈ expected_obj
                
                # Test constraint evaluation
                cons_val = NLPModels.cons(nlp32, nlp32.meta.x0)
                expected_cons = TestProblems.rosenbrock_constraint(Float32.(ros.init))
                Test.@test cons_val[1] ≈ expected_cons
            end
        end

        # ====================================================================
        # INTEGRATION TESTS WITH REAL PROBLEMS
        # ====================================================================
        
        Test.@testset "Integration with Real Problems" begin
            Test.@testset "Complete workflow - Rosenbrock ADNLP" begin
                ros = TestProblems.Rosenbrock()
                
                # Get builder
                builder = Optimization.get_adnlp_model_builder(ros.prob)
                
                # Build model
                nlp = builder(ros.init; show_time=false)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                
                # Verify problem properties
                Test.@test nlp.meta.nvar == 2
                Test.@test nlp.meta.ncon == 1
                Test.@test nlp.meta.minimize == true
                
                # Verify at initial point
                Test.@test NLPModels.obj(nlp, ros.init) ≈ TestProblems.rosenbrock_objective(ros.init)
                
                # Verify at solution
                Test.@test NLPModels.obj(nlp, ros.sol) ≈ TestProblems.rosenbrock_objective(ros.sol)
                Test.@test TestProblems.rosenbrock_objective(ros.sol) < TestProblems.rosenbrock_objective(ros.init)
            end
            
            Test.@testset "Complete workflow - Rosenbrock Exa" begin
                ros = TestProblems.Rosenbrock()
                
                # Get builder
                builder = Optimization.get_exa_model_builder(ros.prob)
                
                # Build model
                nlp = builder(Float64, ros.init)
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                
                # Verify problem properties
                Test.@test nlp.meta.nvar == 2
                Test.@test nlp.meta.ncon == 1
                Test.@test nlp.meta.minimize == true
                
                # Verify at initial point
                Test.@test NLPModels.obj(nlp, Float64.(ros.init)) ≈ TestProblems.rosenbrock_objective(ros.init)
                
                # Verify at solution
                Test.@test NLPModels.obj(nlp, Float64.(ros.sol)) ≈ TestProblems.rosenbrock_objective(ros.sol)
            end
        end
    end
end

end # module

test_real_problems() = TestRealProblems.test_real_problems()

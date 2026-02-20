module TestCommonSolveAPI

import Test
import CTBase.Exceptions
import CTSolvers.Solvers
import NLPModels
import SolverCore
import ADNLPModels
import CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# FAKE TYPES FOR TESTING (TOP-LEVEL)
# ============================================================================

"""
Fake solver that counts calls for testing CommonSolve API.
"""
struct FakeSolver <: Solvers.AbstractNLPSolver
    calls::Base.RefValue{Int}
    display_flag::Base.RefValue{Union{Nothing, Bool}}
end

FakeSolver() = FakeSolver(Ref(0), Ref{Union{Nothing, Bool}}(nothing))

"""
Implement callable interface for FakeSolver.
"""
function (s::FakeSolver)(nlp::NLPModels.AbstractNLPModel; display::Bool=true)
    s.calls[] += 1
    s.display_flag[] = display
    # Return a valid GenericExecutionStats using the NLP model
    return SolverCore.GenericExecutionStats(nlp; status=:first_order)
end

# ============================================================================
# TEST FUNCTION
# ============================================================================

"""
    test_common_solve_api()

Tests for CommonSolve API integration with solvers.

🧪 **Applying Testing Rule**: Contract-First Testing + Isolation

Tests the CommonSolve.solve() interface with fake solvers to verify
proper routing and display flag handling.
"""
function test_common_solve_api()
    Test.@testset "CommonSolve API" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - solve(nlp, solver)
        # ====================================================================
        
        Test.@testset "solve(nlp, solver)" begin
            # Create a simple NLP problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Create fake solver
            solver = FakeSolver()
            
            # Test solve with display=true (default)
            stats = CommonSolve.solve(nlp, solver; display=true)
            
            Test.@test stats isa SolverCore.AbstractExecutionStats
            Test.@test stats.status == :first_order
            Test.@test solver.calls[] == 1
            Test.@test solver.display_flag[] === true
        end
        
        # ====================================================================
        # UNIT TESTS - solve(nlp, solver) with display=false
        # ====================================================================
        
        Test.@testset "solve(nlp, solver) with display=false" begin
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            solver = FakeSolver()
            
            stats = CommonSolve.solve(nlp, solver; display=false)
            
            Test.@test stats isa SolverCore.AbstractExecutionStats
            Test.@test solver.calls[] == 1
            Test.@test solver.display_flag[] === false
        end
        
        # ====================================================================
        # UNIT TESTS - Multiple calls
        # ====================================================================
        
        Test.@testset "Multiple solve calls" begin
            nlp1 = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0])
            nlp2 = ADNLPModels.ADNLPModel(x -> sum(x.^4), [2.0, 3.0])
            
            solver = FakeSolver()
            
            # First call
            stats1 = CommonSolve.solve(nlp1, solver; display=true)
            Test.@test solver.calls[] == 1
            
            # Second call
            stats2 = CommonSolve.solve(nlp2, solver; display=false)
            Test.@test solver.calls[] == 2
            
            # Both should return stats
            Test.@test stats1 isa SolverCore.AbstractExecutionStats
            Test.@test stats2 isa SolverCore.AbstractExecutionStats
        end
        
        # ====================================================================
        # UNIT TESTS - Solver callable is invoked
        # ====================================================================
        
        Test.@testset "Solver callable invocation" begin
            nlp = ADNLPModels.ADNLPModel(x -> x[1]^2 + x[2]^2, [1.0, 1.0])
            solver = FakeSolver()
            
            # Verify initial state
            Test.@test solver.calls[] == 0
            Test.@test solver.display_flag[] === nothing
            
            # Call solve
            CommonSolve.solve(nlp, solver; display=true)
            
            # Verify solver was called
            Test.@test solver.calls[] == 1
            Test.@test solver.display_flag[] === true
        end
        
        # ====================================================================
        # UNIT TESTS - Different NLP types
        # ====================================================================
        
        Test.@testset "Different NLP types" begin
            solver = FakeSolver()
            
            # Test with different objective functions
            nlp_quadratic = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0, 3.0])
            nlp_linear = ADNLPModels.ADNLPModel(x -> sum(x), [1.0, 2.0])
            nlp_rosenbrock = ADNLPModels.ADNLPModel(
                x -> (1 - x[1])^2 + 100*(x[2] - x[1]^2)^2,
                [0.0, 0.0]
            )
            
            # All should work with CommonSolve
            Test.@test_nowarn CommonSolve.solve(nlp_quadratic, solver; display=false)
            Test.@test_nowarn CommonSolve.solve(nlp_linear, solver; display=false)
            Test.@test_nowarn CommonSolve.solve(nlp_rosenbrock, solver; display=false)
            
            # Verify all were called
            Test.@test solver.calls[] == 3
        end
    end
end

end # module

test_common_solve_api() = TestCommonSolveAPI.test_common_solve_api()

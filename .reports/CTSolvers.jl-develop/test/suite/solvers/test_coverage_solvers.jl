module TestCoverageSolvers

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options
import NLPModels
import SolverCore
import ADNLPModels
import CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake types for testing (must be at module top-level)
# ============================================================================

struct CovUnimplementedSolver <: Solvers.AbstractNLPSolver
    options::Strategies.StrategyOptions
end

struct CovCallableSolver <: Solvers.AbstractNLPSolver
    options::Strategies.StrategyOptions
end

# Implement callable for a non-NLPModel argument (covers generic solve overload)
function (s::CovCallableSolver)(nlp; display::Bool=true)
    return (status=:ok, display=display)
end

function test_coverage_solvers()
    Test.@testset "Coverage: Solvers" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - AbstractNLPSolver callable (abstract_solver.jl)
        # ====================================================================

        Test.@testset "AbstractNLPSolver callable - NotImplemented" begin
            opts = Strategies.StrategyOptions()
            solver = CovUnimplementedSolver(opts)
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0])

            Test.@test_throws Exceptions.NotImplemented solver(nlp)
            Test.@test_throws Exceptions.NotImplemented solver(nlp; display=false)
        end

        # ====================================================================
        # UNIT TESTS - Solvers.Knitro (knitro_solver.jl)
        # ====================================================================

        Test.@testset "Solvers.Knitro" begin
            # Type hierarchy
            Test.@test Solvers.Knitro <: Solvers.AbstractNLPSolver
            Test.@test Solvers.Knitro <: Strategies.AbstractStrategy
            Test.@test !isabstracttype(Solvers.Knitro)

            # id() contract
            Test.@test Strategies.id(Solvers.Knitro) === :knitro

            # Tag type
            Test.@test Solvers.KnitroTag <: Solvers.AbstractTag
            Test.@test !isabstracttype(Solvers.KnitroTag)
            Test.@test_nowarn Solvers.KnitroTag()

            # Struct fields
            Test.@test :options in fieldnames(Solvers.Knitro)
            Test.@test length(fieldnames(Solvers.Knitro)) == 1

            # Constructor throws ExtensionError (NLPModelsKnitro not loaded)
            Test.@test_throws Exceptions.ExtensionError Solvers.Knitro()

            # build_knitro_solver stub throws ExtensionError
            Test.@test_throws Exceptions.ExtensionError Solvers.build_knitro_solver(Solvers.KnitroTag())

            # Verify error message content
            err = nothing
            try
                Solvers.build_knitro_solver(Solvers.KnitroTag())
            catch e
                err = e
            end
            Test.@test err isa Exceptions.ExtensionError
            err_str = string(err)
            Test.@test occursin("Knitro", err_str)
            Test.@test occursin("NLPModelsKnitro", err_str)
        end

        # ====================================================================
        # UNIT TESTS - Solvers.Ipopt stub (ipopt_solver.jl)
        # ====================================================================

        Test.@testset "Solvers.Ipopt - ExtensionError on construct" begin
            # Without NLPModelsIpopt loaded, constructor should throw
            # (NLPModelsIpopt IS loaded in test env, so this tests the stub path)
            # We test the stub directly with a non-IpoptTag
            Test.@test_throws Exceptions.ExtensionError Solvers.build_ipopt_solver(Solvers.KnitroTag())
        end

        # ====================================================================
        # UNIT TESTS - Solvers.MadNLP stub (madnlp_solver.jl)
        # ====================================================================

        Test.@testset "Solvers.MadNLP - stub with wrong tag" begin
            Test.@test_throws Exceptions.ExtensionError Solvers.build_madnlp_solver(Solvers.KnitroTag())
        end

        # ====================================================================
        # UNIT TESTS - Solvers.MadNCL stub (madncl_solver.jl)
        # ====================================================================

        Test.@testset "Solvers.MadNCL - stub with wrong tag" begin
            Test.@test_throws Exceptions.ExtensionError Solvers.build_madncl_solver(Solvers.KnitroTag())
        end

        # ====================================================================
        # UNIT TESTS - __display() helper (common_solve_api.jl)
        # ====================================================================

        Test.@testset "__display() default" begin
            Test.@test Solvers.__display() === true
        end

        # ====================================================================
        # UNIT TESTS - Strategies.id() direct calls for all solvers
        # ====================================================================

        Test.@testset "Strategies.id() direct calls" begin
            Test.@test Strategies.id(Solvers.Ipopt) === :ipopt
            Test.@test Strategies.id(Solvers.MadNLP) === :madnlp
            Test.@test Strategies.id(Solvers.MadNCL) === :madncl
            Test.@test Strategies.id(Solvers.Knitro) === :knitro
        end

        # ====================================================================
        # UNIT TESTS - CommonSolve.solve(nlp, solver) generic overload
        # (common_solve_api.jl:112-117)
        # ====================================================================

        Test.@testset "CommonSolve.solve(nlp, solver) generic" begin
            opts = Strategies.StrategyOptions()
            solver = CovCallableSolver(opts)

            # Use a plain NamedTuple as "nlp" to hit the generic overload
            # (not AbstractNLPModel)
            fake_nlp = (name="fake",)
            result = CommonSolve.solve(fake_nlp, solver; display=false)
            Test.@test result.status === :ok
            Test.@test result.display === false

            result2 = CommonSolve.solve(fake_nlp, solver; display=true)
            Test.@test result2.display === true
        end
    end
end

end # module

test_coverage_solvers() = TestCoverageSolvers.test_coverage_solvers()

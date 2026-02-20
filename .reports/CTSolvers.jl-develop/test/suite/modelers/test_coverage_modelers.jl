module TestCoverageModelers

import Test
import CTBase.Exceptions
import CTSolvers.Modelers
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Optimization
import SolverCore

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake types for testing (must be at module top-level)
# ============================================================================

struct CovFakeModeler <: Modelers.AbstractNLPModeler
    options::Strategies.StrategyOptions
end

struct CovFakeProblem <: Optimization.AbstractOptimizationProblem end

struct CovFakeStats <: SolverCore.AbstractExecutionStats end

function test_coverage_modelers()
    Test.@testset "Coverage: Modelers" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - AbstractNLPModeler (abstract_modeler.jl)
        # ====================================================================

        Test.@testset "AbstractNLPModeler - NotImplemented errors" begin
            opts = Strategies.StrategyOptions()
            modeler = CovFakeModeler(opts)
            prob = CovFakeProblem()
            stats = CovFakeStats()

            # Model building callable - NotImplemented
            Test.@test_throws Exceptions.NotImplemented modeler(prob, [1.0, 2.0])

            # Solution building callable - NotImplemented
            Test.@test_throws Exceptions.NotImplemented modeler(prob, stats)
        end

        Test.@testset "AbstractNLPModeler - type hierarchy" begin
            Test.@test Modelers.AbstractNLPModeler <: Strategies.AbstractStrategy
            Test.@test isabstracttype(Modelers.AbstractNLPModeler)
        end

        # ====================================================================
        # UNIT TESTS - Modelers.ADNLP defaults (adnlp_modeler.jl)
        # ====================================================================

        Test.@testset "Modelers.ADNLP - default helpers" begin
            Test.@test Modelers.__adnlp_model_backend() == :optimized
        end

        # ====================================================================
        # UNIT TESTS - Modelers.Exa defaults (exa_modeler.jl)
        # ====================================================================

        Test.@testset "Modelers.Exa - default helpers" begin
            Test.@test Modelers.__exa_model_base_type() == Float64
            Test.@test Modelers.__exa_model_backend() === nothing
        end

        # ====================================================================
        # UNIT TESTS - Modelers.Exa invalid base_type
        # ====================================================================

        Test.@testset "Modelers.Exa - invalid base_type" begin
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Modelers.Exa(base_type=Int)
            end
        end

        # ====================================================================
        # UNIT TESTS - Modelers.ADNLP invalid unknown option (strict mode)
        # ====================================================================

        Test.@testset "Modelers.ADNLP - unknown option strict mode" begin
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(unknown_opt=42)
            end
        end

        Test.@testset "Modelers.Exa - unknown option strict mode" begin
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Modelers.Exa(unknown_opt=42)
            end
        end

        # ====================================================================
        # UNIT TESTS - Strategies.id() direct calls (coverage for id lines)
        # ====================================================================

        Test.@testset "Modelers.ADNLP - Strategies.id() direct" begin
            Test.@test Strategies.id(Modelers.ADNLP) === :adnlp
        end

        Test.@testset "Modelers.Exa - Strategies.id() direct" begin
            Test.@test Strategies.id(Modelers.Exa) === :exa
        end
    end
end

end # module

test_coverage_modelers() = TestCoverageModelers.test_coverage_modelers()

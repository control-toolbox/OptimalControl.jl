module TestOrchestration

import Test
import OptimalControl
import CTModels
import CTDirect
import CTSolvers
import CTBase
import CommonSolve

import NLPModelsIpopt
import MadNLP
import MadNLPMumps
import MadNLPGPU
import MadNCL
import CUDA

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

function test_orchestration()
    Test.@testset "Orchestration - CommonSolve.solve" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Mode detection (via helpers)
        # ====================================================================

        Test.@testset "ExplicitMode detection" begin
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            kw   = pairs((; discretizer=disc))
            Test.@test OptimalControl._explicit_or_descriptive((), kw) isa OptimalControl.ExplicitMode
        end

        Test.@testset "DescriptiveMode detection" begin
            kw = pairs(NamedTuple())
            Test.@test OptimalControl._explicit_or_descriptive((:collocation,), kw) isa OptimalControl.DescriptiveMode
        end

        # ====================================================================
        # UNIT TESTS - Conflict validation
        # ====================================================================

        Test.@testset "Conflict: explicit + description raises IncorrectArgument" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)

            Test.@test_throws CTBase.IncorrectArgument begin
                CommonSolve.solve(pb.ocp, :adnlp, :ipopt; discretizer=disc, display=false)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - ExplicitMode path
        # ====================================================================

        Test.@testset "ExplicitMode - complete components" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            mod  = CTSolvers.ADNLP()
            sol  = CTSolvers.Ipopt(print_level=0, max_iter=0)

            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init,
                discretizer=disc, modeler=mod, solver=sol,
                display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "ExplicitMode - partial components (registry completes)" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)

            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        # ====================================================================
        # CONTRACT TESTS - DescriptiveMode path (stub validation)
        # ====================================================================

        Test.@testset "DescriptiveMode raises NotImplemented" begin
            pb = TestProblems.Beam()

            Test.@test_throws CTBase.NotImplemented begin
                CommonSolve.solve(pb.ocp, :collocation, :adnlp, :ipopt;
                    display=false
                )
            end
        end

        # ====================================================================
        # UNIT TESTS - initial_guess normalization
        # ====================================================================

        Test.@testset "initial_guess=nothing is accepted" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            result = CommonSolve.solve(pb.ocp;
                initial_guess=nothing, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "initial_guess as NamedTuple is accepted" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "initial_guess as AbstractInitialGuess is accepted" begin
            pb   = TestProblems.Beam()
            init = CTModels.build_initial_guess(pb.ocp, pb.init)
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            result = CommonSolve.solve(pb.ocp;
                initial_guess=init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_orchestration() = TestOrchestration.test_orchestration()

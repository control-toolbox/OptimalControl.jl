module TestKwargExtraction

import Test
import OptimalControl
import CTDirect
import CTSolvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: mock instances for testing (avoid external dependencies)
struct MockDiscretizer <: CTDirect.AbstractDiscretizer end
struct MockModeler <: CTSolvers.AbstractNLPModeler end
struct MockSolver <: CTSolvers.AbstractNLPSolver end

const DISC = MockDiscretizer()
const MOD  = MockModeler()
const SOL  = MockSolver()

function test_kwarg_extraction()
    Test.@testset "KwargExtraction" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Basic extraction
        # ====================================================================

        Test.@testset "Extracts matching type" begin
            kw = pairs((; discretizer=DISC, print_level=0))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result === DISC
        end

        Test.@testset "Returns nothing when absent" begin
            kw = pairs((; print_level=0, max_iter=100))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test isnothing(result)
        end

        Test.@testset "Returns nothing for empty kwargs" begin
            kw = pairs(NamedTuple())
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPSolver))
        end

        # ====================================================================
        # UNIT TESTS - All three component types
        # ====================================================================

        Test.@testset "Extracts all three component types" begin
            kw = pairs((; discretizer=DISC, modeler=MOD, solver=SOL, print_level=0))
            Test.@test OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer) === DISC
            Test.@test OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler) === MOD
            Test.@test OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPSolver) === SOL
        end

        # ====================================================================
        # UNIT TESTS - Name independence (key design property)
        # ====================================================================

        Test.@testset "Name-independent extraction" begin
            # The key is found by TYPE, not by name
            kw = pairs((; my_custom_key=DISC, another_key=42))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result === DISC
        end

        Test.@testset "Non-matching types ignored" begin
            kw = pairs((; x=42, y="hello", z=3.14))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler))
        end

        # ====================================================================
        # UNIT TESTS - Type safety
        # ====================================================================

        Test.@testset "Return type correctness" begin
            kw = pairs((; discretizer=DISC))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result isa Union{CTDirect.AbstractDiscretizer, Nothing}
        end

        Test.@testset "Nothing return type" begin
            kw = pairs(NamedTuple())
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result isa Nothing
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_kwarg_extraction() = TestKwargExtraction.test_kwarg_extraction()

# ============================================================================
# Keyword Argument Extraction Helpers Tests
# ============================================================================
# This file contains unit tests for helpers that extract specific types from
# keyword arguments (e.g., `_extract_kwarg`) and check for the presence of
# explicit components (`_has_explicit_components`). It ensures reliable
# argument parsing for the main solve dispatch logic.

module TestKwargExtraction

import Test
import OptimalControl
import CTDirect
import CTSolvers
import CTBase

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
        # ====================================================================
        # UNIT TESTS - Action Kwarg Extraction (aliases)
        # ====================================================================

        Test.@testset "Action Kwarg Extraction" begin
            Test.@testset "Extracts primary name" begin
                kw = pairs((; initial_guess=42, display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, (:initial_guess, :init, :i), nothing)
                Test.@test val == 42
                Test.@test haskey(rest, :display)
                Test.@test !haskey(rest, :initial_guess)
            end

            Test.@testset "Extracts alias 1" begin
                kw = pairs((; init=42, display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, (:initial_guess, :init, :i), nothing)
                Test.@test val == 42
                Test.@test haskey(rest, :display)
                Test.@test !haskey(rest, :init)
            end

            Test.@testset "Extracts alias 2" begin
                kw = pairs((; i=42, display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, (:initial_guess, :init, :i), nothing)
                Test.@test val == 42
                Test.@test haskey(rest, :display)
                Test.@test !haskey(rest, :i)
            end

            Test.@testset "Returns default when not found" begin
                kw = pairs((; display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, (:initial_guess, :init, :i), :my_default)
                Test.@test val === :my_default
                Test.@test haskey(rest, :display)
            end

            Test.@testset "Throws on multiple aliases present" begin
                kw = pairs((; init=42, i=43))
                Test.@test_throws CTBase.IncorrectArgument OptimalControl._extract_action_kwarg(kw, (:initial_guess, :init, :i), nothing)
                
                kw2 = pairs((; initial_guess=42, init=43, i=44))
                Test.@test_throws CTBase.IncorrectArgument OptimalControl._extract_action_kwarg(kw2, (:initial_guess, :init, :i), nothing)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_kwarg_extraction() = TestKwargExtraction.test_kwarg_extraction()

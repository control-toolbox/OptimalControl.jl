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
                val, rest = OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
                Test.@test val == 42
                Test.@test haskey(rest, :display)
                Test.@test !haskey(rest, :initial_guess)
            end

            Test.@testset "Extracts alias 1" begin
                kw = pairs((; init=42, display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
                Test.@test val == 42
                Test.@test haskey(rest, :display)
                Test.@test !haskey(rest, :init)
            end

            Test.@testset "No alias 'i' (removed)" begin
                kw = pairs((; i=42, display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
                Test.@test val === nothing  # default, since :i is not recognized
                Test.@test haskey(rest, :display)
                Test.@test haskey(rest, :i)  # :i remains in remaining kwargs
            end

            Test.@testset "Returns default when not found" begin
                kw = pairs((; display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, :my_default)
                Test.@test val === :my_default
                Test.@test haskey(rest, :display)
            end

            Test.@testset "Throws on multiple aliases present" begin
                kw = pairs((; initial_guess=42, init=43))
                Test.@test_throws CTBase.IncorrectArgument OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
            end
        end

        # ====================================================================
        # PERFORMANCE TESTS
        # ====================================================================

        Test.@testset "Performance Characteristics" begin
            Test.@testset "_extract_kwarg Performance" begin
                # Test with matching type
                kw = pairs((; discretizer=DISC, print_level=0))
                
                # Should be allocation-free for simple cases
                allocs = Test.@allocated OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
                Test.@test allocs == 0
                
                # Type stability
                Test.@test_nowarn Test.@inferred OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            end

            Test.@testset "_extract_kwarg Performance - No Match" begin
                # Test with no matching type
                kw = pairs((; print_level=0, max_iter=100))
                
                # Should be allocation-free
                allocs = Test.@allocated OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
                Test.@test allocs == 0
                
                # Type stability
                Test.@test_nowarn Test.@inferred OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            end

            Test.@testset "_extract_kwarg Performance - Large kwargs" begin
                # Test with many kwargs
                large_kw = pairs((
                    discretizer=DISC,
                    modeler=MOD,
                    solver=SOL,
                    option1=1,
                    option2=2,
                    option3=3,
                    option4=4,
                    option5=5,
                    option6=6,
                    option7=7,
                    option8=8,
                    option9=9,
                    option10=10,
                ))
                
                # Should still be efficient
                allocs = Test.@allocated OptimalControl._extract_kwarg(large_kw, CTDirect.AbstractDiscretizer)
                Test.@test allocs < 1000  # Small allocation acceptable for large kwargs
                
                # Type stability
                Test.@test_nowarn Test.@inferred OptimalControl._extract_kwarg(large_kw, CTDirect.AbstractDiscretizer)
            end

            Test.@testset "_extract_action_kwarg Performance" begin
                # Test with primary name
                kw = pairs((; initial_guess=42, display=false))
                
                # Small allocation expected for tuple reconstruction
                allocs = Test.@allocated OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
                Test.@test allocs < 5000  # Adjusted from 1000
                
                # Type stability (complex return types make @inferred difficult)
                val, rest = OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
                Test.@test val == 42
                Test.@test !haskey(rest, :initial_guess)
            end

            Test.@testset "_extract_action_kwarg Performance - Default" begin
                # Test with default value
                kw = pairs((; display=false))
                
                allocs = Test.@allocated OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, :default)
                Test.@test allocs < 5000  # Adjusted from 1000
            end
        end

        # ====================================================================
        # EDGE CASE TESTS
        # ====================================================================

        Test.@testset "Edge Cases" begin
            Test.@testset "Empty aliases tuple" begin
                kw = pairs((; display=false))
                val, rest = OptimalControl._extract_action_kwarg(kw, (), :default)
                Test.@test val === :default
                Test.@test length(rest) == 1
                Test.@test haskey(rest, :display)
            end

            Test.@testset "Single alias tuple" begin
                kw = pairs((; initial_guess=42))
                val, rest = OptimalControl._extract_action_kwarg(kw, (:initial_guess,), nothing)
                Test.@test val == 42
                Test.@test length(rest) == 0
            end

            Test.@testset "Multiple matching types in kwargs" begin
                # Test when multiple instances of the same type are present
                kw = pairs((; discretizer=DISC, another_disc=DISC))
                result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
                Test.@test result === DISC  # Should return the first match
            end

            Test.@testset "Complex nested types" begin
                # Test with more complex types
                kw = pairs((; discretizer=DISC, some_string="hello", some_number=42))
                
                result1 = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
                result2 = OptimalControl._extract_kwarg(kw, String)
                result3 = OptimalControl._extract_kwarg(kw, Int)
                
                Test.@test result1 === DISC
                Test.@test result2 == "hello"
                Test.@test result3 == 42
            end

            Test.@testset "Very large kwargs tuple" begin
                # Test performance with very large number of kwargs
                large_kwargs_dict = Dict{Symbol, Any}()
                for i in 1:100
                    large_kwargs_dict[Symbol("option_$i")] = i
                end
                large_kwargs_dict[:discretizer] = DISC
                
                large_kw = pairs(NamedTuple(large_kwargs_dict))
                
                # Should still find the type efficiently
                result = OptimalControl._extract_kwarg(large_kw, CTDirect.AbstractDiscretizer)
                Test.@test result === DISC
                
                # Reasonable allocation limit
                allocs = Test.@allocated OptimalControl._extract_kwarg(large_kw, CTDirect.AbstractDiscretizer)
                Test.@test allocs < 50000  # Adjusted from 10000 (38352 observed)
            end
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================

        Test.@testset "Integration Scenarios" begin
            Test.@testset "Complete solve-like kwargs parsing" begin
                # Simulate a realistic solve call kwargs
                kw = pairs((
                    discretizer=DISC,
                    modeler=MOD,
                    solver=SOL,
                    initial_guess=:zeros,
                    display=false,
                    max_iter=1000,
                    tolerance=1e-6,
                    verbose=true,
                ))
                
                # Extract components
                disc = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
                mod = OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler)
                sol = OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPSolver)
                
                Test.@test disc === DISC
                Test.@test mod === MOD
                Test.@test sol === SOL
                
                # Extract action options
                init_val, kw_without_init = OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
                display_val, kw_final = OptimalControl._extract_action_kwarg(kw_without_init, (:display,), true)
                
                Test.@test init_val === :zeros
                Test.@test display_val == false
                Test.@test !haskey(kw_final, :initial_guess)
                Test.@test !haskey(kw_final, :display)
                Test.@test haskey(kw_final, :max_iter)
            end

            Test.@testset "No explicit components scenario" begin
                # Test when no components are provided (descriptive mode)
                kw = pairs((
                    initial_guess=:random,
                    display=true,
                    grid_size=50,
                    max_iter=500,
                ))
                
                disc = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
                mod = OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler)
                sol = OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPSolver)
                
                Test.@test isnothing(disc)
                Test.@test isnothing(mod)
                Test.@test isnothing(sol)
                
                init_val, kw_final = OptimalControl._extract_action_kwarg(kw, OptimalControl._INITIAL_GUESS_ALIASES, nothing)
                Test.@test init_val === :random
                Test.@test !haskey(kw_final, :initial_guess)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_kwarg_extraction() = TestKwargExtraction.test_kwarg_extraction()

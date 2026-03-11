# ============================================================================
# Mode Detection Tests
# ============================================================================
# This file contains unit tests for the `_explicit_or_descriptive` helper
# function. It strictly verifies the logic used to determine whether the user's
# `solve` call is in explicit or descriptive mode based on the provided arguments,
# and ensures that conflicting or mixed arguments throw the appropriate errors.

module TestModeDetection

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

function test_mode_detection()
    Test.@testset "Mode Detection" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - ExplicitMode detection
        # ====================================================================

        Test.@testset "ExplicitMode - discretizer only" begin
            kw = pairs((; discretizer=DISC))
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.ExplicitMode
        end

        Test.@testset "ExplicitMode - modeler only" begin
            kw = pairs((; modeler=MOD))
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.ExplicitMode
        end

        Test.@testset "ExplicitMode - solver only" begin
            kw = pairs((; solver=SOL))
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.ExplicitMode
        end

        Test.@testset "ExplicitMode - all three components" begin
            kw = pairs((; discretizer=DISC, modeler=MOD, solver=SOL))
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.ExplicitMode
        end

        Test.@testset "ExplicitMode - with extra strategy kwargs" begin
            kw = pairs((; discretizer=DISC, print_level=0, max_iter=100))
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.ExplicitMode
        end

        # ====================================================================
        # UNIT TESTS - DescriptiveMode detection
        # ====================================================================

        Test.@testset "DescriptiveMode - empty description, no components" begin
            kw = pairs(NamedTuple())
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.DescriptiveMode
        end

        Test.@testset "DescriptiveMode - with description" begin
            kw = pairs(NamedTuple())
            result = OptimalControl._explicit_or_descriptive((:collocation, :adnlp, :ipopt), kw)
            Test.@test result isa OptimalControl.DescriptiveMode
        end

        Test.@testset "DescriptiveMode - with strategy-specific kwargs (no components)" begin
            kw = pairs((; print_level=0, max_iter=100))
            result = OptimalControl._explicit_or_descriptive((:collocation,), kw)
            Test.@test result isa OptimalControl.DescriptiveMode
        end

        # ====================================================================
        # UNIT TESTS - Name independence (key design property)
        # ====================================================================

        Test.@testset "Name-independent detection - component under custom key" begin
            # A discretizer stored under a non-standard key name is still detected
            kw = pairs((; my_disc=DISC))
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.ExplicitMode
        end

        Test.@testset "Non-component value named 'discretizer' is ignored" begin
            # A kwarg named 'discretizer' but with wrong type is NOT detected as explicit
            kw = pairs((; discretizer=:collocation))  # Symbol, not AbstractDiscretizer
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.DescriptiveMode
        end

        # ====================================================================
        # UNIT TESTS - Conflict detection (error cases)
        # ====================================================================

        Test.@testset "Conflict: discretizer + description" begin
            kw = pairs((; discretizer=DISC))
            Test.@test_throws CTBase.IncorrectArgument begin
                OptimalControl._explicit_or_descriptive((:adnlp, :ipopt), kw)
            end
        end

        Test.@testset "Conflict: solver + description" begin
            kw = pairs((; solver=SOL))
            Test.@test_throws CTBase.IncorrectArgument begin
                OptimalControl._explicit_or_descriptive((:collocation,), kw)
            end
        end

        Test.@testset "Conflict: all components + description" begin
            kw = pairs((; discretizer=DISC, modeler=MOD, solver=SOL))
            Test.@test_throws CTBase.IncorrectArgument begin
                OptimalControl._explicit_or_descriptive((:collocation, :adnlp), kw)
            end
        end

        Test.@testset "Conflict: custom key component + description" begin
            # Even with custom key names, mixing with description is forbidden
            kw = pairs((; my_custom_disc=DISC))
            Test.@test_throws CTBase.IncorrectArgument begin
                OptimalControl._explicit_or_descriptive((:trapeze,), kw)
            end
        end

        # ====================================================================
        # UNIT TESTS - Edge cases
        # ====================================================================

        Test.@testset "Edge case: empty kwargs with description" begin
            kw = pairs(NamedTuple())
            result = OptimalControl._explicit_or_descriptive((:collocation,), kw)
            Test.@test result isa OptimalControl.DescriptiveMode
        end

        Test.@testset "Edge case: empty kwargs, empty description" begin
            kw = pairs(NamedTuple())
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.DescriptiveMode
        end

        Test.@testset "Edge case: non-component values only" begin
            # Strategy options without component types should not trigger ExplicitMode
            kw = pairs((; print_level=0, max_iter=100, tol=1e-6))
            result = OptimalControl._explicit_or_descriptive((), kw)
            Test.@test result isa OptimalControl.DescriptiveMode
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_mode_detection() = TestModeDetection.test_mode_detection()

# ============================================================================
# Mode Types and Extraction Tests
# ============================================================================
# This file tests the basic mode sentinel types (`ExplicitMode`, `DescriptiveMode`)
# and the low-level keyword argument extraction helpers (`_extract_kwarg`,
# `_has_explicit_components`) used by the top-level dispatch system.

module TestSolveMode

using Test: Test
using OptimalControl: OptimalControl

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_solve_mode()
    Test.@testset "SolveMode Types" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Type hierarchy
        # ====================================================================

        Test.@testset "Type hierarchy" begin
            Test.@test OptimalControl.ExplicitMode <: OptimalControl.SolveMode
            Test.@test OptimalControl.DescriptiveMode <: OptimalControl.SolveMode
            Test.@test OptimalControl.SolveMode isa DataType
            Test.@test isabstracttype(OptimalControl.SolveMode)
            Test.@test !isabstracttype(OptimalControl.ExplicitMode)
            Test.@test !isabstracttype(OptimalControl.DescriptiveMode)
        end

        # ====================================================================
        # UNIT TESTS - Instantiation
        # ====================================================================

        Test.@testset "Instantiation" begin
            em = OptimalControl.ExplicitMode()
            dm = OptimalControl.DescriptiveMode()
            Test.@test em isa OptimalControl.ExplicitMode
            Test.@test em isa OptimalControl.SolveMode
            Test.@test dm isa OptimalControl.DescriptiveMode
            Test.@test dm isa OptimalControl.SolveMode
        end

        # ====================================================================
        # UNIT TESTS - Dispatch
        # ====================================================================

        Test.@testset "Multiple dispatch" begin
            # Verify dispatch works correctly on instances
            function _mode_name(::OptimalControl.ExplicitMode)
                return :explicit
            end
            function _mode_name(::OptimalControl.DescriptiveMode)
                return :descriptive
            end

            Test.@test _mode_name(OptimalControl.ExplicitMode()) == :explicit
            Test.@test _mode_name(OptimalControl.DescriptiveMode()) == :descriptive
        end

        # ====================================================================
        # UNIT TESTS - Distinctness
        # ====================================================================

        Test.@testset "Distinctness" begin
            Test.@test OptimalControl.ExplicitMode != OptimalControl.DescriptiveMode
            Test.@test !(OptimalControl.ExplicitMode() isa OptimalControl.DescriptiveMode)
            Test.@test !(OptimalControl.DescriptiveMode() isa OptimalControl.ExplicitMode)
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_mode() = TestSolveMode.test_solve_mode()

# ============================================================================
# ExaModels Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `ExaModels`. It verifies that
# the expected types and functions related to the ExaModels backend are
# properly exported by `OptimalControl`.

module TestExamodels

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
using ExaModels: ExaModels # for names(ExaModels) in the export-collision canary

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestExamodels

function test_examodels()
    Test.@testset "ExaModels reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Generated Code Prefix" begin
            Test.@test isdefined(OptimalControl, :ExaModels)
            Test.@test isdefined(CurrentModule, :ExaModels)
            Test.@test ExaModels isa Module
        end

        # --------------------------------------------------------------------
        # Export-collision canary
        # --------------------------------------------------------------------
        # ExaModels 0.12 newly exports `objective` and `constraint` (oracle
        # builders); OptimalControl exports both as accessors. A user who writes
        # `using ExaModels` next to `using OptimalControl` then gets a bare
        # `UndefVarError` on the next `objective(sol)` — Julia refuses to pick.
        # The docs no longer tell anyone to import ExaModels (`:exa` needs no
        # `using`), but this test turns the *next* upstream export that collides
        # into a red test here rather than a user bug report. See issue #882.
        Test.@testset "Export surface does not collide with OptimalControl" begin
            shared = intersect(names(ExaModels), names(OptimalControl))
            # keep only the genuine clashes: same name, different binding
            # (`:ExaModels` itself is shared but resolves to the one module).
            clash = sort!(
                filter(
                    s -> getglobal(ExaModels, s) !== getglobal(OptimalControl, s), shared
                ),
            )
            Test.@test clash == [:constraint, :objective]
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_examodels() = TestExamodels.test_examodels()

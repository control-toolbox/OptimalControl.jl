# ============================================================================
# CTSolvers Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTSolvers`. It verifies that
# the strategy builders, solver types, options, and utilities like `route_to`
# and `bypass` are properly exported by `OptimalControl`.

module TestCtsolvers

import Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtsolvers

function test_ctsolvers()
    Test.@testset "CTSolvers reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "DOCP Types" begin
            for T in (
                OptimalControl.DiscretizedModel,
            )
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "DOCP Functions" begin
            for f in (
                :ocp_model,
                :nlp_model,
                :ocp_solution,
            )
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end
        Test.@testset "Modeler Types" begin
            for T in (
                OptimalControl.AbstractNLPModeler,
                OptimalControl.ADNLP,
                OptimalControl.Exa,
            )
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "Solver Types" begin
            for T in (
                OptimalControl.AbstractNLPSolver,
                OptimalControl.Ipopt,
                OptimalControl.MadNLP,
                OptimalControl.MadNCL,
                OptimalControl.Knitro,
            )
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "Strategy Types" begin
            for T in (
                OptimalControl.AbstractStrategy,
                OptimalControl.StrategyRegistry,
                OptimalControl.StrategyMetadata,
                OptimalControl.StrategyOptions,
                OptimalControl.OptionDefinition,
                OptimalControl.RoutedOption,
                OptimalControl.BypassValue,
            )
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "Strategy Metadata Functions" begin
            for f in (
                :id,
                :metadata,
            )
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end
        Test.@testset "Strategy Introspection Functions" begin
            for f in (
                :option_names,
                :option_type,
                :option_description,
                :option_default,
                :option_defaults,
                :option_value,
                :option_source,
                :has_option,
                :is_user,
                :is_default,
                :is_computed,
            )
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end
        Test.@testset "Strategy Utility Functions" begin
            for f in (
                :route_to,
                :bypass,
            )
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctsolvers() = TestCtsolvers.test_ctsolvers()
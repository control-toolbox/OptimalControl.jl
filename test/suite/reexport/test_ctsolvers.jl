# ============================================================================
# CTSolvers Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTSolvers`. It verifies that
# the strategy builders, solver types, options, and utilities like `route_to`
# and `bypass` are properly exported by `OptimalControl`.

module TestCtsolvers

using Test: Test
using CTSolvers: CTSolvers
using OptimalControl # using is mandatory since we test exported symbols
using SolverCore: SolverCore # needed for ocp_solution signature check

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtsolvers

function test_ctsolvers()
    Test.@testset "CTSolvers reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "DOCP Types" begin
            for T in (OptimalControl.DiscretizedModel,)
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end

        Test.@testset "DOCP Functions" begin
            for f in (:ocp_model, :nlp_model, :ocp_solution)
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Display and Introspection Functions" begin
            for f in (:describe, :options)
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end
        Test.@testset "Modeler Types" begin
            for T in (
                OptimalControl.AbstractNLPModeler, OptimalControl.ADNLP, OptimalControl.Exa
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
                OptimalControl.Uno,
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
                OptimalControl.OptionValue,
                OptimalControl.RoutedOption,
                OptimalControl.BypassValue,
            )
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "Strategy Metadata Functions" begin
            for f in (:id, :metadata)
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
            for f in (:route_to, :bypass)
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Strategy Parameter Types" begin
            # Test that parameter types are available
            # AbstractStrategyParameter is imported only, CPU and GPU are reexported
            Test.@test isdefined(OptimalControl, :AbstractStrategyParameter)
            Test.@test isdefined(OptimalControl, :CPU)
            Test.@test isdefined(OptimalControl, :GPU)

            # CPU and GPU should be accessible in current module since they are reexported
            Test.@test isdefined(CurrentModule, :CPU)
            Test.@test isdefined(CurrentModule, :GPU)

            # AbstractStrategyParameter should NOT be in the public exports (names with all=false)
            # CPU and GPU should BE in the public exports since they are reexported
            Test.@test :AbstractStrategyParameter ∉ names(OptimalControl; all=false)
            Test.@test :CPU ∈ names(OptimalControl; all=false)
            Test.@test :GPU ∈ names(OptimalControl; all=false)

            # They should also be accessible via CTSolvers
            Test.@test isdefined(CTSolvers, :AbstractStrategyParameter)
            Test.@test isdefined(CTSolvers, :CPU)
            Test.@test isdefined(CTSolvers, :GPU)

            # Test parameter type validation functions are accessible via CTSolvers
            Test.@test isdefined(CTSolvers.Strategies, :is_parameter_type)
            Test.@test isdefined(CTSolvers.Strategies, :get_parameter_type)
            Test.@test isdefined(CTSolvers.Strategies, :available_parameters)

            # These should NOT be reexported by OptimalControl (internal functions)
            Test.@test !isdefined(OptimalControl, :is_parameter_type)
            Test.@test !isdefined(OptimalControl, :get_parameter_type)
            Test.@test !isdefined(OptimalControl, :available_parameters)
        end

        Test.@testset "Type Hierarchy" begin
            Test.@testset "Modelers" begin
                Test.@test OptimalControl.ADNLP <: OptimalControl.AbstractNLPModeler
                Test.@test OptimalControl.Exa <: OptimalControl.AbstractNLPModeler
            end
            Test.@testset "Solvers" begin
                Test.@test OptimalControl.Ipopt <: OptimalControl.AbstractNLPSolver
                Test.@test OptimalControl.MadNLP <: OptimalControl.AbstractNLPSolver
                Test.@test OptimalControl.Uno <: OptimalControl.AbstractNLPSolver
                Test.@test OptimalControl.MadNCL <: OptimalControl.AbstractNLPSolver
                Test.@test OptimalControl.Knitro <: OptimalControl.AbstractNLPSolver
            end
            Test.@testset "Parameters" begin
                Test.@test OptimalControl.CPU <: CTSolvers.AbstractStrategyParameter
                Test.@test OptimalControl.GPU <: CTSolvers.AbstractStrategyParameter
            end
        end

        Test.@testset "Method Signatures" begin
            Test.@testset "ocp_model" begin
                Test.@test hasmethod(ocp_model, Tuple{OptimalControl.DiscretizedModel})
            end
            Test.@testset "nlp_model" begin
                Test.@test hasmethod(
                    nlp_model,
                    Tuple{
                        OptimalControl.DiscretizedModel,
                        Any,
                        OptimalControl.AbstractNLPModeler,
                    },
                )
            end
            Test.@testset "ocp_solution" begin
                Test.@test hasmethod(
                    ocp_solution,
                    Tuple{
                        OptimalControl.DiscretizedModel,
                        SolverCore.AbstractExecutionStats,
                        OptimalControl.AbstractNLPModeler,
                    },
                )
            end
            Test.@testset "describe" begin
                Test.@test hasmethod(describe, Tuple{Symbol})
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctsolvers() = TestCtsolvers.test_ctsolvers()

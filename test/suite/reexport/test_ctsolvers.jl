module TestCtsolvers

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_ctsolvers()
    @testset "CTSolvers reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        @testset "DOCP Types" begin
            for T in (
                DiscretizedOptimalControlProblem,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test isdefined(Main, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "DOCP Functions" begin
            for f in (
                :ocp_model,
                :nlp_model,
                :ocp_solution,
            )
                @test isdefined(OptimalControl, f)
                @test isdefined(Main, f)
                @test getfield(OptimalControl, f) isa Function
            end
        end
        @testset "Modeler Types" begin
            for T in (
                AbstractOptimizationModeler,
                ADNLPModeler,
                ExaModeler,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test isdefined(Main, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Solver Types" begin
            for T in (
                AbstractOptimizationSolver,
                IpoptSolver,
                MadNLPSolver,
                MadNCLSolver,
                KnitroSolver,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test isdefined(Main, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Strategy Types" begin
            for T in (
                AbstractStrategy,
                StrategyRegistry,
                StrategyMetadata,
                StrategyOptions,
                OptionDefinition,
                RoutedOption,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test isdefined(Main, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Strategy Metadata Functions" begin
            for f in (
                :id,
                :metadata,
            )
                @test isdefined(OptimalControl, f)
                @test isdefined(Main, f)
                @test getfield(OptimalControl, f) isa Function
            end
        end
        @testset "Strategy Introspection Functions" begin
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
                @test isdefined(OptimalControl, f)
                @test isdefined(Main, f)
                @test getfield(OptimalControl, f) isa Function
            end
        end
        @testset "Strategy Utility Functions" begin
            for f in (
                :filter_options,
                :suggest_options,
                :options_dict,
                :route_to,
            )
                @test isdefined(OptimalControl, f)
                @test isdefined(Main, f)
                @test getfield(OptimalControl, f) isa Function
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctsolvers() = TestCtsolvers.test_ctsolvers()
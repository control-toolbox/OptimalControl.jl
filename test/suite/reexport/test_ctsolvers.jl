module TestCtsolvers

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtsolvers

function test_ctsolvers()
    @testset "CTSolvers reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        @testset "DOCP Types" begin
            for T in (
                OptimalControl.DiscretizedOptimalControlProblem,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test !isdefined(CurrentModule, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "DOCP Functions" begin
            for f in (
                :ocp_model,
                :nlp_model,
                :ocp_solution,
            )
                @testset "$f" begin
                    @test isdefined(OptimalControl, f)
                    @test isdefined(CurrentModule, f)
                    @test getfield(OptimalControl, f) isa Function
                end
            end
        end
        @testset "Modeler Types" begin
            for T in (
                OptimalControl.AbstractOptimizationModeler,
                OptimalControl.ADNLPModeler,
                OptimalControl.ExaModeler,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test !isdefined(CurrentModule, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Solver Types" begin
            for T in (
                OptimalControl.AbstractOptimizationSolver,
                OptimalControl.IpoptSolver,
                OptimalControl.MadNLPSolver,
                OptimalControl.MadNCLSolver,
                OptimalControl.KnitroSolver,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test !isdefined(CurrentModule, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Strategy Types" begin
            for T in (
                OptimalControl.AbstractStrategy,
                OptimalControl.StrategyRegistry,
                OptimalControl.StrategyMetadata,
                OptimalControl.StrategyOptions,
                OptimalControl.OptionDefinition,
                OptimalControl.RoutedOption,
            )
                @test isdefined(OptimalControl, nameof(T))
                @test !isdefined(CurrentModule, nameof(T))
                @test T isa DataType || T isa UnionAll
            end
        end
        @testset "Strategy Metadata Functions" begin
            for f in (
                :id,
                :metadata,
            )
                @testset "$f" begin
                    @test isdefined(OptimalControl, f)
                    @test isdefined(CurrentModule, f)
                    @test getfield(OptimalControl, f) isa Function
                end
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
                @testset "$f" begin
                    @test isdefined(OptimalControl, f)
                    @test isdefined(CurrentModule, f)
                    @test getfield(OptimalControl, f) isa Function
                end
            end
        end
        @testset "Strategy Utility Functions" begin
            for f in (
                :route_to,
            )
                @testset "$f" begin
                    @test isdefined(OptimalControl, f)
                    @test isdefined(CurrentModule, f)
                    @test getfield(OptimalControl, f) isa Function
                end
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctsolvers() = TestCtsolvers.test_ctsolvers()
module TestCtmodels

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtmodels

function test_ctmodels()
    @testset "CTModels reexports" verbose = VERBOSE showtiming = SHOWTIMING begin

        @testset "Generated Code Prefix" begin
            @test isdefined(OptimalControl, :CTModels)
            @test isdefined(CurrentModule, :CTModels)
            @test CTModels isa Module
        end

        @testset "Display" begin
            @test isdefined(OptimalControl, :plot)
            @test isdefined(CurrentModule, :plot)
            @test plot isa Function
        end
        
        @testset "Initial Guess Types" begin
            for T in (
                OptimalControl.AbstractOptimalControlInitialGuess,
                OptimalControl.OptimalControlInitialGuess,
            )
                @testset "$(nameof(T))" begin
                    @test isdefined(OptimalControl, nameof(T))
                    @test !isdefined(CurrentModule, nameof(T))
                    @test T isa DataType || T isa UnionAll
                end
            end
        end
        
        @testset "Serialization Functions" begin
            for f in (
                :export_ocp_solution,
                :import_ocp_solution,
            )
                @testset "$f" begin
                    @test isdefined(OptimalControl, f)
                    @test isdefined(CurrentModule, f)
                    @test getfield(OptimalControl, f) isa Function
                end
            end
        end
        
        @testset "API Types" begin
            for T in (
                OptimalControl.Model,
                OptimalControl.AbstractModel,
                OptimalControl.AbstractOptimalControlProblem,
                OptimalControl.Solution,
                OptimalControl.AbstractSolution,
                OptimalControl.AbstractOptimalControlSolution,
            )
                @testset "$(nameof(T))" begin
                    @test isdefined(OptimalControl, nameof(T))
                    @test !isdefined(CurrentModule, nameof(T))
                    @test T isa DataType || T isa UnionAll
                end
            end
        end
        
        @testset "Accessors" begin
            for f in (
                :constraint, :constraints, :name, :dimension, :components,
                :initial_time, :final_time, :time_name, :time_grid, :times,
                :initial_time_name, :final_time_name,
                :criterion, :has_mayer_cost, :has_lagrange_cost,
                :is_mayer_cost_defined, :is_lagrange_cost_defined,
                :has_fixed_initial_time, :has_free_initial_time,
                :has_fixed_final_time, :has_free_final_time,
                :is_autonomous,
                :is_initial_time_fixed, :is_initial_time_free,
                :is_final_time_fixed, :is_final_time_free,
                :state_dimension, :control_dimension, :variable_dimension,
                :state_name, :control_name, :variable_name,
                :state_components, :control_components, :variable_components,
            )
                @testset "$f" begin
                    @test isdefined(OptimalControl, f)
                    @test isdefined(CurrentModule, f)
                    @test getfield(OptimalControl, f) isa Function
                end
            end
        end

        @testset "Constraint Accessors" begin
            for f in (
                :path_constraints_nl, :boundary_constraints_nl,
                :state_constraints_box, :control_constraints_box, :variable_constraints_box,
                :dim_path_constraints_nl, :dim_boundary_constraints_nl,
                :dim_state_constraints_box, :dim_control_constraints_box,
                :dim_variable_constraints_box,
                :state, :control, :variable, :costate, :objective,
                :dynamics, :mayer, :lagrange,
                :definition, :dual,
                :iterations, :status, :message, :success, :successful,
                :constraints_violation, :infos,
                :get_build_examodel,
                :is_empty, :is_empty_time_grid,
                :index, :time,
                :model,
            )
                @testset "$f" begin
                    @test isdefined(OptimalControl, f)
                    @test isdefined(CurrentModule, f)
                    @test getfield(OptimalControl, f) isa Function
                end
            end
        end

        @testset "Dual Constraints Accessors" begin
            for f in (
                :path_constraints_dual, :boundary_constraints_dual,
                :state_constraints_lb_dual, :state_constraints_ub_dual,
                :control_constraints_lb_dual, :control_constraints_ub_dual,
                :variable_constraints_lb_dual, :variable_constraints_ub_dual,
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
test_ctmodels() = TestCtmodels.test_ctmodels()
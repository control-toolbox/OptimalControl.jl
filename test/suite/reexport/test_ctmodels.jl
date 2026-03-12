# ============================================================================
# CTModels Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTModels`. It verifies that
# all the core types and functions required to define and manipulate optimal
# control problems (OCPs) are properly exported by `OptimalControl`.

module TestCtmodels

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtmodels

function test_ctmodels()
    Test.@testset "CTModels reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Generated Code Prefix" begin
            Test.@test isdefined(OptimalControl, :CTModels)
            Test.@test isdefined(CurrentModule, :CTModels)
            Test.@test CTModels isa Module
        end

        Test.@testset "Display" begin
            Test.@test isdefined(OptimalControl, :plot)
            Test.@test isdefined(CurrentModule, :plot)
            Test.@test plot isa Function
        end

        Test.@testset "Initial Guess Types" begin
            for T in (OptimalControl.AbstractInitialGuess, OptimalControl.InitialGuess)
                Test.@testset "$(nameof(T))" begin
                    Test.@test isdefined(OptimalControl, nameof(T))
                    Test.@test !isdefined(CurrentModule, nameof(T))
                    Test.@test T isa DataType || T isa UnionAll
                end
            end
        end

        Test.@testset "Initial Guess Functions" begin
            for f in (:build_initial_guess,)
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test !isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Serialization Functions" begin
            for f in (:export_ocp_solution, :import_ocp_solution)
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "API Types" begin
            for T in (
                OptimalControl.Model,
                OptimalControl.AbstractModel,
                OptimalControl.AbstractModel,
                OptimalControl.Solution,
                OptimalControl.AbstractSolution,
                OptimalControl.AbstractSolution,
            )
                Test.@testset "$(nameof(T))" begin
                    Test.@test isdefined(OptimalControl, nameof(T))
                    Test.@test !isdefined(CurrentModule, nameof(T))
                    Test.@test T isa DataType || T isa UnionAll
                end
            end
        end

        Test.@testset "Accessors" begin
            for f in (
                :constraint,
                :constraints,
                :name,
                :dimension,
                :components,
                :initial_time,
                :final_time,
                :time_name,
                :time_grid,
                :times,
                :initial_time_name,
                :final_time_name,
                :criterion,
                :has_mayer_cost,
                :has_lagrange_cost,
                :is_mayer_cost_defined,
                :is_lagrange_cost_defined,
                :has_fixed_initial_time,
                :has_free_initial_time,
                :has_fixed_final_time,
                :has_free_final_time,
                :is_autonomous,
                :is_initial_time_fixed,
                :is_initial_time_free,
                :is_final_time_fixed,
                :is_final_time_free,
                :state_dimension,
                :control_dimension,
                :variable_dimension,
                :state_name,
                :control_name,
                :variable_name,
                :state_components,
                :control_components,
                :variable_components,
            )
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Constraint Accessors" begin
            for f in (
                :path_constraints_nl,
                :boundary_constraints_nl,
                :state_constraints_box,
                :control_constraints_box,
                :variable_constraints_box,
                :dim_path_constraints_nl,
                :dim_boundary_constraints_nl,
                :dim_state_constraints_box,
                :dim_control_constraints_box,
                :dim_variable_constraints_box,
                :state,
                :control,
                :variable,
                :costate,
                :objective,
                :dynamics,
                :mayer,
                :lagrange,
                :definition,
                :dual,
                :iterations,
                :status,
                :message,
                :success,
                :successful,
                :constraints_violation,
                :infos,
                :get_build_examodel,
                :is_empty,
                :is_empty_time_grid,
                :index,
                :time,
                :model,
            )
                Test.@testset "$f" begin
                    Test.@test isdefined(OptimalControl, f)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Dual Constraints Accessors" begin
            for f in (
                :path_constraints_dual,
                :boundary_constraints_dual,
                :state_constraints_lb_dual,
                :state_constraints_ub_dual,
                :control_constraints_lb_dual,
                :control_constraints_ub_dual,
                :variable_constraints_lb_dual,
                :variable_constraints_ub_dual,
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
test_ctmodels() = TestCtmodels.test_ctmodels()

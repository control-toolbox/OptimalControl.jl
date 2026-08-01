# ============================================================================
# CTModels Reexports Tests
# ============================================================================
# Grouped by owning submodule (`Components`, `Models`, `Solutions`,
# `Building`, `Init`, `Serialization`), matching src/imports/ctmodels.jl.
#
# Two v2.1.0-beta corrections are pinned down here:
#
#   - `time` is no longer a CTModels function. It is `Base.time`, extended by
#     `CTModels.Components` but not exported. Re-exporting it was wrong.
#   - the seven traits (`is_autonomous`, `has_variable`, …) are re-exported by
#     `CTModels.Models` but *owned* by `CTBase.Traits` — they moved to
#     test_ctbase.jl.
#
# ⚠️ `name`, `status`, `success`, `value`, `index`, `model` all collide with
# `Base` or with a sibling package, so `isdefined` proves nothing about them.
# Ownership assertions throughout.

module TestCtmodels

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
using CTModels: CTModels
using CTBase: CTBase

include(joinpath(@__DIR__, "..", "..", "helpers", "reexport.jl"))
using .ReexportUtils: reexports, imports, is_exported

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtmodels

const COMPONENTS = (
    :components,
    :dimension,
    :name,
    :index,
    :expression,
    :criterion,
    # time
    :initial_time,
    :final_time,
    :time_name,
    :time_grid,
    :times,
    :initial_time_name,
    :final_time_name,
    :has_fixed_initial_time,
    :has_free_initial_time,
    :has_fixed_final_time,
    :has_free_final_time,
    :is_initial_time_fixed,
    :is_initial_time_free,
    :is_final_time_fixed,
    :is_final_time_free,
    # cost
    :has_mayer_cost,
    :has_lagrange_cost,
    :is_mayer_cost_defined,
    :is_lagrange_cost_defined,
    :mayer,
    :lagrange,
    :objective,
    # trajectory
    :state,
    :control,
    :variable,
    :costate,
    # constraints
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
)

const MODELS = (
    :constraint,
    :constraints,
    :definition,
    :dynamics,
    :has_abstract_definition,
    :is_abstractly_defined,
    :get_build_examodel,
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

const SOLUTIONS = (
    :dual,
    :iterations,
    :status,
    :message,
    :successful,
    :constraints_violation,
    :infos,
    :is_empty,
    :is_empty_time_grid,
    :model,
    # dual constraint accessors
    :path_constraints_dual,
    :boundary_constraints_dual,
    :state_constraints_lb_dual,
    :state_constraints_ub_dual,
    :control_constraints_lb_dual,
    :control_constraints_ub_dual,
    :variable_constraints_lb_dual,
    :variable_constraints_ub_dual,
    :dim_dual_state_constraints_box,
    :dim_dual_control_constraints_box,
    :dim_dual_variable_constraints_box,
)

const BUILDING = (
    :time!,
    :state!,
    :control!,
    :variable!,
    :dynamics!,
    :objective!,
    :constraint!,
    :time_dependence!,
    :build,
)

function test_ctmodels()
    Test.@testset "CTModels reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Generated Code Prefix" begin
            Test.@test isdefined(OptimalControl, :CTModels)
            Test.@test isdefined(CurrentModule, :CTModels)
            Test.@test CTModels isa Module
        end

        Test.@testset "Display" begin
            for f in (:plot, :plot!)
                Test.@test isdefined(OptimalControl, f)
                Test.@test isdefined(CurrentModule, f)
                Test.@test getfield(OptimalControl, f) isa Function
            end
        end

        Test.@testset "Init" begin
            for T in (:AbstractInitialGuess, :InitialGuess)
                Test.@testset "$T" begin
                    Test.@test imports(OptimalControl, T, CTModels.Init)
                    Test.@test !isdefined(CurrentModule, T)
                end
            end
            Test.@test reexports(OptimalControl, :build_initial_guess, CTModels.Init)
            Test.@test isdefined(CurrentModule, :build_initial_guess)
        end

        Test.@testset "Serialization" begin
            for f in (:export_ocp_solution, :import_ocp_solution)
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTModels.Serialization)
                    Test.@test isdefined(CurrentModule, f)
                end
            end
        end

        Test.@testset "API Types" begin
            Test.@test imports(OptimalControl, :PreModel, CTModels.Building)
            for T in (:Model, :AbstractModel)
                Test.@test imports(OptimalControl, T, CTModels.Models)
            end
            for T in (:Solution, :AbstractSolution)
                Test.@test imports(OptimalControl, T, CTModels.Solutions)
            end
            for T in (:PreModel, :Model, :AbstractModel, :Solution, :AbstractSolution)
                Test.@test !isdefined(CurrentModule, T)
            end
        end

        Test.@testset "Components accessors" begin
            for f in COMPONENTS
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTModels.Components)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Models accessors" begin
            for f in MODELS
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTModels.Models)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Solutions accessors" begin
            for f in SOLUTIONS
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTModels.Solutions)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end

            Test.@testset "success is not re-exported" begin
                # ⚠️ v2.1.0-beta: `CTModels.Solutions` exports the *name*
                # `success` but defines no method for it — it resolves to bare
                # `Base.success`, which only handles processes and commands.
                # `success(sol)` was therefore always a `MethodError`; the real
                # accessor is `successful`. Same rule as `time`: a name that is
                # really `Base.X` with no CT method is not ours to re-export.
                Test.@test !is_exported(OptimalControl, :success)
                Test.@test getfield(OptimalControl, :success) === Base.success
                Test.@test !any(
                    m -> parentmodule(m) === CTModels.Solutions, methods(Base.success)
                )
                # …whereas `successful` is a real, CTModels-owned accessor.
                Test.@test reexports(OptimalControl, :successful, CTModels.Solutions)
            end
        end

        Test.@testset "Building functions" begin
            for f in BUILDING
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTModels.Building)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "time is Base.time now" begin
            # ⚠️ v2.1.0-beta: `time` is no longer a CTModels function.
            # `CTModels.Components` extends `Base.time` without exporting it,
            # so OptimalControl must not re-export it either — users get it
            # from `Base`, like everyone else.
            Test.@test !is_exported(OptimalControl, :time)
            Test.@test getfield(OptimalControl, :time) === Base.time
            Test.@test !isdefined(CTModels, :time) ||
                getfield(CTModels, :time) === Base.time
            # The extension itself must still be there.
            Test.@test any(
                m -> parentmodule(m) === CTModels.Components, methods(Base.time)
            )
        end

        Test.@testset "traits live in CTBase now" begin
            # Re-exported by CTModels.Models, owned by CTBase.Traits.
            for f in (:is_autonomous, :is_variable, :has_variable, :has_control)
                Test.@test parentmodule(getfield(OptimalControl, f)) === CTBase.Traits
            end
        end

        Test.@testset "Type Hierarchy" begin
            Test.@test OptimalControl.Model <: OptimalControl.AbstractModel
            Test.@test OptimalControl.Solution <: OptimalControl.AbstractSolution
            Test.@test OptimalControl.InitialGuess <: OptimalControl.AbstractInitialGuess
            Test.@test OptimalControl.PreModel isa DataType
        end

        Test.@testset "Method Signatures" begin
            Test.@testset "export_ocp_solution" begin
                Test.@test hasmethod(
                    export_ocp_solution, Tuple{OptimalControl.AbstractSolution}
                )
            end
            Test.@testset "import_ocp_solution" begin
                Test.@test hasmethod(import_ocp_solution, Tuple{OptimalControl.AbstractModel})
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctmodels() = TestCtmodels.test_ctmodels()

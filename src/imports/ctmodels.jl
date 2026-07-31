# CTModels reexports
#
# Re-pointed at the owning submodules (`Components`, `Models`, `Solutions`,
# `Building`, `Init`, `Serialization`), per the Handbook `modules.md` rule.
#
# Two names that used to be here are gone:
#   - `time`    — it is `Base.time`, extended (but not exported) by
#                 `CTModels.Components`. Users get it from `Base`.
#   - `success` — `CTModels.Solutions` exports the name but defines no method
#                 for it, so it resolves to bare `Base.success` (processes and
#                 commands only) and `success(sol)` was always a `MethodError`.
#                 The real accessor is `successful`. Same rule as `time`.
#   - the seven traits (`is_autonomous`, `has_variable`, …) — re-exported by
#     `CTModels.Models` but *owned* by `CTBase.Traits`; see imports/ctbase.jl.

# For internal use
using CTModels: CTModels

# Generated code
@reexport import CTModels: CTModels # for generated code (prefix)

# Display
@reexport import RecipesBase: plot, plot!

# ---------------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------------
import CTModels.Init: AbstractInitialGuess, InitialGuess

@reexport import CTModels.Init: build_initial_guess

# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------
@reexport import CTModels.Serialization: export_ocp_solution, import_ocp_solution

# ---------------------------------------------------------------------------
# api types
# ---------------------------------------------------------------------------
import CTModels.Building: PreModel
import CTModels.Models: Model, AbstractModel
import CTModels.Solutions: Solution, AbstractSolution

# ---------------------------------------------------------------------------
# Components — accessors on the model components
#
# ⚠️ `times` is deliberately CTModels': it returns the `TimesModel`
# *component*. `CTSolvers.Integrators.times` returns an integration grid — a
# genuinely different concept, and one that already has a name here,
# `time_grid`.
# ---------------------------------------------------------------------------
@reexport import CTModels.Components:
    components,
    dimension,
    name,
    index,
    expression,
    criterion,

    # time
    initial_time,
    final_time,
    time_name,
    time_grid,
    times,
    initial_time_name,
    final_time_name,
    has_fixed_initial_time,
    has_free_initial_time,
    has_fixed_final_time,
    has_free_final_time,
    is_initial_time_fixed,
    is_initial_time_free,
    is_final_time_fixed,
    is_final_time_free,

    # cost
    has_mayer_cost,
    has_lagrange_cost,
    is_mayer_cost_defined,
    is_lagrange_cost_defined,
    mayer,
    lagrange,
    objective,

    # trajectory
    state,
    control,
    variable,
    costate,

    # constraint accessors
    path_constraints_nl,
    boundary_constraints_nl,
    state_constraints_box,
    control_constraints_box,
    variable_constraints_box,
    dim_path_constraints_nl,
    dim_boundary_constraints_nl,
    dim_state_constraints_box,
    dim_control_constraints_box,
    dim_variable_constraints_box

# ---------------------------------------------------------------------------
# Models — accessors on the model itself
# ---------------------------------------------------------------------------
@reexport import CTModels.Models:
    constraint,
    constraints,
    definition,
    dynamics,
    has_abstract_definition,
    is_abstractly_defined,
    get_build_examodel,
    state_dimension,
    control_dimension,
    variable_dimension,
    state_name,
    control_name,
    variable_name,
    state_components,
    control_components,
    variable_components

# ---------------------------------------------------------------------------
# Solutions
#
# `status` and `successful` are shared generics: `CTSolvers.Integrators`
# extends the very objects owned here, so one import covers both.
# ---------------------------------------------------------------------------
@reexport import CTModels.Solutions:
    dual,
    iterations,
    status,
    message,
    successful,
    constraints_violation,
    infos,
    is_empty,
    is_empty_time_grid,
    model,

    # Dual constraints accessors
    path_constraints_dual,
    boundary_constraints_dual,
    state_constraints_lb_dual,
    state_constraints_ub_dual,
    control_constraints_lb_dual,
    control_constraints_ub_dual,
    variable_constraints_lb_dual,
    variable_constraints_ub_dual,
    dim_dual_state_constraints_box,
    dim_dual_control_constraints_box,
    dim_dual_variable_constraints_box

# ---------------------------------------------------------------------------
# Building — OCP builder functions (functional API)
# ---------------------------------------------------------------------------
@reexport import CTModels.Building:
    time!,
    state!,
    control!,
    variable!,
    dynamics!,
    objective!,
    constraint!,
    time_dependence!,
    build

# CTModels reexports

# For internal use
using CTModels: CTModels

# Generated code
@reexport import CTModels: CTModels # for generated code (prefix)

# Display
@reexport import RecipesBase: plot, plot!

# Initial guess
import CTModels: AbstractInitialGuess, InitialGuess
@reexport import CTModels: build_initial_guess

# Serialization
@reexport import CTModels: export_ocp_solution, import_ocp_solution

# OCP
import CTModels:

    # api types
    Model,
    AbstractModel,
    Solution,
    AbstractSolution

@reexport import CTModels:

    # accessors
    constraint,
    constraints,
    name,
    dimension,
    components,
    initial_time,
    final_time,
    time_name,
    time_grid,
    times,
    initial_time_name,
    final_time_name,
    criterion,
    has_mayer_cost,
    has_lagrange_cost,
    is_mayer_cost_defined,
    is_lagrange_cost_defined,
    has_fixed_initial_time,
    has_free_initial_time,
    has_fixed_final_time,
    has_free_final_time,
    is_autonomous,
    is_initial_time_fixed,
    is_initial_time_free,
    is_final_time_fixed,
    is_final_time_free,
    state_dimension,
    control_dimension,
    variable_dimension,
    state_name,
    control_name,
    variable_name,
    state_components,
    control_components,
    variable_components,

    # Constraint accessors
    path_constraints_nl,
    boundary_constraints_nl,
    state_constraints_box,
    control_constraints_box,
    variable_constraints_box,
    dim_path_constraints_nl,
    dim_boundary_constraints_nl,
    dim_state_constraints_box,
    dim_control_constraints_box,
    dim_variable_constraints_box,
    state,
    control,
    variable,
    costate,
    objective,
    dynamics,
    mayer,
    lagrange,
    definition,
    dual,
    iterations,
    status,
    message,
    success,
    successful,
    constraints_violation,
    infos,
    get_build_examodel,
    is_empty,
    is_empty_time_grid,
    index,
    time,
    model,

    # Dual constraints accessors
    path_constraints_dual,
    boundary_constraints_dual,
    state_constraints_lb_dual,
    state_constraints_ub_dual,
    control_constraints_lb_dual,
    control_constraints_ub_dual,
    variable_constraints_lb_dual,
    variable_constraints_ub_dual

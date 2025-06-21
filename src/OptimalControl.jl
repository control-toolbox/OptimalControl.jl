"""
OptimalControl module.

List of all the exported names:

$(EXPORTS)
"""
module OptimalControl

using DocStringExtensions

# CTBase
import CTBase: CTBase, ParsingError
export ParsingError

# CTModels
import CTModels:
    CTModels,
    # setters
    variable!,
    time!,
    state!,
    control!,
    dynamics!,
    constraint!,
    objective!,
    definition!,
    time_dependence!,
    # model
    build,
    Model,
    PreModel,
    Solution,
    # getters
    constraints,
    get_build_examodel,
    times,
    definition,
    dual,
    initial_time,
    initial_time_name,
    final_time,
    final_time_name,
    time_name,
    variable_dimension,
    variable_components,
    variable_name,
    state_dimension,
    state_components,
    state_name,
    control_dimension,
    control_components,
    control_name,
    constraint,
    dynamics,
    mayer,
    lagrange,
    criterion,
    has_fixed_final_time,
    has_fixed_initial_time,
    has_free_final_time,
    has_free_initial_time,
    has_lagrange_cost,
    has_mayer_cost,
    is_autonomous,
    export_ocp_solution,
    import_ocp_solution,
    constraint,
    time_grid,
    control,
    state,
    variable,
    costate,
    constraints_violation,
    objective,
    iterations,
    status,
    message,
    infos,
    successful
export Model, Solution
export constraints,
    get_build_examodel,
    times,
    definition,
    dual,
    initial_time,
    initial_time_name,
    final_time,
    final_time_name,
    time_name,
    variable_dimension,
    variable_components,
    variable_name,
    state_dimension,
    state_components,
    state_name,
    control_dimension,
    control_components,
    control_name,
    constraint,
    dynamics,
    mayer,
    lagrange,
    criterion,
    has_fixed_final_time,
    has_fixed_initial_time,
    has_free_final_time,
    has_free_initial_time,
    has_lagrange_cost,
    has_mayer_cost,
    is_autonomous,
    export_ocp_solution,
    import_ocp_solution,
    constraint,
    time_grid,
    control,
    state,
    variable,
    costate,
    constraints_violation,
    objective,
    iterations,
    status,
    message,
    infos,
    successful

# CTParser
import CTParser: CTParser, @def
export @def

# CTDirect
import CTDirect: CTDirect, direct_transcription, set_initial_guess, build_OCP_solution
export direct_transcription, set_initial_guess, build_OCP_solution

# CTFlows
import CTFlows:
    CTFlows,
    VectorField,
    Lift,
    Hamiltonian,
    HamiltonianLift,
    HamiltonianVectorField,
    Flow,
    ⋅,
    Lie,
    Poisson,
    @Lie,
    * # debug: complete?
export VectorField,
    Lift,
    Hamiltonian,
    HamiltonianLift,
    HamiltonianVectorField,
    Flow,
    ⋅,
    Lie,
    Poisson,
    @Lie,
    *

# CommonSolve
import CommonSolve: CommonSolve, solve
export solve
export available_methods
include("solve.jl")

end

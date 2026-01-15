"""
OptimalControl module.

List of all the exported names:

$(EXPORTS)
"""
module OptimalControl

using DocStringExtensions

# CTBase
import CTBase:
    CTBase,
    ParsingError,
    CTException,
    AmbiguousDescription,
    IncorrectArgument,
    IncorrectMethod,
    IncorrectOutput,
    NotImplemented,
    UnauthorizedCall,
    ExtensionError
export ParsingError,
    CTException,
    AmbiguousDescription,
    IncorrectArgument,
    IncorrectMethod,
    IncorrectOutput,
    NotImplemented,
    UnauthorizedCall,
    ExtensionError

# CTParser
import CTParser: CTParser, @def
export @def

function __init__()
    CTParser.prefix_fun!(:OptimalControl)
    CTParser.prefix_exa!(:OptimalControl)
    CTParser.e_prefix!(:OptimalControl)
end

# RecipesBase.plot
import RecipesBase: RecipesBase, plot
export plot

# CTModels
import CTModels:
    CTModels,
    # setters
    variable!,
    time!,
    state!,
    control!,
    dynamics!,
    #    constraint!,
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
    #    constraint,
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
    time_grid,
    control,
    state,
    #    variable,
    costate,
    constraints_violation,
    #    objective,
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
    #    constraint,
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
    time_grid,
    control,
    state,
    #    variable,
    costate,
    constraints_violation,
    #    objective,
    iterations,
    status,
    message,
    infos,
    successful

# CTDirect
import CTDirect:
    CTDirect,
    direct_transcription,
    set_initial_guess,
    build_OCP_solution,
    nlp_model,
    ocp_model
export direct_transcription, set_initial_guess, build_OCP_solution, nlp_model, ocp_model

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

# To trigger CTDirectExtADNLP and CTDirectExtExa
using ADNLPModels: ADNLPModels
import ExaModels:
    ExaModels,
    ExaModel,
    ExaCore,
    variable,
    constraint,
    constraint!,
    objective,
    solution,
    multipliers,
    multipliers_L,
    multipliers_U,
    Constraint

# Conflicts of functions defined in several packages
# ExaModels.variable, CTModels.variable
# ExaModels.constraint, CTModels.constraint
# ExaModels.constraint!, CTModels.constraint!
# ExaModels.objective, CTModels.objective
"""
$(TYPEDSIGNATURES)

See CTModels.variable.
"""
variable(ocp::Model) = CTModels.variable(ocp)

"""
$(TYPEDSIGNATURES)

Return the variable or `nothing`.

```@example
julia> v = variable(sol)
```
"""
variable(sol::Solution) = CTModels.variable(sol)

"""
$(TYPEDSIGNATURES)

Get a labelled constraint from the model. Returns a tuple of the form
`(type, f, lb, ub)` where `type` is the type of the constraint, `f` is the function, 
`lb` is the lower bound and `ub` is the upper bound. 

The function returns an exception if the label is not found in the model.

## Arguments

- `model`: The model from which to retrieve the constraint.
- `label`: The label of the constraint to retrieve.

## Returns

- `Tuple`: A tuple containing the type, function, lower bound, and upper bound of the constraint.
"""
constraint(ocp::Model, label::Symbol) = CTModels.constraint(ocp, label)

"""
$(TYPEDSIGNATURES)

See CTModels.constraint!.
"""
function constraint!(ocp::PreModel, type::Symbol; kwargs...)
    CTModels.constraint!(ocp, type; kwargs...)
end

"""
$(TYPEDSIGNATURES)

See CTModels.objective.
"""
objective(ocp::Model) = CTModels.objective(ocp)

"""
$(TYPEDSIGNATURES)

Return the objective value.
"""
objective(sol::Solution) = CTModels.objective(sol)

export variable, constraint, objective

# CommonSolve
import CommonSolve: CommonSolve, solve
include("solve.jl")
export solve
export available_methods

include("exa_linalg.jl") # debug: just for dev, using OptimalControl.ExaLinAlg

end

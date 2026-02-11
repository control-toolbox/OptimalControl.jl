# To trigger CTDirectExtADNLP and CTDirectExtExa
using ADNLPModels: ADNLPModels

import ExaModels:
    ExaModels #,
#     ExaModel,
#     ExaCore,
#     variable,
#     constraint,
#     constraint!,
#     objective,
#     solution,
#     multipliers,
#     multipliers_L,
#     multipliers_U,
#     Constraint

# # Conflicts of functions defined in several packages
# # ExaModels.variable, CTModels.variable
# # ExaModels.constraint, CTModels.constraint
# # ExaModels.constraint!, CTModels.constraint!
# # ExaModels.objective, CTModels.objective
# """
# $(TYPEDSIGNATURES)

# See CTModels.variable.
# """
# variable(ocp::Model) = CTModels.variable(ocp)

# """
# $(TYPEDSIGNATURES)

# Return the variable or `nothing`.

# ```@example
# julia> v = variable(sol)
# ```
# """
# variable(sol::Solution) = CTModels.variable(sol)

# """
# $(TYPEDSIGNATURES)

# Get a labelled constraint from the model. Returns a tuple of the form
# `(type, f, lb, ub)` where `type` is the type of the constraint, `f` is the function, 
# `lb` is the lower bound and `ub` is the upper bound. 

# The function returns an exception if the label is not found in the model.

# ## Arguments

# - `model`: The model from which to retrieve the constraint.
# - `label`: The label of the constraint to retrieve.

# ## Returns

# - `Tuple`: A tuple containing the type, function, lower bound, and upper bound of the constraint.
# """
# constraint(ocp::Model, label::Symbol) = CTModels.constraint(ocp, label)

# """
# $(TYPEDSIGNATURES)

# See CTModels.constraint!.
# """
# function constraint!(ocp::PreModel, type::Symbol; kwargs...)
#     CTModels.constraint!(ocp, type; kwargs...)
# end

# """
# $(TYPEDSIGNATURES)

# See CTModels.objective.
# """
# objective(ocp::Model) = CTModels.objective(ocp)

# """
# $(TYPEDSIGNATURES)

# Return the objective value.
# """
# objective(sol::Solution) = CTModels.objective(sol)

# export variable, constraint, objective
# Redefine problematic methods
"""
$(TYPEDSIGNATURES)

See CTDirect.discretize.
"""
discretize(ocp::AbstractModel, discretizer::AbstractDiscretizer) = CTDirect.discretize(ocp, discretizer)

"""
$(TYPEDSIGNATURES)

See CTDirect.discretize.
"""
discretize(ocp::AbstractModel; discretizer::AbstractDiscretizer=CTDirect.__discretizer()) = CTDirect.discretize(ocp, discretizer)

"""
$(TYPEDSIGNATURES)

See CTModels.variable.
"""
variable(ocp::Model) = CTModels.variable(ocp)

"""
$(TYPEDSIGNATURES)

See CTModels.variable.
"""
variable(sol::Solution) = CTModels.variable(sol)

"""
$(TYPEDSIGNATURES)

See CTModels.variable.
"""
variable(init::AbstractInitialGuess) = CTModels.variable(init)

"""
$(TYPEDSIGNATURES)

See CTModels.constraint.
"""
constraint(ocp::Model, label::Symbol) = CTModels.constraint(ocp, label)

"""
$(TYPEDSIGNATURES)

See CTModels.objective.
"""
objective(ocp::Model) = CTModels.objective(ocp)

"""
$(TYPEDSIGNATURES)

See CTModels.objective.
"""
objective(sol::Solution) = CTModels.objective(sol)

#
export variable, constraint, objective, discretize
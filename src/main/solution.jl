abstract type AbstractOptimalControlSolution end
#
message_aocs = "method not implemented for solutions of type "
error_aocs(sol::AbstractOptimalControlSolution) = error(message_aocs*String(typeof(sol)))
#
state_dimension(sol::AbstractOptimalControlSolution) = error_aocs(sol)
control_dimension(sol::AbstractOptimalControlSolution) = error_aocs(sol)
time_steps(sol::AbstractOptimalControlSolution) = error_aocs(sol)
steps_dimension(sol::AbstractOptimalControlSolution) = error_aocs(sol)
state(sol::AbstractOptimalControlSolution) = error_aocs(sol)
control(sol::AbstractOptimalControlSolution) = error_aocs(sol)
adjoint(sol::AbstractOptimalControlSolution) = error_aocs(sol)
objective(sol::AbstractOptimalControlSolution) = error_aocs(sol)
iterations(sol::AbstractOptimalControlSolution) = error_aocs(sol)
success(sol::AbstractOptimalControlSolution) = error_aocs(sol)
message(sol::AbstractOptimalControlSolution) = error_aocs(sol)
stopping(sol::AbstractOptimalControlSolution) = error_aocs(sol)
constraints_violation(sol::AbstractOptimalControlSolution) = error_aocs(sol)
# ------------------------------------------------------------------------------------
# Abstract solution
#
abstract type AbstractOptimalControlSolution end

# getters
message_aocs = "method not implemented for solutions of type "
error_aocs(sol::AbstractOptimalControlSolution) = error(message_aocs*String(typeof(sol)))
#
state_dimension(sol::AbstractOptimalControlSolution) = error_aocs(sol)
control_dimension(sol::AbstractOptimalControlSolution) = error_aocs(sol)
time_steps(sol::AbstractOptimalControlSolution) = error_aocs(sol)
time_steps_length(sol::AbstractOptimalControlSolution) = error_aocs(sol)
state(sol::AbstractOptimalControlSolution) = error_aocs(sol)
control(sol::AbstractOptimalControlSolution) = error_aocs(sol)
adjoint(sol::AbstractOptimalControlSolution) = error_aocs(sol)
objective(sol::AbstractOptimalControlSolution) = error_aocs(sol)
iterations(sol::AbstractOptimalControlSolution) = error_aocs(sol)
success(sol::AbstractOptimalControlSolution) = error_aocs(sol)
message(sol::AbstractOptimalControlSolution) = error_aocs(sol)
stopping(sol::AbstractOptimalControlSolution) = error_aocs(sol)
constraints_violation(sol::AbstractOptimalControlSolution) = error_aocs(sol)

# ------------------------------------------------------------------------------------
# Direct solution
#
mutable struct DirectSolution
    T::Vector{<:MyNumber}
    X::Matrix{<:MyNumber}
    U::Matrix{<:MyNumber}
    P::Matrix{<:MyNumber}
    P_ξ::Matrix{<:MyNumber}
    P_ψ::Matrix{<:MyNumber}
    n::Integer
    m::Integer
    N::Integer
    objective::MyNumber
    constraints_violation::MyNumber
    iterations::Integer
    stats       # remove later 
    #type is https://juliasmoothoptimizers.github.io/SolverCore.jl/stable/reference/#SolverCore.GenericExecutionStats
end

# getters
# todo: return all variables on a common time grid
# trapeze scheme case: state and control on all time steps [t0,...,tN], as well as path constraints
# only exception is the costate, associated to the dynamics equality constraints: N values instead of N+1
# we could use the basic extension for the final costate P_N := P_(N-1)  (or linear extrapolation) 
# NB. things will get more complicated with other discretization schemes (time stages on a different grid ...)
# NEED TO CHOOSE A COMMON OUTPUT GRID FOR ALL SCHEMES (note that building the output can be scheme-dependent)
# PM: I propose to use the time steps [t0, ... , t_N]
# - states are ok, and we can evaluate boundary conditions directly
# - control are technically on a different grid (stages) that can coincide with the steps for some schemes.
# Alternately, the averaged control (in the sense of the butcher coefficients) can be computed on each step. cf bocop
# - adjoint are for each equation linking x(t_i+1) and x(t_i), so always N values regardless of the scheme

state_dimension(sol::DirectSolution) = sol.n
control_dimension(sol::DirectSolution) = sol.m
time_steps_length(sol::DirectSolution) = sol.N
time_steps(sol::DirectSolution) = sol.T            
state(sol::DirectSolution) = sol.X
control(sol::DirectSolution) = sol.U
function adjoint(sol::DirectSolution)
    N = sol.N
    n = sol.n
    P = zeros(N+1, n)
    P[1:N,1:n] = sol.P[1:N,1:n]
    # trivial constant extrapolation for p(t_f)
    P[N+1,1:n] = P[N,1:n]
    return P
end
objective(sol::DirectSolution) = sol.objective
constraints_violation(sol::DirectSolution) = sol.constraints_violation  
iterations(sol::DirectSolution) = sol.iterations   

# ------------------------------------------------------------------------------------
# Direct shooting solution
#
struct DirectShootingSolution <: AbstractOptimalControlSolution
    T::TimesDisc # the times
    X::States # the states at the times T
    U::Controls # the controls at T
    P::Adjoints # the adjoint at T
    objective::MyNumber
    state_dimension::Dimension # the dimension of the state
    control_dimension::Dimension # the dimension of the control
    stopping::Symbol # the stopping criterion
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

# getters
state_dimension(sol::DirectShootingSolution) = sol.state_dimension
control_dimension(sol::DirectShootingSolution) = sol.control_dimension
time_steps(sol::DirectShootingSolution) = sol.T
time_steps_length(sol::DirectShootingSolution) = length(time(sol))
state(sol::DirectShootingSolution) = sol.X
control(sol::DirectShootingSolution) = sol.U
adjoint(sol::DirectShootingSolution) = sol.P
objective(sol::DirectShootingSolution) = sol.objective
iterations(sol::DirectShootingSolution) = sol.iterations   
success(sol::DirectShootingSolution) = sol.success
message(sol::DirectShootingSolution) = sol.message
stopping(sol::DirectShootingSolution) = sol.stopping

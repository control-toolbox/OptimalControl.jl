# --------------------------------------------------------------------------------------------------
# Definition of an initialization for the descent method
mutable struct DescentOCPInit <: OptimalControlInit
    U::Controls # the optimization variable U of the ocp for the descent method
end

# --------------------------------------------------------------------------------------------------
# Definition of a solution for the descent method
mutable struct DescentOCPSol <: OptimalControlSolution
    T::Times # the times
    X::States # the states at the times T
    U::Controls # the controls at T
    P::Adjoints # the adjoint at T
    state_dimension::Dimension # the dimension of the state
    control_dimension::Dimension # the dimension of the control
    stopping::Symbol # the stopping criterion at the end of the descent method
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

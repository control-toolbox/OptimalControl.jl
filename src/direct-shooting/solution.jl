# --------------------------------------------------------------------------------------------------
# make a DirectShootingSolution (Unconstrained)

#struct UnconstrainedSolution <: CTOptimizationSolution
#    x::Primal
#    stopping::Symbol
#    message::String
#    iterations::Integer
#end

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
steps_dimension(sol::DirectShootingSolution) = length(time_steps(sol))
state(sol::DirectShootingSolution) = sol.X
control(sol::DirectShootingSolution) = sol.U
adjoint(sol::DirectShootingSolution) = sol.P
objective(sol::DirectShootingSolution) = sol.objective
iterations(sol::DirectShootingSolution) = sol.iterations   
success(sol::DirectShootingSolution) = sol.success
message(sol::DirectShootingSolution) = sol.message
stopping(sol::DirectShootingSolution) = sol.stopping

function DirectShootingSolution(sol::CTOptimization.UnconstrainedSolution,
    ocp::OptimalControlModel, grid::TimesDisc, penalty_constraint::Real)

    # 
    VFN = VectorField{:nonautonomous}

    # parsing ocp
    dy, co, cf, x0, n, m = parse_ocp_direct_shooting(ocp)

    # control solution
    U⁺ = vec2vec(sol.x, m)

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for final constraints
    αₚ = penalty_constraint

    # state flow
    f = Flow(VFN(dy))

    # augmented state flow
    fa = Flow(VFN((t, x, u) -> [dy(t, x[1:end-1], u)[:]; co(t, x[1:end-1], u)]))

    # flow for state-adjoint
    p⁰ = -1.0
    H(t, x, p, u) = p⁰ * co(t, x, u) + p' * dy(t, x, u)
    fh = Flow(Hamiltonian{:nonautonomous}(H))

    # get state and adjoint
    T = grid
    xₙ, _ = model_primal_forward(x0, T, U⁺, f)
    pₙ = p⁰ * αₚ * transpose(Jcf(xₙ)) * cf(xₙ)
    _, _, X⁺, P⁺ = model_adjoint_backward(xₙ, pₙ, T, U⁺, fh)

    # function J, that we minimize
    function J(U::Controls)
        # via augmented system
        xₙ, X = model_primal_forward([x0[:]; 0.0], T, U, fa)
        cost = xₙ[end] + 0.5 * αₚ * norm(cf(xₙ[1:end-1]))^2
        return cost
    end
    objective = J(U⁺)

    return DirectShootingSolution(T, X⁺, U⁺, P⁺, objective, n, m, 
        sol.stopping, sol.message, sol.success, sol.iterations)
   
end
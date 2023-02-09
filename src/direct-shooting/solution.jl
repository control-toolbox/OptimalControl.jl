# --------------------------------------------------------------------------------------------------
# make a DirectShootingSolution (Unconstrained)

#struct UnconstrainedSolution <: CTOptimizationSolution
#    x::Primal
#    stopping::Symbol
#    message::String
#    iterations::Integer
#end

struct DirectShootingSolution # <: AbstractOptimalControlSolution
    T::TimesDisc # the times
    X::States # the states at the times T
    U::Controls # the controls at T
    P::Adjoints # the adjoint at T
    state_dimension::Dimension # the dimension of the state
    control_dimension::Dimension # the dimension of the control
    stopping::Symbol # the stopping criterion
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

function DirectShootingSolution(sol::CTOptimization.UnconstrainedSolution,
    ocp::OptimalControlModel, grid::TimesDisc, penalty_constraint::Real)

    # parsing ocp
    dy, co, cf, x0, n, m = parse_ocp_direct_shooting(ocp)

    # control solution
    U⁺ = vec2vec(sol.x, m)

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for final constraints
    αₚ = penalty_constraint

    # flow for state
    f = Flow(VectorField{:nonautonomous}(dy))

    # flow for state-adjoint
    p⁰ = -1.0
    H(t, x, p, u) = p⁰ * co(t, x, u) + p' * dy(t, x, u)
    fh = Flow(Hamiltonian{:nonautonomous}(H))

    # get state and adjoint
    T = grid
    xₙ, _ = model(x0, T, U⁺, f)
    pₙ = p⁰ * αₚ * transpose(Jcf(xₙ)) * cf(xₙ)
    _, _, X⁺, P⁺ = adjoint(xₙ, pₙ, T, U⁺, fh)

    return DirectShootingSolution(T, X⁺, U⁺, P⁺, n, m, 
        sol.stopping, sol.message, sol.success, sol.iterations)
   
end
# --------------------------------------------------------------------------------------------------
# make an UncFreeXfSolution (Unconstrained) from AbstractOptimalControlSolution
# direct simple shooting

#struct UnconstrainedSolution <: CTOptimizationSolution
#    x::Primal
#    stopping::Symbol
#    message::String
#    iterations::Integer
#end

function make_udss_solution(sol::CTOptimization.UnconstrainedSolution,
    ocp::UncFreeXfProblem, grid::Times, penalty_constraint::Real)

    # ocp data
    dy = ocp.dynamics
    co = ocp.Lagrange_cost
    cf = ocp.final_constraint
    x0 = ocp.initial_condition
    desc = ocp.description

    # control solution
    U⁺ = vec2vec(sol.x, ocp.control_dimension)

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for final constraints
    αₚ = penalty_constraint

    # flow for state
    vf(t, x, u) = isnonautonomous(desc) ? dy(t, x, u) : dy(x, u)
    f = flow(VectorField(vf), :nonautonomous) # we always give a non autonomous Vector Field

    # flow for state-adjoint
    p⁰ = -1.0
    H(t, x, p, u) = isnonautonomous(desc) ? p⁰ * co(t, x, u) + p' * dy(t, x, u) : p⁰ * co(x, u) + p' * dy(x, u)
    fh = flow(Hamiltonian(H), :nonautonomous) # we always give a non autonomous Hamiltonian

    # get state and adjoint
    T = grid
    xₙ, _ = model(x0, T, U⁺, f)
    pₙ = p⁰ * αₚ * transpose(Jcf(xₙ)) * cf(xₙ)
    _, _, X⁺, P⁺ = adjoint(xₙ, pₙ, T, U⁺, fh)

    return UncFreeXfSolution(T, X⁺, U⁺, P⁺, ocp.state_dimension, ocp.control_dimension, 
        sol.stopping, sol.message, sol.success, sol.iterations)
   
end
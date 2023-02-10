function DirectShootingSolution(sol::CTOptimization.UnconstrainedSolution,
    ocp::OptimalControlModel, grid::TimesDisc, penalty_constraint::Real)

    # 
    VFN = VectorField{:nonautonomous}

    # parsing ocp
    dy, co, cf, x0, n, m = parse_ocp_direct_shooting(ocp)

    # control solution
    U⁺ = vec2vec(sol.x, m)

    # Jacobian of the constraints
    Jcf(x) = ctjacobian(cf, x)

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

    return CTBase.DirectShootingSolution(T, X⁺, U⁺, P⁺, objective, n, m, 
        sol.stopping, sol.message, sol.success, sol.iterations)
   
end
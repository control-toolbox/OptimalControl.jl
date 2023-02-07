# --------------------------------------------------------------------------------------------------
# make an CTOptimizationProblem (Unconstrained) from UncFreeXfProblem
# direct simple shooting
function make_udss_problem(ocp::UncFreeXfProblem, grid::TimesDisc, penalty_constraint::Real)

    # ocp data
    dy = ocp.dynamics
    co = ocp.Lagrange_cost
    cf = ocp.final_constraint
    x0 = ocp.initial_condition

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for the final constraints
    αₚ = penalty_constraint

    # state flow
    vf(t, x, u) = isnonautonomous(ocp) ? dy(t, x, u) : dy(x, u)
    f = Flow(VectorField{:nonautonomous}(vf)) # we always give a non autonomous Vector Field

    # augmented state flow
    vfa(t, x, u) = isnonautonomous(ocp) ? [dy(t, x[1:end-1], u)[:]; co(t, x[1:end-1], u)] : [dy(x[1:end-1], u)[:]; co(x[1:end-1], u)]
    fa = Flow(VectorField{:nonautonomous}(vfa)) # we always give a non autonomous Vector Field

    # state-costate flow
    p⁰ = -1.0
    H(t, x, p, u) = isnonautonomous(ocp) ? p⁰ * co(t, x, u) + p' * dy(t, x, u) : p⁰ * co(x, u) + p' * dy(x, u)
    fh = Flow(Hamiltonian{:nonautonomous}(H)) # we always give a non autonomous Hamiltonian

    # to compute the gradient of the function by the adjoint method,
    # we need the partial derivative of the Hamiltonian wrt to the control
    Hu(t, x, p, u) = ∇(u -> H(t, x, p, u), u)

    # discretization grid
    T = grid

    # gradient of the function J
    function ∇J(U::Controls)
        xₙ, _ = model(x0, T, U, f)
        pₙ = p⁰ * αₚ * transpose(Jcf(xₙ)) * cf(xₙ)
        _, _, X, P = adjoint(xₙ, pₙ, T, U, fh)
        g = [-Hu(T[i], X[i], P[i], U[i]) .* (T[i+1] - T[i]) for i in 1:length(T)-1]
        return g
    end
    # vec2vec permet de passer d'un vecteur de vecteur à simplement un vecteur
    ∇J(x::Vector{<:Real}) = vec2vec(∇J(vec2vec(x, ocp.control_dimension))) # for desent solver

    # function J, that we minimize
    L(t, x, u) = isnonautonomous(ocp) ? co(t, x, u) : co(x, u)
    function J(U::Controls)
        # via augmented system
        xₙ, X = model([x0[:]; 0.0], T, U, fa)
        cost = xₙ[end] + 0.5 * αₚ * norm(cf(xₙ[1:end-1]))^2
        return cost
    end
    J(x::Vector{<:Real}) = J(vec2vec(x, ocp.control_dimension)) # for descent solver

    # CTOptimization (Unconstrained) problem
    prob = CTOptimizationProblem(J, gradient=∇J, dimension=length(grid)*ocp.control_dimension)

    return prob

end
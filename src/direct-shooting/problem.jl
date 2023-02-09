# --------------------------------------------------------------------------------------------------
# make an CTOptimizationProblem (Unconstrained) from OptimalControlModel
# direct simple shooting
function CTOptimizationProblem(ocp::OptimalControlModel, grid::TimesDisc, penalty_constraint::Real)

    # 
    VFN = VectorField{:nonautonomous}

    # parsing ocp
    dy, co, cf, x0, n, m = parse_ocp_direct_shooting(ocp)

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for the final constraints
    αₚ = penalty_constraint

    # state flow
    f = Flow(VFN(dy))

    # augmented state flow
    fa = Flow(VFN((t, x, u) -> [dy(t, x[1:end-1], u)[:]; co(t, x[1:end-1], u)]))

    # state-costate flow
    p⁰ = -1.0
    H(t, x, p, u) = p⁰ * co(t, x, u) + p' * dy(t, x, u)
    fh = Flow(Hamiltonian{:nonautonomous}(H))

    # to compute the gradient of the function by the adjoint method,
    # we need the partial derivative of the Hamiltonian wrt to the control
    Hu(t, x, p, u) = ∇(u -> H(t, x, p, u), u)

    # discretization grid
    T = grid

    # gradient of the function J
    function ∇J(U::Controls)
        xₙ, _ = model_primal_forward(x0, T, U, f)
        pₙ = p⁰ * αₚ * transpose(Jcf(xₙ)) * cf(xₙ)
        _, _, X, P = model_adjoint_backward(xₙ, pₙ, T, U, fh)
        g = [-Hu(T[i], X[i], P[i], U[i]) .* (T[i+1] - T[i]) for i in 1:length(T)-1]
        return g
    end
    # vec2vec permet de passer d'un vecteur de vecteur à simplement un vecteur
    ∇J(x::Vector{<:Real}) = vec2vec(∇J(vec2vec(x, ocp.control_dimension))) # for desent solver

    # function J, that we minimize
    function J(U::Controls)
        # via augmented system
        xₙ, X = model_primal_forward([x0[:]; 0.0], T, U, fa)
        cost = xₙ[end] + 0.5 * αₚ * norm(cf(xₙ[1:end-1]))^2
        return cost
    end
    J(x::Vector{<:Real}) = J(vec2vec(x, ocp.control_dimension)) # for descent solver

    # CTOptimization (Unconstrained) problem
    prob = CTOptimizationProblem(J, gradient=∇J, dimension=length(grid)*ocp.control_dimension)

    return prob

end
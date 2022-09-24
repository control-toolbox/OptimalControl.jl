mutable struct SDP
    ∇f::Function
end

function model(x0, T, U, f)
    xₙ = x0
    X = [xₙ]
    for n ∈ range(1, length(T)-1)
        xₙ = f(T[n], xₙ, T[n+1], U[n]); X = hcat(X, [xₙ])
    end
    return xₙ, X
end;

function adjoint(xₙ, pₙ, T, U, f)
    X = [xₙ]; P = [pₙ]
    for n ∈ range(length(T), 2, step=-1)
        xₙ, pₙ = f(T[n], xₙ, pₙ, T[n-1], U[n-1]); X = hcat([xₙ], X); P = hcat([pₙ], P)
    end
    return xₙ, pₙ, X, P
end;

function steepest_descent_ocp(ocp::ROCP; init::Union{Nothing, Vector{<:Number}, Vector{<:Vector{<:Number}}}=nothing, grid_size::Integer=100, 
    penalty_constraint::Number=1e1, iterations::Integer=100, step_length::Number=1e-1)

    # step 1: transcription from ocp to sd problem
    sd_problem, sd_init = ocp2sd(ocp, init, penalty_constraint, grid_size)

    # step 2: resolution of the problem
    sd_solution = sd_solver(sd_problem, sd_init, iterations, step_length)

    # step 3: transcription of the solution
    T, X, U = sd2ocp_solution(sd_solution, grid_size)

    return T, X, U

end

function sd2ocp_solution(sd_solution, grid_size)

    U = sd_solution

    # ocp data
    dy = ocp.dynamics
    t0 = ocp.initial_time
    x0 = ocp.initial_condition
    tf = ocp.final_time    

    f = Flow(VectorField(dy))  
    T = range(t0, tf, grid_size)
    xₙ, X = model(x0, T, U, f)

    return T, X, U

end

function sd_solver(sdp::SDP, init, iterations, step_length)
    # steepest descent solver
    ∇f = sdp.∇f
    α  = step_length
    xᵢ = init
    for i ∈ range(1, iterations)
    xᵢ = xᵢ .- α.*∇f(xᵢ)
    end
    return xᵢ
end

function ocp2sd(ocp::ROCP, init, penalty_constraint, grid_size)

    # ocp data
    dy = ocp.dynamics
    co = ocp.integrand_cost
    cf = ocp.final_constraints
    t0 = ocp.initial_time
    x0 = ocp.initial_condition
    tf = ocp.final_time

    Jcf(x) = J(cf, x)

    # penalty term for final condition
    αₚ = penalty_constraint

    # flows
    f  = Flow(VectorField(dy))
    p⁰ = -1.0; H(x, p, u) = p⁰*co(u)+p'*dy(x, u); fh = Flow(Hamiltonian(H));

    # for adjoint method
    Hu(x, p, u) = ∇(u -> H(x, p, u), u)

    T = range(t0, tf, grid_size)     # discretization grid

    function ∇J(U)
    xₙ, X_ = model(x0, T, U, f)
    pₙ = p⁰*αₚ*transpose(Jcf(xₙ))*cf(xₙ)
    x₀, p₀, X, P = adjoint(xₙ, pₙ, T, U, fh)
    g = [ -Hu(X[i], P[i], U[i]).*(T[i+1]-T[i]) for i=1:length(T)-1 ]
        return g
    end

    # steepest descent problem
    sdp = SDP(∇J)

    return sdp, init

end
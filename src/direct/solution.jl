mutable struct DirectSolution
    T::Vector{<:MyNumber}
    X::Matrix{<:MyNumber}
    U::Matrix{<:MyNumber}
    P::Matrix{<:MyNumber}
    n::Integer
    m::Integer
    N::Integer
end

function DirectSolution(ocp::OptimalControlModel, N::Integer, ipopt_solution)

    # direct_infos
    t0, tf, n_x, m, f, ξ, ψ, ϕ, dim_ξ, dim_ψ, dim_ϕ, 
    has_ξ, has_ψ, has_ϕ, hasLagrangianCost, hasMayerCost, 
    dim_x, nc, dim_xu, f_Mayer = direct_infos(ocp, N)

    function parse_ipopt_sol(stats)
        """
            return
            X : matrix(N+1,n+1)
            U : matrix(N,m)
            P : matrix(N,n+1)
        """
        # states and controls
        xu = stats.solution
        X = zeros(N+1,dim_x)
        U = zeros(N,m)
        for i in 1:N
            X[i,:] =  get_state_at_time_step(xu, i-1, dim_x, N)
            U[i,:] = get_control_at_time_step(xu, i-1, dim_x, N, m)
        end
        X[N+1,:] = get_state_at_time_step(xu, N, dim_x, N)

        # adjoints
        P = zeros(N, dim_x)
        lambda = stats.multipliers
        for i in 1:N
            P[i,:] = lambda[1+(i-1)*dim_x:i*dim_x]
        end
        return X, U, P
    end

    # state, control, adjoint
    X, U, P = parse_ipopt_sol(ipopt_solution)
    
    # times
    T = collect(t0:(tf-t0)/N:tf)

    # DirectSolution
    sol  = DirectSolution(T, X, U, P, n_x, m, N)

    return sol
end
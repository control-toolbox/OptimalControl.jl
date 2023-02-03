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
    stats  #stats::SolverCore.GenericExecutionStats
end

function DirectSolution(ocp::OptimalControlModel, N::Integer, ipopt_solution)

    # direct_infos
    t0, tf_, n_x, m, f, ξ, ψ, ϕ, dim_ξ, dim_ψ, dim_ϕ, 
    has_ξ, has_ψ, has_ϕ, hasLagrangianCost, hasMayerCost, 
    dim_x, nc, dim_xu, f_Mayer, has_free_final_time, criterion = direct_infos(ocp, N)

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
        P_ξ = zeros(N,dim_ξ)
        P_ψ = zeros(N+1,dim_ψ)
        index = 1 # counter for the constraints
        for i ∈ 1:N
            # state equation
            P[i,:] = lambda[index:index+dim_x-1]
            index = index + dim_x
            if has_ξ
                P_ξ[i,:] =  lambda[index:index+dim_ξ-1]
                index = index + dim_ξ
            end
            if has_ψ
                P_ψ[i,:] =  lambda[index:index+dim_ψ-1]
                index = index + dim_ψ
            end
            P_ψ[N+1,:] = lambda[index:index+dim_ψ-1]
        end
        return X, U, P, P_ξ, P_ψ
    end

    # state, control, adjoint
    X, U, P, P_ξ, P_ψ = parse_ipopt_sol(ipopt_solution)
    
    # times
    if has_free_final_time
        tf = stats.solution[end]
    else
        tf = tf_
    end
    T = collect(t0:(tf-t0)/N:tf)

    # DirectSolution
    sol  = DirectSolution(T, X, U, P, P_ξ, P_ψ, n_x, m, N, ipopt_solution)

    return sol
end
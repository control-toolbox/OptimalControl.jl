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
    objective::MyNumber
    constraints_violation::MyNumber
    iterations::Integer
    stats       # remove later 
    #type is https://juliasmoothoptimizers.github.io/SolverCore.jl/stable/reference/#SolverCore.GenericExecutionStats
end


# getters
# todo: return all variables on a common time grid
# trapeze scheme case: state and control on all time steps [t0,...,tN], as well as path constraints
# only exception is the costate, associated to the dynamics equality constraints: N values instead of N+1
# we could use the basic extension for the final costate P_N := P_(N-1)  (or linear extrapolation) 
# NB. things will get more complicated with other discretization schemes (time stages on a different grid ...)
# NEED TO CHOOSE A COMMON OUTPUT GRID FOR ALL SCHEMES (note that building the output can be scheme-dependent)
# PM: I propose to use the time steps [t0, ... , t_N]
# - states are ok, and we can evaluate boundary conditions directly
# - control are technically on a different grid (stages) that can coincide with the steps for some schemes.
# Alternately, the averaged control (in the sense of the butcher coefficients) can be computed on each step. cf bocop
# - adjoint are for each equation linking x(t_i+1) and x(t_i), so always N values regardless of the scheme

state_dimension(sol::DirectSolution) = sol.n
control_dimension(sol::DirectSolution) = sol.m
steps_dimension(sol::DirectSolution) = sol.N
time_steps(sol::DirectSolution) = sol.T            
state(sol::DirectSolution) = sol.X
control(sol::DirectSolution) = sol.U
function adjoint(sol::DirectSolution)
    N = sol.N
    n = sol.n
    P = zeros(N+1, n)
    P[1:N,1:n] = sol.P[1:N,1:n]
    # trivial constant extrapolation for p(t_f)
    P[N+1,1:n] = P[N,1:n]
    return P
end
objective(sol::DirectSolution) = sol.objective
constraints_violation(sol::DirectSolution) = sol.constraints_violation  
iterations(sol::DirectSolution) = sol.iterations   
    

function DirectSolution(ocp::OptimalControlModel, N::Integer, ipopt_solution)

    # direct_infos
    t0, tf_, n_x, m, f, ξ, ψ, ϕ, dim_ξ, dim_ψ, dim_ϕ, 
    has_ξ, has_ψ, has_ϕ, hasLagrangeCost, hasMayerCost, 
    dim_x, nc, dim_xu, g, f_Mayer, has_free_final_time, criterion = direct_infos(ocp, N)

    function parse_ipopt_sol(stats)
        
        # states and controls
        xu = stats.solution
        X = zeros(N+1,dim_x)
        U = zeros(N+1,m)
        for i in 1:N+1
            X[i,:] = get_state_at_time_step(xu, i-1, dim_x, N)
            U[i,:] = get_control_at_time_step(xu, i-1, dim_x, N, m)
        end

        # adjoints
        P = zeros(N, dim_x)
        lambda = stats.multipliers
        P_ξ = zeros(N+1,dim_ξ)
        P_ψ = zeros(N+1,dim_ψ)
        index = 1 # counter for the constraints
        for i ∈ 1:N
            # state equation
            P[i,:] = lambda[index:index+dim_x-1]            # use getter
            index = index + dim_x
            if has_ξ
                P_ξ[i,:] =  lambda[index:index+dim_ξ-1]      # use getter
                index = index + dim_ξ
            end
            if has_ψ
                P_ψ[i,:] =  lambda[index:index+dim_ψ-1]      # use getter
                index = index + dim_ψ
            end
        end
        if has_ξ
            P_ξ[N+1,:] =  lambda[index:index+dim_ξ-1]        # use getter
            index = index + dim_ξ
        end
        if has_ψ
            P_ψ[N+1,:] =  lambda[index:index+dim_ψ-1]         # use getter
            index = index + dim_ψ
        end
        return X, U, P, P_ξ, P_ψ
    end

    # state, control, adjoint
    X, U, P, P_ξ, P_ψ = parse_ipopt_sol(ipopt_solution)
    
    # times
    tf = get_final_time(ipopt_solution.solution, tf_, has_free_final_time)
    T = collect(LinRange(t0, tf, N+1))
    
    # misc info
    objective = ipopt_solution.objective
    constraints_violation = ipopt_solution.primal_feas
    iterations = ipopt_solution.iter
    #status = ipopt_solution.status this is a 'Symbol' not an int...
        
    # DirectSolution
    #sol  = DirectSolution(T, X, U, P, P_ξ, P_ψ, n_x, m, N, ipopt_solution)
    sol  = DirectSolution(T, X, U, P, P_ξ, P_ψ, n_x, m, N, objective, constraints_violation, iterations, ipopt_solution)     

    return sol
end

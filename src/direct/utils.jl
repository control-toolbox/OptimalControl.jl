function get_state_at_time_step(xu, i, dim_x, N)
    """
        return
        x(t_i)
    """
    if i > N
        error("trying to access at x(t_i) for i > N")
    end  
    return xu[1+i*dim_x:(i+1)*dim_x]
end

function get_control_at_time_step(xu, i, dim_x, N, m)
    """
        return
        u(t_i)
    """
    if i > N
        error("trying to access at (t_i) for i > N")
    end
    return xu[1+(N+1)*dim_x+i*m:m+(N+1)*dim_x+i*m]
end

get_final_time(xu, tf_, has_free_final_time) = has_free_final_time ? xu[end] : tf_

function direct_infos(ocp::OptimalControlModel, N::Integer)

    # Parameters of the Optimal Control Problem
    # times
    t0 = ocp.initial_time
    tf = ocp.final_time
    has_free_final_time = isnothing(tf)
        # multiplier la dynamique par (tf-t0)
        # travailler avec le nouveau temps s dans (0., 1.)
        # une fonction t(s)
    # dimensions
    n_x = ocp.state_dimension
    m = ocp.control_dimension
    # dynamics
    f = ocp.dynamics
    # constraints
    ξ, ψ, ϕ = OptimalControl.nlp_constraints(ocp)
    dim_ξ = length(ξ[1])      # dimension of the boundary constraints
    dim_ψ = length(ψ[1])
    dim_ϕ = length(ϕ[1])
    has_ξ = !isempty(ξ[1])
    has_ψ = !isempty(ψ[1])
    has_ϕ = !isempty(ϕ[1])

    #println("has_ξ = ", has_ξ)
    #println("has_ψ = ", has_ψ)
    #println("has_ϕ = ", has_ϕ)

    hasLagrangeCost = !isnothing(ocp.lagrange)
    L = ocp.lagrange

    hasMayerCost = !isnothing(ocp.mayer)
    g = ocp.mayer
    #println("hasLagrange : ", hasLagrangeCost)
    #println("Mayer = ", hasMayerCost)

    # Mayer formulation
    # use an additional state for the Lagrange cost
    #
    # remark : we pass u[1] because in our case ocp.dynamics and ocp.lagrange are defined with a scalar u
    # and we consider vectors for x and u in the discretized problem. Note that the same would apply for a scalar x.
    # question : how determine if u and x are scalar or vector ?
    # second member of the ode for the Mayer formulation

    if hasLagrangeCost
        dim_x = n_x + 1  
        nc = N*(dim_x+dim_ξ+dim_ψ) + (dim_ξ + dim_ψ) + dim_ϕ + 1       # dimension of the constraints            
      else
        dim_x = n_x  
        nc = N*(dim_x+dim_ξ+dim_ψ) + (dim_ξ + dim_ψ) + dim_ϕ       # dimension of the constraints
    end

    dim_xu = (N+1)*(dim_x+m)  # dimension the the unknown xu
    has_free_final_time ? dim_xu = dim_xu + 1 : nothing

    # todo: cas vectoriel sur u a ajouter
    f_Mayer(x, u) = hasLagrangeCost ? [f(x[1:n_x], u[1]); L(x[1:n_x], u[1])] : f(x,u[1])

    criterion = ocp.criterion

    return t0, tf, n_x, m, f, ξ, ψ, ϕ, dim_ξ, dim_ψ, dim_ϕ, 
    has_ξ, has_ψ, has_ϕ, hasLagrangeCost, hasMayerCost, dim_x, nc, dim_xu, 
    g, f_Mayer, has_free_final_time, criterion

end

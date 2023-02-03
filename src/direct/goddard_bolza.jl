
function solve(ocp::OptimalControlModel,N)
  """
    Solve the optimal control problem

    Input : 
    ocp : functional description of the optimal control problem (cf. ocp.jl)
    N   : number of time steps for the discretization
          Int
    
    Output
    sol : solution of the discretized problem
          (time, X, U, n, m, N)
  """




  #function constraint(ocp, xu::Vector{<:Real},N)::Vector{<:Real}
  function constraint(ocp, xu, N)
    """
    compute the constraints for the NLP : 
      - discretization of the dynamics via the Euler method
      - boundary conditions
    inputs
    ocp :: ocp model
    xu :: 
      layout of the nlp unknown xu for Euler discretization 
      additional state variable x_{n+1}(t) for the objective (Lagrange to Mayer formulation)
      [x_1(t_0), ... , x_{n+1}(t_0),
      ... , 
      x_{1}(t_N), ... , x_{n+1}(t_N),
      u_1(t_0), ... , u_m(t_0), 
      ... , 
      u_m(t_{N-1}), ..., u_m(t_{N-1})]
    return
    c :: 
    """

  # bounds for the constraints
  function  l_u_b(ocp,xu,N)
    lb = zeros(nc)
    ub = zeros(nc)

    index = 1 # counter for the constraints
    for i in 0:N-1
      # state and control at the current state
      xi = get_state_at_time_step(xu,i)
      ui = get_control_at_time_step(xu,i)
      # state equation
      #c[index:index+dim_x-1] = xip1 - (xi + h*f_Mayer(xi, ui))
      index = index + dim_x
      if has_ξ
        lb[index:index+dim_ξ-1] = ξ[1]
        ub[index:index+dim_ξ-1] = ξ[3]
        index = index + dim_ξ
      end
      if has_ψ
        lb[index:index+dim_ψ-1] = ψ[1]
        ub[index:index+dim_ψ-1] = ψ[3]
        index = index + dim_ψ
      end
    end  
    if has_ψ
      lb[index:index+dim_ψ-1] = ψ[1]
      ub[index:index+dim_ψ-1] = ψ[3]
      index = index + dim_ψ
    end
    # boundary conditions
    lb[index:index+dim_ϕ-1] = ϕ[1]
    ub[index:index+dim_ϕ-1] = ϕ[3]
    index = index + dim_ϕ
    if hasLagrangianCost
      lb[index] = 0.
      ub[index] = 0.
      index = index + 1
    end

    return lb, ub
  end

  xu0 = 1.1*ones(dim_xu)
  l_var = -Inf*ones(dim_xu)
  u_var = Inf*ones(dim_xu)

  if has_free_final_time
    xu0[end] = 1.
    l_var[end] = 1.e-3
  end


  lb, ub = l_u_b(ocp,xu0,N)
  constraint_Ipopt(xu) = constraint(ocp,xu,N)

 # println("length(lb) = ", length(lb))
 # println("length(ub) = ", length(ub))
 # println("length(constraint) = ", length( constraint_Ipopt(xu0)))

  nlp = ADNLPModel(xu -> objective(ocp,xu,N), xu0, l_var, u_var, xu -> constraint(ocp,xu,N),lb,ub)
  stats = ipopt(nlp, print_level=5)
  X, U, P, P_ξ, P_ψ = parse_sol(stats)
  t0 = ocp.initial_time
  if has_free_final_time
    tf = stats.solution[end]
  else
    tf = ocp.final_time
  end
  time = collect(t0:(tf-t0)/N:tf)
  sol  = direct_sol(time,X,U,P,P_ξ,P_ψ,n_x,m,N,stats)
return sol
end



function plot(sol::direct_sol)
  """
     Plot the solution

     input
       sol : direct_sol
  """
  time = sol.time
  X = sol.X
  U = sol.U
  P = sol.P
  n = sol.n
  m = sol.m
  N = sol.N
  px = Plots.plot(time, X,layout = (n,1))
  Plots.plot!(px[1],title="state")
  Plots.plot!(px[n], xlabel="t")
  for i in 1:n
    Plots.plot!(px[i],ylabel = string("x_",i))
  end

  pp = Plots.plot(time[1:N], P,layout = (n,1))
  Plots.plot!(pp[1],title="costate")
  Plots.plot!(pp[n], xlabel="t")
  for i in 1:n
    Plots.plot!(pp[i],ylabel = string("p_",i))
  end

  pu = Plots.plot(time[1:N],U,lc=:red,layout = (m,1))
  for i in 1:m
    Plots.plot!(pu[i],ylabel = string("u_",i))
  end
  Plots.plot!(pu[1],title = "control")
  Plots.plot!(pu[m],xlabel = "t")

  Plots.plot(px,pp,pu,layout = (1,3),legend = false)
end



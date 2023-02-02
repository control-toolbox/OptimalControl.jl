# Module

mutable struct direct_sol
  time::Vector{<:Real}
  X::Matrix{<:Real}
  U::Matrix{<:Real}
  P::Matrix{<:Real}
  n::Int
  m::Int
  N::Int
  #stats::SolverCore.GenericExecutionStats
end




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

  t0 = ocp.initial_time
  tf = ocp.final_time


  n_x = ocp.state_dimension
  m = ocp.control_dimension
  f = ocp.dynamics

  ξ, ψ, ϕ = OptimalControl.nlp_constraints(ocp)
  dim_ξ = length(ξ[1])      # dimension of the boundary constraints
  dim_ψ = length(ψ[1])
  dim_ϕ = length(ϕ[1])

  if isempty(ξ[1])
    has_ξ = false
  else
    has_ξ = true
  end

  if isempty(ψ[1])
    has_ψ = false
  else
    has_ψ = true
  end

  if isempty(ϕ[1])
    has_ϕ = false
  else
    has_ϕ = true
  end

  println("has_ξ = ", has_ξ)
  println("has_ψ = ", has_ψ)
  println("has_ϕ = ", has_ϕ)


  if isnothing(ocp.lagrangian)
    hasLagrangianCost = false
  else
    hasLagrangianCost = true
    L = ocp.lagrangian
  end  

  if isnothing(ocp.mayer)
    hasMayerCost = false
  else
    hasMayerCost = true
    g = ocp.mayer
  end  
  println("hasLagrangien : ", hasLagrangianCost)
  println("Mayer = ", hasMayerCost)


  # Mayer formulation
  # use an additional state for the Lagrangian cost
  #
  # remark : we pass u[1] because in our case ocp.dynamics and ocp.lagrange are defined with a scalar u
  # and we consider vectors for x and u in the discretized problem. Note that the same would apply for a scalar x.
  # question : how determine if u and x are scalar or vector ?
  # second member of the ode for the Mayer formulation
  


  if hasLagrangianCost
    dim_x = n_x + 1  
    nc = N*(dim_x+dim_ξ+dim_ψ) + dim_ϕ + 1        # dimension of the constraints            
  else
    dim_x = n_x  
    nc = N*(dim_x+dim_ξ+dim_ψ) + dim_ϕ        # dimension of the constraints
  end

  dim_xu = (N+1)*(n_x+1)+N*m                  # dimension the the unknown xu


  function f_Mayer(x,u)
    if hasLagrangianCost
      f_val = [f(x[1:n_x],u[1]); L(x[1:n_x],u[1])]
    else
      f_val = f(x,u[1])
    end
    return f_val
  end

  # layout of the nlp unknown xu for Euler discretization 
  # additional state variable x_{n+1}(t) for the objective (Lagrange to Mayer formulation)
  # [x_1(t_0), ... , x_{n+1}(t_0),
  #  ... , 
  #  x_{1}(t_N), ... , x_{n+1}(t_N),
  #  u_1(t_0), ... , u_m(t_0), 
  #  ... , 
  #  u_m(t_{N-1}), ..., u_m(t_{N-1})]
  #  tf if free




  function get_state_at_time_step(xu,i)
    """
      return
      x(t_i)
    """
    if i > N
      error("trying to access at x(t_i) for i > N")
    end  
    return xu[1+i*dim_x:(i+1)*dim_x]
  end

  function get_control_at_time_step(xu,i)
    """
      return
      u(t_i)
    """
    if i > N-1
      error("trying to access at (t_i) for i > N-1")
    end
    return xu[1+(N+1)*dim_x+i*m:m+(N+1)*dim_x+i*m]
  end

  function parse_sol(stats)
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
        X[i,:] =  get_state_at_time_step(xu,i-1)
        U[i,:] = get_control_at_time_step(xu,i-1)
      end
      X[N+1,:] = get_state_at_time_step(xu,N)

      # adjoints
      P = zeros(N,dim_x)
      lambda = stats.multipliers
      for i in 1:N
        P[i,:] = lambda[1+(i-1)*dim_x:i*dim_x]
      end
    return X, U, P
  end

 

  function objective(ocp, xu, N)
    
    obj = 0.
    if hasMayerCost
      x0 = get_state_at_time_step(xu,0)
      xf = get_state_at_time_step(xu,N)
      obj = obj + g(t0, x0[1:n_x], tf, xf[1:n_x])
    end
    if hasLagrangianCost
      obj = obj + xu[(N+1)*dim_x]
    end
    return obj
  end

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
      t0 = ocp.initial_time
      tf = ocp.final_time
      h = (tf-t0)/N
      c = zeros(eltype(xu),nc)
      #
      # state equation

      index = 1 # counter for the constraints
      for i in 0:N-1
        # state and control at the current state
        xi = get_state_at_time_step(xu,i)
        xip1 = get_state_at_time_step(xu,i+1)
        ui = get_control_at_time_step(xu,i)
        # state equation
        c[index:index+dim_x-1] = xip1 - (xi + h*f_Mayer(xi, ui))
        index = index + dim_x
        if has_ξ
          c[index:index+dim_ξ-1] = ξ[2](ui)        # ui vector
          index = index + dim_ξ
        end
        if has_ψ
          c[index:index+dim_ψ-1] = ψ[2](xi[1:n_x],ui)        # ui vector
          index = index + dim_ψ
        end

      end

      # boundary conditions
      # -------------------
      x0 = get_state_at_time_step(xu,0)
      xf = get_state_at_time_step(xu,N)
      
      c[index:index+dim_ϕ-1] = ϕ[2](t0,x0[1:n_x],tf,xf[1:n_x])  # because Lagrangian cost possible
      index = index + dim_ϕ
      if hasLagrangianCost
        c[index] = xu[dim_x]
        index = index + 1
      end
  
      return c
  end




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

  xu0 = zeros(dim_xu)





  lb, ub = l_u_b(ocp,xu0,N)
  constraint_Ipopt(xu) = constraint(ocp,xu,N)

  nlp = ADNLPModel(xu -> objective(ocp,xu,N), xu0, xu -> constraint(ocp,xu,N),lb,ub)
  stats = ipopt(nlp, print_level=3)
  X, U, P = parse_sol(stats)
  t0 = ocp.initial_time
  tf = ocp.final_time
  time = collect(t0:(tf-t0)/N:tf)
  sol  = direct_sol(time,X,U,P,n_x,m,N)
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
  px = Plots.plot(time, X,layout = (n+1,1))
  Plots.plot!(px[1],title="state")
  Plots.plot!(px[n+1], xlabel="t")
  for i in 1:n+1
    Plots.plot!(px[i],ylabel = string("x_",i))
  end

  pp = Plots.plot(time[1:N], P,layout = (n+1,1))
  Plots.plot!(pp[1],title="costate")
  Plots.plot!(pp[n+1], xlabel="t")
  for i in 1:n+1
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



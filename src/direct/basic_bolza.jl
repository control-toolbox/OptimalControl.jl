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
  # transcription ocp -> NLP
  n_x = ocp.state_dimension
  m = ocp.control_dimension
  f = ocp.dynamics



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
  #x0 = get_state_at_time_step(xu,0)
    
  #xf = get_state_at_time_step(xu,N)
  t0 = ocp.initial_time
  tf = ocp.final_time

  println(g(t0, [-1., 0], tf, [0.,0.]))

   # Mayer formulation
  # use an additional state for the Lagrangian cost
  #
  # remark : we pass u[1] because in our case ocp.dynamics and ocp.lagrange are defined with a scalar u
  # and we consider vectors for x and u in the discretized problem. Note that the same would apply for a scalar x.
  # question : how determine if u and x are scalar or vector ?
  # second member of the ode for the Mayer formulation

  if hasLagrangianCost
    dim_x = n_x + 1
    nc = N*dim_x+2*n_x+1               # dimension of the constraints
  else
    dim_x = n_x
    nc = N*dim_x+2*n_x               # dimension of the constraints
  end

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
      t0 = ocp.initial_time
      tf = ocp.final_time
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
      n = ocp.state_dimension
      m = ocp.control_dimension
      nc = N*(n+1)+2*n+1               # dimension of the constraints

      #x0 = ocp.initial_condition
      #xf = ocp.final_condition                                                   
      x0 = [-1., 0.]
      xf = [0., 0.]

      h = (tf-t0)/N
      c = zeros(eltype(xu),nc)
      for i in 0:N-1
        xi = get_state_at_time_step(xu,i)
        xip1 = get_state_at_time_step(xu,i+1)
        ui = get_control_at_time_step(xu,i)
        c[1+i*dim_x:(i+1)*dim_x] = xip1 - (xi + h*f_Mayer(xi, ui))
      end

      c[1+N*dim_x:n_x+N*dim_x] = xu[1:n_x] - x0
      c[n_x+1+N*dim_x:2*n_x+N*dim_x] = xu[1+N*dim_x:n_x+N*dim_x] - xf
      if hasLagrangianCost
        c[2*n_x+1+N*dim_x] = xu[dim_x]
      end
  
      return c
  end




  # bounds for the constraints
  lb = zeros(nc)
  ub = zeros(nc)

  constraint_Ipopt(xu) = constraint(ocp,xu,N)
  xu0 = zeros((N+1)*(n_x+1)+N*m)  
  #println(get_state_at_time_step(xu0,1))

  #nlp = ADNLPModel(objective, xu0, constraint_Ipopt,lb,ub)
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



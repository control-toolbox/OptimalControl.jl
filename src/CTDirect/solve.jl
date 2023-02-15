function direct_solve(ocp::OptimalControlModel, 
  #algo::DirectAlgorithm, 
  method::Description;
  grid_size::Integer=__grid_size_direct(),
  print_level::Integer=__print_level_ipopt(),
  mu_strategy::String=__mu_strategy_ipopt(),
  display::Bool=__display(),
  init=nothing,  #NB. for now, can be nothing or (n+m) vector
  kwargs...)
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

  # no display
  print_level = display ?  print_level : 0

  # from OCP to NLP
  nlp = ADNLProblem(ocp, grid_size, init)
  #println("nlp x0:", nlp.meta.x0)

  # solve by IPOPT: more info at 
  # https://github.com/JuliaSmoothOptimizers/NLPModelsIpopt.jl/blob/main/src/NLPModelsIpopt.jl#L119
  # options of ipopt: https://coin-or.github.io/Ipopt/OPTIONS.html
  # callback: https://github.com/jump-dev/Ipopt.jl#solver-specific-callback
  ipopt_solution = ipopt(nlp, print_level=print_level, mu_strategy=mu_strategy; kwargs...)

  # from IPOPT solution to DirectSolution
  sol = DirectSolution(ocp, grid_size, ipopt_solution)

  return sol

end

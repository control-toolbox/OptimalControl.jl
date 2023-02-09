function solve(ocp::OptimalControlModel, algo::Direct, method::Description;
  grid_size::Integer=__grid_size_direct(),
  print_level::Integer=__print_level_ipopt(),
  mu_strategy::String=__mu_strategy_ipopt(),
  display::Bool=__display(),
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
  print_level = display ?  0 : print_level

  # from OCP to NLP
  nlp = ADNLProblem(ocp, grid_size)

  # solve by IPOPT
  ipopt_solution = ipopt(nlp, print_level=print_level, mu_strategy=mu_strategy; kwargs...)

  # from IPOPT solution to DirectSolution
  sol = DirectSolution(ocp, grid_size, ipopt_solution)

  return sol

end

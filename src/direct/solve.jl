function solve(ocp::OptimalControlModel, N::Integer=100)
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
    
      # from OCP to NLP
      nlp = DirectProblem(ocp, N)
    
      # solve by IPOPT
      ipopt_solution = ipopt(nlp, print_level=3)

      # from IPOPT solution to DirectSolution
      sol = DirectSolution(ocp, N, ipopt_solution)
    
    return sol
    
    end
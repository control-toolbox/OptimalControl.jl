function Plots.plot(sol::DirectSolution)
  """
      Plot the solution

      input
        sol : direct_sol
  """
    
  # retrieve info from direct solution
  n = Direct_solution_state_dimension(sol)
  m = Direct_solution_control_dimension(sol)
  N = Direct_solution_steps_dimension(sol)    
  T = Direct_solution_time_steps(sol) 
  X = Direct_solution_state(sol)
  U = Direct_solution_control(sol)
  P = Direct_solution_adjoint(sol)
  obj = Direct_solution_objective(sol)
  cons = Direct_solution_constraints_violation(sol)
  iter = Direct_solution_iterations(sol)
    
  println("Objective: ",obj," Constraints: ",cons," Iterations: ",iter)
    
  # state (plot actual state from ocp ie mask additional state for lagrange cost if present)
  # use option for layout 'columns' or 'rows' ?
  #px = Plots.plot(T, X[:,1:n], layout=(n,1))
  px = Plots.plot(T, X[:,1:n], layout=(1,n))    
  Plots.plot!(px[1], title="state")
  Plots.plot!(px[n], xlabel="t")
  for i ∈ 1:n
    Plots.plot!(px[i], ylabel=string("x_",i))
  end

  # costate
  #pp = Plots.plot(T[1:N], P[:,1:n],layout = (n,1))
  pp = Plots.plot(T[1:N], P[:,1:n],layout = (1,n))    
  Plots.plot!(pp[1], title="costate")
  Plots.plot!(pp[n], xlabel="t")
  for i ∈ 1:n
    Plots.plot!(pp[i], ylabel=string("p_",i))
  end

  # control
  #pu = Plots.plot(T, U, lc=:red, layout=(m,1))
  pu = Plots.plot(T, U, lc=:red, layout=(1,m))  
  for i ∈ 1:m
    Plots.plot!(pu[i], ylabel=string("u_",i))
  end
  Plots.plot!(pu[1], title="control")
  Plots.plot!(pu[m], xlabel="t")

  # main plot
  #Plots.plot(px, pp, pu, layout=(1,3), legend=false) #column layout
  Plots.plot(px, pp, pu, layout=(3,1), legend=false) #row layout

end
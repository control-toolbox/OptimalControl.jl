function Plots.plot(sol::DirectSolution)
  """
      Plot the solution

      input
        sol : direct_sol
  """
  T = sol.T
  X = sol.X
  U = sol.U
  P = sol.P
  n = sol.n
  m = sol.m
  N = sol.N

  # state
  px = Plots.plot(time, X, layout=(n,1))
  Plots.plot!(px[1], title="state")
  Plots.plot!(px[n], xlabel="t")
  for i ∈ 1:n
    Plots.plot!(px[i], ylabel=string("x_",i))
  end

  # costate
  pp = Plots.plot(time[1:N], P,layout = (n,1))
  Plots.plot!(pp[1], title="costate")
  Plots.plot!(pp[n], xlabel="t")
  for i ∈ 1:n
    Plots.plot!(pp[i], ylabel=string("p_",i))
  end

  # control
  pu = Plots.plot(time[1:N], U, lc=:red, layout=(m,1))
  for i ∈ 1:m
    Plots.plot!(pu[i], ylabel=string("u_",i))
  end
  Plots.plot!(pu[1], title="control")
  Plots.plot!(pu[m], xlabel="t")

  # main plot
  Plots.plot(px, pp, pu, layout=(1,3), legend=false)

end
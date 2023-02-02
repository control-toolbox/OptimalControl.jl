using OptimalControl, NLPModelsIpopt, ADNLPModels
using Plots
ocp = Model()
#
state!(ocp, 2)
control!(ocp, 1)
#
time!(ocp, [0., 1.])
#
constraint!(ocp, :initial, [ -1., 0. ])
constraint!(ocp, :final,   [  0., 0. ])
#
A = [ 0. 1.
      0. 0.]
B = [ 0.
      1. ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
#
objective!(ocp, :lagrangian, (x, u) -> 0.5*u^2) # default is to minimise

include("basic_lagrange.jl")

sol = solve(ocp,100)
#println(sol)
plot_sol(sol)


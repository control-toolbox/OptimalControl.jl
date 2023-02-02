using OptimalControl
using NLPModelsIpopt, ADNLPModels
#using Plots
import Plots: plot

include("basic_bolza.jl") 

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
objective!(ocp, :mayer, (t0, x0, tf, xf) -> 1.) # for test if there is a Mayer cost

sol = solve(ocp,100)
#println(sol)
plot(sol)


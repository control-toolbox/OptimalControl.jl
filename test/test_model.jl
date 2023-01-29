t0 = 0.
tf = 1.

ocp = Model()

#
time!(ocp, (t0, tf))

@test typeof(ocp) == OptimalControlModel
@test ocp.initial_time == t0
@test ocp.final_time == tf

#
constraint!(ocp, :Initial, [ -1., 0. ])
constraint!(ocp, :Final,   [  0., 0. ])

@test ocp.initial_condition ≈ [-1.; 0.] atol = 1e-8
@test ocp.final_condition ≈ [0.; 0.] atol = 1e-8

#
A = [ 0. 1.
      0. 0.]
B = [ 0.
      1. ]

constraint!(ocp, :Dynamics, (x, u) -> A*x + B*u)
@test ocp.dynamics([0.; 1.], 1.0) ≈ [1.; 1.] atol=1e-8

#
objective!(ocp, :Lagrangian, (x, u) -> 0.5*u^2) # default is to minimise
@test ocp.Lagrange([0.; 0.], 1.0) ≈ 0.5 atol=1e-8

# from model to problem
# tbd
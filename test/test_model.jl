t0 = 0.
tf = 1.

ocp = Model()

#
state!(ocp, 2)
control!(ocp, 1)
@test ocp.state_dimension == 2
@test ocp.control_dimension == 1

#
time!(ocp, [t0, tf])

@test typeof(ocp) == OptimalControlModel
@test ocp.initial_time == t0
@test ocp.final_time == tf

#
constraint!(ocp, :initial, [ -1., 0. ])
constraint!(ocp, :final,   [  0., 0. ])

@test ocp.initial_condition ≈ [-1.; 0.] atol = 1e-8
@test ocp.final_condition ≈ [0.; 0.] atol = 1e-8

#
A = [ 0. 1.
      0. 0.]
B = [ 0.
      1. ]

constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
@test ocp.dynamics([0.; 1.], 1.0) ≈ [1.; 1.] atol=1e-8

#
objective!(ocp, :lagrangian, (x, u) -> 0.5*u^2) # default is to minimise
@test ocp.lagrange([0.; 0.], 1.0) ≈ 0.5 atol=1e-8

# from model to problem
# tbd
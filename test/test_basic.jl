t0 = 0.
tf = 1.

ocp = Model()

#
state!(ocp, 2)   # dimension of the state
control!(ocp, 1) # dimension of the control
time!(ocp, [t0, tf])
constraint!(ocp, :initial, [ -1.0, 0.0 ])
constraint!(ocp, :final,   [  0.0, 0.0 ])

#
A = [ 0.0 1.0
      0.0 0.0 ]
B = [ 0.0
      1.0 ]

constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
objective!(ocp, :lagrangian, (x, u) -> 0.5*u^2) # default is to minimise

#
@test ocp.state_dimension == 2
@test ocp.control_dimension == 1
@test typeof(ocp) == OptimalControlModel
@test ocp.initial_time == t0
@test ocp.final_time == tf
@test ocp.dynamics([0.; 1.], 1.0) ≈ [1.; 1.] atol=1e-8
@test ocp.lagrangian([0.; 0.], 1.0) ≈ 0.5 atol=1e-8

# solve
sol = solve(ocp)

# solution
u_sol(t) = 6.0-12.0*t
U_sol_direct = sol.U
T_sol_direct = sol.T

#@test U_sol_direct ≈ u_sol.(T_sol_direct[1:end-1]) atol=1e-1
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

constraint!(ocp, :dynamics, (x, u) -> A*x + B*u[1])
objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2) # default is to minimise

#
@test ocp.state_dimension == 2
@test ocp.control_dimension == 1
@test typeof(ocp) == OptimalControlModel{:autonomous}
@test ocp.initial_time == t0
@test ocp.final_time == tf
@test ocp.dynamics(0.0, [0.; 1.], 1.0) ≈ [1.; 1.] atol=1e-8
@test ocp.lagrange(0.0, [0.; 0.], 1.0) ≈ 0.5 atol=1e-8

# solve
sol = solve(ocp)
println(objective(sol), constraints_violation(sol))


# solution
u_sol(t) = 6.0-12.0*t
U = sol.U
T = sol.T
dT = T[2:end]-T[1:end-1]

@test sum(dT .* abs.(U[1:end-1] - u_sol.(T[1:end-1]))) ≈ 0 atol=1e-1
@test objective(sol) ≈ 6.0 atol=1e-1
@test constraints_violation(sol) < 1e-6

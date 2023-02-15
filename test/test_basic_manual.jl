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

# initial guess (constant state and control functions)
init = [1., 0.5, 0.3]

# solve
#sol = solve(ocp, grid_size=10, print_level=5)
sol = solve(ocp, grid_size=10, print_level=5, init=init)


# plot
plot(sol)

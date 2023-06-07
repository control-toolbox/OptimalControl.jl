# goddard with state constraint - maximize altitude
prob = Problem(:goddard, :classical, :altitude, :x_dim_3, :u_dim_1, :mayer, :x_cons, :u_cons, :singular_arc)
ocp = prob.model

# initial guess (constant state and control functions)
#init = ([1.01, 0.05, 0.8], 0.1, 0.2)
init = [1.01, 0.05, 0.8, 0.1, 0.2]

# solve
sol = solve(ocp, grid_size=10, print_level=5, init=init)

# test
@test sol.objective ≈ prob.solution.objective atol=5e-3

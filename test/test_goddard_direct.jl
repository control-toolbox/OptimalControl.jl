# goddard with state constraint - maximize altitude
prob = Problem(:goddard, :state_constraint)
ocp = prob.model

# initial guess (constant state and control functions)
init = [1.01, 0.05, 0.8, 0.1]

# solve
sol = solve(ocp, grid_size=10, print_level=0, init=init)

# test
@test sol.objective ≈ prob.solution.objective atol=5e-3

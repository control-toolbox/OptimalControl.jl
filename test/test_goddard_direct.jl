function test_goddard_direct()

# goddard with state constraint - maximize altitude
prob = Problem(:goddard, :classical, :altitude, :x_dim_3, :u_dim_1, :mayer, :x_cons, :u_cons, :singular_arc)
ocp = prob.model

# initial guess (constant state and control functions)
init = (state=[1.01, 0.05, 0.8], control=0.1, variable=0.2)
sol = solve(ocp, grid_size=10, print_level=0, init=init)
@test sol.objective ≈ prob.solution.objective atol=5e-3

end
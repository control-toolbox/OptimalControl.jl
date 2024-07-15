function test_init()

    # get double integrator enregy min problem
    prob = Problem(:integrator, :energy, :x_dim_2, :u_dim_1, :lagrange, :noconstraints)
    ocp = prob.model

    #
    N = 50
    tol = 1e-2
   
    # initial guess (constant state and control)
    init = (state=[-0.5, 0.2], control=0.5)
    sol = solve(ocp, grid_size=N, init=init, print_level=0)
    @test sol.objective ≈ prob.solution.objective atol=tol

    # initial guess (constant state and functional control)
    init = (state=[-0.5, 0.2], control=t->6-12*t)
    sol = solve(ocp, grid_size=N, init=init, print_level=0)
    @test sol.objective ≈ prob.solution.objective atol=tol

    # initial guess (functional state and constant control)
    init = (state=t->[-1+t, t*(t-1)], control=0.5)
    sol = solve(ocp, grid_size=N, init=init, print_level=0)
    @test sol.objective ≈ prob.solution.objective atol=tol

    # initial guess (functional state and functional control)
    init = (state=t->[-1+t, t*(t-1)], control=t->6-12*t)
    sol = solve(ocp, grid_size=N, init=init, print_level=0)
    @test sol.objective ≈ prob.solution.objective atol=tol

end
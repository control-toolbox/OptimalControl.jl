function test_init()

    # double integrator energy min problem
    @def ocp begin
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [ -1, 0 ]
        x(1) == [ 0, 0 ]
        ẋ(t) == [ x₂(t), u(t) ]
        ∫( 0.5u(t)^2 ) → min
    end

    objective = 6

    #
    N = 50
    tol = 1e-2
   
    # initial guess (constant state and control)
    init = (state=[-0.5, 0.2], control=0.5)
    sol = solve(ocp; grid_size=N, init=init, display=false)
    @test sol.objective ≈ objective atol=tol

    # initial guess (constant state and functional control)
    init = (state=[-0.5, 0.2], control=t->6-12*t)
    sol = solve(ocp; grid_size=N, init=init, display=false)
    @test sol.objective ≈ objective atol=tol

    # initial guess (functional state and constant control)
    init = (state=t->[-1+t, t*(t-1)], control=0.5)
    sol = solve(ocp; grid_size=N, init=init, display=false)
    @test sol.objective ≈ objective atol=tol

    # initial guess (functional state and functional control)
    init = (state=t->[-1+t, t*(t-1)], control=t->6-12*t)
    sol = solve(ocp; grid_size=N, init=init, display=false)
    @test sol.objective ≈ objective atol=tol

end
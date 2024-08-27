function test_goddard_direct()

    # goddard with state constraint - maximize altitude
    ocp, obj = Goddard()

    # initial guess (constant state and control functions)
    init = (state = [1.01, 0.05, 0.8], control = 0.1, variable = 0.2)
    sol = solve(ocp; grid_size = 10, display = false, init = init)
    @test objective(sol) ≈ obj atol = 5e-3
end

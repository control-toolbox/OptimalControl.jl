# test some grid options

function test_grid()

    ocp = Model()
    state!(ocp, 1)
    control!(ocp, 2)
    time!(ocp, t0=0, tf=1)
    constraint!(ocp, :initial, lb=-1, ub=-1)
    constraint!(ocp, :final, lb=0, ub=0)
    constraint!(ocp, :control, lb=[0,0], ub=[Inf, Inf])
    dynamics!(ocp, (x, u) -> -x - u[1] + u[2])
    objective!(ocp, :lagrange, (x, u) -> (u[1]+u[2])^2)

    time_grid = [0,0.1,0.3,0.6,0.98,0.99,1]
    sol6 = OptimalControl.solve(ocp, time_grid=time_grid, print_level=0)
    @test sol6.objective ≈ 0.309 rtol=1e-2

end
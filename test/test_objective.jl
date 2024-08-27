# test some objective options, variable tf
function test_objective()

    # min tf
    ocp = Model(variable = true)
    state!(ocp, 2)
    control!(ocp, 1)
    variable!(ocp, 1)
    time!(ocp, t0 = 0, indf = 1)
    constraint!(ocp, :initial, lb = [0, 0], ub = [0, 0])
    constraint!(ocp, :final, lb = [1, 0], ub = [1, 0])
    constraint!(ocp, :control, lb = -1, ub = 1)
    constraint!(ocp, :variable, lb = 0.1, ub = 10)
    dynamics!(ocp, (x, u, v) -> [x[2], u])
    objective!(ocp, :mayer, (x0, xf, v) -> v)

    @testset verbose = true showtiming = true ":min_tf :mayer" begin
        sol = solve(ocp, print_level = 0, tol = 1e-12)
        @test objective(sol) ≈ 2.0 rtol = 1e-2
    end

    # min tf (lagrange)
    ocp = Model(variable = true)
    state!(ocp, 2)
    control!(ocp, 1)
    variable!(ocp, 1)
    time!(ocp, t0 = 0, indf = 1)
    constraint!(ocp, :initial, lb = [0, 0], ub = [0, 0])
    constraint!(ocp, :final, lb = [1, 0], ub = [1, 0])
    constraint!(ocp, :control, lb = -1, ub = 1)
    constraint!(ocp, :variable, lb = 0.1, ub = 10)
    dynamics!(ocp, (x, u, v) -> [x[2], u])
    objective!(ocp, :lagrange, (x, u, v) -> 1)

    @testset verbose = true showtiming = true ":min_tf :lagrange" begin
        sol = solve(ocp, print_level = 0, tol = 1e-12)
        @test objective(sol) ≈ 2.0 rtol = 1e-2
    end

    # max t0 (free t0 and tf)
    ocp = Model(variable = true)
    state!(ocp, 2)
    control!(ocp, 1)
    variable!(ocp, 2)
    time!(ocp, ind0 = 1, indf = 2)
    constraint!(ocp, :initial, lb = [0, 0], ub = [0, 0])
    constraint!(ocp, :final, lb = [1, 0], ub = [1, 0])
    constraint!(ocp, :control, lb = -1, ub = 1)
    constraint!(ocp, :variable, lb = [0.1, 0.1], ub = [10, 10])
    constraint!(ocp, :variable, f = v -> v[2] - v[1], lb = 0.1, ub = Inf)
    dynamics!(ocp, (x, u, v) -> [x[2], u])
    objective!(ocp, :mayer, (x0, xf, v) -> v[1], :max)

    @testset verbose = true showtiming = true ":max_t0" begin
        sol = solve(ocp, print_level = 0, tol = 1e-12)
        @test objective(sol) ≈ 8.0 rtol = 1e-2
    end

    @testset verbose = true showtiming = true ":max_t0 :explicit_grid" begin
        sol = solve(ocp, time_grid = LinRange(0, 1, 101), print_level = 0, tol = 1e-12)
        @test objective(sol) ≈ 8.0 rtol = 1e-2
    end

    @testset verbose = true showtiming = true ":max_t0 :non_uniform_grid" begin
        sol = solve(ocp, time_grid = [0, 0.1, 0.6, 0.95, 1], print_level = 0, tol = 1e-12)
        @test objective(sol) ≈ 7.48 rtol = 1e-2
    end
end

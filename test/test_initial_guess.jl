# test initial guess options
function test_initial_guess()

    # use 0 iterations to check initial guess, >0 to check cv
    maxiter = 0

    # test functions
    function check_xf(sol, xf)
        return xf == sol.state(sol.times[end])
    end
    function check_uf(sol, uf)
        return uf == sol.control(sol.times[end])
    end
    function check_v(sol, v)
        return v == sol.variable
    end

    # reference solution
    @def ocp begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(0) == [0, 0]
        x(tf) == [1, 0]
        0.05 ≤ tf ≤ Inf
        ẋ(t) == [x₂(t), u(t)]
        tf → min
    end
    sol0 = solve(ocp, print_level = 0)

    # constant initial guess
    x_const = [0.5, 0.2]
    u_const = 0.5
    v_const = 0.15

    # functional initial guess
    x_func = t -> [t^2, sqrt(t)]
    u_func = t -> (cos(10 * t) + 1) * 0.5

    # interpolated initial guess
    x_vec = [[0, 0], [1, 2], [5, -1]]
    x_matrix = [0 0; 1 2; 5 -1]
    u_vec = [0, 0.3, 0.1]

    #################################################
    # 1 Pass initial guess to all-in-one solve call

    # 1.a default initial guess
    @testset verbose = true showtiming = true ":default_init_no_arg" begin
        sol = solve(ocp, print_level = 0, max_iter = maxiter)
        @test(check_xf(sol, [0.1, 0.1]) && check_uf(sol, 0.1) && check_v(sol, 0.1))
    end
    @testset verbose = true showtiming = true ":default_init_()" begin
        sol = solve(ocp, print_level = 0, init = (), max_iter = maxiter)
        @test(check_xf(sol, [0.1, 0.1]) && check_uf(sol, 0.1) && check_v(sol, 0.1))
    end
    @testset verbose = true showtiming = true ":default_init_nothing" begin
        sol = solve(ocp, print_level = 0, init = nothing, max_iter = maxiter)
        @test(check_xf(sol, [0.1, 0.1]) && check_uf(sol, 0.1) && check_v(sol, 0.1))
    end

    # 1.b constant initial guess
    @testset verbose = true showtiming = true ":constant_x" begin
        sol = solve(ocp, print_level = 0, init = (state = x_const,), max_iter = maxiter)
        @test(check_xf(sol, x_const))
    end
    @testset verbose = true showtiming = true ":constant_u" begin
        sol = solve(ocp, print_level = 0, init = (control = u_const,), max_iter = maxiter)
        @test(check_uf(sol, u_const))
    end
    @testset verbose = true showtiming = true ":constant_v" begin
        sol = solve(ocp, print_level = 0, init = (variable = v_const,), max_iter = maxiter)
        @test(check_v(sol, v_const))
    end
    @testset verbose = true showtiming = true ":constant_xu" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (state = x_const, control = u_const),
            max_iter = maxiter,
        )
        @test(check_xf(sol, x_const) && check_uf(sol, u_const))
    end
    @testset verbose = true showtiming = true ":constant_xv" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (state = x_const, variable = v_const),
            max_iter = maxiter,
        )
        @test(check_xf(sol, x_const) && check_v(sol, v_const))
    end
    @testset verbose = true showtiming = true ":constant_uv" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (control = u_const, variable = v_const),
            max_iter = maxiter,
        )
        @test(check_uf(sol, u_const) && check_v(sol, v_const))
    end
    @testset verbose = true showtiming = true ":constant_xuv" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (state = x_const, control = u_const, variable = v_const),
            max_iter = maxiter,
        )
        @test(check_xf(sol, x_const) && check_uf(sol, u_const) && check_v(sol, v_const))
    end

    # 1. functional initial guess
    @testset verbose = true showtiming = true ":functional_x" begin
        sol = solve(ocp, print_level = 0, init = (state = x_func,), max_iter = maxiter)
        @test(check_xf(sol, x_func(sol.times[end])))
    end
    @testset verbose = true showtiming = true ":functional_u" begin
        sol = solve(ocp, print_level = 0, init = (control = u_func,), max_iter = maxiter)
        @test(check_uf(sol, u_func(sol.times[end])))
    end
    @testset verbose = true showtiming = true ":functional_xu" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (state = x_func, control = u_func),
            max_iter = maxiter,
        )
        @test(check_xf(sol, x_func(sol.times[end])) && check_uf(sol, u_func(sol.times[end])))
    end

    # 1.d interpolated initial guess
    t_vec = [0, 0.1, v_const]
    @testset verbose = true showtiming = true ":vector_txu :constant_v" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (time = t_vec, state = x_vec, control = u_vec, variable = v_const),
            max_iter = maxiter,
        )
        @test(check_xf(sol, x_vec[end]) && check_uf(sol, u_vec[end]) && check_v(sol, v_const))
    end
    t_matrix = [0 0.1 v_const]
    @testset verbose = true showtiming = true ":matrix_t :vector_xu :constant_v" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (time = t_matrix, state = x_vec, control = u_vec, variable = v_const),
            max_iter = maxiter,
        )
        @test(check_xf(sol, x_vec[end]) && check_uf(sol, u_vec[end]) && check_v(sol, v_const))
    end
    @testset verbose = true showtiming = true ":matrix_x :vector_tu :constant_v" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (time = t_vec, state = x_matrix, control = u_vec, variable = v_const),
            max_iter = maxiter,
        )
        @test(check_xf(sol, x_vec[end]) && check_uf(sol, u_vec[end]) && check_v(sol, v_const))
    end

    # 1.e mixed initial guess
    @testset verbose = true showtiming = true ":vector_tx :functional_u :constant_v" begin
        sol = solve(
            ocp,
            print_level = 0,
            init = (time = t_vec, state = x_vec, control = u_func, variable = v_const),
            max_iter = maxiter,
        )
        @test(
            check_xf(sol, x_vec[end]) &&
            check_uf(sol, u_func(sol.times[end])) &&
            check_v(sol, v_const)
        )
    end

    # 1.f warm start
    @testset verbose = true showtiming = true ":warm_start" begin
        sol = solve(ocp, print_level = 0, init = sol0, max_iter = maxiter)
        @test(
            check_xf(sol, sol.state(sol.times[end])) &&
            check_uf(sol, sol.control(sol.times[end])) &&
            check_v(sol, sol.variable)
        )
    end
end

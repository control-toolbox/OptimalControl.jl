println("testing: initial guess options")

# use 0 iterations to check initial guess, >0 to check cv
maxiter = 0

# reference solution
prob = double_integrator_mintf()
ocp = prob.ocp
sol0 = solve(ocp, display = false)

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
    sol = solve(ocp, display = false, max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), (t -> [0.1, 0.1]).(T), rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), (t -> 0.1).(T), rtol = 1e-2)
    @test isapprox(CTModels.variable(sol), 0.1, rtol = 1e-2)
end
@testset verbose = true showtiming = true ":default_init_()" begin
    sol = solve(ocp, display = false, init = (), max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), (t -> [0.1, 0.1]).(T), rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), (t -> 0.1).(T), rtol = 1e-2)
    @test isapprox(CTModels.variable(sol), 0.1, rtol = 1e-2)
end
@testset verbose = true showtiming = true ":default_init_nothing" begin
    sol = solve(ocp, display = false, init = nothing, max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), (t -> [0.1, 0.1]).(T), rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), (t -> 0.1).(T), rtol = 1e-2)
    @test CTModels.variable(sol) == 0.1
end

# 1.b constant initial guess
@testset verbose = true showtiming = true ":constant_x" begin
    sol = solve(ocp, display = false, init = (state = x_const,), max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), (t -> x_const).(T), rtol = 1e-2)
end
@testset verbose = true showtiming = true ":constant_u" begin
    sol = solve(ocp, display = false, init = (control = u_const,), max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.control(sol).(T), (t -> u_const).(T), rtol = 1e-2)
end
@testset verbose = true showtiming = true ":constant_v" begin
    sol = solve(ocp, display = false, init = (variable = v_const,), max_iter = maxiter)
    @test CTModels.variable(sol) == v_const
end
@testset verbose = true showtiming = true ":constant_xu" begin
    sol = solve(
        ocp,
        display = false,
        init = (state = x_const, control = u_const),
        max_iter = maxiter,
    )
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), (t -> x_const).(T), rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), (t -> u_const).(T), rtol = 1e-2)
end
@testset verbose = true showtiming = true ":constant_xv" begin
    sol = solve(
        ocp,
        display = false,
        init = (state = x_const, variable = v_const),
        max_iter = maxiter,
    )
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), (t -> x_const).(T), rtol = 1e-2)
    @test CTModels.variable(sol) == v_const
end
@testset verbose = true showtiming = true ":constant_uv" begin
    sol = solve(
        ocp,
        display = false,
        init = (control = u_const, variable = v_const),
        max_iter = maxiter,
    )
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.control(sol).(T), (t -> u_const).(T), rtol = 1e-2)
    @test CTModels.variable(sol) == v_const
end
@testset verbose = true showtiming = true ":constant_xuv" begin
    sol = solve(
        ocp,
        display = false,
        init = (state = x_const, control = u_const, variable = v_const),
        max_iter = maxiter,
    )
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), (t -> x_const).(T), rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), (t -> u_const).(T), rtol = 1e-2)
    @test CTModels.variable(sol) == v_const
end

# 1. functional initial guess
@testset verbose = true showtiming = true ":functional_x" begin
    sol = solve(ocp, display = false, init = (state = x_func,), max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), x_func.(T), rtol = 1e-2)
end
@testset verbose = true showtiming = true ":functional_u" begin
    sol = solve(ocp, display = false, init = (control = u_func,), max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.control(sol).(T), u_func.(T), rtol = 1e-2)
end
@testset verbose = true showtiming = true ":functional_xu" begin
    sol = solve(
        ocp,
        display = false,
        init = (state = x_func, control = u_func),
        max_iter = maxiter,
    )
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), x_func.(T), rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), u_func.(T), rtol = 1e-2)
end

# 1.d interpolated initial guess
t_vec = [0, 0.1, v_const]
@testset verbose = true showtiming = true ":vector_txu :constant_v" begin
    sol = solve(
        ocp,
        display = false,
        init = (time = t_vec, state = x_vec, control = u_vec, variable = v_const),
        max_iter = maxiter,
    )
    @test isapprox(CTModels.state(sol).(t_vec), x_vec, rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(t_vec), u_vec, rtol = 1e-2)
    @test CTModels.variable(sol) == v_const
end
t_matrix = [0 0.1 v_const]
@testset verbose = true showtiming = true ":matrix_t :vector_xu :constant_v" begin
    sol = solve(
        ocp,
        display = false,
        init = (time = t_matrix, state = x_vec, control = u_vec, variable = v_const),
        max_iter = maxiter,
    )
    @test isapprox(CTModels.state(sol).(flatten(t_matrix)), x_vec, rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(flatten(t_matrix)), u_vec, rtol = 1e-2)
    @test CTModels.variable(sol) == v_const
end
@testset verbose = true showtiming = true ":matrix_x :vector_tu :constant_v" begin
    sol = solve(
        ocp,
        display = false,
        init = (time = t_vec, state = x_matrix, control = u_vec, variable = v_const),
        max_iter = maxiter,
    )
    @test isapprox(stack(CTModels.state(sol).(t_matrix), dims = 1), x_matrix, rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(t_vec), u_vec, rtol = 1e-2)
    @test CTModels.variable(sol) == v_const
end

# 1.e mixed initial guess
@testset verbose = true showtiming = true ":vector_tx :functional_u :constant_v" begin
    sol = solve(
        ocp,
        display = false,
        init = (time = t_vec, state = x_vec, control = u_func, variable = v_const),
        max_iter = maxiter,
    )
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(t_vec), x_vec, rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), u_func.(T), rtol = 1e-2)
    @test CTModels.variable(sol) == v_const
end

# 1.f warm start
@testset verbose = true showtiming = true ":warm_start" begin
    sol = solve(ocp, display = false, init = sol0, max_iter = maxiter)
    T = CTModels.time_grid(sol)
    @test isapprox(CTModels.state(sol).(T), CTModels.state(sol0).(T), rtol = 1e-2)
    @test isapprox(CTModels.control(sol).(T), CTModels.control(sol0).(T), rtol = 1e-2)
    @test CTModels.variable(sol) == CTModels.variable(sol0)
end
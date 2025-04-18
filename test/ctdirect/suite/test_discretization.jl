println("testing: discretization options")

normalize_grid(t) = return (t .- t[1]) ./ (t[end] - t[1])
N = 250

# 1. simple integrator min energy (dual control for test)
if !isdefined(Main, :simple_integrator)
    include("../problems/simple_integrator.jl")
end
ocp = simple_integrator().ocp
sol0 = solve(ocp; display=false)

# solve with explicit and non uniform time grid
@testset verbose = true showtiming = true ":explicit_grid" begin
    sol = solve(ocp, time_grid=LinRange(0, 1, N + 1), display=false)
    @test (objective(sol) == objective(sol0)) && (iterations(sol) == iterations(sol0))
end

@testset verbose = true showtiming = true ":non_uniform_grid" begin
    grid = [0, 0.1, 0.3, 0.6, 0.98, 0.99, 1]
    sol = solve(ocp, time_grid=grid, display=false)
    @test time_grid(sol) ≈ grid
end

# 2. integrator free times
if !isdefined(Main, :double_integrator_freet0tf)
    include("../problems/double_integrator.jl")
end
ocp = double_integrator_freet0tf().ocp
sol0 = solve(ocp; display=false)

@testset verbose = true showtiming = true ":explicit_grid" begin
    sol = solve(ocp, time_grid=LinRange(0, 1, N + 1), display=false)
    @test (objective(sol) == objective(sol0)) && (iterations(sol) == iterations(sol0))
end

@testset verbose = true showtiming = true ":max_t0 :non_uniform_grid" begin
    grid = [0, 0.1, 0.6, 0.95, 1]
    sol = solve(ocp, time_grid=grid, display=false)
    @test normalize_grid(time_grid(sol)) ≈ grid
end

# 3. double integrator min energy ocp (T=2) with explicit / non-uniform grid
if !isdefined(Main, :double_integrator_minenergy)
    include("../problems/double_integrator.jl")
end
ocp = double_integrator_minenergy(2).ocp
sol0 = solve(ocp; display=false)

@testset verbose = true showtiming = true ":explicit_grid" begin
    sol = solve(ocp, time_grid=LinRange(0, 1, N + 1), display=false)
    @test (objective(sol) == objective(sol0)) && (iterations(sol) == iterations(sol0))
end

@testset verbose = true showtiming = true ":non_uniform_grid" begin
    grid = [0, 0.3, 1, 1.9, 2]
    sol = solve(ocp, time_grid=grid, display=false)
    @test time_grid(sol) ≈ grid
end

# discretization methods
if !isdefined(Main, :goddard_all)
    include("../problems/goddard.jl")
end

@testset verbose = true showtiming = true ":simple_integrator :disc_method" begin
    prob = simple_integrator()
    sol = solve(prob.ocp, display=false, disc_method=:trapeze)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:midpoint)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:euler)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:euler_implicit)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:gauss_legendre_2)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:gauss_legendre_3)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
end

@testset verbose = true showtiming = true ":double_integrator :disc_method" begin
    prob = double_integrator_freet0tf()
    sol = solve(prob.ocp, display=false, disc_method=:trapeze)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:midpoint)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:euler)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:euler_implicit)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:gauss_legendre_2)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:gauss_legendre_3)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
end

@testset verbose = true showtiming = true ":goddard :disc_method" begin
    prob = goddard_all()
    sol = solve(prob.ocp, display=false, disc_method=:trapeze)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:midpoint)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:euler)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:euler_implicit)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:gauss_legendre_2)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
    sol = solve(prob.ocp, display=false, disc_method=:gauss_legendre_3)
    @test objective(sol) ≈ prob.obj rtol = 1e-2
end

println("testing: OCP definitions")

# beam
if !isdefined(Main, :beam)
    include("../problems/beam.jl")
end
@testset verbose = true showtiming = true ":beam" begin
    prob = beam()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

# double integrator min tf
if !isdefined(Main, :double_integrator_mintf)
    include("../problems/double_integrator.jl")
end
@testset verbose = true showtiming = true ":double_integrator :min_tf" begin
    prob = double_integrator_mintf()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

# fuller
if !isdefined(Main, :fuller)
    include("../problems/fuller.jl")
end
@testset verbose = true showtiming = true ":fuller" begin
    prob = fuller()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

# goddard max rf
if !isdefined(Main, :goddard)
    include("../problems/goddard.jl")
end
@testset verbose = true showtiming = true ":goddard :max_rf" begin
    prob = goddard()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

# jackson
if !isdefined(Main, :jackson)
    include("../problems/jackson.jl")
end
@testset verbose = true showtiming = true ":jackson" begin
    prob = jackson()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

#= robbins
if !isdefined(Main, :robbins)
    include("../problems/robbins.jl")
end
@testset verbose = true showtiming = true ":robbins" begin
    prob = robbins()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end=#

# simple integrator
if !isdefined(Main, :simple_integrator)
    include("../problems/simple_integrator.jl")
end
@testset verbose = true showtiming = true ":simple_integrator" begin
    prob = simple_integrator()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

# vanderpol
if !isdefined(Main, :vanderpol)
    include("../problems/vanderpol.jl")
end
@testset verbose = true showtiming = true ":vanderpol" begin
    prob = vanderpol()
    sol = direct_solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end
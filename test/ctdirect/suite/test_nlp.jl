println("testing: nlp options")

if !isdefined(Main, :simple_integrator)
    include("../problems/simple_integrator.jl")
end
prob = simple_integrator()
ocp = prob.ocp
obj = prob.obj

@testset verbose = true showtiming = true ":methods" begin
    @test is_solvable(ocp)
    @test (:adnlp, :ipopt) in CTDirect.available_methods()
    @test (:adnlp, :madnlp) in CTDirect.available_methods()
end

# AD backends
@testset verbose = true showtiming = true ":AD_backends" begin
    sol = direct_solve(ocp, display = false)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = direct_solve(ocp, display = false, adnlp_backend = :default)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = direct_solve(ocp, display = false, adnlp_backend = :manual)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = direct_solve(ocp, display = false, disc_method=:midpoint, adnlp_backend = :manual)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = direct_solve(ocp, display = false, disc_method=:gauss_legendre_2, adnlp_backend = :manual)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
end

# DOCP solving
@testset verbose = true showtiming = true ":solve_docp" begin
    docp, nlp = direct_transcription(ocp)
    solver_backend = CTDirect.IpoptBackend()
    dsol = CTDirect.solve_docp(solver_backend, docp, nlp, display = false)
    sol = CTDirect.build_OCP_solution(docp, dsol)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = build_OCP_solution(docp, primal = dsol.solution)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = build_OCP_solution(docp, primal = dsol.solution, dual = dsol.multipliers)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = build_OCP_solution(docp, primal = dsol.solution, dual = dsol.multipliers, mult_LB = dsol.multipliers_L, mult_UB = dsol.multipliers_U)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
end


@testset verbose = true showtiming = true ":solve_docp :madnlp :gl2" begin
    docp, nlp = direct_transcription(ocp, disc_method=:gauss_legendre_2)
    solver_backend = CTDirect.MadNLPBackend()
    dsol = CTDirect.solve_docp(solver_backend, docp, nlp, display = false)
    sol = CTDirect.build_OCP_solution(docp, dsol)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = build_OCP_solution(docp, primal = dsol.solution)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = build_OCP_solution(docp, primal = dsol.solution, dual = dsol.multipliers)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
    sol = build_OCP_solution(docp, primal = dsol.solution, dual = dsol.multipliers, mult_LB = dsol.multipliers_L, mult_UB = dsol.multipliers_U)
    @test CTModels.objective(sol) ≈ obj rtol = 1e-2
end

# solution building
if !isdefined(Main, :double_integrator_minenergy)
    include("../problems/double_integrator.jl")
end
ocp = double_integrator_minenergy(1).ocp
x_opt = t -> [6 * (t^2 / 2 - t^3 / 3), 6 * (t - t^2)]
u_opt = t -> 6 - 12 * t
p_opt = t -> [24, 12 - 24 * t]

@testset verbose = true showtiming = true ":analytic_solution :ipopt" begin
    sol = direct_solve(ocp, display = false)
    T = CTModels.time_grid(sol)
    @test isapprox(x_opt.(T), CTModels.state(sol).(T), rtol = 1e-2)
    @test isapprox(u_opt.(T), CTModels.control(sol).(T), rtol = 1e-2)
    @test isapprox(p_opt.(T), CTModels.costate(sol).(T), rtol = 1e-2)
end

@testset verbose = true showtiming = true ":analytic_solution :madnlp" begin
    sol = direct_solve(ocp, :madnlp, display = false)
    T = CTModels.time_grid(sol)
    @test isapprox(x_opt.(T), CTModels.state(sol).(T), rtol = 1e-2)
    @test isapprox(u_opt.(T), CTModels.control(sol).(T), rtol = 1e-2)
    @test isapprox(p_opt.(T), CTModels.costate(sol).(T), rtol = 1e-2)
end

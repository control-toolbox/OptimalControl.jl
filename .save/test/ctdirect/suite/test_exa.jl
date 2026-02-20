# beam2
if !isdefined(Main, :beam2)
    include("../problems/beam2.jl")
end

display = false # during optim solves

# Test on CPU

println("testing: ExaModels (CPU)")

@testset verbose = true showtiming = true ":examodel :cpu :trapeze" begin
    prob = beam2()
    sol = solve(prob.ocp, :madnlp, :exa; disc_method=:trapeze, display=display)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

@testset verbose = true showtiming = true ":examodel :cpu :euler :init" begin
    prob = beam2()
    sol = solve(
        prob.ocp,
        :madnlp,
        :exa;
        disc_method=:euler,
        display=display,
        init=(control=6.66,),
        max_iter=0,
    )
    @test control(sol)(0.5) == 6.66
end

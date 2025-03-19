println("testing: objective")

# min tf
if !isdefined(Main, :double_integrator_mintf)
    include("../problems/double_integrator.jl")
end

@testset verbose = true showtiming = true ":min_tf :mayer" begin
    prob = double_integrator_mintf()
    sol = solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end


# max t0 (free t0 and tf)
@testset verbose = true showtiming = true ":max_t0" begin
    prob = double_integrator_freet0tf()
    sol = solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

# bolza, non-autonomous mayer term, tf in dynamics
if !isdefined(Main, :bolza_freetf)
    include("../problems/bolza.jl")
end
prob = bolza_freetf()
@testset verbose = true showtiming = true ":bolza :tf_in_dyn_and_cost" begin
    sol = solve(prob.ocp, display = false)
    @test sol.objective ≈ prob.obj rtol = 1e-2
end

#= +++retry with :default AD backend ?
@def ocp begin
    v = (t0, tf) ∈ R^2, variable
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t) == tf * u(t) + t0
    x(t0) == 0
    x(tf) == 1
    0 ≤ t0 ≤ 10
    0.01 ≤ tf - t0 ≤ 10
    (t0^2 + tf) + 0.5∫(u(t)^2) → min
end
@testset verbose = true showtiming = true ":bolza :t0_tf_in_dyn_and_cost" begin
    sol = solve(ocp, print_level=5)
    @test sol.variable[1] ≈ 1.107 rtol=1e-2
end

# :default backend ?
@def ocp2 begin
    s ∈ [0, 1], time
    y ∈ R^2, state
    u ∈ R, control
    ẏ(s) == [u(s), 0]
    y[1](0) == 0
    y[1](1) == 0
    ∫(u(s)^2) → min
end
sol = solve(ocp2)
=#

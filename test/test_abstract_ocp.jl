# for parser testing
function test_abstract_ocp()

    # double integrator min tf, abstract definition
    @def ocp1 begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(0) == [0, 0]
        x(tf) == [1, 0]
        0.1 ≤ tf ≤ Inf
        ẋ(t) == [x₂(t), u(t)]
        tf → min
    end

    @testset verbose = true showtiming = true ":double_integrator :min_tf :abstract" begin
        sol1 = solve(ocp1, print_level = 0, tol = 1e-12)
        @test sol1.objective ≈ 2.0 rtol = 1e-2
    end

    @testset verbose = true showtiming = true ":goddard :max_rf :abstract :constr" begin
        ocp3 = goddard_a().ocp
        sol3 = solve(ocp3, print_level = 0, tol = 1e-12)
        @test sol3.objective ≈ 1.0125 rtol = 1e-2
    end
end

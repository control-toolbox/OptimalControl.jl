function test_basic()
    @def ocp begin
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end

    sol = solve(ocp; display = false)
    @test objective(sol) ≈ 6 atol = 1e-2
end

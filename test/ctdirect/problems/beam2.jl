# Beam example from bocop
# beam2: coordinate wise dynamics

function beam2()
    beam2 = @def begin
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [0, 1]
        x(1) == [0, -1]
        ∂(x₁)(t) == x₂(t)
        ∂(x₂)(t) == u(t)
        0 ≤ x₁(t) ≤ 0.1
        -10 ≤ u(t) ≤ 10
        ∫(u(t)^2) → min
    end

    return ((ocp=beam2, obj=8.898598, name="beam2", init=nothing))
end

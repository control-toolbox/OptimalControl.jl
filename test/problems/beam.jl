# Beam example from bocop

function beam()

    @def beam begin
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [0,1]
        x(1) == [0,-1]
        ẋ(t) == [x₂(t), u(t)]
        0 ≤ x₁(t) ≤ 0.1    
        -10 ≤ u(t) ≤ 10
        ∫(u(t)^2) → min
    end

    return ((ocp=beam, obj=8.898598, name="beam", init=nothing))
end
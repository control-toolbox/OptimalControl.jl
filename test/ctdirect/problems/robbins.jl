# Robbins example from Bocop

function robbins()
    @def robbins begin
        # constants
        alpha = 3
        beta = 0
        gamma = 0.5

        t ∈ [0, 10], time
        x ∈ R³, state
        u ∈ R, control
        0 ≤ x[1](t) ≤ Inf
        x(0) == [1, -2, 0]
        x(10) == [0, 0, 0]
        ẋ(t) == [x[2](t), x[3](t), u(t)]
        ∫(alpha * x[1](t) + beta * x[1](t)^2 + gamma * u(t)^2) → min
    end

    return ((ocp = robbins, obj = 19.4, name = "robbins", init = nothing))
end

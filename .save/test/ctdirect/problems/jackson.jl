# Jackson example from Bocop

function jackson()
    @def jackson begin
        # constants
        k1 = 1
        k2 = 10
        k3 = 1

        t ∈ [0, 4], time
        x ∈ R³, state
        u ∈ R, control
        [0, 0, 0] ≤ x(t) ≤ [1.1, 1.1, 1.1]
        0 ≤ u(t) ≤ 1
        x(0) == [1, 0, 0]
        a = x[1]
        b = x[2]
        ẋ(t) == [
            -u(t) * (k1 * a(t) - k2 * b(t)),
            u(t) * (k1 * a(t) - k2 * b(t)) - (1 - u(t)) * k3 * b(t),
            (1 - u(t)) * k3 * b(t),
        ]
        x[3](4) → max
    end

    return ((ocp=jackson, obj=0.192011, name="jackson", init=nothing))
end

# Duumy problem to visualize sparsity patterns

function pattern()
    @def ocp begin
        t ∈ [0, 1], time
        x ∈ R, state
        u ∈ R, control
        v ∈ R, variable
        x(0) + x(1) + v == 0
        ẋ(t) == x(t)^2 + u(t)^2 + v^2
        ∫(u(t)^2 + x(t)^2 + v^2) → min
    end

    return ((ocp = ocp, obj = nothing, name = "pattern", init = nothing))
end
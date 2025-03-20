using OptimalControl
using CTParser
using CTModels
CTParser.set_prefix(:CTModels)

beam = @def begin
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [0, 1]
        x(1) == [0, -1]
        ẋ(t) == [x₂(t), u(t)]
        0 ≤ x₁(t) ≤ 0.1
        -10 ≤ u(t) ≤ 10
        ∫(u(t)^2) → min
end

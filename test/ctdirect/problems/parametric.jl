# Parametric problem (name ??)
function parametric(ρ)
    relu(x) = max(0, x)
    μ = 10
    p_relu(x) = log(abs(1 + exp(μ * x))) / μ
    f(x) = 1 - x
    m(x) = (p_relu ∘ f)(x)
    T = 2

    @def param begin
        τ ∈ R, variable
        s ∈ [0, 1], time
        x ∈ R², state
        u ∈ R², control
        x₁(0) == 0
        x₂(0) == 1
        x₁(1) == 1
        ẋ(s) == [τ * (u₁(s) + 2), (T - τ) * u₂(s)]
        -1 ≤ u₁(s) ≤ 1
        -1 ≤ u₂(s) ≤ 1
        0 ≤ τ ≤ T
        -(x₂(1) - 2)^3 - ∫(ρ * (τ * m(x₁(s))^2 + (T - τ) * m(x₂(s))^2)) → min
    end

    return ((ocp=param, obj=nothing, name="parametric", init=nothing))
end

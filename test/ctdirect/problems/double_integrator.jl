# double integrator

# min tf
function double_integrator_mintf()
    @def ocp begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(0) == [0, 0]
        x(tf) == [1, 0]
        0.05 ≤ tf ≤ Inf
        ẋ(t) == [x₂(t), u(t)]
        tf → min
    end

    return ((ocp=ocp, obj=2.0, name="double_integrator_mintf", init=nothing))
end

# min energy with fixed tf
function double_integrator_minenergy(T=2)
    @def ocp begin
        t ∈ [0, T], time
        x ∈ R², state
        u ∈ R, control
        q = x₁
        v = x₂
        q(0) == 0
        v(0) == 0
        q(T) == 1
        v(T) == 0
        ẋ(t) == [v(t), u(t)]
        ∫(u(t)^2) → min
    end

    return ((ocp=ocp, obj=nothing, name="double_integrator_minenergy", init=nothing))
end

# max t0 with free t0,tf
function double_integrator_freet0tf()
    @def ocp begin
        v ∈ R², variable
        t0 = v₁
        tf = v₂
        t ∈ [t0, tf], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(t0) == [0, 0]
        x(tf) == [1, 0]
        0.05 ≤ t0 ≤ 10
        0.05 ≤ tf ≤ 10
        0.01 ≤ tf - t0 ≤ Inf
        ẋ(t) == [x₂(t), u(t)]
        t0 → max
    end

    return ((ocp=ocp, obj=8.0, name="double_integrator_freet0tf", init=nothing))
end

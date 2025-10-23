# simple intergator
# min energy, dual control

function simple_integrator()
    @def ocp begin
        t ∈ [0, 1], time
        x ∈ R, state
        u ∈ R², control
        [0, 0] ≤ u(t) ≤ [Inf, Inf]
        x(0) == -1
        x(1) == 0
        ẋ(t) == -x(t) - u[1](t) + u[2](t)
        ∫((u[1](t)+u[2](t))^2) → min
    end

    return ((ocp=ocp, obj=3.13e-1, name="simple_integrator", init=nothing))
end

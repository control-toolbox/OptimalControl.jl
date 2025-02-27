# some test problems with free times

function bolza_freetf()
    @def ocp begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R, state
        u ∈ R, control
        tf >= 0.1
        x(t) >= 0
        ẋ(t) == tf * u(t)
        x(0) == 0
        x(tf) == 1
        tf + 0.5∫(u(t)^2) → min
    end

    return ((ocp = ocp, obj = 1.476, name = "bolza_freetf", init = nothing))
end

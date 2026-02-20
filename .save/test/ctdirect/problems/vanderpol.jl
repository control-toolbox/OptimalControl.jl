# Van der Pol example from Bocop

function vanderpol()
    @def vanderpol begin
        # constants
        omega = 1
        epsilon = 1

        t ∈ [0, 2], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [1, 0]
        ẋ(t) ==
        [x[2](t), epsilon * omega * (1 - x[1](t)^2) * x[2](t) - omega^2 * x[1](t) + u(t)]
        ∫(0.5 * (x[1](t)^2 + x[2](t)^2 + u(t)^2)) → min
    end

    return ((ocp=vanderpol, obj=1.047921, name="vanderpol", init=nothing))
end

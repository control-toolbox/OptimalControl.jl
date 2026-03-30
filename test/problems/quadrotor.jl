# Quadrotor optimal control problem definition used by tests and examples.
#
# Returns a NamedTuple with fields:
#   - ocp  :: the CTParser-defined optimal control problem
#   - obj  :: reference optimal objective value (Ipopt / MadNLP, Collocation)
#   - name :: a short problem name
#   - init :: NamedTuple of components for CTSolvers.initial_guess
function Quadrotor(; T=1, g=9.8, r=0.1)
    ocp = @def begin
        t ∈ [0, T], time
        x ∈ R⁹, state
        u ∈ R⁴, control

        x(0) == zeros(9)

        ∂(x₁)(t) == x₂(t)
        ∂(x₂)(t) ==
        u₁(t) * cos(x₇(t)) * sin(x₈(t)) * cos(x₉(t)) + u₁(t) * sin(x₇(t)) * sin(x₉(t))
        ∂(x₃)(t) == x₄(t)
        ∂(x₄)(t) ==
        u₁(t) * cos(x₇(t)) * sin(x₈(t)) * sin(x₉(t)) - u₁(t) * sin(x₇(t)) * cos(x₉(t))
        ∂(x₅)(t) == x₆(t)
        ∂(x₆)(t) == u₁(t) * cos(x₇(t)) * cos(x₈(t)) - g
        ∂(x₇)(t) == u₂(t) * cos(x₇(t)) / cos(x₈(t)) + u₃(t) * sin(x₇(t)) / cos(x₈(t))
        ∂(x₈)(t) == -u₂(t) * sin(x₇(t)) + u₃(t) * cos(x₇(t))
        ∂(x₉)(t) ==
        u₂(t) * cos(x₇(t)) * tan(x₈(t)) + u₃(t) * sin(x₇(t)) * tan(x₈(t)) + u₄(t)

        dt1 = sin(2π * t / T)
        df1 = 0
        dt3 = 2sin(4π * t / T)
        df3 = 0
        dt5 = 2t / T
        df5 = 2

        0.5∫(
            (x₁(t) - dt1)^2 +
            (x₃(t) - dt3)^2 +
            (x₅(t) - dt5)^2 +
            x₇(t)^2 +
            x₈(t)^2 +
            x₉(t)^2 +
            r * (u₁(t)^2 + u₂(t)^2 + u₃(t)^2 + u₄(t)^2),
        ) → min
    end

    init = @init ocp begin
        x(t) := 0.1 * ones(9)
        u(t) := 0.1 * ones(4)
    end

    return (ocp=ocp, obj=4.2679623758, name="quadrotor", init=init)
end

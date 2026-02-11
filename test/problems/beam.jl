# Beam optimal control problem definition used by tests and examples.
#
# Returns a NamedTuple with fields:
#   - ocp  :: the CTParser-defined optimal control problem
#   - obj  :: reference optimal objective value (Ipopt / MadNLP, Collocation)
#   - name :: a short problem name
#   - init :: NamedTuple of components for CTSolvers.initial_guess
function Beam()
    ocp = @def begin
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control

        x(0) == [0, 1]
        x(1) == [0, -1]
        0 ≤ x₁(t) ≤ 0.1
        -10 ≤ u(t) ≤ 10

        ∂(x₁)(t) == x₂(t)
        ∂(x₂)(t) == u(t)

        ∫(u(t)^2) → min
    end

    init = (state=[0.05, 0.1], control=0.1)

    return (ocp=ocp, obj=8.898598, name="beam", init=init)
end

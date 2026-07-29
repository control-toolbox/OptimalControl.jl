# Beam optimal control problem, in both front-end forms.
#
# min ∫₀¹ u(t)² dt  subject to  ẋ = (x₂, u),  x(0) = (0, 1),  x(1) = (0, -1),
#                               0 ≤ x₁ ≤ 0.1,  -10 ≤ u ≤ 10

"""
    Beam(form::Symbol=:abstract)

Return the beam problem as a [`TestProblem`](@ref).

`form` selects the front end: `:abstract` (the `@def` DSL) or `:functional`
(the `CTModels.Building` API). The two must produce equivalent models.
"""
function Beam(form::Symbol=:abstract)
    check_form(form)
    return cached(:beam, form, ()) do
        form === :abstract ? _beam_abstract() : _beam_functional()
    end
end

const _BEAM_OBJ = 8.898598

function _beam_abstract()
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

    init = @init ocp begin
        x(t) := [0.05, 0.1]
        u(t) := 0.1
    end

    return TestProblem(:beam, :abstract, ocp, _BEAM_OBJ, init, (;))
end

function _beam_functional()
    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 0)
    CTModels.Building.time!(pre; t0=0.0, tf=1.0)
    CTModels.Building.state!(pre, 2)
    CTModels.Building.control!(pre, 1)

    # Dynamics are in-place, signature (r, t, x, u, v).
    function dyn!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    CTModels.Building.objective!(pre, :min; lagrange=(t, x, u, v) -> u[1]^2)

    function f_boundary(r, x0, xf, v)
        r[1] = x0[1] - 0.0
        r[2] = x0[2] - 1.0
        r[3] = xf[1] - 0.0
        r[4] = xf[2] + 1.0
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(4), ub=zeros(4), label=:beam_boundary
    )
    CTModels.Building.constraint!(
        pre, :state; rg=1:1, lb=[0.0], ub=[0.1], label=:beam_state_x1
    )
    CTModels.Building.constraint!(
        pre, :control; rg=1:1, lb=[-10.0], ub=[10.0], label=:beam_control_u
    )

    # ⚠️ Mandatory before `build`, and easy to forget: omitting it is a
    # `PreconditionError`, not a sensible default.
    CTModels.Building.time_dependence!(pre; autonomous=true)

    ocp = CTModels.Building.build(pre)

    return TestProblem(
        :beam, :functional, ocp, _BEAM_OBJ, (state=[0.05, 0.1], control=0.1), (;)
    )
end

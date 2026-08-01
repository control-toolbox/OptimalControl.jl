# Quadrotor tracking problem, in both front-end forms.
#
# The largest problem in the library: 9-D state, 4-D control, non-autonomous
# Lagrange cost (the reference trajectory reads `t`). Its role is to keep the
# direct path honest on a model that is not tiny.

"""
    Quadrotor(form::Symbol=:abstract; T=1, g=9.8, r=0.1)

Return the quadrotor tracking problem as a [`TestProblem`](@ref).

`data` carries the three parameters `T`, `g`, `r`.
"""
function Quadrotor(form::Symbol=:abstract; T=1, g=9.8, r=0.1)
    check_form(form)
    return cached(:quadrotor, form, (T, g, r)) do
        form === :abstract ? _quadrotor_abstract(; T, g, r) : _quadrotor_functional(; T, g, r)
    end
end

const _QUADROTOR_OBJ = 4.2679623758

function _quadrotor_abstract(; T, g, r)
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

    return TestProblem(:quadrotor, :abstract, ocp, _QUADROTOR_OBJ, init, (; T, g, r))
end

function _quadrotor_functional(; T, g, r)
    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 0)
    CTModels.Building.time!(pre; t0=0.0, tf=Float64(T))
    CTModels.Building.state!(pre, 9)
    CTModels.Building.control!(pre, 4)

    function dyn!(dx, t, x, u, v)
        c7, s7 = cos(x[7]), sin(x[7])
        c8, s8 = cos(x[8]), sin(x[8])
        c9, s9 = cos(x[9]), sin(x[9])
        dx[1] = x[2]
        dx[2] = u[1] * c7 * s8 * c9 + u[1] * s7 * s9
        dx[3] = x[4]
        dx[4] = u[1] * c7 * s8 * s9 - u[1] * s7 * c9
        dx[5] = x[6]
        dx[6] = u[1] * c7 * c8 - g
        dx[7] = u[2] * c7 / c8 + u[3] * s7 / c8
        dx[8] = -u[2] * s7 + u[3] * c7
        dx[9] = u[2] * c7 * tan(x[8]) + u[3] * s7 * tan(x[8]) + u[4]
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    # Reference trajectory — the reason this problem is non-autonomous.
    function lagrange(t, x, u, v)
        dt1 = sin(2π * t / T)
        dt3 = 2sin(4π * t / T)
        dt5 = 2t / T
        return 0.5 * (
            (x[1] - dt1)^2 +
            (x[3] - dt3)^2 +
            (x[5] - dt5)^2 +
            x[7]^2 +
            x[8]^2 +
            x[9]^2 +
            r * (u[1]^2 + u[2]^2 + u[3]^2 + u[4]^2)
        )
    end
    CTModels.Building.objective!(pre, :min; lagrange=lagrange)

    function f_boundary(res, x0, xf, v)
        for i in 1:9
            res[i] = x0[i]
        end
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(9), ub=zeros(9), label=:quadrotor_x0
    )

    CTModels.Building.time_dependence!(pre; autonomous=false)

    ocp = CTModels.Building.build(pre)

    init = (state=0.1 * ones(9), control=0.1 * ones(4))

    return TestProblem(:quadrotor, :functional, ocp, _QUADROTOR_OBJ, init, (; T, g, r))
end

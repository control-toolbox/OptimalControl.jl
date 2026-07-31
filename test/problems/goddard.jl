# Goddard rocket ascent, in both front-end forms.
#
# Maximise the final altitude r(tf). Free final time, three-dimensional state,
# box constraints on state and control — the reference case for the indirect
# suite (B+ S C B0 structure).

"""
    Goddard(form::Symbol=:abstract; vmax=0.1, Tmax=3.5)

Return the Goddard rocket problem as a [`TestProblem`](@ref).

`data` carries the two dynamics fields the indirect method needs:

  * `F0` – drift
  * `F1` – control field

plus the constants the shooting function is written against (`vmax`, `mf`,
`x0`, …).
"""
function Goddard(form::Symbol=:abstract; vmax=0.1, Tmax=3.5)
    check_form(form)
    return cached(:goddard, form, (vmax, Tmax)) do
        return if form === :abstract
            _goddard_abstract(; vmax, Tmax)
        else
            _goddard_functional(; vmax, Tmax)
        end
    end
end

const _GODDARD_OBJ = 1.01257

# Shared constants and dynamics fields — identical for both forms, which is
# what makes the two models comparable.
function _goddard_constants(; vmax, Tmax)
    Cd = 310
    β = 500
    b = 2
    r0 = 1
    v0 = 0
    m0 = 1
    mf = 0.6
    x0 = [r0, v0, m0]

    function F0(x)
        r, v, m = x
        D = Cd * v^2 * exp(-β * (r - r0))
        return [v, -D / m - 1 / r^2, 0]
    end

    function F1(x)
        r, v, m = x
        return [0, Tmax / m, -b * Tmax]
    end

    # Reference solution of the B+ S C B0 shooting problem. Carried here so
    # the indirect fixture is self-describing: declaring `:indirect` without a
    # `p0` is rejected by the `TestProblem` constructor.
    p0 = [3.9457646586891744, 0.15039559623165552, 0.05371271293970545]
    switching_times = (
        0.023509684041879215,   # t1 — end of the B+ arc
        0.059737380899876,      # t2 — end of the singular arc
        0.10157134842432228,    # t3 — end of the boundary arc
    )
    tf_ref = 0.20204744057100849

    return (; Cd, β, b, r0, v0, m0, mf, vmax, Tmax, x0, F0, F1, p0, switching_times, tf_ref)
end

"""
    _goddard_shoot_builder(ocp, c)

The B+ S C B0 shooting derivation for Goddard, as a [`TestProblem.shoot_builder`](@ref
TestProblem) closure. Ported from what used to be written independently in
`suite/indirect/test_goddard.jl` and, a second time, in
`suite/problems/test_hamiltonian_type.jl` — this is now the single copy both consume.

Flat shooting vector: `ξ = [p0 (3); t1; t2; t3; tf]`, 7 unknowns for 7 residuals — mass at
`tf`, transversality on `(p_r, p_v)`, and the four switching/boundary conditions between arcs.
"""
function _goddard_shoot_builder(ocp, c)
    return function (; hamiltonian_type::Symbol=:total)
        t0 = 0.0
        vmax, mf, x0, F0, F1 = c.vmax, c.mf, c.x0, c.F0, c.F1

        g(x) = vmax - x[2]

        H0 = OptimalControl.Lift(F0)
        H1 = OptimalControl.Lift(F1)
        H01 = OptimalControl.@Lie {H0, H1}
        H001 = OptimalControl.@Lie {H0, H01}
        H101 = OptimalControl.@Lie {H1, H01}
        us(x, p) = -H001(x, p) / H101(x, p)

        # `Lie(X, f)` is `ad(X, f)` since v2.1.0-beta; `⋅` was dropped with no
        # replacement.
        ub(x) = -OptimalControl.ad(F0, g)(x) / OptimalControl.ad(F1, g)(x)
        μ(x, p) = H01(x, p) / OptimalControl.ad(F1, g)(x)

        f0 = OptimalControl.Flow(ocp, (x, p, v) -> 0.0; hamiltonian_type)
        f1 = OptimalControl.Flow(ocp, (x, p, v) -> 1.0; hamiltonian_type)
        fs = OptimalControl.Flow(ocp, (x, p, v) -> us(x, p); hamiltonian_type)
        fb = OptimalControl.Flow(
            ocp,
            (x, p, v) -> ub(x);
            constraint=(x, u, v) -> g(x),
            multiplier=(x, p, v) -> μ(x, p),
            hamiltonian_type,
        )

        function shoot!(s, ξ)
            p0 = ξ[1:3]
            τ1, τ2, τ3, τf = ξ[4], ξ[5], ξ[6], ξ[7]
            x1, p1 = f1(t0, x0, p0, τ1; variable=τf)
            x2, p2 = fs(τ1, x1, p1, τ2; variable=τf)
            x3, p3 = fb(τ2, x2, p2, τ3; variable=τf)
            xf, pf = f0(τ3, x3, p3, τf; variable=τf)
            s[1] = xf[3] - mf
            s[2:3] = pf[1:2] - [1, 0]
            s[4] = H1(x1, p1)
            s[5] = H01(x1, p1)
            s[6] = g(x2)
            s[7] = H0(xf, pf)
            return nothing
        end

        ξ_exact = [c.p0; collect(c.switching_times); c.tf_ref]
        ξ_guess = ξ_exact .* 1.1

        return shoot!, ξ_exact, ξ_guess
    end
end

function _goddard_abstract(; vmax, Tmax)
    c = _goddard_constants(; vmax, Tmax)
    Cd, β, b, r0, v0, m0, mf, x0 = c.Cd, c.β, c.b, c.r0, c.v0, c.m0, c.mf, c.x0

    @def goddard begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R^3, state
        u ∈ R, control

        0.01 ≤ tf ≤ Inf

        r = x[1]
        v = x[2]
        m = x[3]

        x(0) == x0
        m(tf) == mf

        r0 ≤ r(t) ≤ r0 + 0.1
        v0 ≤ v(t) ≤ vmax
        mf ≤ m(t) ≤ m0
        0 ≤ u(t) ≤ 1

        # Component-wise dynamics (Goddard rocket)
        D = Cd * v(t)^2 * exp(-β * (r(t) - r0))
        g = 1 / r(t)^2
        T = Tmax * u(t)

        ∂(r)(t) == v(t)
        ∂(v)(t) == (T - D - m(t) * g) / m(t)
        ∂(m)(t) == -b * T

        r(tf) → max
    end

    # Components for a reasonable initial guess around a feasible trajectory.
    init = @init goddard begin
        x(t) := [1.01, 0.05, 0.8]
        u(t) := 0.5
        tf := 0.1
    end

    return TestProblem(
        :goddard,
        :abstract,
        goddard,
        _GODDARD_OBJ,
        init,
        c;
        methods=(:direct, :indirect),
        shoot_builder=_goddard_shoot_builder(goddard, c),
    )
end

function _goddard_functional(; vmax, Tmax)
    c = _goddard_constants(; vmax, Tmax)
    Cd, β, b, r0, v0, m0, mf, x0 = c.Cd, c.β, c.b, c.r0, c.v0, c.m0, c.mf, c.x0

    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 1, :tf)
    # Free final time: the horizon end is variable component 1.
    CTModels.Building.time!(pre; t0=0.0, indf=1)
    CTModels.Building.state!(pre, 3, :x, [:r, :v, :m])
    CTModels.Building.control!(pre, 1)

    function dyn!(dx, t, x, u, v)
        r, vv, m = x[1], x[2], x[3]
        D = Cd * vv^2 * exp(-β * (r - r0))
        g = 1 / r^2
        T = Tmax * u[1]
        dx[1] = vv
        dx[2] = (T - D - m * g) / m
        dx[3] = -b * T
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    # Maximise the final altitude — a Mayer cost read off the final state.
    CTModels.Building.objective!(pre, :max; mayer=(x0_, xf, v) -> xf[1])

    # x(0) == x0  and  m(tf) == mf
    function f_boundary(res, x0_, xf, v)
        res[1] = x0_[1] - x0[1]
        res[2] = x0_[2] - x0[2]
        res[3] = x0_[3] - x0[3]
        res[4] = xf[3] - mf
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(4), ub=zeros(4), label=:goddard_boundary
    )

    CTModels.Building.constraint!(
        pre,
        :state;
        rg=1:3,
        lb=[r0, v0, mf],
        ub=[r0 + 0.1, vmax, m0],
        label=:goddard_state_box,
    )
    CTModels.Building.constraint!(
        pre, :control; rg=1:1, lb=[0.0], ub=[1.0], label=:goddard_control_box
    )
    CTModels.Building.constraint!(
        pre, :variable; rg=1:1, lb=[0.01], ub=[Inf], label=:goddard_tf_box
    )

    CTModels.Building.time_dependence!(pre; autonomous=true)

    ocp = CTModels.Building.build(pre)

    init = (state=[1.01, 0.05, 0.8], control=0.5, variable=0.1)

    return TestProblem(
        :goddard,
        :functional,
        ocp,
        _GODDARD_OBJ,
        init,
        c;
        methods=(:direct, :indirect),
        shoot_builder=_goddard_shoot_builder(ocp, c),
    )
end

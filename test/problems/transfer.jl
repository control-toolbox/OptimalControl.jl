# Orbital transfer, in both front-end forms.
#
# Minimal-time low-thrust transfer in equinoctial coordinates: 6-D state, 3-D
# control, free final time, a nonlinear path constraint on the thrust norm, and
# a partial terminal condition (only the first five components are pinned).
# The only problem in the library with a non-box path constraint, which is why
# it stays in the curated selection.

asqrt(x; ε=1e-9) = sqrt(sqrt(x^2 + ε^2))     # Avoid issues with AD

const μ = 5165.8620912                     # Earth gravitation constant

function F0(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    w = 1 + ex * cl + ey * sl
    F = [0, 0, 0, 0, 0, w^2 / (P * pdm)]
    return F
end

function F1(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    F = pdm * [0, sl, -cl, 0, 0, 0]
    return F
end

function F2(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    w = 1 + ex * cl + ey * sl
    F = pdm * [2 * P / w, cl + (ex + cl) / w, sl + (ey + sl) / w, 0, 0, 0]
    return F
end

function F3(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    w = 1 + ex * cl + ey * sl
    pdmw = pdm / w
    zz = hx * sl - hy * cl
    uh = (1 + hx^2 + hy^2) / 2
    F = pdmw * [0, -zz * ey, zz * ex, uh * cl, uh * sl, zz]
    return F
end

"""
    Transfer(form::Symbol=:abstract; Tmax=60)

Return the orbital transfer problem as a [`TestProblem`](@ref).

`data` carries the four dynamics fields `F0`–`F3`, the boundary states
`x0`/`xf`, and the thrust parameters.
"""
function Transfer(form::Symbol=:abstract; Tmax=60)
    check_form(form)
    return cached(:transfer, form, (Tmax,)) do
        form === :abstract ? _transfer_abstract(; Tmax) : _transfer_functional(; Tmax)
    end
end

const _TRANSFER_OBJ = 14.79643132

function _transfer_constants(; Tmax)
    cTmax = 3600^2 / 1e6
    T = Tmax * cTmax     # Conversion from Newtons to kg x Mm / h²
    mass0 = 1500                               # Initial mass of the spacecraft
    β = 1.42e-02                               # Engine specific impulsion
    P0 = 11.625                                # Initial semilatus rectum
    ex0, ey0 = 0.75, 0                         # Initial eccentricity
    hx0, hy0 = 6.12e-2, 0                      # Initial ascending node and inclination
    L0 = π                                     # Initial longitude
    Pf = 42.165                                # Final semilatus rectum
    exf, eyf = 0, 0                            # Final eccentricity
    hxf, hyf = 0, 0                            # Final ascending node and inclination
    Lf = 3π                                    # Estimation of final longitude
    x0 = [P0, ex0, ey0, hx0, hy0, L0]          # Initial state
    xf = [Pf, exf, eyf, hxf, hyf, Lf]          # Final state
    return (; Tmax, T, mass0, β, x0, xf, F0, F1, F2, F3)
end

function _transfer_abstract(; Tmax)
    c = _transfer_constants(; Tmax)
    T, mass0, β, x0, xf = c.T, c.mass0, c.β, c.x0, c.xf

    ocp = @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (P, ex, ey, hx, hy, L) ∈ R⁶, state
        u ∈ R³, control
        x(0) == x0
        x[1:5](tf) == xf[1:5]
        mass = mass0 - β * T * t
        ẋ(t) ==
        F0(x(t)) + T / mass * (u₁(t) * F1(x(t)) + u₂(t) * F2(x(t)) + u₃(t) * F3(x(t)))
        u₁(t)^2 + u₂(t)^2 + u₃(t)^2 ≤ 1
        tf → min
    end

    init = @init ocp begin
        tf_i = 15
        x(t) := x0 + (xf - x0) * t / tf_i       # Linear interpolation
        u(t) := [0.1, 0.5, 0.0]                  # Initial guess for the control
        tf := tf_i                              # Initial guess for final time
    end

    return TestProblem(:transfer, :abstract, ocp, _TRANSFER_OBJ, init, c)
end

function _transfer_functional(; Tmax)
    c = _transfer_constants(; Tmax)
    T, mass0, β, x0, xf = c.T, c.mass0, c.β, c.x0, c.xf

    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 1, :tf)
    CTModels.Building.time!(pre; t0=0.0, indf=1)
    CTModels.Building.state!(pre, 6, :x, [:P, :ex, :ey, :hx, :hy, :L])
    CTModels.Building.control!(pre, 3)

    # ⚠️ Non-autonomous: the mass decreases with `t`.
    function dyn!(dx, t, x, u, v)
        mass = mass0 - β * T * t
        f = F0(x) + T / mass * (u[1] * F1(x) + u[2] * F2(x) + u[3] * F3(x))
        for i in 1:6
            dx[i] = f[i]
        end
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    CTModels.Building.objective!(pre, :min; mayer=(x0_, xf_, v) -> v[1])

    # x(0) == x0 (6 components) and x[1:5](tf) == xf[1:5] — the longitude is
    # deliberately left free at the final time.
    function f_boundary(res, x0_, xf_, v)
        for i in 1:6
            res[i] = x0_[i] - x0[i]
        end
        for i in 1:5
            res[6 + i] = xf_[i] - xf[i]
        end
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(11), ub=zeros(11), label=:transfer_boundary
    )

    # Nonlinear path constraint on the thrust norm.
    function f_path(res, t, x, u, v)
        res[1] = u[1]^2 + u[2]^2 + u[3]^2
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :path; f=f_path, lb=[-Inf], ub=[1.0], label=:transfer_thrust
    )

    CTModels.Building.time_dependence!(pre; autonomous=false)

    ocp = CTModels.Building.build(pre)

    tf_i = 15
    init = (
        state=t -> x0 + (xf - x0) * t / tf_i, control=[0.1, 0.5, 0.0], variable=tf_i
    )

    return TestProblem(:transfer, :functional, ocp, _TRANSFER_OBJ, init, c)
end

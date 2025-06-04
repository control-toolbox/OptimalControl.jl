# Goddard problem
# free final time, fixed final mass, max altitude
# constraint on max speed

using CTModels # for functional definitions

# aux functions
# NB defining these inside the problem function does not seem to change the allocations
function F0(x, Cd, beta)
    r, v, m = x
    D = Cd * v^2 * exp(-beta * (r - 1))
    return [v, -D / m - 1 / r^2, 0]
end
function F1(x, Tmax, b)
    r, v, m = x
    return [0, Tmax / m, -b * Tmax]
end

# abstract definition
function goddard(; vmax=0.1, Tmax=3.5)
    # constants
    Cd = 310
    beta = 500
    b = 2
    r0 = 1
    v0 = 0
    m0 = 1
    mf = 0.6
    x0 = [r0, v0, m0]

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
        ẋ(t) == F0(x(t), Cd, beta) + u(t) * F1(x(t), Tmax, b)
        r(tf) → max
    end

    return ((ocp=goddard, obj=1.01257, name="goddard", init=(state=[1.01, 0.05, 0.8],)))
end

# all constraints, CTModels inplace functional version
function goddard_all()
    # constants
    Cd = 310
    beta = 500
    b = 2
    r0 = 1
    v0 = 0
    m0 = 1
    mf = 0.6
    vmax = 0.1
    Tmax = 3.5

    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 3)
    CTModels.control!(pre_ocp, 1)
    CTModels.variable!(pre_ocp, 1)
    CTModels.time!(pre_ocp; t0=0.0, indf=1)
    # state box (active at t0 and tf)
    CTModels.constraint!(
        pre_ocp, :state; rg=1:3, lb=[r0, v0, 0], ub=[Inf, Inf, m0], label=:state_rg
    )
    # control box (active on last bang arc)
    CTModels.constraint!(pre_ocp, :control; rg=1:1, lb=[0], ub=[Inf], label=:control_rg)
    # variable box (inactive)
    CTModels.constraint!(
        pre_ocp, :variable; rg=1:1, lb=[0.01], ub=[Inf], label=:variable_rg
    )
    # state constraint (active on constrained arc)
    # control constraint (active on first bang arc)
    # 'mixed' constraint (inactive)
    function path!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
        r[3] = x[1] + x[2] + x[3] + u[1] + v[1]
    end
    CTModels.constraint!(
        pre_ocp, :path; f=(path!), lb=[-Inf, -Inf, 0], ub=[vmax, 1, Inf], label=:path
    )
    mayer(x0, xf, v) = xf[1]
    CTModels.objective!(pre_ocp, :max; mayer=mayer)
    function f!(r, t, x, u, v)
        r[1] = x[2]
        D = Cd * x[2]^2 * exp(-beta * (x[1] - 1))
        r[2] = -D / x[3] - 1 / x[1]^2 + u[1] * Tmax / x[3]
        r[3] = -b * Tmax * u[1]
    end
    CTModels.dynamics!(pre_ocp, f!)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = x0[2]
        r[3] = x0[3]
        r[4] = xf[3]
    end
    CTModels.constraint!(
        pre_ocp,
        :boundary;
        f=(bc!),
        lb=[r0, v0, m0, mf],
        ub=[r0, v0, m0, mf],
        label=:boundary,
    )
    CTModels.definition!(pre_ocp, Expr(:goddard_all))
    CTModels.time_dependence!(pre_ocp; autonomous=true)
    ocp = CTModels.build(pre_ocp)

    return ((
        ocp=ocp,
        obj=1.01257,
        name="goddard_all_constraints",
        init=(state=[1.01, 0.05, 0.8],),
    ))
end

# all constraints, CTModels outplace functional version
function goddard_all_outplace()
    # constants
    Cd = 310
    beta = 500
    b = 2
    r0 = 1
    v0 = 0
    m0 = 1
    mf = 0.6
    vmax = 0.1
    Tmax = 3.5

    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 3)
    CTModels.control!(pre_ocp, 1)
    CTModels.variable!(pre_ocp, 1)
    CTModels.time!(pre_ocp; t0=0.0, indf=1)
    # state box (active at t0 and tf)
    CTModels.constraint!(
        pre_ocp, :state; rg=1:3, lb=[r0, v0, 0], ub=[Inf, Inf, m0], label=:state_rg
    )
    # control box (active on last bang arc)
    CTModels.constraint!(pre_ocp, :control; rg=1:1, lb=[0], ub=[Inf], label=:control_rg)
    # variable box (inactive)
    CTModels.constraint!(
        pre_ocp, :variable; rg=1:1, lb=[0.01], ub=[Inf], label=:variable_rg
    )
    # state constraint (active on constrained arc)
    # control constraint (active on first bang arc)
    # 'mixed' constraint (inactive)
    function path(t, x, u, v)
        return [x[2], u[1], x[1] + x[2] + x[3] + u[1] + v[1]]
    end
    CTModels.constraint!(
        pre_ocp, :path; f=path, lb=[-Inf, -Inf, 0], ub=[vmax, 1, Inf], label=:path
    )
    mayer(x0, xf, v) = xf[1]
    CTModels.objective!(pre_ocp, :max; mayer=mayer)
    function f(r, t, x, u, v)
        D = Cd * x[2]^2 * exp(-beta * (x[1] - 1))
        return [x[2], -D / x[3] - 1 / x[1]^2 + u[1] * Tmax / x[3], -b * Tmax * u[1]]
    end
    CTModels.dynamics!(pre_ocp, f)
    function bc(x0, xf, v)
        return [x0[1], x0[2], x0[3], xf[3]]
    end
    CTModels.constraint!(
        pre_ocp, :boundary; f=bc, lb=[r0, v0, m0, mf], ub=[r0, v0, m0, mf], label=:boundary
    )
    CTModels.definition!(pre_ocp, Expr(:goddard_all))
    CTModels.time_dependence!(pre_ocp; autonomous=true)
    ocp = CTModels.build(pre_ocp)

    return ((
        ocp=ocp,
        obj=1.01257,
        name="goddard_all_constraints",
        init=(state=[1.01, 0.05, 0.8],),
    ))
end

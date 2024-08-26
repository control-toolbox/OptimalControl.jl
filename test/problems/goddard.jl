# Goddard problem
# free final time, fixed final mass, max altitude
# constraint on max speed

# aux functions
function F0(x, Cd, beta)
    r, v, m = x
    D = Cd * v^2 * exp(-beta * (r - 1))
    return [v, -D / m - 1 / r^2, 0]
end
function F1(x, Tmax, b)
    r, v, m = x
    return [0, Tmax / m, -b * Tmax]
end

function goddard(; vmax = 0.1, Tmax = 3.5, functional_constraints = false)
    # constants
    Cd = 310
    beta = 500
    b = 2
    r0 = 1
    v0 = 0
    m0 = 1
    mf = 0.6
    x0 = [r0, v0, m0]

    #ocp
    goddard = Model(variable = true)
    state!(goddard, 3)
    control!(goddard, 1)
    variable!(goddard, 1)
    time!(goddard, t0 = 0, indf = 1)
    constraint!(goddard, :initial, lb = x0, ub = x0)
    constraint!(goddard, :final, rg = 3, lb = mf, ub = Inf)
    if functional_constraints
        # note: the equations do not handle r<1 well
        # without the box constraint on x, the default init (0.1) is not suitable
        constraint!(goddard, :state, f = (x, v) -> x, lb = [r0, v0, mf], ub = [r0 + 0.2, vmax, m0])
        constraint!(goddard, :control, f = (u, v) -> u, lb = 0, ub = 1)
    else
        constraint!(goddard, :state, lb = [r0, v0, mf], ub = [r0 + 0.2, vmax, m0])
        constraint!(goddard, :control, lb = 0, ub = 1)
    end
    constraint!(goddard, :variable, lb = 0.01, ub = Inf)
    objective!(goddard, :mayer, (x0, xf, v) -> xf[1], :max)
    dynamics!(goddard, (x, u, v) -> F0(x, Cd, beta) + u * F1(x, Tmax, b))

    return ((ocp = goddard, obj = 1.01257, name = "goddard", init = (state = [1.01, 0.05, 0.8],)))
end

# abstratc definition
function goddard_a(; vmax = 0.1, Tmax = 3.5)
    # constants
    Cd = 310
    beta = 500
    b = 2
    r0 = 1
    v0 = 0
    m0 = 1
    mf = 0.6
    x0 = [r0, v0, m0]

    @def goddard_a begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R^3, state
        u ∈ R, control
        0.1 ≤ tf ≤ Inf
        r = x[1]
        v = x[2]
        m = x[3]
        x(0) == x0
        m(tf) == mf
        r0 ≤ r(t) ≤ 1.1
        v0 ≤ v(t) ≤ 0.1
        mf ≤ m(t) ≤ m0
        0 ≤ u(t) ≤ 1
        ẋ(t) == F0(x(t), Cd, beta) + u(t) * F1(x(t), Tmax, b)
        r(tf) → max
    end

    return ((
        ocp = goddard_a,
        obj = 1.01257,
        name = "goddard_a",
        init = (state = [1.01, 0.05, 0.8],),
    ))
end

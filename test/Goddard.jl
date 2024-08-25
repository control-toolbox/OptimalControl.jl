function Goddard()

    # parameters
    Cd = 310
    Tmax = 3.5
    β = 500
    b = 2
    t0 = 0
    r0 = 1
    v0 = 0
    vmax = 0.1
    m0 = 1
    mf = 0.6
    x0 = [r0, v0, m0]

    # the model    
    @def ocp begin
        # parameters
        Cd = 310
        Tmax = 3.5
        β = 500
        b = 2
        t0 = 0
        r0 = 1
        v0 = 0
        vmax = 0.1
        m0 = 1
        mf = 0.6
        x0 = [r0, v0, m0]

        # variables
        tf ∈ R, variable
        t ∈ [t0, tf], time
        x ∈ R³, state
        u ∈ R, control
        r = x₁
        v = x₂
        m = x₃

        # constraints
        0 ≤ u(t) ≤ 1, (u_con)
        r(t) ≥ r0, (x_con_rmin)
        0 ≤ v(t) ≤ vmax, (x_con_vmax)
        x(t0) == x0, (initial_con)
        m(tf) == mf, (final_con)

        # dynamics
        ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

        # objective
        r(tf) → max
    end

    # dynamics
    function F0(x)
        r, v, m = x
        D = Cd * v^2 * exp(-β * (r - 1))
        return [v, -D / m - 1 / r^2, 0]
    end
    function F1(x)
        r, v, m = x
        return [0, Tmax / m, -b * Tmax]
    end

    #
    objective = 1.0125762700748699

    return ocp, objective

end

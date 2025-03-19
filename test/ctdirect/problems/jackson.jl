# Jackson example from Bocop
function jackson()
    # constants
    k1 = 1
    k2 = 10
    k3 = 1

    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 3)
    CTModels.control!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, tf=4)
    CTModels.constraint!(pre_ocp, :control, rg=1:1, lb=[0], ub=[1], label=:control_rg)
    CTModels.constraint!(pre_ocp, :state, rg=1:3, lb=[0, 0, 0], ub=[1.1, 1.1, 1.1], label=:state_rg)
    function bc!(r, x0, xf, v)
        r .= x0
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[1, 0, 0], ub=[1, 0, 0], label=:boundary)
    function f!(r, t, x, u, v)
        r[1] = -u[1] * (k1 * x[1] - k2 * x[2])
        r[2] = u[1] * (k1 * x[1] - k2 * x[2]) - (1 - u[1]) * k3 * x[2]
        r[3] = (1 - u[1]) * k3 * x[2]
    end
    CTModels.dynamics!(pre_ocp, f!)
    mayer(x0, xf, v) = xf[3]
    CTModels.objective!(pre_ocp, :max, mayer=mayer)
    CTModels.definition!(pre_ocp, Expr(:jackson))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 1.92011e-1, name = "jackson", init = nothing))
end

#=function jackson()
    @def jackson begin
        # constants
        k1 = 1
        k2 = 10
        k3 = 1

        t ∈ [0, 4], time
        x ∈ R³, state
        u ∈ R, control
        [0, 0, 0] ≤ x(t) ≤ [1.1, 1.1, 1.1]
        0 ≤ u(t) ≤ 1
        x(0) == [1, 0, 0]
        a = x[1]
        b = x[2]
        ẋ(t) == [
            -u(t) * (k1 * a(t) - k2 * b(t)),
            u(t) * (k1 * a(t) - k2 * b(t)) - (1 - u(t)) * k3 * b(t),
            (1 - u(t)) * k3 * b(t),
        ]
        x[3](4) → max
    end

    return ((ocp = jackson, obj = 0.192011, name = "jackson", init = nothing))
end=#

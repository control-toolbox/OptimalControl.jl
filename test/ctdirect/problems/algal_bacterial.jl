# Optimal control of an algal-bacterial consortium system. Original code from Rand Asswad.

function algal_bacterial()

    # parameters
    s_in = 0.5
    β = 23e-3
    γ = 0.44
    dmax = 1.5
    ϕmax = 6.48; ks = 0.09;
    ρmax = 27.3e-3; kv = 0.57e-3;
    μmax = 1.0211; qmin = 2.7628e-3;
    ϕ(s) = ϕmax * s / (ks + s)
    ρ(v) = ρmax * v / (kv + v)
    μ(q) = μmax * (1 - qmin / q)
    t0 = 0; tf = 20
    x0 = [0.1629, 0.0487, 0.0003, 0.0177, 0.035, 0]

    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 6)
    CTModels.control!(pre_ocp, 2)
    CTModels.time!(pre_ocp, t0=0.0, tf=20.0)
    function bc!(r, x0, xf, v)
        r .= x0 #ok
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=x0, ub=x0, label=:boundary)
    CTModels.constraint!(pre_ocp, :state, rg=1:6, lb=[0, 0, 0, qmin, 0, 0], ub=[Inf,Inf,Inf,Inf,Inf,Inf], label=:state_rg)
    CTModels.constraint!(pre_ocp, :control, rg=1:2, lb=[0, 0], ub=[1, dmax], label=:control_rg)
    function f!(r, t, x, u, v)
        r[1] = u[2]*(s_in - x[1]) - ϕ(x[1])*x[2]/γ
        r[2] = ((1 - u[1])*ϕ(x[1]) - u[2])*x[2]
        r[3] = u[1]*β*ϕ(x[1])*x[2] - ρ(x[3])*x[5] - u[2]*x[3]
        r[4] = ρ(x[3]) - μ(x[4])*x[4]
        r[5] = (μ(x[4]) - u[2])*x[5]
        r[6] = u[2]*x[5]
        #=r .= [ u[2]*(s_in - x[1]) - ϕ(x[1])*x[2]/γ,
            ((1 - u[1])*ϕ(x[1]) - u[2])*x[2],
            u[1]*β*ϕ(x[1])*x[2] - ρ(x[3])*x[5] - u[2]*x[3],
            ρ(x[3]) - μ(x[4])*x[4],
            (μ(x[4]) - u[2])*x[5],
            u[2]*x[5] ] more allocations but less memory, similar speed =#
    end
    CTModels.dynamics!(pre_ocp, f!)
    mayer(x0, xf, v) = xf[6]
    CTModels.objective!(pre_ocp, :max, mayer=mayer)
    CTModels.definition!(pre_ocp, Expr(:algal_bacterial))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 5.45, name = "algal_bacterial", init = nothing))
end

# some test problems with free times

function bolza_freetf()
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 1)
    CTModels.control!(pre_ocp, 1)
    CTModels.variable!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, indf=1)
    function f!(r, t, x, u, v)
        r[1] = v[1] * u[1]
    end 
    CTModels.dynamics!(pre_ocp, f!)
    l(t, x, u, v) = 0.5 * u[1].^2
    mayer(x0, xf, v) = v[1]
    CTModels.objective!(pre_ocp, :min, lagrange=l, mayer=mayer)
    CTModels.definition!(pre_ocp, Expr(:bolza))
    CTModels.constraint!(pre_ocp, :state, rg=1:1, lb=[0], ub=[Inf], label=:state_rg)
    CTModels.constraint!(pre_ocp, :variable, rg=1:1, lb=[0.1], ub=[Inf], label=:variable_rg)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = xf[1]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[0, 1], ub=[0, 1], label=:boundary)

    ocp = CTModels.build_model(pre_ocp)
    return ((ocp = ocp, obj = 1.476, name = "bolza_freetf", init = nothing))    
end

#=function bolza_freetf()
    @def ocp begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R, state
        u ∈ R, control
        tf >= 0.1
        x(t) >= 0
        ẋ(t) == tf * u(t)
        x(0) == 0
        x(tf) == 1
        tf + 0.5∫(u(t)^2) → min
    end

    return ((ocp = ocp, obj = 1.476, name = "bolza_freetf", init = nothing))
end=#

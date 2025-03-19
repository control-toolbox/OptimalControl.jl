# simple intergator

# define problem with new model: simple integrator
function simple_integrator()
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 1)
    CTModels.control!(pre_ocp, 2)
    CTModels.time!(pre_ocp, t0=0.0, tf=1.0)
    f!(r, t, x, u, v) = r .=  .- x[1] .- u[1] .+ u[2] 
    CTModels.dynamics!(pre_ocp, f!)
    l(t, x, u, v) = (u[1] .+ u[2]).^2
    CTModels.objective!(pre_ocp, :min, lagrange=l)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = xf[1]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[-1, 0], ub=[-1, 0], label=:boundary)
    CTModels.constraint!(pre_ocp, :control, rg=1:2, lb=[0, 0], ub=[Inf, Inf], label=:control_rg)
    CTModels.definition!(pre_ocp, Expr(:simple_integrator_min_energy))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 3.13e-1, name = "simple_integrator", init = nothing))
end

function simple_integrator_v()
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 1)
    CTModels.control!(pre_ocp, 2)
    CTModels.variable!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, tf=1.0)
    f!(r, t, x, u, v) = r .=  .- x[1] .- u[1] .+ u[2] 
    CTModels.dynamics!(pre_ocp, f!)
    l(t, x, u, v) = (u[1] .+ u[2]).^2
    CTModels.objective!(pre_ocp, :min, lagrange=l)
    function bc!(r, x0, xf, v)
        r[1] = x0[1] + v[1]
        r[2] = xf[1]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[-1, 0], ub=[-1, 0], label=:boundary)
    CTModels.constraint!(pre_ocp, :control, rg=1:2, lb=[0, 0], ub=[Inf, Inf], label=:control_rg)
    CTModels.definition!(pre_ocp, Expr(:simple_integrator_min_energy))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 0., name = "simple_integrator_v", init = nothing))
end

#= min enery, dual control (no constraint u1 * u2 = 0 cf objective)
function simple_integrator()
    @def ocp begin
        t ∈ [0, 1], time
        x ∈ R, state
        u ∈ R², control
        [0, 0] ≤ u(t) ≤ [Inf, Inf]
        x(0) == -1
        x(1) == 0
        ẋ(t) == -x(t) -u[1](t) + u[2](t)
        ∫((u[1](t)+u[2](t))^2) → min
    end

    return ((ocp = ocp, obj = 3.13e-1, name = "simple_integrator", init = nothing))
end=#

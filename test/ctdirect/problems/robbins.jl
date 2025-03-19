# Robbins example from Bocop
function robbins()
    # constants
    alpha = 3
    beta = 0
    gamma = 0.5    
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 3)
    CTModels.control!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, tf=10)
    CTModels.constraint!(pre_ocp, :state, rg=1:1, lb=[0], ub=[Inf], label=:state_rg)
    function bc!(r, x0, xf, v)
        r[1:3] .= x0
        r[4:6] .= xf
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[1, -2, 0, 0, 0, 0], ub=[1, -2, 0, 0, 0, 0], label=:boundary)
    function f!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = x[3]
        r[3] = u[1]
    end
    CTModels.dynamics!(pre_ocp, f!)
    l(t, x, u, v) = alpha * x[1] + beta * x[1]^2 + gamma * u[1]^2
    CTModels.objective!(pre_ocp, :min, lagrange=l)
    CTModels.definition!(pre_ocp, Expr(:robbins))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 19.44, name = "robbins", init = nothing))
end

#=function robbins()
    @def robbins begin
        # constants
        alpha = 3
        beta = 0
        gamma = 0.5

        t ∈ [0, 10], time
        x ∈ R³, state
        u ∈ R, control
        0 ≤ x[1](t) ≤ Inf
        x(0) == [1, -2, 0]
        x(10) == [0, 0, 0]
        ẋ(t) == [x[2](t), x[3](t), u(t)]
        ∫(alpha * x[1](t) + beta * x[1](t)^2 + gamma * u(t)^2) → min
    end

    return ((ocp = robbins, obj = 20.0, name = "robbins", init = nothing))
end=#

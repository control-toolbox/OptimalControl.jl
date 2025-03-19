# Van der Pol example from Bocop
function vanderpol()
    # constants
    omega = 1
    epsilon = 1

    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 2)
    CTModels.control!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, tf=2)
    function f!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = epsilon * omega * (1 - x[1]^2) * x[2] - omega^2 * x[1] + u[1]
    end 
    CTModels.dynamics!(pre_ocp, f!)
    l(t, x, u, v) = 0.5 * (x[1]^2 + x[2]^2 + u[1]^2)
    CTModels.objective!(pre_ocp, :min, lagrange=l)
    function bc!(r, x0, xf, v)
        r.= x0
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[1, 0], ub=[1, 0], label=:boundary)
    CTModels.definition!(pre_ocp, Expr(:vanderpol))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 1.047921, name = "vanderpol", init = nothing))
end

#=function vanderpol()
    @def vanderpol begin
        # constants
        omega = 1
        epsilon = 1

        t ∈ [0, 2], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [1, 0]
        ẋ(t) == [x[2](t), epsilon * omega * (1 - x[1](t)^2) * x[2](t) - omega^2 * x[1](t) + u(t)]
        ∫(0.5 * (x[1](t)^2 + x[2](t)^2 + u(t)^2)) → min
    end

    return ((ocp = vanderpol, obj = 1.047921, name = "vanderpol", init = nothing))
end=#


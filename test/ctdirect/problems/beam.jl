# Beam example from bocop

function beam()
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 2)
    CTModels.control!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, tf=1.0)
    function f!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
    end 
    CTModels.dynamics!(pre_ocp, f!)
    l(t, x, u, v) = u[1].^2
    CTModels.objective!(pre_ocp, :min, lagrange=l)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = x0[2]
        r[3] = xf[1]
        r[4] = xf[2]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[0, 1, 0, -1], ub=[0, 1, 0, -1], label=:boundary)
    CTModels.constraint!(pre_ocp, :control, rg=1:1, lb=[-10], ub=[10], label=:control_rg)
    CTModels.constraint!(pre_ocp, :state, rg=1:2, lb=[0, -Inf], ub=[0.1, Inf], label=:state_rg)
    CTModels.definition!(pre_ocp, Expr(:beam))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 8.898598, name = "beam", init = nothing))
end


function beam2()
    @def beam begin
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [0, 1]
        x(1) == [0, -1]
        ẋ(t) == [x₂(t), u(t)]
        0 ≤ x₁(t) ≤ 0.1
        -10 ≤ u(t) ≤ 10
        ∫(u(t)^2) → min
    end

    return ((ocp = beam, obj = 8.898598, name = "beam", init = nothing))
end

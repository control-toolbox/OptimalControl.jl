# Fuller example

# define problem with new model: fuller
function fuller()
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 2)
    CTModels.control!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, tf=3.5)
    function f!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
    end 
    CTModels.dynamics!(pre_ocp, f!)
    l(t, x, u, v) = x[1]^2
    CTModels.objective!(pre_ocp, :min, lagrange=l)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = x0[2]
        r[3] = xf[1]
        r[4] = xf[2]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[0, 1, 0, 0], ub=[0, 1, 0, 0], label=:boundary)
    CTModels.constraint!(pre_ocp, :control, rg=1:1, lb=[-1], ub=[1], label=:control_rg)
    CTModels.definition!(pre_ocp, Expr(:fuller_min_energy))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 2.683944e-1, name = "fuller", init = nothing))
end

#=function fuller()
    @def fuller begin
        t ∈ [0, 3.5], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(0) == [0, 1]
        x(3.5) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(x₁(t)^2) → min
    end

    return ((ocp = fuller, obj = 2.683944e-1, name = "fuller", init = nothing))
end=#

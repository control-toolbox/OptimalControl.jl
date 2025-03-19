# double integrator

# define problem with new model: double integrator
function double_integrator_mintf()
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 2)
    CTModels.control!(pre_ocp, 1)
    CTModels.variable!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, indf=1)
    function f!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
    end 
    CTModels.dynamics!(pre_ocp, f!)
    mayer(x0, xf, v) = v[1]
    CTModels.objective!(pre_ocp, :min, mayer=mayer)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = x0[2]
        r[3] = xf[1]
        r[4] = xf[2]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[0, 0, 1, 0], ub=[0, 0, 1, 0], label=:boundary)
    CTModels.constraint!(pre_ocp, :control, rg=1:1, lb=[-1], ub=[1], label=:control_rg)
    CTModels.constraint!(pre_ocp, :variable, rg=1:1, lb=[0.05], ub=[Inf], label=:variable_rg)
    CTModels.definition!(pre_ocp, Expr(:double_integrator_min_tf))
    ocp = CTModels.build_model(pre_ocp)
    
    return ((ocp = ocp, obj = 2.0, name = "double_integrator_mintf", init = nothing))
end


#= min tf
function double_integrator_mintf()
    @def ocp begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(0) == [0, 0]
        x(tf) == [1, 0]
        0.05 ≤ tf ≤ Inf
        ẋ(t) == [x₂(t), u(t)]
        tf → min
    end

    return ((ocp = ocp, obj = 2.0, name = "double_integrator_mintf", init = nothing))
end
=#

# min energy with fixed tf
function double_integrator_minenergy(T=2)
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 2)
    CTModels.control!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0.0, tf=T)
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
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[0, 0, 1, 0], ub=[0, 0, 1, 0], label=:boundary)
    CTModels.definition!(pre_ocp, Expr(:double_integrator_minenergy))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = nothing, name = "double_integrator_minenergy", init = nothing))
end

#=
function double_integrator_minenergy(T=2)
    @def ocp begin
        t ∈ [0, T], time
        x ∈ R², state
        u ∈ R, control
        q = x₁
        v = x₂
        q(0) == 0
        v(0) == 0
        q(T) == 1
        v(T) == 0
        ẋ(t) == [v(t), u(t)]
        ∫(u(t)^2) → min
    end

    return ((ocp = ocp, obj = nothing, name = "double_integrator_minenergy", init = nothing))
end=#

# max t0 with free t0,tf
function double_integrator_freet0tf()
    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 2)
    CTModels.control!(pre_ocp, 1)
    CTModels.variable!(pre_ocp, 2)
    CTModels.time!(pre_ocp, ind0=1, indf=2)
    function f!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
    end 
    CTModels.dynamics!(pre_ocp, f!)
    mayer(x0, xf, v) = v[1]
    CTModels.objective!(pre_ocp, :max, mayer=mayer)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = x0[2]
        r[3] = xf[1]
        r[4] = xf[2]
        r[5] = v[2] - v[1]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[0, 0, 1, 0, 0.01], ub=[0, 0, 1, 0, Inf], label=:boundary)
    CTModels.constraint!(pre_ocp, :control, rg=1:1, lb=[-1], ub=[1], label=:control_rg)
    CTModels.constraint!(pre_ocp, :variable, rg=1:2, lb=[0.05,0.05], ub=[10,10], label=:variable_rg)
    CTModels.definition!(pre_ocp, Expr(:double_integrator_freet0tf))
    ocp = CTModels.build_model(pre_ocp)

    return ((ocp = ocp, obj = 8.0, name = "double_integrator_freet0tf", init = nothing))
end

#=
function double_integrator_freet0tf(lagrange = false)
    @def ocp begin
        v ∈ R², variable
        t0 = v₁
        tf = v₂
        t ∈ [t0, tf], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(t0) == [0, 0]
        x(tf) == [1, 0]
        0.05 ≤ t0 ≤ 10        
        0.05 ≤ tf ≤ 10
        0.01 ≤ tf - t0 ≤ Inf
        ẋ(t) == [x₂(t), u(t)]
        t0 → max
    end

    return ((ocp = ocp, obj = 8.0, name = "double_integrator_freet0tf", init = nothing))
end=#

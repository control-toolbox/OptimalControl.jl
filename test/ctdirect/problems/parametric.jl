# Parametric problem (name ??)

function parametric(ρ)

    relu(x) = max(0, x)
    μ = 10
    p_relu(x) = log(abs(1 + exp(μ * x))) / μ
    f(x) = 1 - x
    m(x) = (p_relu ∘ f)(x)
    T = 2

    pre_ocp = CTModels.PreModel()
    CTModels.state!(pre_ocp, 2)
    CTModels.control!(pre_ocp, 2)
    CTModels.variable!(pre_ocp, 1)
    CTModels.time!(pre_ocp, t0=0, tf=1)

    CTModels.constraint!(pre_ocp, :control, rg=1:2, lb=[-1,-1], ub=[1,1], label=:control_rg)
    CTModels.constraint!(pre_ocp, :variable, rg=1:1, lb=[0], ub=[T], label=:variable_rg)
    
    function f!(r, t, x, u, v)
        τ = v[1]
        r[1] = τ * (u[1] + 2) 
        r[2] = (T - τ) * u[2]
    end 
    CTModels.dynamics!(pre_ocp, f!)
    function bc!(r, x0, xf, v)
        r[1] = x0[1]
        r[2] = x0[2]
        r[3] = xf[1]
    end
    CTModels.constraint!(pre_ocp, :boundary, f=bc!, lb=[0, 1, 1], ub=[0, 1, 1], label=:boundary)
    mayer(x0, xf, v) = -(xf[2] - 2)^3
    function l(t, x, u, v) 
        τ = v[1]
        return - ρ * (τ * m(x[1])^2 + (T - τ) * m(x[2])^2)
    end
    CTModels.objective!(pre_ocp, :min, lagrange=l, mayer=mayer)

    CTModels.definition!(pre_ocp, Expr(:parametric))
    ocp = CTModels.build_model(pre_ocp)
    return ((ocp = ocp, obj = nothing, name = "parametric", init = nothing))
end

#=function parametric(ρ)
    relu(x) = max(0, x)
    μ = 10
    p_relu(x) = log(abs(1 + exp(μ * x))) / μ
    f(x) = 1 - x
    m(x) = (p_relu ∘ f)(x)
    T = 2

    @def param begin
        τ ∈ R, variable
        s ∈ [0, 1], time
        x ∈ R², state
        u ∈ R², control
        x₁(0) == 0
        x₂(0) == 1
        x₁(1) == 1
        ẋ(s) == [τ * (u₁(s) + 2), (T - τ) * u₂(s)]
        -1 ≤ u₁(s) ≤ 1
        -1 ≤ u₂(s) ≤ 1
        0 ≤ τ ≤ T
        -(x₂(1) - 2)^3 - ∫(ρ * (τ * m(x₁(s))^2 + (T - τ) * m(x₂(s))^2)) → min
    end

    return ((ocp = param, obj = nothing, name = "parametric", init = nothing))
end=#

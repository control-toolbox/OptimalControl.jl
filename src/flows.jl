# u0(x, p)
# f0 = Flow(ocp, u0)
# ub(x, p)
# μb(x, p)
# fb = Flow(ocp, ub, :state_con2_upper, μb)

function H(f::Function, u::Function)
    return (x, p) -> p'*f(x,u(x,p))
end

function H(f::Function, u::Function, f⁰::Function, p⁰::MyNumber)
    return (x, p) -> p'*f(x,u(x,p)) + p⁰*f⁰(x,u(x,p))
end

function H(f::Function, u::Function, μ::Function, g::Function)
    return (x, p) -> p'*f(x,u(x,p)) + μ(x,p)*g(x,u(x,p))
end

function H(f::Function, u::Function, f⁰::Function, p⁰::MyNumber, μ::Function, g::Function)
    return (x, p) -> p'*f(x,u(x,p)) + p⁰*f⁰(x,u(x,p)) + μ(x,p)*g(x,u(x,p))
end

function HamiltonianFlows.Flow(ocp::OptimalControlModel, u::Function)

    p⁰ = -1.
    f  = ocp.dynamics
    f! = ocp.dynamics!
    f⁰ = ocp.lagrangian        

    # construct Hamiltonian
    # autonomous case
    if f ≠ nothing
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? H(f, u, f⁰, p⁰)(x,p) : H(f, u)(x,p))
    elseif f! ≠ nothing
        function f_(x, u)
            dx = zeros(eltype(x), length(x))
            f!(dx, x, u)
            return dx
        end
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? H(f_, u, f⁰, p⁰)(x,p) : H(f_, u)(x,p))
    else 
        error("no dynamics in ocp")
    end

    return HamiltonianFlows.Flow(Ham)

end

function _Flow(ocp::OptimalControlModel, u::Function, g::Function, μ::Function)

    p⁰ = -1.
    f  = ocp.dynamics
    f! = ocp.dynamics!
    f⁰ = ocp.lagrangian        

    # construct Hamiltonian
    # autonomous case
    if f ≠ nothing
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? H(f, u, f⁰, p⁰, μ, g)(x,p) : H(f, u, μ, g)(x,p))
    elseif f! ≠ nothing
        function f_(x, u)
            dx = zeros(eltype(x), length(x))
            f!(dx, x, u)
            return dx
        end
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? H(f_, u, f⁰, p⁰, μ, g)(x,p) : H(f_, u, μ, g)(x,p))
    else 
        error("no dynamics in ocp")
    end

    return HamiltonianFlows.Flow(Ham)

end

function HamiltonianFlows.Flow(ocp::OptimalControlModel, u::Function, label::Symbol, bound::Symbol, μ::Function)
    type, _, c, lb, ub = ocp.constraints[label]
    if !( bound in [ :lower, :upper ] )
        error("this constraint is not valid")
    end
    if (bound == :lower && lb == -Inf) || (bound == :upper && ub == Inf)
        error("this constraint is not valid")
    end
    if type == :state
        f = _Flow(ocp, u, bound == :lower ? (x, u) -> c(x, u) - lb : (x, u) -> ub - c(x,u), μ)
    else
        error("this constraint is not valid")
    end
    return f
end

function HamiltonianFlows.Flow(ocp::OptimalControlModel, u::Function, label::Symbol, μ::Function)
    con = ocp.constraints[label]
    if length(con) != 4
        nothing
    else
        error("this constraint is not valid")
    end
    type, _, c, val = con
    if type == :state
        f = _Flow(ocp, u, (x, u) -> c(x, u) - val, μ)
    else
        error("this constraint is not valid")
    end
    return f
end
# u0(x, p)
# f0 = Flow(ocp, u0)
# ub(x, p)
# μb(x, p)
# fb = Flow(ocp, ub, :state_con2_upper, μb)

function Flow(ocp::OptimalControlModel, u::Function)

    p⁰ = -1.

    # construct Hamiltonian
    # autonomous case
    if ocp.dynamics ≠ nothing
        f(x, u) = ocp.dynamics(x, u)
    elseif ocp.dynamics! ≠ nothing
        f! = ocp.dynamics!
        function f(x, u)
            dx = zeros(eltype(x), length(x))
            f!(dx, x, u)
            return dx
        end
    else 
        error("no dynamics in ocp")
    end

    ocp.lagrangian === nothing ? H(x,p) = p'*f(x,u(x,p)) : 
    H(x,p) = p'*f(x,u(x,p)) + p⁰*ocp.lagrangian(x,u(x,p))

    return HamiltonianFlows.Flow(Hamiltonian(H))

end

function Flow(ocp::OptimalControlModel, u::Function, g::Function, μ::Function)

    p⁰ = -1.

    # construct Hamiltonian
    # autonomous case
    if ocp.dynamics ≠ nothing
        f(x, u) = ocp.dynamics(x, u)
    elseif ocp.dynamics! ≠ nothing
        f! = ocp.dynamics!
        function f(x, u)
            dx = zeros(eltype(x), length(x))
            f!(dx, x, u)
            return dx
        end
    else 
        error("no dynamics in ocp")
    end

    ocp.lagrangian === nothing ? H(x,p) = p'*f(x,u(x,p)) + μ(x,p)*g(x,u(x,p)) : 
    H(x,p) = p'*f(x,u(x,p)) + p⁰*ocp.lagrangian(x,u(x,p)) + μ(x,p)*g(x,u(x,p))

    return HamiltonianFlows.Flow(Hamiltonian(H))

end

function Flow(ocp::OptimalControlModel, u::Function, lg::Symbol, μ::Function)
    g = ocp.constraints[lg][3]
    return Flow(ocp, u, g, μ)
end
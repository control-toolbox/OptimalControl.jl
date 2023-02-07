function makeH(f::Function, u::Function)
    return (x, p) -> p'*f(x,u(x,p))
end

function makeH(f::Function, u::Function, f⁰::Function, p⁰::MyNumber, s::MyNumber)
    return (x, p) -> p'*f(x,u(x,p)) + s*p⁰*f⁰(x,u(x,p))
end

function makeH(f::Function, u::Function, μ::Function, c::Function)
    return (x, p) -> p'*f(x,u(x,p)) + μ(x,p)'*c(x,u(x,p))
end

function makeH(f::Function, u::Function, f⁰::Function, p⁰::MyNumber, μ::Function, c::Function, s::MyNumber)
    return (x, p) -> p'*f(x,u(x,p)) + s*p⁰*f⁰(x,u(x,p)) + μ(x,p)'*c(x,u(x,p))
end

function HamiltonianFlows.Flow(ocp::OptimalControlModel, u::Function)

    p⁰ = -1.
    f  = ocp.dynamics
    f! = ocp.dynamics!
    f⁰ = ocp.lagrange        

    s = ocp.criterion == :min ? 1.0 : -1.0 # 

    # construct Hamiltonian
    # autonomous case
    if f ≠ nothing
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? makeH(f, u, f⁰, p⁰, s)(x,p) : makeH(f, u)(x,p))
    elseif f! ≠ nothing
        function f_(x, u)
            dx = zeros(eltype(x), length(x))
            f!(dx, x, u)
            return dx
        end
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? makeH(f_, u, f⁰, p⁰, s)(x,p) : makeH(f_, u)(x,p))
    else 
        error("no dynamics in ocp")
    end

    return HamiltonianFlows.Flow(Ham)

end

function HamiltonianFlows.Flow(ocp::OptimalControlModel, u::Function, c::Function, μ::Function)

    p⁰ = -1.
    f  = ocp.dynamics
    f! = ocp.dynamics!
    f⁰ = ocp.lagrange        

    # construct Hamiltonian
    # autonomous case
    if f ≠ nothing
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? makeH(f, u, f⁰, p⁰, μ, c, s)(x,p) : makeH(f, u, μ, c)(x,p))
    elseif f! ≠ nothing
        function f_(x, u)
            dx = zeros(eltype(x), length(x))
            f!(dx, x, u)
            return dx
        end
        Ham = Hamiltonian((x, p) -> f⁰ ≠ nothing ? makeH(f_, u, f⁰, p⁰, μ, c, s)(x,p) : makeH(f_, u, μ, c)(x,p))
    else 
        error("no dynamics in ocp")
    end

    return HamiltonianFlows.Flow(Ham)

end
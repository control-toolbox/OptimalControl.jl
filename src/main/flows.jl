function makeH(f::DynamicsFunction, u::ControlFunction)
    return (t, x, p) -> p'*f(t, x, u(t, x, p))
end

function makeH(f::DynamicsFunction, u::ControlFunction, f⁰::LagrangeFunction, p⁰::MyNumber, s::MyNumber)
    function H(t, x, p)
        u_ = u(t, x, p)
        return p'*f(t, x, u_) + s*p⁰*f⁰(t, x, u_)
    end
    return H
end

function makeH(f::DynamicsFunction, u::ControlFunction, g::MixedConstraintFunction, μ::MultiplierFunction)
    function H(t, x, p)
        u_ = u(t, x, p)
        return p'*f(t, x, u_) + μ(t, x, p)'*g(t, x, u_)
    end
    return H
end

function makeH(f::DynamicsFunction, u::ControlFunction, f⁰::LagrangeFunction, p⁰::MyNumber, s::MyNumber, g::MixedConstraintFunction, μ::MultiplierFunction)
    function H(t, x, p)
        u_ = u(t, x, p)
        return p'*f(t, x, u_) + s*p⁰*f⁰(t, x, u_) + μ(t, x, p)'*g(t, x, u_)
    end
    return H
end

function HamiltonianFlows.Flow(ocp::OptimalControlModel{time_dependence}, u_::Function) where {time_dependence}

    p⁰ = -1.
    f  = dynamics(ocp)
    f⁰ = lagrange(ocp)
    s  = ismin(ocp) ? 1.0 : -1.0 #

    # construction of the Hamiltonian
    if f ≠ nothing
        u = ControlFunction{time_dependence}(u_) # coherence is needed on the time dependence
        H = Hamiltonian{:nonautonomous}(f⁰ ≠ nothing ? makeH(f, u, f⁰, p⁰, s) : makeH(f, u))
    else 
        error("no dynamics in ocp")
    end

    return HamiltonianFlows.Flow(H)

end

function HamiltonianFlows.Flow(ocp::OptimalControlModel{time_dependence}, u_::Function, g_::Function, μ_::Function) where {time_dependence}

    p⁰ = -1.
    f  = dynamics(ocp)
    f⁰ = lagrange(ocp)
    s  = ismin(ocp) ? 1.0 : -1.0 #

    # construction of the Hamiltonian
    if f ≠ nothing
        u = ControlFunction{time_dependence}(u_) # coherence is needed on the time dependence
        g = MixedConstraintFunction{time_dependence}(g_)
        μ = MultiplierFunction{time_dependence}(μ_)
        H = Hamiltonian{:nonautonomous}(f⁰ ≠ nothing ? makeH(f, u, f⁰, p⁰, s, g, μ) : makeH(f, u, g, μ))
    else 
        error("no dynamics in ocp")
    end

    return HamiltonianFlows.Flow(H)

end
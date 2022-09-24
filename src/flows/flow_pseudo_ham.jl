# --------------------------------------------------------------------------------------------
# Pseudo Hamiltonian
# --------------------------------------------------------------------------------------------
struct PseudoHamiltonian f::Function end

function (h::PseudoHamiltonian)(x, p, u) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
   return h.f(x, p, u)
end

function (h::PseudoHamiltonian)(x, p, p⁰, u)
   return h.f(x, p, p⁰, u)
end

# Flow from a pseudo-Hamiltonian
function Flow(H::PseudoHamiltonian; p⁰::Number=Inf)

    if p⁰==Inf
        h = H.f
    else
        h(x, p, u) = H.f(x, p, p⁰, u)
    end
    
    function ∂h∂z(z, u)
        n = size(z, 1)÷2
        foo(z) = h(z[1:n], z[n+1:2*n], u)
        return ForwardDiff.gradient(foo, z)
    end
    
    function ∂h∂u(z, u)
        n = size(z, 1)÷2
        foo(u) = h(z[1:n], z[n+1:2*n], u)
        return ForwardDiff.gradient(foo, u)
    end
    
    ∂h∂u(x, p, u) = ∂h∂u([x; p], u)
    
    ∂²h∂u²(z, u)  = ForwardDiff.jacobian(u->∂h∂u(z, u), u)
    ∂²h∂z∂u(z, u) = ForwardDiff.jacobian(u->∂h∂z(z, u), u)
    
    function rhs!(dw, w, λ, t)
        # w = (z, u) = (x, p, u)
        n, m = λ
        z  = w[1:2n]
        u  = w[2n+1:2n+m]
        dh = ∂h∂z(z, u)
        hv = [dh[n+1:2n]; -dh[1:n]]
        dw[1:2n] = hv  
        dw[2n+1:2n+m] = -∂²h∂u²(z, u)\(∂²h∂z∂u(z, u)'*hv)
    end
    
    function f(tspan, x0, p0, u0; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        w0 = [ x0 ; p0; u0 ]
        λ = [size(x0, 1), size(u0, 1)]
        ode = ODEProblem(rhs!, w0, tspan, λ)
        sol = OrdinaryDiffEq.solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0, x0, p0, u0, tf; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, tf), x0, p0, u0, abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2n, end], sol[2n+1:end, end]
    end
    
    return f, ∂h∂u

end
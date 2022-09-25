# --------------------------------------------------------------------------------------------
# Hamiltonian
# --------------------------------------------------------------------------------------------

struct Hamiltonian f::Function end

function (h::Hamiltonian)(x::State, p::Adjoint, λ...) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
   return h.f(x, p, λ...)
end

# Flow from a Hamiltonian
function Flow(h::Hamiltonian)
    
    function rhs!(dz::DCoTangent, z::CoTangent, λ, t::Time)
        n = size(z, 1)÷2
        foo = z -> h(z[1:n], z[n+1:2*n], λ...)
        dh = ForwardDiff.gradient(foo, z)
        dz[1:n] = dh[n+1:2n]
        dz[n+1:2n] = -dh[1:n]
    end
    
    function f(tspan::Tuple{Time, Time}, x0::State, p0::Adjoint, λ...; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        z0  = [ x0 ; p0 ]
        ode = OrdinaryDiffEq.ODEProblem(rhs!, z0, tspan, λ)
        sol = OrdinaryDiffEq.solve(ode, method, abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0::Time, x0::State, p0::Adjoint, tf::Time, λ...; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, tf), x0, p0, λ..., method=method, abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2*n, end]
    end
    
    return f

end;
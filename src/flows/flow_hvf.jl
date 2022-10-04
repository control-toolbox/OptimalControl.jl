# --------------------------------------------------------------------------------------------
# Hamiltonian Vector Field
# --------------------------------------------------------------------------------------------
struct HamiltonianVectorField f::Function end

function (hv::HamiltonianVectorField)(x::State, p::Adjoint, λ...) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
   return hv.f(x, p, λ...)
end

function (hv::HamiltonianVectorField)(t::Time, x::State, p::Adjoint, λ...)
    return hv.f(t, x, p, λ...)
end

# Fonction permettant de calculer le flot d'un système hamiltonien
function Flow(hv::HamiltonianVectorField, description...; kwargs_Flow...)
    
    hv_(t, x, p, λ...) = isnonautonomous(makeDescription(description...)) ? 
        hv(t, x, p, λ...) : hv(x, p, λ...)

    function rhs!(dz::DCoTangent, z::CoTangent, λ, t::Time)
        n = size(z, 1)÷2
        dz[:] = hv_(t, z[1:n], z[n+1:2*n], λ...)
    end
    
    function f(tspan::Tuple{Time, Time}, x0::State, p0::Adjoint, λ...; 
                method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(),
                kwargs...)
        z0 = [ x0 ; p0 ]
        ode = OrdinaryDiffEq.ODEProblem(rhs!, z0, tspan, λ)
        sol = OrdinaryDiffEq.solve(ode, method, abstol=abstol, reltol=reltol, saveat=saveat;
                kwargs..., kwargs_Flow...)
        return sol
    end
    
    function f(t0::Time, x0::State, p0::Adjoint, t::Time, λ...; 
                method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(),
                kwargs...)
        sol = f((t0, t), x0, p0, λ..., method=method, abstol=abstol, reltol=reltol, saveat=saveat;
                kwargs..., kwargs_Flow...)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2*n, end]
    end
    
    return f

end;

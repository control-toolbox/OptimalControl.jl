# --------------------------------------------------------------------------------------------
# Hamiltonian
# --------------------------------------------------------------------------------------------

struct Hamiltonian
    f::Function
end

"""
	(h::Hamiltonian)(x::State, p::Adjoint, λ...)

TBW
"""
function (h::Hamiltonian)(x::State, p::Adjoint, λ...)
    return h.f(x, p, λ...)
end

"""
	(h::Hamiltonian)(t::Time, x::State, p::Adjoint, λ...)

TBW
"""
function (h::Hamiltonian)(t::Time, x::State, p::Adjoint, λ...)
    return h.f(t, x, p, λ...)
end

# Flow from a Hamiltonian
# On peut mettre les options d'intégration dans Flow
# ou à l'appel de f par la suite
"""
	Flow(h::Hamiltonian, description...; kwargs_Flow...)

TBW
"""
function Flow(h::Hamiltonian, description...; kwargs_Flow...)

    h_(t, x, p, λ...) = isnonautonomous(makeDescription(description...)) ? h(t, x, p, λ...) : h(x, p, λ...)

    """
   	rhs!(dz::DCoTangent, z::CoTangent, λ, t::Time)

   TBW
   """
    function rhs!(dz::DCoTangent, z::CoTangent, λ, t::Time)
        n = size(z, 1) ÷ 2
        if isempty(λ)
            foo = z -> h_(t, z[1:n], z[n+1:2*n])
        else
            foo = z -> h_(t, z[1:n], z[n+1:2*n], λ...)
        end
        dh = ForwardDiff.gradient(foo, z)
        dz[1:n] = dh[n+1:2n]
        dz[n+1:2n] = -dh[1:n]
    end

    """
   	f(tspan::Tuple{Time, Time}, x0::State, p0::Adjoint, λ...; 
   				method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(),
   				kwargs...)

   TBW
   """
    function f(tspan::Tuple{Time,Time}, x0::State, p0::Adjoint, λ...; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(), kwargs...)
        z0 = [x0; p0]
        if isempty(λ)
            ode = OrdinaryDiffEq.ODEProblem(rhs!, z0, tspan)
        else
            ode = OrdinaryDiffEq.ODEProblem(rhs!, z0, tspan, λ)
        end
        sol = OrdinaryDiffEq.solve(ode, method, abstol=abstol, reltol=reltol, saveat=saveat; kwargs..., kwargs_Flow...)
        return sol
    end

    """
   	f(t0::Time, x0::State, p0::Adjoint, tf::Time, λ...; 
   				method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(),
   				kwargs...)

   TBW
   """
    function f(t0::Time, x0::State, p0::Adjoint, tf::Time, λ...; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(), kwargs...)
        sol = f((t0, tf), x0, p0, λ..., method=method, abstol=abstol, reltol=reltol, saveat=saveat; kwargs..., kwargs_Flow...)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2*n, end]
    end

    return f

end;

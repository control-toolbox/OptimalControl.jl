# --------------------------------------------------------------------------------------------
# Hamiltonian Vector Field
# --------------------------------------------------------------------------------------------
struct HamiltonianVectorField f::Function end

function (hv::HamiltonianVectorField)(x, p) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
   return hv.f(x,p)
end

# Fonction permettant de calculer le flot d'un système hamiltonien
function Flow(hv::HamiltonianVectorField)
    
    function rhs!(dz, z, dummy, t)
        n = size(z, 1)÷2
        dz[:] = hv(z[1:n], z[n+1:2*n])
    end
    
    function f(tspan, x0, p0; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        z0 = [ x0 ; p0 ]
        ode = ODEProblem(rhs!, z0, tspan)
        sol = OrdinaryDiffEq.solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0, x0, p0, t; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, t), x0, p0; abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2*n, end]
    end
    
    return f

end;

# --------------------------------------------------------------------------------------------
# Vector Field
# --------------------------------------------------------------------------------------------
struct VectorField f::Function end

function (vf::VectorField)(x::State, λ...) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
   return vf.f(x, λ...)
end

function (vf::VectorField)(t::Time, x::State, λ...)
    return vf.f(t, x, λ...)
 end

# Flow of a vector field
function Flow(vf::VectorField, args...; kwargs_Flow...)
    
    description = makeDescription(args...)
    vf_(t, x, λ...) = isnonautonomous(description) ? vf(t, x, λ...) : vf(x, λ...)

    function rhs!(dx::DState, x::State, λ, t::Time)
        dx[:] = vf_(t, x, λ...)
    end
    
    function f(tspan::Tuple{Time, Time}, x0::State, λ...; 
                method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(),
                kwargs...)
        ode = OrdinaryDiffEq.ODEProblem(rhs!, x0, tspan, λ)
        sol = OrdinaryDiffEq.solve(ode, method, abstol=abstol, reltol=reltol, saveat=saveat;
                kwargs..., kwargs_Flow...)
        return sol
    end
    
    function f(t0::Time, x0::State, t::Time, λ...; 
                method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(),
                kwargs...)
        sol = f((t0, t), x0, λ..., method=method, abstol=abstol, reltol=reltol, saveat=saveat;
                kwargs..., kwargs_Flow...)
        n = size(x0, 1)
        return sol[1:n, end]
    end
    
    return f

end;

# --------------------------------------------------------------------------------------------
# Vector Field
# --------------------------------------------------------------------------------------------
struct VectorField f::Function end

function (vf::VectorField)(x::Vector{<:Number}, λ...) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
   return vf.f(x, λ...)
end

# Flow of a vector field
function Flow(vf::VectorField)
    
    function rhs!(dx::Vector{<:Number}, x::Vector{<:Number}, λ, t::Number)
        dx[:] = vf(x, λ...)
    end
    
    function f(tspan::Tuple{Number, Number}, x0::Vector{<:Number}, λ...; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        ode = ODEProblem(rhs!, x0, tspan, λ)
        sol = OrdinaryDiffEq.solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0::Number, x0::Vector{<:Number}, t::Number, λ...; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, t), x0, λ...; abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end]
    end
    
    return f

end;

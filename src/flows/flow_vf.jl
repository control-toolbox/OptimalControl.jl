# --------------------------------------------------------------------------------------------
# Vector Field
# --------------------------------------------------------------------------------------------
struct VectorField
    f::Function
end

function (vf::VectorField)(x::State, λ...) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
    return vf.f(x, λ...)
end

function (vf::VectorField)(t::Time, x::State, λ...)
    return vf.f(t, x, λ...)
end

# Flow of a vector field
function Flow(vf::VectorField, description...; 
        alg=__alg(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(), kwargs_Flow...)

    vf_(t, x, λ...) = isnonautonomous(makeDescription(description...)) ? vf(t, x, λ...) : vf(x, λ...)

    function rhs!(dx::DState, x::State, λ, t::Time)
        dx[:] = isempty(λ) ? vf_(t, x) : vf_(t, x, λ...)
    end

    # kwargs has priority wrt kwargs_flow
    function f(tspan::Tuple{Time,Time}, x0::State, λ...; kwargs...)
        args = isempty(λ) ? (rhs!, x0, tspan) : (rhs!, x0, tspan, λ)
        ode = OrdinaryDiffEq.ODEProblem(args...)
        sol = OrdinaryDiffEq.solve(ode, alg=alg, abstol=abstol, reltol=reltol, saveat=saveat; kwargs_Flow..., kwargs...)
        return sol
    end

    function f(t0::Time, x0::State, t::Time, λ...; kwargs...)
        sol = f((t0, t), x0, λ...; kwargs...)
        n = size(x0, 1)
        return sol[1:n, end]
    end

    return f

end;

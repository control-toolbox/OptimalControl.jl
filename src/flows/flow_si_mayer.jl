
# todo: add Types and parameters to flow

# --------------------------------------------------------------------------------------------
# Single input and affine Mayer system 
# --------------------------------------------------------------------------------------------
struct SIMayer
    f₀::Function 
    f₁::Function
    control_bounds::Tuple{Number, Number}
    constraint::Union{Function, Nothing}
end

function __vector_fields(ocp::SIMayer)
    f₀ = ocp.f₀
    f₁ = ocp.f₁
    return f₀, f₁
end

function __hamiltonian_lifts(ocp::SIMayer)
    f₀ = ocp.f₀
    f₁ = ocp.f₁
    h₀(x, p) = p'*f₀(x)
    h₁(x, p) = p'*f₁(x)   
    return h₀, h₁
end

function __min_control(ocp::SIMayer)
     u(x, p) = ocp.control_bounds[1]
end

function __max_control(ocp::SIMayer)
     u(x, p) = ocp.control_bounds[2]
end

function __singular_control(ocp::SIMayer)
    
    h₀, h₁ = __hamiltonian_lifts(ocp)
    H₀₁  = Poisson(h₀, h₁)
    H₀₀₁ = Poisson(h₀, H₀₁)
    H₁₀₁ = Poisson(h₁, H₀₁)
    us(x, p) = -H₀₀₁(x, p)/H₁₀₁(x, p)  
    
    return us
    
end

function __boundary_control(ocp::SIMayer)
    
    f₀, f₁ = __vector_fields(ocp)
    g = ocp.constraint
    ub(x) = -Lie(f₀, g)(x) / Lie(f₁, g)(x)
    
    return ub
    
end

function __boundary_multiplier(ocp::SIMayer)
   
    f₀ = ocp.f₀
    f₁ = ocp.f₁  
    h₀, h₁ = __hamiltonian_lifts(ocp)
    H₀₁ = Poisson(h₀, h₁)   
    g = ocp.constraint
    μb(x, p) = H₀₁(x, p) / Lie(f₁, g)(x)
    
    return μb
    
end

function __gradient_constrain(ocp::SIMayer)  
    g = ocp.constraint
    ∇g(x) = ForwardDiff.gradient(g, x)
    return ∇g
end

function __hamiltonian_min(ocp::SIMayer)
    h₀, h₁ = __hamiltonian_lifts(ocp)
    u = __min_control(ocp)
    h(x, p) = h₀(x, p) + u(x, p) * h₁(x, p)
    return h
end

function __hamiltonian_max(ocp::SIMayer)
    h₀, h₁ = __hamiltonian_lifts(ocp)
    u = __max_control(ocp)
    h(x, p) = h₀(x, p) + u(x, p) * h₁(x, p)
    return h
end

function __hamiltonian_sing(ocp::SIMayer)
    h₀, h₁ = __hamiltonian_lifts(ocp)
    us = __singular_control(ocp)
    h(x, p) = h₀(x, p) + us(x, p) * h₁(x, p)
    return h
end

function __hamiltonian_bound(ocp::SIMayer)
    h₀, h₁ = __hamiltonian_lifts(ocp)
    ub = __boundary_control(ocp)
    μb = __boundary_multiplier(ocp)  
    g = ocp.constraint
    h(x, p) = h₀(x, p) + ub(x) * h₁(x, p) + μb(x,p)*g(x)
    return h
end

function Hamiltonian(ocp::SIMayer, control::Symbol)
    if control==:singular
        return Hamiltonian(__hamiltonian_sing(ocp))
    elseif control==:min
        return Hamiltonian(__hamiltonian_min(ocp))
    elseif control==:max
        return Hamiltonian(__hamiltonian_max(ocp))
    elseif control==:boundary
        return Hamiltonian(__hamiltonian_bound(ocp))
    else
        nothing
    end    
end

function control(ocp::SIMayer, control::Symbol)
    if control==:singular
        return __singular_control(ocp)
    elseif control==:min
        return __min_control(ocp)
    elseif control==:max
        return __max_control(ocp)
    elseif control==:boundary
        return __boundary_control(ocp)
    else
        nothing
    end    
end

function multiplier(ocp::SIMayer)
   return __boundary_multiplier(ocp)
end

# --------------------------------------------------------------------------------------------
# Flow
# --------------------------------------------------------------------------------------------
function __flow(rhs!, tspan, x0, p0; method, abstol, reltol, saveat)
    z0 = [ x0 ; p0 ]
    n = size(x0, 1)
    ode = OrdinaryDiffEq.ODEProblem(rhs!, z0, tspan, n)
    sol = OrdinaryDiffEq.solve(ode, method, abstol=abstol, reltol=reltol, saveat=saveat)
    return sol
end

function __flow(rhs!, t0, x0, p0, tf; method, abstol, reltol, saveat)
    sol = __flow(rhs!, (t0, tf), x0, p0, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    n = size(x0, 1)
    return sol[1:n, end], sol[n+1:2n, end]
end

function __dh(ocp::SIMayer)
    
    #f₀ = ocp.f₀
    #f₁ = ocp.f₁
    #h₀(x, p) = p'*f₀(x)
    #h₁(x, p) = p'*f₁(x)

    #
    h₀, h₁ = __hamiltonian_lifts(ocp)
    
    function dh₀(x, p)
        n = size(x, 1)
        foo(z) = h₀(z[1:n], z[n+1:2n])
        return ForwardDiff.gradient(foo, [x; p])
    end

    function dh₁(x, p)
        n = size(x, 1)
        foo(z) = h₁(z[1:n], z[n+1:2n])
        return ForwardDiff.gradient(foo, [x; p])
    end
    
    return dh₀, dh₁
    
end

function __FlowMIN(ocp::SIMayer)
  
    u_bounds = ocp.control_bounds
    dh₀, dh₁ = __dh(ocp)
        
    function rhs!(dz, z, n, t)
        x   = z[1:n]
        p   = z[n+1:2n]
        u   = u_bounds[1]
        dh0 = dh₀(x, p)
        dh1 = dh₁(x, p)
        hv0 = [dh0[n+1:2n]; -dh0[1:n]]
        hv1 = [dh1[n+1:2n]; -dh1[1:n]]
        dz[1:2n] = hv0 + u*hv1
    end
    
    function f(tspan, x0, p0; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    return f

end;

function __FlowMAX(ocp::SIMayer)
  
    u_bounds = ocp.control_bounds
    dh₀, dh₁ = __dh(ocp)
        
    function rhs!(dz, z, n, t)
        x   = z[1:n]
        p   = z[n+1:2n]
        u   = u_bounds[2]
        dh0 = dh₀(x, p)
        dh1 = dh₁(x, p)
        hv0 = [dh0[n+1:2n]; -dh0[1:n]]
        hv1 = [dh1[n+1:2n]; -dh1[1:n]]
        dz[1:2n] = hv0 + u*hv1
    end
    
    function f(tspan, x0, p0; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    return f

end;

function __us(ocp::SIMayer)
    return __singular_control(ocp)
end

function __FlowSING(ocp::SIMayer)
  
    dh₀, dh₁ = __dh(ocp)
    us =  __us(ocp)
        
    function rhs!(dz, z, n, t)
        x   = z[1:n]
        p   = z[n+1:2n]
        u   = us(x, p)
        dh0 = dh₀(x, p)
        dh1 = dh₁(x, p)
        hv0 = [dh0[n+1:2n]; -dh0[1:n]]
        hv1 = [dh1[n+1:2n]; -dh1[1:n]]
        dz[1:2n] = hv0 + u*hv1
    end
    
    function f(tspan, x0, p0; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    return f, us

end

function __u_μ_boundary(ocp::SIMayer) 
    ub = __boundary_control(ocp)
    μb = __boundary_multiplier(ocp)
    ∇g = __gradient_constrain(ocp)
    return ub, μb, ∇g
end

function __FlowBOUND(ocp::SIMayer)
  
    dh₀, dh₁ = __dh(ocp)
    ub, μb, ∇g = __u_μ_boundary(ocp)
    
    function rhs!(dz, z, n, t)
        x   = z[1:n]
        p   = z[n+1:2n]
        u   = ub(x)
        μ   = μb(x, p)
        dh0 = dh₀(x, p)
        dh1 = dh₁(x, p)
        hv0 = [dh0[n+1:2n]; -dh0[1:n]]
        hv1 = [dh1[n+1:2n]; -dh1[1:n]]
        dz[1:2n] = hv0 + u*hv1
        dz[n+1:2n] = dz[n+1:2n] - μ*∇g(x)
    end
    
    function f(tspan, x0, p0; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; method=__method(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, method=method, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    return f, ub, μb

end;

function Flow(ocp::SIMayer, control::Symbol)
    if control==:singular
        return __FlowSING(ocp)
    elseif control==:min
        return __FlowMIN(ocp)
    elseif control==:max
        return __FlowMAX(ocp)
    elseif control==:boundary
        return __FlowBOUND(ocp)
    else
        nothing
    end    
end
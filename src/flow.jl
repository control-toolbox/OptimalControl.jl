# Alias for gradient and jacobian: see utils.jl
#grad(f, x) = ForwardDiff.gradient(f, x)
#jac(f, x)  = ForwardDiff.jacobian(f, x);
jac(f, x) = J(f, x)

# types of controls
@enum CONTROL umin=1 umax=2 usingular=3 uboundary=4 #uregular=5

# --------------------------------------------------------------------------------------------
# Default options for flows
# --------------------------------------------------------------------------------------------
function __abstol()
    return 1e-10
end

function __reltol()
    return 1e-10
end

function __saveat()
    return []
end

# --------------------------------------------------------------------------------------------
# Hamiltonian
# --------------------------------------------------------------------------------------------
struct Hamiltonian f::Function end

function (h::Hamiltonian)(x, p, λ...) # https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
   return h.f(x, p, λ...)
end

# Flow from a Hamiltonian
function Flow(h::Hamiltonian)
    
    function rhs!(dz, z, λ, t)
        n = size(z, 1)÷2
        foo = z -> h(z[1:n], z[n+1:2*n], λ...)
        dh = ∇(foo, z)
        dz[1:n] = dh[n+1:2n]
        dz[n+1:2n] = -dh[1:n]
    end
    
    function f(tspan::Tuple{Number, Number}, x0, p0, λ...; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        z0  = [ x0 ; p0 ]
        ode = ODEProblem(rhs!, z0, tspan, λ)
        sol = solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0::Number, x0, p0, tf::Number, λ...; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, tf), x0, p0, λ..., abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2*n, end]
    end
    
    return f

end;

# --------------------------------------------------------------------------------------------
#
# Single input and affine Mayer system 
#
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

#function __gradient_constrain(ocp::SIMayer)  
#    g = ocp.constraint
#    ∇g(x) = ∇(g, x)
#    return ∇g
#end

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

function Hamiltonian(ocp::SIMayer, control::CONTROL)
    if control==usingular
        return Hamiltonian(__hamiltonian_sing(ocp))
    elseif control==umin
        return Hamiltonian(__hamiltonian_min(ocp))
    elseif control==umax
        return Hamiltonian(__hamiltonian_max(ocp))
    elseif control==uboundary
        return Hamiltonian(__hamiltonian_bound(ocp))
    else
        nothing
    end    
end;

function Control(ocp::SIMayer, control::CONTROL)
    if control==usingular
        return __singular_control(ocp)
    elseif control==umin
        return __min_control(ocp)
    elseif control==umax
        return __max_control(ocp)
    elseif control==uboundary
        return __boundary_control(ocp)
    else
        nothing
    end    
end;

function Multiplier(ocp::SIMayer)
   return __boundary_multiplier(ocp)
end;

# --------------------------------------------------------------------------------------------
#
# Hamiltonian Vector Field
#
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
        sol = solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0, x0, p0, t; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, t), x0, p0; abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2*n, end]
    end
    
    return f

end;

# --------------------------------------------------------------------------------------------
#
# Vector Field
#
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
        sol = solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0::Number, x0::Vector{<:Number}, t::Number, λ...; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, t), x0, λ...; abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end]
    end
    
    return f

end;

# --------------------------------------------------------------------------------------------
#
# Pseudo Hamiltonian
#
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
        return ∇(foo, z)
    end
    
    function ∂h∂u(z, u)
        n = size(z, 1)÷2
        foo(u) = h(z[1:n], z[n+1:2*n], u)
        return ∇(foo, u)
    end
    
    ∂h∂u(x, p, u) = ∂h∂u([x; p], u)
    
    ∂²h∂u²(z, u)  = jac(u->∂h∂u(z, u), u)
    ∂²h∂z∂u(z, u) = jac(u->∂h∂z(z, u), u)
    
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
        sol = solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
        return sol
    end
    
    function f(t0, x0, p0, u0, tf; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        sol = f((t0, tf), x0, p0, u0, abstol=abstol, reltol=reltol, saveat=saveat)
        n = size(x0, 1)
        return sol[1:n, end], sol[n+1:2n, end], sol[2n+1:end, end]
    end
    
    return f, ∂h∂u

end;

# --------------------------------------------------------------------------------------------
#
# Mayer
#
# --------------------------------------------------------------------------------------------
struct Mayer f::Function end

# Flow from Mayer system
Flow(Σu::Mayer) = Flow(PseudoHamiltonian((x, p, u) -> p'*Σu.f(x,u)));

# --------------------------------------------------------------------------------------------
#
# Lagrange
#
# --------------------------------------------------------------------------------------------
struct Lagrange 
    f::Function
    f⁰::Function 
end

# Flow from Lagrange system
Flow(Σu::Lagrange, p⁰::Number=-1.0) = Flow(PseudoHamiltonian((x, p, p⁰, u) -> p⁰*Σu.f⁰(x,u)+p'*Σu.f(x,u)), p⁰=p⁰);

# --------------------------------------------------------------------------------------------
#
# SIMayer
#
# --------------------------------------------------------------------------------------------
function __flow(rhs!, tspan, x0, p0; abstol, reltol, saveat)
    z0 = [ x0 ; p0 ]
    n = size(x0, 1)
    ode = ODEProblem(rhs!, z0, tspan, n)
    sol = solve(ode, Tsit5(), abstol=abstol, reltol=reltol, saveat=saveat)
    return sol
end

function __flow(rhs!, t0, x0, p0, tf; abstol, reltol, saveat)
    sol = __flow(rhs!, (t0, tf), x0, p0, abstol=abstol, reltol=reltol, saveat=saveat)
    n = size(x0, 1)
    return sol[1:n, end], sol[n+1:2n, end]
end

function __dh(ocp::SIMayer)
    
    f₀ = ocp.f₀
    f₁ = ocp.f₁
    h₀(x, p) = p'*f₀(x)
    h₁(x, p) = p'*f₁(x)
    
    function dh₀(x, p)
        n = size(x, 1)
        foo(z) = h₀(z[1:n], z[n+1:2n])
        return ∇(foo, [x; p])
    end

    function dh₁(x, p)
        n = size(x, 1)
        foo(z) = h₁(z[1:n], z[n+1:2n])
        return ∇(foo, [x; p])
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
    
    function f(tspan, x0, p0; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, abstol=abstol, reltol=reltol, saveat=saveat)
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
    
    function f(tspan, x0, p0; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    return f

end;

function __us(ocp::SIMayer)
    
    f₀ = ocp.f₀
    f₁ = ocp.f₁
    h₀(x, p) = p'*f₀(x)
    h₁(x, p) = p'*f₁(x)  
    
    # singular control
    H₀₁  = Poisson(h₀, h₁)
    H₀₀₁ = Poisson(h₀, H₀₁)
    H₁₀₁ = Poisson(h₁, H₀₁)
    us(x, p) = -H₀₀₁(x, p)/H₁₀₁(x, p)  
    
    return us
    
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
    
    function f(tspan, x0, p0; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    return f, us

end;

function __u_μ_boundary(ocp::SIMayer)
    f₀ = ocp.f₀
    f₁ = ocp.f₁
    h₀(x, p) = p'*f₀(x)
    h₁(x, p) = p'*f₁(x)  
    H₀₁ = Poisson(h₀, h₁)   
    g = ocp.constraint
    ub(x) = -Lie(f₀, g)(x) / Lie(f₁, g)(x)
    μb(x, p) = H₀₁(x, p) / Lie(f₁, g)(x)
    ∇g(x) = ∇(g, x)
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
    
    function f(tspan, x0, p0; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, tspan, x0, p0, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    function f(t0, x0, p0, tf; abstol=__abstol(), reltol=__reltol(), saveat=__saveat())
        return __flow(rhs!, t0, x0, p0, tf, abstol=abstol, reltol=reltol, saveat=saveat)
    end
    
    return f, ub, μb

end;

function Flow(ocp::SIMayer, control::CONTROL)
    if control==usingular
        return __FlowSING(ocp)
    elseif control==umin
        return __FlowMIN(ocp)
    elseif control==umax
        return __FlowMAX(ocp)
    elseif control==uboundary
        return __FlowBOUND(ocp)
    else
        nothing
    end    
end
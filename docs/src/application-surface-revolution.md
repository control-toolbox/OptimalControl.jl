# The surface of revolution of minimum area

We consider the well-known surface of revolution of minimum area problem which dates 
back to Euler[^1] [^2]. This is a problem of calculus of variations for which it is 
easy to have the analytic solutions. But here, as we use this simple problem 
to illustrate the use of the `OptimalControl.jl` package, we consider the 
optimal control version. We minimise the cost integral

```math
    \int_0^{1} x(t)\,\sqrt{1+u^2(t)}\,\mathrm{d} t
```

under the dynamical constraint

```math
    \dot{x}(t) = u(t), \quad u(t)\in\R,
```

and the limit conditions

```math
    x(0) = 1, \quad x(1) = 2.5.
```

To define this problem with `OptimalControl.jl` we have to type:

```@example main
using OptimalControl

t0 = 0
tf = 1
x0 = 1
xf = 2.5

@def ocp begin

    t ∈ [ t0, tf ], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) ==  u(t)

    ∫( x(t) * √(1 + u(t)^2) ) → min

end
nothing # hide
```

[^1]: H. Schättler & U. Ledzewicz, *Geometric optimal control: theory, methods and examples*, vol~**38** of *Interdisciplinary applied mathematics*, Springer Science & Business Media, New York (2012), xiv+640.

[^2]: D. Liberzon, *Calculus ov Variations and Optimal Control Theory*, Princeton University Press (2012).

```@setup main
using Suppressor # to suppress warnings
```

Here the maximization of the pseudo-Hamiltonian provides the control with respect to 
the state and the costate (or covector):

```math
    u(x,p) = \mathrm{sign}(x) \frac{p}{\sqrt{x^2-p^2}}.
```

Then, we can define the Hamiltonian $\mathbf{H}(x,p)=H(x, p, u(x,p))$ and can compute
the flow of the Hamiltonian system by using the `Flow` function of the 
`OptimalControl.jl` package. At the end we can easily compute and plot this flow 
for different values of the initial costate.

```@example main
using OrdinaryDiffEq

u(x, p) = sign(x) * p / √(x^2-p^2)

ocp_flow = Flow(ocp, u, reltol=1e-10, abstol=1e-10)
nothing # hide
```

```@example main
tmax = 2
xmax = 4

# the extremal which has a conjugate time equal to 2: 
p0_tau_2 = -0.6420147569351132
xf_tau_2, _ = ocp_flow(t0, x0, p0_tau_2, tmax)

#
Np0x = 4
Δx = xmax - xf_tau_2
δx = Δx / (Np0x-1)
δt = δx * (tmax - t0) / (xmax - 0) # depends on the xlims and ylims of the plots

#
xs_target = range(xf_tau_2, xmax, length=Np0x)
ts_target = collect(tmax:-δt:t0)
Np0t = length(ts_target)
Np0 = Np0x + Np0t

#
condition(z,t,integrator) = z[1] - (xmax+1)
affect!(integrator) = terminate!(integrator)
cbt  = ContinuousCallback(condition,affect!)

#
π((x, p)) = x

# we seek the p0 which give the xs_target at tf = 2
F(p0) = (π ∘ ocp_flow)(t0, x0, p0, tmax, callback=cbt)
p0s = []
for i ∈ 1:Np0x
    if i == 1
        push!(p0s, p0_tau_2)
    else
        push!(p0s, Roots.find_zero(p0 -> F(p0) - xs_target[i], (p0_tau_2,  0.999)))
    end
    if i < Np0x
        push!(p0s, Roots.find_zero(p0 -> F(p0) - (xs_target[i]+δx/2), (p0_tau_2, -0.999)))
    end
end

# we seek the p0 which give the ts_target at xf = xmax
for i ∈ 1:Np0t
    F(p0) = (π ∘ ocp_flow)(t0, x0, p0, ts_target[i], callback=cbt) - xmax
    push!(p0s, Roots.find_zero(p0 -> F(p0), (p0_tau_2,  0.999)))
    try 
        F(p0) = (π ∘ ocp_flow)(t0, x0, p0, ts_target[i] - (δt/2), callback=cbt) - xmax
        push!(p0s, Roots.find_zero(p0 -> F(p0), (p0_tau_2, -0.999)))
    catch e 
        nothing
    end
end

Np0 = length(p0s);
```

```@example main
using Plots

N = 200
tf = 2
tspan = range(t0, tf, N)    # time interval
plt_x = plot()              # plot of the state x(t)
plt_p = plot()              # plot of the costate p(t)
plt_u = plot()              # plot of the control u(t)
plt_phase = plot()          # plot (x, p)
color_trajectory = :blue

# callback: termination
# Without this, the numerical integration stop before tf for p_0 = 0.99
condition(z,t,integrator) = z[1] - (xmax+1)
affect!(integrator) = terminate!(integrator)
cbt  = ContinuousCallback(condition,affect!)

for p0 ∈ p0s # plot for each p_0 in p0s

    flow_p0 = ocp_flow((t0, tf), x0, p0, saveat=tspan, callback=cbt)

    T = flow_p0.ode_sol.t
    Z = flow_p0.(T)
    X = [Z[i][1] for i in 1:length(T)]
    P = [Z[i][2] for i in 1:length(T)]

    plot!(plt_x, T, X, color=color_trajectory)
    plot!(plt_p, T, P, color=color_trajectory)
    plot!(plt_u, T, u.(X, P), color=color_trajectory)  
    plot!(plt_phase, X, P, color=color_trajectory)

end

# Plots
plot!(plt_x, xlabel=L"t", ylabel=L"x(t,p_0)", legend=false, ylims=(0, xmax))
plot!(plt_p, xlabel=L"t", ylabel=L"p(t,p_0)", legend=false)
plot!(plt_u, xlabel=L"t", ylabel=L"u(t,p_0)", legend=false, ylims=(-2.5, 5))
plot!(plt_phase, xlabel=L"x(t,p_0)", ylabel=L"p(t,p_0)", legend=false, xlims=(0, 2), ylims=(-1, 2))

plot(plt_x, plt_p, plt_u, plt_phase, layout=(2,2), size=(800,600))
```
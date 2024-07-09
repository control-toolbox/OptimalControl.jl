# The surface of revolution of minimum area

We consider the well-known surface of revolution of minimum area problem which dates 
back to Euler[^1] [^2]. This is a problem from 
[calculus of variations](https://en.wikipedia.org/wiki/Calculus_of_variation) but we consider 
its optimal control version. We minimise the cost integral

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

To define this problem with `OptimalControl.jl` we have write:

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

The maximization of the pseudo-Hamiltonian provides the control with respect to 
the state and the costate:

```math
    u(x,p) = \mathrm{sign}(x) \frac{p}{\sqrt{x^2-p^2}}.
```

From this control law, we could define the Hamiltonian 
$\mathbf{H}(x,p)=H(x, p, u(x,p))$ and its associated Hamiltonian flow.
The `OptimalControl.jl` package does this for us simply passing to the function
`Flow`, the optimal control problem with the control law.

```@example main
using OrdinaryDiffEq

u(x, p) = sign(x) * p / √(x^2-p^2)

ocp_flow = Flow(ocp, u, reltol=1e-10, abstol=1e-10)
nothing # hide
```

Let us plot some extremals, solutions of this flow. The initial condition $x_0$
is fixed while we compute some extremals for different values of initial 
covector $p_0$. We compute some specific initial covectors for a nice plot.

```@raw html
<article class="docstring">
<header>
    <a class="docstring-article-toggle-button fa-solid fa-chevron-right" href="javascript:;" title="Expand docstring"> </a>
    <span class="docstring-category">Computation of the initial covectors</span>
</header>
<section style="display: none;">
    <div>
    <pre>
    <code class="language-julia hljs">using Roots

# parameters
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

# we seek the p0 which gives the xs_target at tf = 2
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

# we seek the p0 which gives the ts_target at xf = xmax
G(p0, ts_target) = (π ∘ ocp_flow)(t0, x0, p0, ts_target, callback=cbt) - xmax
for i ∈ 1:Np0t
    push!(p0s, Roots.find_zero(p0 -> G(p0, ts_target[i]), (p0_tau_2,  0.999)))
    try 
        push!(p0s, Roots.find_zero(p0 -> G(p0, ts_target[i] - (δt/2)), (p0_tau_2, -0.999)))
    catch e 
        nothing
    end
end

Np0 = length(p0s)</code><button class="copy-button fa-solid fa-copy" aria-label="Copy this code ;opblock" title="Copy"></button></pre></div>
</section>
</article>
```

```@example main
using Roots # hide

# parameters # hide
tmax = 2 # hide
xmax = 4 # hide

# the extremal which has a conjugate time equal to 2:  # hide
p0_tau_2 = -0.6420147569351132 # hide
global xf_tau_2, _ = # hide
@suppress_err begin # hide
ocp_flow(t0, x0, p0_tau_2, tmax) # hide
xf_tau_2, _ = ocp_flow(t0, x0, p0_tau_2, tmax) # hide
end # hide

# # hide
Np0x = 4 # hide
Δx = xmax - xf_tau_2 # hide
δx = Δx / (Np0x-1) # hide
δt = δx * (tmax - t0) / (xmax - 0) # depends on the xlims and ylims of the plots # hide

# # hide
xs_target = range(xf_tau_2, xmax, length=Np0x) # hide
ts_target = collect(tmax:-δt:t0) # hide
Np0t = length(ts_target) # hide
Np0 = Np0x + Np0t # hide

# # hide
condition(z,t,integrator) = z[1] - (xmax+1) # hide
affect!(integrator) = terminate!(integrator) # hide
cbt  = ContinuousCallback(condition,affect!) # hide

# # hide
π((x, p)) = x # hide

# we seek the p0 which gives the xs_target at tf = 2 # hide
F(p0) = (π ∘ ocp_flow)(t0, x0, p0, tmax, callback=cbt) # hide
p0s = [] # hide
for i ∈ 1:Np0x # hide
    if i == 1 # hide
        push!(p0s, p0_tau_2) # hide
    else # hide
        @suppress_err begin # hide
        push!(p0s, Roots.find_zero(p0 -> F(p0) - xs_target[i], (p0_tau_2,  0.999))) # hide
        end # hide
    end # hide
    if i < Np0x # hide
        @suppress_err begin # hide
        push!(p0s, Roots.find_zero(p0 -> F(p0) - (xs_target[i]+δx/2), (p0_tau_2, -0.999))) # hide
        end # hide
    end # hide
end # hide

# we seek the p0 which gives the ts_target at xf = xmax # hide
G(p0, ts_target) = (π ∘ ocp_flow)(t0, x0, p0, ts_target, callback=cbt) - xmax # hide
for i ∈ 1:Np0t # hide
    @suppress_err begin # hide
    push!(p0s, Roots.find_zero(p0 -> G(p0, ts_target[i]), (p0_tau_2,  0.999))) # hide
    end # hide
    try  # hide
        @suppress_err begin # hide
        push!(p0s, Roots.find_zero(p0 -> G(p0, ts_target[i] - (δt/2)), (p0_tau_2, -0.999))) # hide
        end # hide
    catch e  # hide
        nothing # hide
    end # hide
end # hide

Np0 = length(p0s) # hide
nothing # hide
```

```@example main
using Plots

N  = 200
tf_ = 2
tspan = range(t0, tf_, N)   # time interval
plt_x = plot()              # plot of the state x(t)
plt_p = plot()              # plot of the costate p(t)
plt_u = plot()              # plot of the control u(t)
plt_phase = plot()          # plot (x, p)

# callback: termination
# Without this, the numerical integration stop before tf for p₀ = 0.99
condition(z,t,integrator) = z[1] - (xmax+1)
affect!(integrator) = terminate!(integrator)
cbt  = ContinuousCallback(condition,affect!)

for p0 ∈ p0s # plot for each p₀ in p0s

    flow_p0 = ocp_flow((t0, tf_), x0, p0, saveat=tspan, callback=cbt)

    T = flow_p0.ode_sol.t
    Z = flow_p0.(T)
    X = [Z[i][1] for i in 1:length(T)]
    P = [Z[i][2] for i in 1:length(T)]

    plot!(plt_x, T, X;          color=:blue)
    plot!(plt_p, T, P;          color=:blue)
    plot!(plt_u, T, u.(X, P);   color=:blue)  
    plot!(plt_phase, X, P;      color=:blue)

end

# Plots
plot!(plt_x, xlabel="t", ylabel="x(t,p₀)", legend=false, ylims=(0, xmax))
plot!(plt_p, xlabel="t", ylabel="p(t,p₀)", legend=false)
plot!(plt_u, xlabel="t", ylabel="u(t,p₀)", legend=false, ylims=(-2.5, 5))
plot!(plt_phase, xlabel="x(t,p₀)", ylabel="p(t,p₀)", legend=false, xlims=(0, 2), ylims=(-1, 2))

plot(plt_x, plt_p, plt_u, plt_phase, layout=(2,2), size=(800,600))
```

Here, the shooting equation given by 

```math
    S({p₀}) = \pi(z(t_f,x_0,{p₀})) - x_f = 0,
```

with $\pi(x, p) = x$, has two solutions: $p₀ = -0.9851$ and $p₀ = 0.5126$.

```@example main
π((x, p)) = x

# Shooting function
S(p0) = (π ∘ ocp_flow)(t0, x0, p0, tf) - xf

# Solve the shooting equation: first extremal
global sol1_p0 = # hide
@suppress_err begin # hide
Roots.find_zero(S, (-0.99, -0.97)) # hide
sol1_p0 = Roots.find_zero(S, (-0.99, -0.97))
end # hide

# Solve the shooting equation: second extremal
global sol2_p0 = # hide
@suppress_err begin # hide
Roots.find_zero(S, (0.5, 0.6)) # hide
sol2_p0 = Roots.find_zero(S, (0.5, 0.6))
end # hide

@suppress_err begin # hide
println("sol1_p0 = ",  sol1_p0, ", S(sol1_p0) = ", S(sol1_p0))
println("sol2_p0 =  ", sol2_p0, ", S(sol2_p0) = ", S(sol2_p0))
end # hide
```

Let us plot the two solutions. One can notice that they intersect as shown by 
the top-left subplot.

```@example main
p0s = (sol1_p0, sol2_p0)     # the different p₀

N  = 100
tspan = range(t0, tf, N)     # time interval
plt2_x = plot()              # plot of the state x(t)
plt2_p = plot()              # plot of the costate p(t)
plt2_u = plot()              # plot of the control u(t)
plt2_phase = plot()          # plot (x, p)

labels = ["p₀=-0.9851" , "p₀=0.51265"]

for (p0, label) ∈ zip(p0s, labels) # plot for each p₀ in p0s 
    
    flow_p0 = ocp_flow((t0, tf), x0, p0, saveat=tspan)

    T = tspan
    Z = flow_p0.(tspan)
    X = [Z[i][1] for i in 1:N]
    P = [Z[i][2] for i in 1:N]
    
    plot!(plt2_x, T, X,         label=label)
    plot!(plt2_p, T, P,         label=label)
    plot!(plt2_u, T, u.(X, P),  label=label)  
    plot!(plt2_phase, X, P,     label=label)

end

plot!(plt2_x, [tf], [xf], xlabel="t", ylabel="x(t,p₀)", seriestype=:scatter,label="")
plot!(plt2_p, xlabel="t", ylabel="p(t,p₀)", legend=false, ylims=(-1.5,5.))
plot!(plt2_u, xlabel="t", ylabel="u(t,p₀)", legend=false, ylims=(-6.,5.))
plot!(plt2_phase, xlabel="x(t,p₀)", ylabel="p(t,p₀)", legend=false, xlims=(0.,2.5), ylims=(-1.,5.))

plot(plt2_x, plt2_p, plt2_u, plt2_phase, layout=(2,2), size=(800, 600))
```

Now, we can compute the conjugate points along the two extremals.
We have to compute the flow $\delta z(t, p₀)$ of the Jacobi equation 
with the initial condition $\delta z(0) = (0, 1)$. This is given solving

```math
    \delta z(t, p₀) = \dfrac{\partial}{\partial p₀}z(t, p₀).
```

Note that to compute the conjugate points, we only need the first component:

```math
    \delta z(t, p₀)_1.
```

```@example main
using ForwardDiff

function jacobi_flow(t, p0)
    x(t, p0) = (π ∘ ocp_flow)(t0, x0, p0, t)
    return ForwardDiff.derivative(p0 -> x(t, p0), p0)
end
nothing # hide
```

The first conjugate time is then the first time $\tau$ such that

```math
    \delta x(\tau, p₀)= \delta z(\tau, p₀)_1 = 0,
```

with $p₀$ fixed. On the following figure, one can see that the first extremal has 
a conjugate time smaller than $t_f=1$ while for the second extremal, there is 
no conjugate time. Thus, the first extremal cannot be optimal.

```@example main
using Plots.PlotMeasures

N = 100

# Jacobi field for the first extremal
tspan = range(t0, tf, N) # time interval

δx = jacobi_flow.(tspan, sol1_p0)

plt_conj1 = plot()
plot!(plt_conj1, tspan, δx)  # as n=1, det(δx) = δx
plot!(plt_conj1, xlabel="t", ylabel="δx(t,p₀)", legend=false, ylims=(-10.,10.), size=(400,300))

# Jacobi field for the second extremal
tspan = range(t0, 1.5, N) # time interval

δx = jacobi_flow.(tspan, sol2_p0)

plt_conj2= plot()
plot!(plt_conj2, tspan, δx)  # as n=1 the det(δx) = δx
plot!(plt_conj2, xlabel="t", ylabel="δx(t,p₀)", legend=false, ylims=(-10.,10.), size=(400,300))

#
plt_conj = plot(plt_conj1, plt_conj2, layout=(1, 2), size=(800, 300), leftmargin=25px)
```

We compute the first conjugate point along the first extremal and add it to the plot.

```@example main
tau0 = Roots.find_zero(tau -> jacobi_flow(tau, sol1_p0), (0.4, 0.6))

println("For p0 = ", sol1_p0, " tau_0 = ", tau0)

plot!(plt_conj[1], [tau0], [jacobi_flow(tau0, sol1_p0)], seriestype=:scatter)
```

To conclude on this example, we compute the conjugate locus by using a path following
algorithm. Define $F(\tau,p₀) = \delta x(\tau,p₀)$ and suppose that the partial 
derivative $\partial_\tau F(\tau,p₀)$ is invertible, then, by the implicit function 
theorem the conjugate time is a function of $p₀$. So, since here $p₀\in\R$, we can 
compute them by solving the initial value problem for 
$p₀ \in [\alpha, \beta]$:

```math
    \dot{\tau}(p₀) = -\dfrac{\partial F}{\partial \tau}(\tau(p₀),p₀)^{-1}\, 
    \dfrac{\partial F}{\partial p₀}(\tau(p₀),p₀), \quad
    \tau(\alpha) = \tau_0.
```

For the numerical experiment, we set $\alpha = -0.9995$, $\beta = -0.5$.

```@example main
function conjugate_times_rhs_path(tau, p0)
    dF = ForwardDiff.gradient(y -> jacobi_flow(y...), [tau, p0])
    return -dF[2]/dF[1]
end

function conjugate_times(p0span, tau0)
    ode = OrdinaryDiffEq.ODEProblem((tau, par, p0) -> conjugate_times_rhs_path(tau, p0), tau0, p0span)
    sol = OrdinaryDiffEq.solve(ode, reltol=1e-8, abstol=1e-8)
    return sol.u, sol.t # taus, p0s
end
nothing # hide
```

Now we have defined the algorithm, let us compute the conjugate locus and plot it.

```@example main
# conjugate locus
p0 = sol1_p0
taus1, p0s1 = conjugate_times((p0, -0.5), tau0)
taus2, p0s2 = conjugate_times((p0, -0.999), tau0)
taus = append!(taus2[end:-1:1],taus1)
p0s = append!(p0s2[end:-1:1],p0s1)

# plot tau(p0)
plt_conj_times = plot(p0s, taus, xlabel="p₀", ylabel="τ", color=:blue, xlims = (-1,-0.5))

# get conjugate points
X = []
for (tau, p0) ∈ zip(taus, p0s)
    # compute x(tau, p0)
    x = (π ∘ ocp_flow)(t0, x0, p0, tau)
    push!(X, x)
end

# plot conjugate points on plt_x
plot!(plt_x, taus, X, linewidth=3, color=:red, legend=false, xlims=(0.,2.0), ylims=(0., xmax))

# 
plot(plt_x, plt_conj_times, layout=(1,2), legend=false, size=(800,300), leftmargin=25px)
```
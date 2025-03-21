using OptimalControl    # to define the optimal control problem and its flow
using OrdinaryDiffEq    # to get the Flow function from OptimalControl
using NonlinearSolve    # interface to NLE solvers
using MINPACK           # NLE solver: use to solve the shooting equation
using Plots             # to plot the solution

t0 = 0
tf = 1
x0 = -1
xf = 0
α  = 1.5
ocp = @def begin

    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == -x(t) + α * x(t)^2 + u(t)

    ∫( 0.5u(t)^2 ) → min
    
end

u(x, p) = p
φ = Flow(ocp, u)

π((x, p)) = x

S(p0) = π( φ(t0, x0, p0, tf) ) - xf    # shooting function

ξ = [ 0.1 ]    # initial guess


### NonlinearSolve.jl

nle! = (s, ξ, λ) -> s[1] = S(ξ[1])    # auxiliary function
prob = NonlinearProblem(nle!, ξ)      # NLE problem with initial guess

using BenchmarkTools
@benchmark solve(prob; show_trace=Val(false))

@benchmark solve(prob, SimpleNewtonRaphson(); show_trace=Val(false))

indirect_sol = solve(prob; show_trace=Val(true))      # resolution of S(p0) = 0  
p0_sol = indirect_sol.u[1]                            # costate solution
println("\ncostate:    p0 = ", p0_sol)
println("shoot: |S(p0)| = ", abs(S(p0_sol)), "\n")

## Plot of the solution

sol = φ((t0, tf), x0, p0_sol)
plot(sol)

using Plots.PlotMeasures # hide
expo(p0; saveat=[]) = φ((t0, tf), x0, p0, saveat=saveat) # hide
 # hide
function pretty_plot(S, p0; Np0=20, kwargs...) # hide
 # hide
    times = range(t0, tf, length=3) # hide
    p0_min = -0.5 # hide
    p0_max = 2 # hide
    p0_sol = p0 # hide
 # hide
    # plot of the flow in phase space # hide
    plt_flow = plot() # hide
    p0s = range(p0_min, p0_max, length=Np0) # hide
    for i ∈ eachindex(p0s) # hide
        sol = expo(p0s[i]) # hide
        x = [state(sol)(t)   for t ∈ time_grid(sol)] # hide
        p = [costate(sol)(t) for t ∈ time_grid(sol)] # hide
        label = i==1 ? "extremals" : false # hide
        plot!(plt_flow, x, p, color=:blue, label=label) # hide
    end # hide
 # hide
    # plot of wavefronts in phase space # hide
    p0s = range(p0_min, p0_max, length=200) # hide
    xs  = zeros(length(p0s), length(times)) # hide
    ps  = zeros(length(p0s), length(times)) # hide
    for i ∈ eachindex(p0s) # hide
        sol = expo(p0s[i], saveat=times) # hide
        xs[i, :] .= state(sol).(times) # hide
        ps[i, :] .= costate(sol).(times) # hide
    end # hide
    for j ∈ eachindex(times) # hide
        label = j==1 ? "flow at times" : false # hide
        plot!(plt_flow, xs[:, j], ps[:, j], color=:green, linewidth=2, label=label) # hide
    end # hide
 # hide
    #  # hide
    plot!(plt_flow, xlims=(-1.1, 1), ylims=(p0_min, p0_max)) # hide
    plot!(plt_flow, [0, 0], [p0_min, p0_max], color=:black, xlabel="x", ylabel="p", label="x=xf") # hide
     # hide
    # solution # hide
    sol = expo(p0_sol) # hide
    x = [state(sol)(t)   for t ∈ time_grid(sol)] # hide
    p = [costate(sol)(t) for t ∈ time_grid(sol)] # hide
    plot!(plt_flow, x, p, color=:red, linewidth=2, label="extremal solution") # hide
    plot!(plt_flow, [x[end]], [p[end]], seriestype=:scatter, color=:green, label=false) # hide
 # hide
    # plot of the shooting function  # hide
    p0s = range(p0_min, p0_max, length=200) # hide
    plt_shoot = plot(xlims=(p0_min, p0_max), ylims=(-2, 4), xlabel="p₀", ylabel="y") # hide
    plot!(plt_shoot, p0s, S, linewidth=2, label="S(p₀)", color=:green) # hide
    plot!(plt_shoot, [p0_min, p0_max], [0, 0], color=:black, label="y=0") # hide
    plot!(plt_shoot, [p0_sol, p0_sol], [-2, 0], color=:black, label="p₀ solution", linestyle=:dash) # hide
    plot!(plt_shoot, [p0_sol], [0], seriestype=:scatter, color=:green, label=false) # hide
 # hide
    # final plot # hide
    plot(plt_flow, plt_shoot; layout=(1,2), leftmargin=15px, bottommargin=15px, kwargs...) # hide
 # hide
end # hide

pretty_plot(S, p0_sol; size=(800, 450))
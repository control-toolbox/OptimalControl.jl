```@example main
exp(p0; saveat=[]) = φ((t0, tf), x0, p0, saveat=saveat).ode_sol # hide
times = range(t0, tf, length=2) # hide
p0min = -0.5 # hide
p0max = 2 # hide
plt_flow = plot() # hide
p0s = range(p0min, p0max, length=20) # hide
for i ∈ 1:length(p0s) # hide
    sol = exp(p0s[i]) # hide
    x = [sol(t)[1] for t ∈ sol.t] # hide
    p = [sol(t)[2] for t ∈ sol.t] # hide
    label = i==1 ? "extremals" : false # hide
    plot!(plt_flow, x, p, color=:blue, label=label) # hide
end # hide
p0s = range(p0min, p0max, length=200) # hide
xs  = zeros(length(p0s), length(times)) # hide
ps  = zeros(length(p0s), length(times)) # hide
for i ∈ 1:length(p0s) # hide
    sol = exp(p0s[i], saveat=times) # hide
    xs[i, :] = [z[1] for z ∈ sol.(times)] # hide
    ps[i, :] = [z[2] for z ∈ sol.(times)] # hide
end # hide
for j ∈ 1:length(times) # hide
    label = j==1 ? "flow at times" : false # hide
    plot!(plt_flow, xs[:, j], ps[:, j], color=:green, linewidth=2, label=label) # hide
end # hide
plot!(plt_flow, xlims = (-1.1, 1), ylims =  (p0min, p0max)) # hide
plot!(plt_flow, [0, 0], [p0min, p0max], color=:black, xlabel="x", ylabel="p", label="x=xf") # hide
sol = exp(p0_sol) # hide
x = [sol(t)[1] for t ∈ sol.t] # hide
p = [sol(t)[2] for t ∈ sol.t] # hide
plot!(plt_flow, x, p, color=:red, linewidth=2, label="extremal solution") # hide
plot!(plt_flow, [x[end]], [p[end]], seriestype=:scatter, color=:green, label=false) # hide
plt_shoot = plot(xlims=(p0min, p0max), ylims=(-2, 4), xlabel="p₀", ylabel="y") # hide
plot!(plt_shoot, p0s, S, linewidth=2, label="S(p₀)", color=:green) # hide
plot!(plt_shoot, [p0min, p0max], [0, 0], color=:black, label="y=0") # hide
plot!(plt_shoot, [p0_sol, p0_sol], [-2, 0], color=:black, label="p₀ solution", linestyle=:dash) # hide
plot!(plt_shoot, [p0_sol], [0], seriestype=:scatter, color=:green, label=false) # hide
plot(plt_flow, plt_shoot, layout=(1,2), size=(800, 450)) # hide
```
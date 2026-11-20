using OptimalControl

t0 = 0
tf = 1
x0 = [-1, 0]
xf = [0, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫(u(t)^2) → min
end

function f_energy!(dx, t, x, u, var)
    dx[1] = x[2]
    dx[2] = u          # scalar control: `u`, not `u[1]`
    return nothing
end

function boundary_energy!(b, x0_, xf_, var)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end

lagrange_energy(t, x, u, var) = 0.5 * u^2

pre = OptimalControl.PreModel()
time!(pre; t0=t0, tf=tf)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)
dynamics!(pre, f_energy!)
constraint!(pre, :boundary; f=boundary_energy!, lb=zeros(4), ub=zeros(4), label=:endpoint)
objective!(pre, :min; lagrange=lagrange_energy)
time_dependence!(pre; autonomous=true)
ocp_func = build(pre)

definition(ocp)          # the macro records the full DSL expression

has_abstract_definition(ocp_func)   # false: no symbolic definition

using NLPModelsIpopt
using Plots

direct_sol = solve(ocp)

plot(direct_sol; size=(800, 710))

sol_init = solve(ocp; init=nothing, max_iter=0, display=false)
plot(sol_init; size=(800, 710))

ig = @init ocp begin
    q(t) := -1 + t
    v(t) := 0
    u(t) := 0
end

sol = solve(ocp; init=ig, display=false)
println("iterations, default guess: ", iterations(direct_sol))
println("iterations, @init guess:   ", iterations(sol))

# Goddard data and dynamics (F0: drift, F1: thrust)
const r0 = 1
const v0 = 0
const m0 = 1
const mf = 0.6
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β * (r - 1))
    [v, -D / m - 1 / r^2, 0]
end
F1(x) = begin
    r, v, m = x
    [0, Tmax / m, -b * Tmax]
end

goddard = @def begin
    tf ∈ R, variable
    t ∈ [t0, tf], time
    x = (r, v, m) ∈ R³, state
    u ∈ R, control

    x(t0) == [r0, v0, m0]
    m(tf) == mf
    0 ≤ u(t) ≤ 1
    r(t) ≥ r0

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

    r(tf) → max
end

using MadNLP

sol_ipopt = solve(goddard; grid_size=250, display=false)
sol_madnlp = solve(goddard, :madnlp; grid_size=250, display=false)

println("Ipopt  : r(tf) = ", objective(sol_ipopt), ", ", iterations(sol_ipopt), " iters")
println("MadNLP : r(tf) = ", objective(sol_madnlp), ", ", iterations(sol_madnlp), " iters")

# cold start: grid 1000 directly (reused below, for the comparison with a bang-bang strategy)
sol_cold = solve(goddard; grid_size=1000, display=false)

# warm cascade: grid 50 first, then grid 1000 initialised from it
s50 = solve(goddard; grid_size=50, display=false)
s1000 = solve(goddard; grid_size=1000, init=s50, display=false)

println("cold    grid 1000        : ", iterations(sol_cold), " iters")
println("cascade grid 50 (warm-up): ", iterations(s50), " iters")
println("cascade grid 1000 (warm) : ", iterations(s1000), " iters")

plt = plot(s50; label="50", size=(800, 1340), legend=false)
plot!(plt, s1000; label="1000")
plot!(plt; subplot=1, legend=:best)   # one legend, on the first subplot

using OrdinaryDiffEqTsit5   # ODE solver + callbacks (ContinuousCallback, terminate!)

# Phase 1: u = 1, stop when m = mf (fuel depleted)
cb_fuel = ContinuousCallback((u, t, int) -> u[3] - mf, terminate!)
flow_bang1 = Flow(VectorField(x -> F0(x) + F1(x)); callback=cb_fuel)
traj_bang1 = flow_bang1((t0, 1.0), [r0, v0, m0])
t1_bang = time_grid(traj_bang1)[end]
x1_bang = state(traj_bang1)(t1_bang)

# Phase 2: u = 0, stop when v = 0 (apogee)
cb_apogee = ContinuousCallback((u, t, int) -> u[2], terminate!)
flow_bang2 = Flow(VectorField(F0); callback=cb_apogee)
traj_bang2 = flow_bang2((t1_bang, 1.0), x1_bang)
tf_bang = time_grid(traj_bang2)[end]
rf_bang = state(traj_bang2)(tf_bang)[1]

r_opt_f = objective(sol_cold)
println("Bang-bang: r(tf) = ", round(rf_bang; digits=6), ", tf = ", round(tf_bang; digits=4))
println("Optimal:   r(tf) = ", round(r_opt_f; digits=6), ", tf = ", round(variable(sol_cold); digits=4))

gain = 100 * (r_opt_f - rf_bang) / (rf_bang - r0)   # gain above r0, in %
println("Extra altitude gain of the optimal strategy: ", round(gain; digits=1), " %")

# assemble the bang-bang altitude as (t, r) for plotting
t1_grid, t2_grid = time_grid(traj_bang1), time_grid(traj_bang2)
t_bang = [t1_grid; t2_grid]
r_bang = [[state(traj_bang1)(t)[1] for t in t1_grid]; [state(traj_bang2)(t)[1] for t in t2_grid]]

# the optimal altitude, read from the solution on its time grid
t_opt = time_grid(sol_cold)
r_opt = [state(sol_cold)(t)[1] for t in t_opt]

tf_opt = t_opt[end]

plt = plot(
    t_opt,
    r_opt;
    label="optimal",
    linewidth=2,
    xlabel="time",
    ylabel="altitude",
    legend=:topleft,
    size=(800, 400),
    left_margin=5Plots.mm,
)
plot!(plt, t_bang, r_bang; label="bang-bang", linestyle=:dash, linewidth=2)
hline!(plt, [r0]; color=:gray, linewidth=0.8, label="")
plot!(plt, [tf_opt, tf_opt], [r0, r_opt_f]; color=1, linestyle=:dot, linewidth=1.2, label="")
plot!(plt, [tf_bang, tf_bang], [r0, rf_bang]; color=2, linestyle=:dot, linewidth=1.2, label="")
scatter!(plt, [tf_opt], [r_opt_f]; color=1, markersize=5, label="")
scatter!(plt, [tf_bang], [rf_bang]; color=2, markersize=5, label="")

# Inset zoom around the two apogees
plot!(
    plt,
    t_opt,
    r_opt;
    inset=(1, bbox(0.40, 0.40, 0.46, 0.45)),
    subplot=2,
    xlims=(0.178, 0.210),
    ylims=(1.01238, 1.01292),
    linewidth=2,
    color=1,
    legend=false,
    title="apogee zoom",
    titlefontsize=9,
    tickfontsize=7,
    framestyle=:box,
)
plot!(plt[2], t_bang, r_bang; linestyle=:dash, linewidth=2, color=2)
scatter!(plt[2], [tf_opt], [r_opt_f]; color=1, markersize=4)
scatter!(plt[2], [tf_bang], [rf_bang]; color=2, markersize=4)
t_ref = 0.203
plot!(plt[2], [tf_opt, t_ref], [r_opt_f, r_opt_f]; color=:gray, linestyle=:dot, linewidth=1)
plot!(plt[2], [tf_bang, t_ref], [rf_bang, rf_bang]; color=:gray, linestyle=:dot, linewidth=1)
plot!(plt[2], [t_ref, t_ref], [rf_bang, r_opt_f]; color=:black, linewidth=1.5)
annotate!(plt[2], t_ref + 0.0008, (rf_bang + r_opt_f) / 2, text("+$(round(gain; digits=1)) %", 8, :left))

using MadNLPGPU
using CUDA
using CUDSS

println("CUDA.functional() = ", CUDA.functional())
try
    global sol_gpu = solve(goddard, :gpu; grid_size=1000, display=false)
    println("GPU solve succeeded: r(tf) = ", objective(sol_gpu))
catch e
    println("GPU solve failed: ", first(sprint(showerror, e), 400))
end

using NonlinearSolve   # nonlinear equations (shooting); the ODE solver is already loaded

# maximising control in feedback form
u_feedback(x, p) = p[2]

# Hamiltonian flow of the OCP
φ = Flow(ocp, u_feedback)

# state projection π(x, p) = x
proj((x, p)) = x

# shooting function
S(p0) = proj(φ(t0, x0, p0, tf)) - xf

nle!(s, p0, _) = (s[:] = S(p0))

p_of_t = costate(direct_sol)     # costate as a function of time
p0_guess = p_of_t(t0)              # initial costate from the direct method

prob = NonlinearProblem(nle!, p0_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(true))
p0_sol = shooting_sol.u

println("costate p0 = ", p0_sol)
println("shoot S(p0) = ", S(p0_sol))

indirect_sol = φ((t0, tf), x0, p0_sol)

plt_compare = plot(direct_sol; label="direct", size=(800, 710), legend=false)
plot!(plt_compare, indirect_sol; label="indirect")
plot!(plt_compare; subplot=1, legend=:best)   # one legend, on the first subplot

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

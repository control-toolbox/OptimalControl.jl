using OptimalControl
using NLPModelsIpopt
using Plots

t0 = 0; tf = 1; x0 = [-1, 0]; xf = [0, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫( u(t)^2 ) → min
end

pre = OptimalControl.PreModel()

time!(pre; t0=t0, tf=tf)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)

function f_energy!(dx, t, x, u, v)
    dx[1] = x[2]
    dx[2] = u[1]
    return nothing
end
dynamics!(pre, f_energy!)

function boundary_energy!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end
constraint!(pre, :boundary; f=boundary_energy!, lb=zeros(4), ub=zeros(4), label=:endpoint)

lagrange_energy(t, x, u, v) = 0.5 * u[1]^2
objective!(pre, :min; lagrange=lagrange_energy)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)

definition(ocp)          # the macro records the full DSL expression

has_abstract_definition(ocp_func)   # false: functional API stores no abstract definition

direct_sol = solve(ocp)

plot(direct_sol)

sol_init = solve(ocp; init=nothing, max_iter=0, display=false)
plot(sol_init; size=(600, 450))

ig = @init ocp begin
    q(t) := -1 + t
    v(t) := 0
    u(t) := 0
end

sol = solve(ocp; init=ig, display=false)
println("iterations, default guess: ", iterations(direct_sol))
println("iterations, @init guess:   ", iterations(sol))

# Goddard data and dynamics (F0: drift, F1: thrust)
const r0 = 1; v0 = 0; m0 = 1; vmax = 0.1; mf = 0.6
Cd = 310; Tmax = 3.5; β = 500; b = 2

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β * (r - 1))
    [v, -D/m - 1/r^2, 0]
end
F1(x) = begin
    r, v, m = x
    [0, Tmax/m, -b*Tmax]
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
    0 ≤ v(t) ≤ vmax

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

    -r(tf) → min
end

using MadNLP
sol_ipopt  = solve(goddard;          grid_size=250, display=false)
sol_madnlp = solve(goddard, :madnlp; grid_size=250, display=false)
println("Ipopt  : r(tf) = ", -objective(sol_ipopt),  ", ", iterations(sol_ipopt),  " iters")
println("MadNLP : r(tf) = ", -objective(sol_madnlp), ", ", iterations(sol_madnlp), " iters")

sol_gl2 = solve(goddard; grid_size=250, scheme=:gauss_legendre_2, display=false)
nothing #hide

using BenchmarkTools

# solutions computed once, reused for iteration counts and the overlay plot
sol_cold = solve(goddard; grid_size=1000, display=false)
s50  = solve(goddard; grid_size=50, display=false)
s1000 = solve(goddard; grid_size=1000, init=s50, display=false)

iter_cold    = iterations(sol_cold)
iter_cascade = iterations(s50) + iterations(s1000)

# timings — BenchmarkTools handles JIT warm-up and reports the minimum
t_cold = @belapsed solve($goddard; grid_size=1000, display=false) samples=3 seconds=10
t_cascade = @belapsed begin
    a = solve($goddard; grid_size=50, display=false)
    solve($goddard; grid_size=1000, init=a, display=false)
end samples=3 seconds=10

println("cold 1000       : ", iter_cold,    " iters, ", round(t_cold;    digits=3), " s")
println("cascade 50→1000 : ", iter_cascade, " iters, ", round(t_cascade; digits=3), " s")

plt = plot(s50;  label="50")
plot!(plt, s1000; label="1000")

using MadNLPGPU
using CUDA

try
    global sol_gpu = solve(goddard, :gpu; grid_size=1000)
    println("GPU solve succeeded — a functional GPU is available.")
catch e
    println("GPU solve failed, as expected without a functional GPU.")
    println("CUDA.functional() = ", CUDA.functional())
    println("Exception: ", first(sprint(showerror, e), 400))
end

using OrdinaryDiffEq   # ODE solver (Hamiltonian flow)
using NonlinearSolve   # nonlinear equations (shooting)

# maximising control in feedback form
u_max(x, p) = p[2]

# Hamiltonian flow of the OCP
φ = Flow(ocp, u_max);

# state projection π(x, p) = x
proj((x, p)) = x

# shooting function
S(p0) = proj(φ(t0, x0, p0, tf)) - xf

nle!(s, p0, _) = (s[:] = S(p0))

p_of_t   = costate(direct_sol)     # costate as a function of time
p0_guess = p_of_t(t0)              # initial costate from the direct method

prob = NonlinearProblem(nle!, p0_guess)
shooting_sol = solve(prob; show_trace=Val(true))
p0_sol = shooting_sol.u

println("costate p0 = ", p0_sol)
println("shoot S(p0) = ", S(p0_sol))

indirect_sol = φ((t0, tf), x0, p0_sol; saveat=range(t0, tf, 100))
plot(indirect_sol)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

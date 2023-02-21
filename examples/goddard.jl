### Goddard

## Direct solve

using OptimalControl
using Plots
#unicodeplots()
ENV["GKSwstype"]="nul" # no plot display on stdout

# Parameters
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2
const t0 = 0
r0 = 1
v0 = 0
vmax = 0.1
m0 = 1
mf = 0.6
x0 = [ r0, v0, m0 ]

ocp = Model()

time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, 3) # state dim
control!(ocp, 1) # control dim

constraint!(ocp, :initial, x0)
constraint!(ocp, :control, u -> u[1], 0, 1) # constraints can be labeled or not
constraint!(ocp, :mixed, (x, u) -> x[1], r0, Inf,  :eq1)
constraint!(ocp, :mixed, (x, u) -> x[2], 0, vmax,  :eq2)
constraint!(ocp, :mixed, (x, u) -> x[3], mf, m0,   :eq3)

objective!(ocp, :mayer,  (t0, x0, tf, xf) -> xf[1], :max)

function F0(x)
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    F = [ v, -D/m - 1/r^2, 0 ]
    return F
end

function F1(x)
    r, v, m = x
    F = [ 0, Tmax/m, -b*Tmax ]
    return F
end

f(x, u) = F0(x) + u[1]*F1(x)

constraint!(ocp, :dynamics, f)

# Solve
N = 30
sol = solve(ocp, grid_size=N)
plot(sol)
savefig("sol-direct.pdf")

## Indirect solve

using MINPACK

# Bang controls
u0(x, p) = [0.]
u1(x, p) = [1.]

# Computation of singular control of order 1
H0(x, p) = p' * F0(x)
H1(x, p) = p' * F1(x)
H01 = Poisson(H0, H1)
H001 = Poisson(H0, H01)
H101 = Poisson(H1, H01)
us(x, p) = [-H001(x, p) / H101(x, p)]

# Computation of boundary control
remove_constraint!(ocp, :eq1)
remove_constraint!(ocp, :eq3)
constraint!(ocp, :boundary, (t0, x0, tf, xf) -> xf[3], mf, :eq4) # one value => equality (not boxed inequality); changed to equality constraint for shooting
#
g(x) = constraint(ocp, :eq2, :upper)(x, 0) # g(x, u) ≥ 0 (cf. nonnegative multiplier)
ub(x, _) = [-Ad(F0, g)(x) / Ad(F1, g)(x)]
μb(x, p) = H01(x, p) / Ad(F1, g)(x)

f0 = Flow(ocp, u0)
f1 = Flow(ocp, u1)
fs = Flow(ocp, us)
fb = Flow(ocp, ub, (x, _) -> g(x), μb)

# Shooting function
function shoot!(s, p0, t1, t2, t3, tf) # B+ S C B0 structure

    x1, p1 = f1(t0, x0, p0, t1)
    x2, p2 = fs(t1, x1, p1, t2)
    x3, p3 = fb(t2, x2, p2, t3)
    xf, pf = f0(t3, x3, p3, tf)
    s[1] = constraint(ocp, :eq4)(t0, x0, tf, xf)
    s[2:3] = pf[1:2] - [ 1, 0 ]
    s[4] = H1(x1, p1)
    s[5] = H01(x1, p1)
    s[6] = g(x2)
    s[7] = H0(xf, pf) # free tf

end

# Initialisation from direct solution
t = sol.T; N = length(t)-1; t = (t[1:end-1] + t[2:end]) / 2
x = [ sol.X[i, 1:3] for i ∈ 1:N+1 ]; x = (x[1:end-1] + x[2:end]) / 2
u = [ sol.U[i, 1  ] for i ∈ 1:N+1 ]; u = (u[1:end-1] + u[2:end]) / 2
p = [ sol.P[i, 1:3] for i ∈ 1:N   ]

u_plot = plot(t, u, xlabel = "t", ylabel = "u", legend = false)
H1_plot = plot(t, H1.(x, p), xlabel = "t", ylabel = "H1", legend = false)
g_plot = plot(t, g.(x), xlabel = "t", ylabel = "g", legend = false)
display(plot(u_plot, H1_plot, g_plot, layout=(3,1), size=(800,600)))

η = 1e-3
t13 = t[ abs.(H1.(x, p)) .≤ η ]
t23 = t[ 0 .≤ g.(x) .≤ η ]
p0 = p[1]
t1 = min(t13...)
t2 = min(t23...)
t3 = max(t23...)
tf = t[end]
ξ = [ p0 ; t1 ; t2 ; t3 ; tf ]

println("Initial guess:\n", ξ)

# Solve
nle = (s, ξ) -> shoot!(s, ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7])
sol = fsolve(nle, ξ, show_trace=true)
println(sol)

# Plots
p0 = sol.x[1:3]
t1 = sol.x[4]
t2 = sol.x[5]
t3 = sol.x[6]
tf = sol.x[7]

f1sb0 = f1 * (t1, fs) * (t2, fb) * (t3, f0) # concatenation of the Hamiltonian flows
sol = f1sb0((t0, tf), x0, p0)
r_plot = plot(sol, idxs=(0, 1), xlabel="t", label="r")
v_plot = plot(sol, idxs=(0, 2), xlabel="t", label="v")
m_plot = plot(sol, idxs=(0, 3), xlabel="t", label="m")
pr_plot = plot(sol, idxs=(0, 4), xlabel="t", label="p_r")
pv_plot = plot(sol, idxs=(0, 5), xlabel="t", label="p_v")
pm_plot = plot(sol, idxs=(0, 6), xlabel="t", label="p_m")
plot(r_plot, pr_plot, v_plot, pv_plot, m_plot, pm_plot, layout=(3, 2))
savefig("sol-indirect.pdf")

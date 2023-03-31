# Parameters
n = 3
m = 1
Cd = 310
Tmax = 3.5
β = 500
b = 2
t0 = 0
r0 = 1
v0 = 0
vmax = 0.1
m0 = 1
mf = 0.6
x0 = [ r0, v0, m0 ]

# model
ocp = Model()

time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, n, ["r", "v", "m"]) # state dim
control!(ocp, m) # control dim

constraint!(ocp, :initial, x0, :initial_constraint) # initial condition
constraint!(ocp, :final, Index(3), mf, :final_constraint)
constraint!(ocp, :control, 0, 1, :control_constraint) # constraints can be labeled or not
constraint!(ocp, :state, Index(1), r0, Inf,  :state_constraint_r)
constraint!(ocp, :state, Index(2), 0, vmax,  :state_constraint_v)
#

objective!(ocp, :mayer,  (t0, x0, tf, xf) -> xf[1], :max)

function F0(x)
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    return [ v, -D/m - 1/r^2, 0 ]
end
function F1(x)
    r, v, m = x
    return [ 0, Tmax/m, -b*Tmax ]
end
f(x, u) = F0(x) + u*F1(x)

constraint!(ocp, :dynamics, f)

# --------------------------------------------------------
# Indirect

u0(x, p) = 0.
u1(x, p) = 1.
#
H0(x, p) = p' * F0(x)
H1(x, p) = p' * F1(x)
H01 = Poisson(H0, H1)
H001 = Poisson(H0, H01)
H101 = Poisson(H1, H01)
us(x, p) = -H001(x, p) / H101(x, p) # singular control of order 1
#
g(x) = vmax-constraint(ocp, :state_constraint_v)(x) # g(x, u) ≥ 0 (cf. nonnegative multiplier)
ub(x, _) = -Ad(F0, g)(x) / Ad(F1, g)(x) # boundary control
μb(x, p) = H01(x, p) / Ad(F1, g)(x)

f0 = Flow(ocp, u0)
f1 = Flow(ocp, u1)
fs = Flow(ocp, us)
fb = Flow(ocp, ub, (x, _) -> g(x), μb)

# Starting Point: [3.9428857983400074, 0.14628855388160236, 0.05412448008321635, 0.025246759388000528, 0.061602092906721286, 0.10401664867856217, 0.20298394547952422]
# Zero: [3.9457646587098827, 0.15039559623399817, 0.05371271294114205, 0.023509684041028683, 0.05973738090274402, 0.10157134842411215, 0.20204744057147958]

# Shooting function
function shoot!(s, p0, t1, t2, t3, tf) # B+ S C B0 structure

    x1, p1 = f1(t0, x0, p0, t1)
    x2, p2 = fs(t1, x1, p1, t2)
    x3, p3 = fb(t2, x2, p2, t3)
    xf, pf = f0(t3, x3, p3, tf)
    s[1] = constraint(ocp, :final_constraint)(xf)-mf
    s[2:3] = pf[1:2] - [ 1, 0 ]
    s[4] = H1(x1, p1)
    s[5] = H01(x1, p1)
    s[6] = g(x2)
    s[7] = H0(xf, pf) # free tf

end

#
p0 = [3.9428857983400074, 0.14628855388160236, 0.05412448008321635]
t1 = 0.025246759388000528
t2 = 0.061602092906721286
t3 = 0.10401664867856217
tf = 0.20298394547952422
s = zeros(eltype(p0), 7)
shoot!(s, p0, t1, t2, t3, tf)
s_guess_sol = [-0.02456074767656735, -0.05699760226157302, 0.0018629693253921868, -0.027013078908634858, -0.21558816838342798, -0.0121146739026253, 0.015713236406057297]
@test s ≈ s_guess_sol atol=1e-6

#
ξ0 = [ p0 ; t1 ; t2 ; t3 ; tf ]

#
foo!(s, ξ) = shoot!(s, ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7])
sol = fsolve(foo!, ξ0, show_trace=true); println(sol)

p0 = sol.x[1:3]
t1 = sol.x[4]
t2 = sol.x[5]
t3 = sol.x[6]
tf = sol.x[7];

shoot!(s, p0, t1, t2, t3, tf)

@test sol.converged
@test norm(s) < 1e-6

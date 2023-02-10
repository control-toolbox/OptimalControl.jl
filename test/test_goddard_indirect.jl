# Parameters
Cd = 310.
Tmax = 3.5
β = 500.
b = 2.
N = 100
t0 = 0.
r0 = 1.
v0 = 0.
vmax = 0.1
m0 = 1.
mf = 0.6
x0 = [r0, v0, m0]

# OCP model
ocp = Model()
time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, 3) # state dim
control!(ocp, 1) # control dim
constraint!(ocp, :initial, x0)
constraint!(ocp, :control, u -> u[1], 0., 1.)
constraint!(ocp, :mixed, (x, u) -> x[1], r0, Inf, :state_con1)
constraint!(ocp, :mixed, (x, u) -> x[2], 0., vmax, :state_con2)
constraint!(ocp, :mixed, (x, u) -> x[3], m0, mf, :state_con3)
#
objective!(ocp, :mayer,  (t0, x0, tf, xf) -> xf[1], :max)

D(x) = Cd * x[2]^2 * exp(-β*(x[1]-1))
F0(x) = [ x[2], -D(x)/x[3]-1/x[1]^2, 0 ]
F1(x) = [ 0, Tmax/x[3], -b*Tmax ]
#f!(dx, x, u) = (dx[:] = F0(x) + u*F1(x))
#constraint!(ocp, :dynamics!, f!) # dynamics can be in place
f(x, u) = F0(x) + u[1]*F1(x)
constraint!(ocp, :dynamics, f)

@test constraint(ocp, :state_con1, :lower)(x0, 0.) ≈ 0. atol=1e-8
@test ocp.state_dimension == 3
@test ocp.control_dimension == 1
@test typeof(ocp) == OptimalControlModel{:autonomous}
@test ocp.initial_time == t0

# --------------------------------------------------------
# Direct

# --------------------------------------------------------
# Indirect

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
remove_constraint!(ocp, :state_con1)
remove_constraint!(ocp, :state_con3)
constraint!(ocp, :boundary, (t0, x0, tf, xf) -> xf[3], mf, :final_con) # one value => equality (not boxed inequality)

g(x) = constraint(ocp, :state_con2, :upper)(x, 0.0) # g(x, u) ≥ 0 (cf. nonnegative multiplier)
ub(x, _) = [-Ad(F0, g)(x) / Ad(F1, g)(x)]
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
    s[1] = constraint(ocp, :final_con)(t0, x0, tf, xf)
    s[2:3] = pf[1:2] - [ 1.0, 0.0 ]
    s[4] = H1(x1, p1)
    s[5] = H01(x1, p1)
    s[6] = g(x2)
    s[7] = H0(xf, pf) # free tf

end

p0 = [3.9428857983400074, 0.14628855388160236, 0.05412448008321635]
t1 = 0.025246759388000528
t2 = 0.061602092906721286
t3 = 0.10401664867856217
tf = 0.20298394547952422
s = zeros(eltype(p0), 7)

shoot!(s, p0, t1, t2, t3, tf)
#println(s)
s_guess_sol = [-0.02456074767656735, -0.05699760226157302, 0.0018629693253921868, -0.027013078908634858, -0.21558816838342798, -0.0121146739026253, 0.015713236406057297]
@test s ≈ s_guess_sol atol=1e-6

ξ0 = [ p0 ; t1 ; t2 ; t3 ; tf ]

#foo(ξ) = shoot(ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7])
#jfoo(ξ) = ForwardDiff.jacobian(foo, ξ)
#foo!(s, ξ) = ( s[:] = foo(ξ); nothing )
#jfoo!(js, ξ) = ( js[:] = jfoo(ξ); nothing )

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

prob = Problem(:goddard, :classical, :altitude, :x_dim_3, :u_dim_1, :mayer, :x_cons, :u_cons, :singular_arc)
ocp = prob.model
sol = prob.solution
title = prob.title

# parameters
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

#
remove_constraint!(ocp, :x_con_rmin)
g(x) = vmax-constraint(ocp, :x_con_vmax)(x, Real[]) # g(x, u) ≥ 0 (cf. nonnegative multiplier)
final_mass_cons(xf) = constraint(ocp, :final_con)(x0, xf, Real[])-mf

function F0(x)
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    return [ v, -D/m - 1/r^2, 0 ]
end

function F1(x)
    r, v, m = x
    return [ 0, Tmax/m, -b*Tmax ]
end

# bang controls
u0 = 0
u1 = 1

# singular control
H0 = Lift(F0)
H1 = Lift(F1)
H01  = @Lie {H0, H1}
H001 = @Lie {H0, H01}
H101 = @Lie {H1, H01}
us(x, p) = -H001(x, p) / H101(x, p)

# boundary control
ub(x)   = -Lie(F0, g)(x) / Lie(F1, g)(x)
μ(x, p) = H01(x, p) / Lie(F1, g)(x)

# flows
f0 = Flow(ocp, (x, p, v) -> u0)
f1 = Flow(ocp, (x, p, v) -> u1)
fs = Flow(ocp, (x, p, v) -> us(x, p))
fb = Flow(ocp, (x, p, v) -> ub(x), (x, u, v) -> g(x), (x, p, v) -> μ(x, p))

# shooting function
function shoot!(s, p0, t1, t2, t3, tf) # B+ S C B0 structure

    x1, p1 = f1(t0, x0, p0, t1)
    x2, p2 = fs(t1, x1, p1, t2)
    x3, p3 = fb(t2, x2, p2, t3)
    xf, pf = f0(t3, x3, p3, tf)
    s[1] = final_mass_cons(xf)
    s[2:3] = pf[1:2] - [ 1, 0 ]
    s[4] = H1(x1, p1)
    s[5] = H01(x1, p1)
    s[6] = g(x2)
    s[7] = H0(xf, pf) # free tf

end

# tests
t1 = 0.025246759388000528
t2 = 0.061602092906721286
t3 = 0.10401664867856217
tf = 0.20298394547952422
p0 = [3.9428857983400074, 0.14628855388160236, 0.05412448008321635]

# test shooting function
s = zeros(eltype(p0), 7)
shoot!(s, p0, t1, t2, t3, tf)
s_guess_sol = [-0.02456074767656735, 
-0.05699760226157302,
0.0018629693253921868, 
-0.027013078908634858, 
-0.21558816838342798, 
-0.0121146739026253, 
0.015713236406057297]
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

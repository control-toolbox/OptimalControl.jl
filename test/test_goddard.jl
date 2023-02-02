Ad(X, f) = ∇(f, x)'*X(x)
function Poisson(f, g)
    function fg(x, p)
        n = size(x, 1)
        ff = z -> f(z[1:n], z[n+1:2n])
        gg = z -> g(z[1:n], z[n+1:2n])
        df = ∇(ff, [ x ; p ])
        dg = ∇(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return fg
end

#
State = @SLVector (:r, :v, :m)

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
x0 = State(r0, v0, m0)

# OCP model
ocp = Model()
time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, 3) # state dim
control!(ocp, 1) # control dim
constraint!(ocp, :initial, x0)
constraint!(ocp, :control, u -> u[1], 0., 1.)
constraint!(ocp, :state, (x, u) -> x[1], r0, Inf, :state_con1)
constraint!(ocp, :state, (x, u) -> x[2], 0., vmax, :state_con2)
constraint!(ocp, :state, (x, u) -> x[3], m0, mf, :state_con3)
#
objective!(ocp, :mayer,  (t0, x0, tf, xf) -> xf[1], :max)

D(x) = Cd * x.v^2 * exp(-β*(x.r-1.))
F0(x) = [ x.v, -D(x)/x.m-1.0/x.r^2, 0. ]
F1(x) = [ 0., Tmax/x.m, -b*Tmax ]
#f!(dx, x, u) = (dx[:] = F0(x(t)) + u*F1(x(t)))
#constraint!(ocp, :dynamics!, f!) # dynamics can be in place
f(x, u) = F0(x(t)) + u*F1(x(t))
constraint!(ocp, :dynamics, f)

#@test 
constraint(ocp, :state_con1, :lower)(x0, 0.) #≈ 0. atol=1e-8
@test ocp.state_dimension == 3
@test ocp.control_dimension == 1
@test typeof(ocp) == OptimalControlModel
@test ocp.initial_time == t0

ξ, ψ, ϕ = nlp_constraints(ocp)

# --------------------------------------------------------
# Direct

# --------------------------------------------------------
# Indirect

# Bang controls
u0(x, p) = 0.
u1(x, p) = 1.

# Computation of singular control of order 1
H0(x, p) = p' * F0(x)
H1(x, p) = p' * F1(x)
H01 = Poisson(H0, H1)
H001 = Poisson(H0, H01)
H101 = Poisson(H1, H01)
us(x, p) = -H001(x, p) / H101(x, p)

# Computation of boundary control
remove_constraint!(ocp, :state_con1)
remove_constraint!(ocp, :state_con3)
constraint!(ocp, :boundary, (t0, x0, tf, xf) -> xf[3], mf, :final_con) # one value => equality (not boxed inequality)

g(x) = constraint(ocp, :state_con2, :upper)(x, 0.) # g(x, u) ≥ 0 (cf. nonnegative multiplier)
ub(x, p) = -Ad(F0, g)(x) / Ad(F1, g)(x)
μb(x, p) = H01(x, p) / Ad(F1, g)(x)

f0 = Flow(ocp, u0)
f1 = Flow(ocp, u1)
fs = Flow(ocp, us)
#fb = Flow(ocp, ub, :state_con2_upper, μb)
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
x0 = [ r0, v0, m0 ]

#
ocp = Model()
@test typeof(ocp) == OptimalControlModel

#
time!(ocp, :initial, t0) # if not provided, final time is free
@test ocp.initial_time == t0

#
state!(ocp, 3) # state dim
control!(ocp, 1) # control dim
@test ocp.state_dimension == 3
@test ocp.control_dimension == 1

#
constraint!(ocp, :initial, x0)

#
constraint!(ocp, :control, u -> u[1], 0., 1.)

#
constraint!(ocp, :state, (x, u) -> x[1], r0, Inf, :state_con1)
constraint!(ocp, :state, (x, u) -> x[2], 0., vmax, :state_con2)
constraint!(ocp, :state, (x, u) -> x[3], m0, mf, :state_con3)

@test constraint(ocp, :state_con1_lower)(x0, 0.) ≈ 0. atol=1e-8

#
objective!(ocp, :mayer,  (t0, x0, tf, xf) -> xf[1], :max)

#
function F0(x)
      r, v, m = x
      D = Cd * v^2 * exp(-β*(r-1.))
      F = [ v, -D/m-1.0/r^2, 0. ]
      return F
  end

function F1(x)
      r, v, m = x
      F = [ 0., Tmax/m, -b*Tmax ]
      return F
end

function f!(dx, x, u)
      dx[:] = F0(x(t)) + u*F1(x(t))
end

constraint!(ocp, :dynamics!, f!) # dynamics can be in place

#
remove_constraint!(ocp, :state_con1)
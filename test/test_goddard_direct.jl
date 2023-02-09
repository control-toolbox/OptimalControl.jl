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

epsilon = 1.e-2

ocp = Model()

time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, 3) # state dim
control!(ocp, 1) # control dim

constraint!(ocp, :initial, x0) # vectorial equality
constraint!(ocp, :control, u -> u[1], 0., 1.) # constraints can be labeled or not
constraint!(ocp, :state, (x, u) -> x[1], r0, Inf, :state_con1)       # epsilon car sinon adjoint state at 0 false because the state is r0 touch the constraint at 0
constraint!(ocp, :state, (x, u) -> x[2], 0., vmax, :state_con2)
constraint!(ocp, :state, (x, u) -> x[3], mf, m0, :state_con3)        

objective!(ocp, :mayer,  (t0, x0, tf, xf) -> xf[1], :max)

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

function f(x, u)
    return F0(x) + u[1]*F1(x)
end

constraint!(ocp, :dynamics, f)
println("test_goddard_direct")
println(sol)

sol = solve(ocp, grid_size=10)

#using JLD2
#@save "./src/direct/sol_goddard_20.jld2" sol

println(sol)
#plot(sol) # no plot in tests (plot crashes without display port, e.g. on a jupyterhub connection)

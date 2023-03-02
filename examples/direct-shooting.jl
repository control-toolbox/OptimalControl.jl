using OptimalControl

t0 = 0
tf = 1
x0 = [ -1, 0 ]
xf = [  0, 0 ]

ocp = Model()

state!(ocp, 2)   # dimension of the state
control!(ocp, 1) # dimension of the control
time!(ocp, [t0, tf])
constraint!(ocp, :initial, x0)
constraint!(ocp, :final,   xf)
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
objective!(ocp, :lagrange, (x, u) -> 0.5u^2)

# initial iterate
u_sol(t) = 6.0-12.0*t # solution
N = 501
T = range(t0, tf, N)
U_init = [[u_sol(T[i])-1.0] for i = 1:N-1]

# resolution
sol = solve(ocp, :direct, :shooting, init=U_init)

# plot solution
ps = plot(sol, size=(800, 400))

# plot target
point_style = (color=:black, seriestype=:scatter, markersize=3, markerstrokewidth=0, label="")
plot!(ps[1], [tf], [xf[1]]; point_style...)
plot!(ps[2], [tf], [xf[2]]; point_style...)
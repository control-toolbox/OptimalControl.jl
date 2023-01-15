using OptimalControl
using Plots

# description of the optimal control problem
t0 = 0.0                # t0 is fixed
tf = 1.0                # tf is fixed
x0 = [-1.0; 0.0]        # the initial condition is fixed
xf = [0.0; 0.0]         # the target is fixed
A = [0.0 1.0
    0.0 0.0]
B = [0.0; 1.0]
f(x, u) = A * x + B * u[1];  # dynamics
L(x, u) = 0.5 * u[1]^2   # integrand of the Lagrange cost

# problem definition
ocp = OptimalControlProblem(L, f, t0, x0, tf, xf, 2, 1, :autonomous)

# display the formulation of the problem
display(ocp)

# initial iterate
u_sol(t) = 6.0-12.0*t # solution
N = 501
T = range(t0, tf, N)
U_init = [[u_sol(T[i])-1.0] for i = 1:N-1]

# resolution
sol = solve(ocp, :direct, :simple_shooting, init=U_init)

# plot solution
ps = plot(sol, size=(800, 400))

# plot target
point_style = (color=:black, seriestype=:scatter, markersize=3, markerstrokewidth=0, label="")
plot!(ps[1], [tf], [xf[1]]; point_style...)
plot!(ps[1], [tf], [xf[2]]; point_style...)
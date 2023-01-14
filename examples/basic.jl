using OptimalControl
using Plots

# ocp description
t0 = 0.0                # t0 is fixed
tf = 1.0                # tf is fixed
x0 = [-1.0; 0.0]        # the initial condition is fixed
xf = [0.0; 0.0]         # the target
A = [0.0 1.0
      0.0 0.0]
B = [0.0; 1.0]
f(x, u) = A * x + B * u[1];  # dynamics
L(x, u) = 0.5 * u[1]^2   # integrand of the Lagrange cost

# 
prob = OptimalControlProblem(L, f, t0, x0, tf, xf, 2, 1)    # ocp definition
sol = solve(prob)                                           # ocp resolution
plot(sol)                                                   # plot ocp solution
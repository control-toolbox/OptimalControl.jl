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
c(x) = x - xf            # final condition

# ocp definition
ocp1 = OptimalControlProblem(L, f, t0, x0, tf, c, 2, 1, 2)
# or                         |        |
ocp2 = OptimalControlProblem(L, f, t0, x0, tf, xf, 2, 1)

# resolution
sol1 = solve(ocp1)
sol2 = solve(ocp2);

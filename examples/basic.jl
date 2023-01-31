using OptimalControl, NLPModelsIpopt, ADNLPModels


# description of the optimal control problem
t0 = 0.0                # t0 is fixed
tf = 1.0                # tf is fixed
n = 2                   # state dimension
m = 1                   # control dimension
x0 = [-1.0; 0.0]        # the initial condition is fixed
xf = [0.0; 0.0]         # the target is fixed
A = [0.0 1.0
      0.0 0.0]
B = [0.0; 1.0]
f(x, u) = A * x + B * u[1];  # dynamics
L(x, u) = 0.5 * u[1]^2   # integrand of the Lagrange cost

# 
# ocp = OptimalControlProblem(L, f, t0, x0, tf, xf, 2, 1)     # problem definition
#  sol = solve(ocp)                                            # resolution
# plot(sol)                                                   # plot solution

N = 10 # time steps
# layout of the nlp unknown xu for Euler discretization 
# additional state variable x_{n+1}(t) for the objective (Lagrange to Mayer formulation)
# [x_1(t_0), ... , x_1(t_N), ... , x_n(t_0), ..., x_n(t_N)
#  x_{n+1}(t_0), ... , x_{n+1}(t_N),
#  u_1(t_0), ... , u_1(t_{N-1}), ... , u_m(t_0), ..., u_m(t_{N-1})]

xu0 = zeros((N+1)*(n+1)+N*m)                                 #
obj(xu) = xu[(N+1)*(n+1)]

nlp = ADNLPModel(obj, xu0, [-1.2; 1.0])
stats = ipopt(nlp)
print(stats)
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
# [x_1(t_0), ... , x_{n+1}(t_0),
#  ... , 
#  x_{1}(t_N), ... , x_{n+1}(t_N),
#  u_1(t_0), ... , u_m(t_0), 
#  ... , 
#  u_m(t_{N-1}), ..., u_m(t_{N-1})]

f_Mayer(x,u) = [f(x,u); L(x,u)]   # second member of the ode for the Mayer formulation

xu0 = zeros((N+1)*(n+1)+N*m)                                 #
objective(xu) = xu[(N+1)*(n+1)]

function constraint(xu::Vector{<:Real},n,m,N,x0,xf)::Vector{<:Real}
    c = zeros(N*(n+1)+2*n+1)
    for i in 0:N-1
      xi = xu[1+i*(n+1):(i+1)*(n+1)]
      xip1 = xu[1+(i+1)*(n+1):(i+2)*(n+1)]
      ui = xu[1+(N+1)*(n+1):m+(N+1)*(n+1)]
      c[1+i*(n+1):(i+1)*(n+1)] = xip1 - (xi + h*f_Mayer(xi, ui))
    end
    c[1+N*(n+1):n+N*(n+1)] = xu[1:n] - x0
    c[n+1+N*(n+1):2*n+N*(n+1)] = xu[1+N*(n+1):(N+1)*(n+1)-1] - xf
    return c
end

constraint_Ipopt(xu) = constraint(xu,n,m,N)
nlp = ADNLPModel(objective, xu0, [-1.2; 1.0])
stats = ipopt(nlp)
print(stats)
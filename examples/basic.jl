using OptimalControl, NLPModelsIpopt, ADNLPModels

ocp = Model()
#
state!(ocp, 2)
control!(ocp, 1)
#
time!(ocp, [0., 1.])
#
constraint!(ocp, :initial, [ -1., 0. ])
constraint!(ocp, :final,   [  0., 0. ])
#
A = [ 0. 1.
      0. 0.]
B = [ 0.
      1. ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
#
objective!(ocp, :lagrangian, (x, u) -> 0.5*u^2) # default is to minimise




# transcription ocp -> NLP
N = 10 # time steps
n = ocp.state_dimension
m = ocp.control_dimension
# layout of the nlp unknown xu for Euler discretization 
# additional state variable x_{n+1}(t) for the objective (Lagrange to Mayer formulation)
# [x_1(t_0), ... , x_{n+1}(t_0),
#  ... , 
#  x_{1}(t_N), ... , x_{n+1}(t_N),
#  u_1(t_0), ... , u_m(t_0), 
#  ... , 
#  u_m(t_{N-1}), ..., u_m(t_{N-1})]



xu0 = zeros((N+1)*(n+1)+N*m)                                 #
objective(xu) = xu[(N+1)*(n+1)]

function constraint(ocp, xu::Vector{<:Real},N)::Vector{<:Real}
  """
  compute the constraints for the NLP : 
    - discretization of the dynamics via the Euler method
    - boundary conditions
  inputs
  ocp :: ocp model
  xu :: 
    layout of the nlp unknown xu for Euler discretization 
    additional state variable x_{n+1}(t) for the objective (Lagrange to Mayer formulation)
    [x_1(t_0), ... , x_{n+1}(t_0),
     ... , 
     x_{1}(t_N), ... , x_{n+1}(t_N),
     u_1(t_0), ... , u_m(t_0), 
     ... , 
     u_m(t_{N-1}), ..., u_m(t_{N-1})]
  return
  c :: 
  """
    t0 = ocp.initial_time
    tf = ocp.final_time
    n = ocp.state_dimension
    m = ocp.control_dimension
  
    x0 = ocp.initial_condition
    xf = ocp.final_condition
  
    f = ocp.dynamics
    L = ocp.lagrange 
    f_Mayer(x,u) = [f(x,u); L(x,u)]   # second member of the ode for the Mayer formulation

    h = (tf-t0)/N
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

# bounds for the constraints
lb = zeros(N*(n+1)+2*n+1)
ub = zeros(N*(n+1)+2*n+1)
constraint_Ipopt(xu) = constraint(ocp,xu,N)
nlp = ADNLPModel(objective, xu0, constraint_Ipopt,lb,ub)
stats = ipopt(nlp)
print(stats)
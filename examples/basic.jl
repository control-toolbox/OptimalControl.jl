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
N = 2 # time steps
m = ocp.control_dimension
f = ocp.dynamics
L = ocp.lagrange 

# we pass u[1] because in our case ocp.dynamics and ocp.lagrange are define with a scalar u
# but her x is a vector
# question : how determine if u and x are scalar or vector ?
# second member of the ode for the Mayer formulation
n = ocp.state_dimension
f_Mayer(x,u) = [f(x[1:n],u[1]); L(x[1:n],u[1])]
# if isnothing(ocp.lagrange)
#   n = ocp.state_dimension
#   f_Mayer(x,u) = f(x,u[1])
# else
#   n = ocp.state_dimension + 1
#   f_Mayer(x,u) = [f(x[1:n],u[1]); L(x[1:n],u[1])]
# end

nc = N*(n+1)+2*n+1               # dimension of the constraints
# layout of the nlp unknown xu for Euler discretization 
# additional state variable x_{n+1}(t) for the objective (Lagrange to Mayer formulation)
# [x_1(t_0), ... , x_{n+1}(t_0),
#  ... , 
#  x_{1}(t_N), ... , x_{n+1}(t_N),
#  u_1(t_0), ... , u_m(t_0), 
#  ... , 
#  u_m(t_{N-1}), ..., u_m(t_{N-1})]



                               #
objective(xu) = xu[(N+1)*(n+1)]

function get_state_at_time_step(xu,i)
  """
     return
     x(t_i)
  """
  if i > N
    error("trying to access at x(t_i) for i > N")
  end  
  return xu[1+i*(n+1):(i+1)*(n+1)]
end

function get_control_at_time_step(xu,i)
  """
     return
     u(t_i)
  """
  if i > N-1
    error("trying to access at (t_i) for i > N-1")
  end
  return xu[1+(N+1)*(n+1)+i*m:m+(N+1)*(n+1)+i*m]
end

function parse_sol(xu,t0,tf,N)
  """
     return
      X = matrix(n+1,N+1)
  """

end



#function constraint(ocp, xu::Vector{<:Real},N)::Vector{<:Real}
function constraint(ocp, xu, N)
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
    nc = N*(n+1)+2*n+1               # dimension of the constraints
    x0 = ocp.initial_condition
    xf = ocp.final_condition
  
   
                                                      

    h = (tf-t0)/N
    c = zeros(eltype(xu),nc)
    for i in 0:N-1
      xi = get_state_at_time_step(xu,i)
      xip1 = get_state_at_time_step(xu,i+1)
      ui = get_control_at_time_step(xu,i)
      c[1+i*(n+1):(i+1)*(n+1)] = xip1 - (xi + h*f_Mayer(xi, ui))
    end
    c[1+N*(n+1):n+1+N*(n+1)] = xu[1:n+1] - [x0 ; 0]
    c[n+2+N*(n+1):2*n+1+N*(n+1)] = xu[1+N*(n+1):(N+1)*(n+1)-1] - xf
 
    return c
end




# bounds for the constraints
lb = zeros(nc)
ub = zeros(nc)

constraint_Ipopt(xu) = constraint(ocp,xu,N)
xu0 = zeros((N+1)*(n+1)+N*m)  
#println(get_state_at_time_step(xu0,1))

#nlp = ADNLPModel(objective, xu0, constraint_Ipopt,lb,ub)
nlp = ADNLPModel(objective, xu0, xu -> constraint(ocp,xu,N),lb,ub)
stats = ipopt(nlp)
print(stats)


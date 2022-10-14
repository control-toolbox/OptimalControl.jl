include("../src/ControlToolbox.jl"); # nécessaire tant que pas un vrai package
import .ControlToolbox: plot , plot! # nécessaire tant que include et using relatif
using .ControlToolbox
using Plots

# ocp description
t0 = 0.0                # t0 is fixed
tf = 1.0                # tf is fixed
x0 = [-1.0; 0.0]        # the initial condition is fixed
xf = [ 0.0; 0.0]        # the target
A  = [0.0 1.0
      0.0 0.0]
B  = [0.0; 1.0]
dy(x, u) = A*x+B*u[1];  # dynamics
co(x, u) = 0.5*u[1]^2   # integrand of the Lagrange cost
cf(x) = x-xf            # final condition

# ocp definition
ocp = OCP(  control_dimension=1,
            Lagrange_cost=co, 
            dynamics=dy, 
            initial_time=t0, 
            initial_condition=x0, 
            final_time=tf, 
            final_constraint=cf)

# resolution
ocp_sol = solve(ocp)

# plot solution
plot(ocp_sol)
# ocp solution to use a close init to the solution
N  = 1001
U⁺ = range(6.0, stop=-6.0, length=N); # solution
U⁺ = U⁺[1:end-1];

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
ocp = OCP(  :autonomous,
            control_dimension=1,
            Lagrange_cost=co, 
            dynamics=dy, 
            initial_time=t0, 
            initial_condition=x0, 
            final_time=tf, 
            final_constraint=cf)

# initial iterate
U_init = U⁺-1e0*ones(N-1); U_init = [ [U_init[i]] for i=1:N-1 ]

# resolution
ocp_sol = solve(ocp, :descent, init=U_init, 
                  grid_size=N, penalty_constraint=1e4, iterations=5, step_length=1)

plot(ocp_sol)

@testset "Descent - Solve" begin
    @test typeof(ocp_sol) == DescentOCPSol
end
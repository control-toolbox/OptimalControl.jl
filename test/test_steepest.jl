t0 = 0.0
tf = 1.0
x0 = [-1.0; 0.0]
xf = [ 0.0; 0.0]
A  = [0.0 1.0
      0.0 0.0]
B  = [0.0; 1.0]

dy(x, u) = A*x+B*u[1];
co(u) = 0.5*u[1]^2
cf(x) = x-xf

# OCP definition
ocp = RegularOptimalControlProblem(co, dy, t0, x0, tf, cf)

N  = 101
U⁺ = range(6.0, -6.0, N); # solution
U⁺ = U⁺[1:end-1];
U_init = U⁺-1e0*ones(N-1)
U_init = [ [U_init[i]] for i=1:N-1 ]

ocp_sol = solve(ocp, :steepest_descent, init=U_init, grid_size=N, penalty_constraint=1e2, iterations=10, step_length=1e-1)

plot(ocp_sol, :time,  (:state, 1), xlabel = "t", ylabel = "x₁",  legend = false)

@testset "Steepest descent - Solve" begin
    @test typeof(ocp_sol) == SteepestOCPSol
end
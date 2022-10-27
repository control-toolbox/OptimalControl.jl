# --------------------------------------------------------------------------------------------------
#
f(x) = (1/2)*norm(x)^2
g(x) = x
dp = ControlToolbox.DescentProblem(g, f)
x0 = [1.0; 0.0]
di = ControlToolbox.DescentInit(x0)
s  = [0.0; 0.0]

@test typeof(dp) == ControlToolbox.DescentProblem
@test typeof(di) == ControlToolbox.DescentInit

ds = ControlToolbox.descent_solver(dp, di, direction=:gradient, line_search=:backtracking, display=false)
@test ds.x ≈ s atol=1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:gradient, line_search=:bissection, display=false)
@test ds.x ≈ s atol=1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:bfgs, line_search=:backtracking, display=false)
@test ds.x ≈ s atol=1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:bfgs, line_search=:bissection, display=false)
@test ds.x ≈ s atol=1e-8

# --------------------------------------------------------------------------------------------------
#

direction, line_search = ControlToolbox.read((:gradient, :bissection, :tata))
@test direction === :gradient
@test line_search === :bissection

# --------------------------------------------------------------------------------------------------
#
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
f(x, u) = A*x+B*u[1];  # dynamics
L(x, u) = 0.5*u[1]^2   # integrand of the Lagrange cost

# ocp definition
ocp = OCP(L, f, t0, x0, tf, xf, 2, 1)

# initial iterate
U_init = U⁺-1e0*ones(N-1); U_init = [ [U_init[i]] for i=1:N-1 ]

# resolution
sol = solve(ocp, :descent, init=U_init, 
                  grid_size=N, penalty_constraint=1e4, iterations=5, step_length=1, display=false)

#
@test typeof(DescentOCPInit(U_init)) == DescentOCPInit
@test typeof(sol) == DescentOCPSol

#plot(sol)

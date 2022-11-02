#
e = IncorrectMethod(:e)
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = AmbiguousDescription((:e,))
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

# ocp description
t0 = 0.0                # t0 is fixed
tf = 1.0                # tf is fixed
x0 = [-1.0; 0.0]        # the initial condition is fixed
xf = [0.0; 0.0]        # the target
A = [0.0 1.0
      0.0 0.0]
B = [0.0; 1.0]
f(x, u) = A * x + B * u[1];  # dynamics
L(x, u) = 0.5 * u[1]^2   # integrand of the Lagrange cost

# ocp definition
ocp = OCP(L, f, t0, x0, tf, xf, 2, 1)

# ocp resolution
@test_throws AmbiguousDescription solve(ocp, :ttt)
@test_throws AmbiguousDescription solve(ocp, :descent, :ttt)
@test_throws AmbiguousDescription solve(ocp, :descent, :backtracking, :ttt)
@test_throws AmbiguousDescription solve(ocp, :descent, :backtracking, :bfgs, :ttt)

# incorrect description
gCSD = ControlToolbox.getCompleteSolverDescription
@test_throws AmbiguousDescription gCSD((:ttt,))
@test_throws AmbiguousDescription gCSD((:descent, :ttt))

# 
f(x) = (1 / 2) * norm(x)^2
g(x) = x
dp = ControlToolbox.DescentProblem(g, f)
x0 = [1.0; 0.0]
di = ControlToolbox.DescentInit(x0)
d_solver = ControlToolbox.descent_solver
@test_throws IncorrectMethod d_solver(dp, di, direction=:tata, line_search=:backtracking)
@test_throws IncorrectMethod d_solver(dp, di, direction=:gradient, line_search=:tata)

# convert
@test_throws IncorrectMethod ControlToolbox.convert(ocp, Integer)
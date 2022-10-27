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

# resolution
#@testset "Type of exceptions" begin
    @test_throws AmbiguousDescriptionError solve(ocp, :ttt)
    @test_throws AmbiguousDescriptionError solve(ocp, :descent, :ttt)
    @test_throws AmbiguousDescriptionError solve(ocp, :descent, :backtracking, :ttt)
    @test_throws AmbiguousDescriptionError solve(ocp, :descent, :backtracking, :bfgs, :ttt)
#end
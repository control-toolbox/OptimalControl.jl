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
c(x) = x-xf            # final condition

#
N  = 101
U⁺ = range(6.0, stop=-6.0, length=N); # solution
U⁺ = U⁺[1:end-1];
U_init = U⁺-1e0*ones(N-1); U_init = [ [U_init[i]] for i=1:N-1 ]

# RegularOCPFinalConstraint 
# ocp definition
ocp = OCP(L, f, t0, x0, tf, c, 2, 1, 2)
@test typeof(ocp) == RegularOCPFinalConstraint
#f(ocp) = @info print(ocp)
#@test_logs (:info,) match_mode=:any f(ocp)
@test print(ocp) === nothing

sol = solve(ocp, :bfgs, :backtracking, init=U_init, grid_size=N, display=false)
@test abs.(ControlToolbox.vec2vec(sol.U)-Vector(U⁺)) ≈ zeros(Float64, N-1) atol=1.0

# RegularOCPFinalCondition
# ocp definition
ocp = OCP(L, f, t0, x0, tf, xf, 2, 1)
@test typeof(ocp) == RegularOCPFinalCondition
#@test_logs (:info,) match_mode=:any f(ocp)
@test print(ocp) === nothing

sol = solve(ocp, :bfgs, :backtracking, init=U_init, grid_size=N, display=false)
@test abs.(ControlToolbox.vec2vec(sol.U)-Vector(U⁺)) ≈ zeros(Float64, N-1) atol=1.0

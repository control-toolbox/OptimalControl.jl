# prob description
t0 = 0.0                # t0 is fixed
tf = 1.0                # tf is fixed
x0 = [-1.0; 0.0]        # the initial condition is fixed
xf = [0.0; 0.0]        # the target
A = [0.0 1.0
      0.0 0.0]
B = [0.0; 1.0]
f(x, u) = A * x + B * u[1];  # dynamics
L(x, u) = 0.5 * u[1]^2   # integrand of the Lagrange cost
c(x) = x - xf            # final condition

#
N = 201
U⁺ = range(6.0, stop=-6.0, length=N); # solution
U⁺ = U⁺[1:end-1];
U_init = U⁺ - 1e0 * ones(N - 1);
U_init = [[U_init[i]] for i = 1:N-1];

# UncFreeXfProblem 
# prob definition
prob = OptimalControlProblem(L, f, t0, x0, tf, c, 2, 1, 2)
@test typeof(prob) == UncFreeXfProblem{:autonomous}
@test print(prob) === nothing

sol = solve(prob, :bfgs, :backtracking, display=false)
@test abs.(vec2vec(sol.U) - Vector(U⁺)) ≈ zeros(Float64, N - 1) atol = 1.0

# UncFixedXfProblem
# prob definition
prob = OptimalControlProblem(L, f, t0, x0, tf, xf, 2, 1)
@test typeof(prob) == UncFixedXfProblem{:autonomous}
@test print(prob) === nothing

sol = solve(prob, :bfgs, :backtracking, display=false)
@test abs.(vec2vec(sol.U) - Vector(U⁺)) ≈ zeros(Float64, N - 1) atol = 1.0

# --------------------------------------------------------------------------------------------------
# convert
#
# prob definition
prob = OptimalControlProblem(L, f, t0, x0, tf, xf, 2, 1)

#
@test_throws IncorrectMethod convert(prob, :DummyProblem)

#
prob_new = convert(prob, :UncFreeXfProblem)
@test typeof(prob_new) == UncFreeXfProblem{:autonomous}
@test prob_new.final_constraint(xf) ≈ [0.0; 0.0] atol = 1e-8

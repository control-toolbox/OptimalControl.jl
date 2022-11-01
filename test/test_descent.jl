# --------------------------------------------------------------------------------------------------
# descent solver
#
f(x) = (1 / 2) * norm(x)^2
g(x) = x
dp = ControlToolbox.DescentProblem(g, f)
x0 = [1.0; 0.0]
di = ControlToolbox.DescentInit(x0)
s = [0.0; 0.0]

@test typeof(dp) == ControlToolbox.DescentProblem
@test typeof(di) == ControlToolbox.DescentInit

ds = ControlToolbox.descent_solver(dp, di, display=false)
@test ds.x ≈ s atol = 1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:gradient, line_search=:backtracking, display=false)
@test ds.x ≈ s atol = 1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:gradient, line_search=:bissection, display=false)
@test ds.x ≈ s atol = 1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:gradient, line_search=:fixedstep,
      optimalityTolerance=1e-3, display=true)
@test ds.x ≈ s atol = 1e-3

ds = ControlToolbox.descent_solver(dp, di, direction=:bfgs, line_search=:backtracking, display=false)
@test ds.x ≈ s atol = 1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:bfgs, line_search=:bissection, display=false)
@test ds.x ≈ s atol = 1e-8

ds = ControlToolbox.descent_solver(dp, di, direction=:bfgs, line_search=:fixedstep,
      optimalityTolerance=1e-3, display=true)
@test ds.x ≈ s atol = 1e-3

# --------------------------------------------------------------------------------------------------
#
direction, line_search = ControlToolbox.read((:gradient, :bissection, :tata))
@test direction === :gradient
@test line_search === :bissection

# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------
#
# ocp
t0 = 0.0                # t0 is fixed
tf = 1.0                # tf is fixed
x0 = [-1.0; 0.0]        # the initial condition is fixed
xf = [0.0; 0.0]        # the target
A = [0.0 1.0
      0.0 0.0]
B = [0.0; 1.0]
f(x, u) = A * x + B * u[1];  # dynamics
L(x, u) = 0.5 * u[1]^2   # integrand of the Lagrange cost
ocp = OCP(L, f, t0, x0, tf, xf, 2, 1)

# solution
u_sol(t) = 6.0-12.0*t

# --------------------------------------------------------------------------------------------------
#
# initialization
ocp_c = ControlToolbox.convert(ocp, RegularOCPFinalConstraint)
ocp2descent_init = ControlToolbox.ocp2descent_init
__grid_size = ControlToolbox.__grid_size
__init = ControlToolbox.__init
__grid = ControlToolbox.__grid
__init_interpolation = ControlToolbox.__init_interpolation

# init=nothing, grid=nothing => init=zeros(m, N-1), grid=range(t0, tf, N), with N=__grid_size()
init_, grid_ = ocp2descent_init(ocp_c, nothing, nothing)
@test init_.x == ControlToolbox.DescentInit(__init(ocp_c)).x
@test grid_ == __grid(ocp_c)

# init=nothing, grid=T => init=zeros(m, N-1), grid=T, with N=length(T) (check validity)
N = floor(Int64, __grid_size()/2) # pour avoir un N différent de __grid_size()
grid = range(t0, tf, N)
init_, grid_ = ocp2descent_init(ocp_c, nothing, grid)
N = length(grid)
@test init_.x == ControlToolbox.DescentInit(__init(ocp_c, N)).x
@test grid_ == grid
@test_throws InconsistentArgument ocp2descent_init(ocp_c, nothing, range(t0-1, tf, N))
@test_throws InconsistentArgument ocp2descent_init(ocp_c, nothing, range(t0, tf+1, N))
@test_throws InconsistentArgument ocp2descent_init(ocp_c, nothing, range(tf, t0, N))

# init=U, grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size()
N = floor(Int64, __grid_size()/2) # pour avoir un N différent de __grid_size()
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
init_, grid_ = ocp2descent_init(ocp_c, U, nothing)
@test init_.x == ControlToolbox.DescentInit(U).x
@test grid_ == range(t0, tf, length(U)+1)

# init=U, grid=T => init=U, grid=T (check validity with ocp and with init)
N = floor(Int64, __grid_size()/2) # pour avoir un N différent de __grid_size()
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
init_, grid_ = ocp2descent_init(ocp_c, U, T)
@test init_.x == ControlToolbox.DescentInit(U).x
@test grid_ == T
@test_throws InconsistentArgument ocp2descent_init(ocp_c, U, range(t0-1, tf, N))
@test_throws InconsistentArgument ocp2descent_init(ocp_c, U, range(t0, tf+1, N))
@test_throws InconsistentArgument ocp2descent_init(ocp_c, U, range(tf, t0, N))
@test_throws InconsistentArgument ocp2descent_init(ocp_c, U, range(t0, tf, 2*N))

# init=(T,U), grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size() (check validity with ocp and with U)
N = floor(Int64, __grid_size()/2) # pour avoir un N différent de __grid_size()
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
init_, grid_ = ocp2descent_init(ocp_c, (T,U), nothing, __init_interpolation())
@test init_.x ≈ ControlToolbox.DescentInit([[u_sol(grid_[i])-1.0] for i = 1:__grid_size()-1]).x atol=1e-4
@test grid_ == __grid(ocp_c)
@test_throws InconsistentArgument ocp2descent_init(ocp_c, (range(t0-1, tf, N), U), nothing, __init_interpolation())
@test_throws InconsistentArgument ocp2descent_init(ocp_c, (range(t0, tf+1, N), U), nothing, __init_interpolation())
@test_throws InconsistentArgument ocp2descent_init(ocp_c, (range(tf, t0, N), U), nothing, __init_interpolation())
@test_throws InconsistentArgument ocp2descent_init(ocp_c, (range(t0, tf, 2*N), U), nothing, __init_interpolation())

# --------------------------------------------------------------------------------------------------
# resolution
#
# init, grid
N = floor(Int64, __grid_size()/2)
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]

# resolution with different init
common_args = (iterations=5, display=true)
sol = solve(ocp, :descent, init=nothing, grid=nothing; common_args...); @test typeof(sol) == DescentOCPSol;
sol = solve(ocp, :descent, init=nothing, grid=T; common_args...); @test typeof(sol) == DescentOCPSol;
sol = solve(ocp, :descent, init=U, grid=nothing; common_args...); @test typeof(sol) == DescentOCPSol;
sol = solve(ocp, :descent, init=U, grid=T; common_args...); @test typeof(sol) == DescentOCPSol;
sol = solve(ocp, :descent, init=(T,U), grid=nothing; common_args...); @test typeof(sol) == DescentOCPSol;

# plots
@test typeof(plot(sol)) == Plots.Plot{Plots.GRBackend}
@test typeof(plot(sol, :time, (:control, 1))) == Plots.Plot{Plots.GRBackend}
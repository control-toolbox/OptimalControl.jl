#
m = 1
n = 2
# description of the optimal control problem
t0 = 0
tf = 1
x0 = [ -1, 0 ]
xf = [  0, 0 ]
ocp = Model()
state!(ocp, n)   # dimension of the state
control!(ocp, m) # dimension of the control
time!(ocp, [t0, tf])
constraint!(ocp, :initial, x0)
constraint!(ocp, :final,   xf)
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u[1])
objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)

# solution
u_sol(t) = 6.0-12.0*t

# --------------------------------------------------------------------------------------------------
#

# init=nothing, grid=nothing => init=zeros(m, N-1), grid=range(t0, tf, N), with N=__grid_size_direct_shooting()
init_, grid_ = CTOptimizationInit(t0, tf, m, nothing, nothing)
@test init_ == __init(m)
@test grid_ == __grid(t0, tf)

# init=nothing, grid=T => init=zeros(m, N-1), grid=T, with N=length(T) (check validity)
N = floor(Int64, __grid_size_direct_shooting()/2) # pour avoir un N différent de __grid_size_direct_shooting()
grid = range(t0, tf, N)
init_, grid_ = CTOptimizationInit(t0, tf, m, nothing, grid)
N = length(grid)
@test init_ == __init(m, N)
@test grid_ == grid
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, nothing, range(t0-1, tf, N))
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, nothing, range(t0, tf+1, N))
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, nothing, range(tf, t0, N))

# init=U, grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size_direct_shooting()
N = floor(Int64, __grid_size_direct_shooting()/2) # pour avoir un N différent de __grid_size_direct_shooting()
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
init_, grid_ = CTOptimizationInit(t0, tf, m, U, nothing, __init_interpolation())
@test init_ ≈ convert_init([[u_sol(grid_[i])-1.0] for i = 1:__grid_size_direct_shooting()-1]) atol=1e-4
@test grid_ == __grid(t0, tf)

# init=U, grid=T => init=U, grid=T (check validity with ocp and with init)
N = floor(Int64, __grid_size_direct_shooting()/2) # pour avoir un N différent de __grid_size_direct_shooting()
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
init_, grid_ = CTOptimizationInit(t0, tf, m, U, T)
@test init_ == convert_init(U)
@test grid_ == T
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, U, range(t0-1, tf, N))
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, U, range(t0, tf+1, N))
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, U, range(tf, t0, N))
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, U, range(t0, tf, 2*N))

# init=(T,U), grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size_direct_shooting() (check validity with ocp and with U)
N = floor(Int64, __grid_size_direct_shooting()/2) # pour avoir un N différent de __grid_size_direct_shooting()
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
init_, grid_ = CTOptimizationInit(t0, tf, m, (T,U), nothing, __init_interpolation())
@test init_ ≈ convert_init([[u_sol(grid_[i])-1.0] for i = 1:__grid_size_direct_shooting()-1]) atol=1e-4
@test grid_ == __grid(t0, tf)
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(t0-1, tf, N), U), nothing, __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(t0, tf+1, N), U), nothing, __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(tf, t0, N), U), nothing, __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(t0, tf, 2*N), U), nothing, __init_interpolation())

# init=(T1,U), grid=T2 => init=U, grid=T2 (check validity with ocp (T1, T2) and with U (T1))
N1 = floor(Int64, __grid_size_direct_shooting()/2) # pour avoir un N différent de __grid_size_direct_shooting()
T1 = range(t0, tf, N1)
U  = [[u_sol(T[i])-1.0] for i = 1:N1-1]
N2 = floor(Int64, __grid_size_direct_shooting()/4) # pour avoir un N différent de __grid_size_direct_shooting()
T2 = range(t0, tf, N2)
init_, grid_ = CTOptimizationInit(t0, tf, m, (T1,U), T2, __init_interpolation())
@test init_ ≈ convert_init([[u_sol(grid_[i])-1.0] for i = 1:N2-1]) atol=1e-4
@test grid_ == T2
# T1
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(t0-1, tf, N), U), T2, __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(t0, tf+1, N), U), T2, __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(tf, t0, N), U), T2, __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (range(t0, tf, 2*N), U), T2, __init_interpolation())
# T2
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (T1, U), range(t0-1, tf, N), __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (T1, U), range(t0, tf+1, N), __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, (T1, U), range(tf, t0, N), __init_interpolation())

# init=S, grid=nothing => init=S.U, grid=range(t0, tf, N), with N=__grid_size_direct_shooting()
N = floor(Int64, __grid_size_direct_shooting()/2)
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
sol = solve(ocp, :descent, init=U, grid=T, iterations=0, display=false)
init_, grid_ = CTOptimizationInit(t0, tf, m, sol, nothing, __init_interpolation())
@test init_ ≈ convert_init([[u_sol(grid_[i])-1.0] for i = 1:__grid_size_direct_shooting()-1]) atol=1e-4
@test grid_ == __grid(t0, tf)

# init=S, grid=T => init=S.U, grid=T (check validity with ocp)
N = floor(Int64, __grid_size_direct_shooting()/2)
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
sol = solve(ocp, :descent, init=U, grid=T, iterations=0, display=false)
N2 = floor(Int64, __grid_size_direct_shooting()/4) # pour avoir un N différent de __grid_size_direct_shooting()
T2 = range(t0, tf, N2)
init_, grid_ = CTOptimizationInit(t0, tf, m, sol, T2, __init_interpolation())
@test init_ ≈ convert_init([[u_sol(grid_[i])-1.0] for i = 1:N2-1]) atol=1e-4
@test grid_ == T2

@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, sol, range(t0-1, tf, N), __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, sol, range(t0, tf+1, N), __init_interpolation())
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, sol, range(tf, t0, N), __init_interpolation())

# init=u, grid=nothing => init=u(T), grid=T=range(t0, tf, N), with N=__grid_size_direct_shooting()
u_init(t) = [u_sol(t)-1.0]
init_, grid_ = CTOptimizationInit(t0, tf, m, u_init, nothing)
@test init_ ≈ convert_init([[u_sol(grid_[i])-1.0] for i = 1:__grid_size_direct_shooting()-1]) atol=1e-4
@test grid_ == __grid(t0, tf)

# init=u, grid=T => init=u(T), grid=T (check validity with ocp)
u_init(t) = [u_sol(t)-1.0]
N = floor(Int64, __grid_size_direct_shooting()/2)
T = range(t0, tf, N)
init_, grid_ = CTOptimizationInit(t0, tf, m, u_init, T, __init_interpolation())
@test init_ ≈ convert_init([[u_sol(T[i])-1.0] for i = 1:N-1]) atol=1e-4
@test grid_ == T

@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, u_init, range(t0-1, tf, N))
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, u_init, range(t0, tf+1, N))
@test_throws InconsistentArgument CTOptimizationInit(t0, tf, m, u_init, range(tf, t0, N))

# --------------------------------------------------------------------------------------------------
# resolution
#
# init, grid
N = floor(Int64, __grid_size_direct_shooting()/2)
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]

N_ = floor(Int64, __grid_size_direct_shooting()/4)
T_ = range(t0, tf, N_)

u_init(t) = [u_sol(t)-1.0]

# resolution with different init
common_args = (iterations=5, display=false)
sol = solve(ocp, :descent, init=nothing, grid=nothing; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=nothing, grid=T; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=U, grid=nothing; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=U, grid=T; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=(T,U), grid=nothing; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=(T,U), grid=T_; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=sol, grid=nothing; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=u_init, grid=nothing; common_args...); @test typeof(sol) == DirectShootingSolution;
sol = solve(ocp, :descent, init=u_init, grid=T; common_args...); @test typeof(sol) == DirectShootingSolution;

# plots
@test typeof(plot(sol)) == Plots.Plot{Plots.GRBackend}
@test typeof(plot(sol, :time, (:control, 1))) == Plots.Plot{Plots.GRBackend}

using OptimalControl
#
using Printf
using LinearAlgebra
#

# description of the optimal control problem
t0 = 0
tf = 1
m = 1
n = 2
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
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
objective!(ocp, :lagrange, (x, u) -> 0.5u^2)

# solution
u_sol(t) = 6.0-12.0*t # solution
# L2 norm of u_sol square = 12
# L1 norm of u_sol = 3

# callback
function my_cb_print(T)
    f_old = 0.0
    symbols = ("🔽", "--", "🔺")
    function myprint(i, sᵢ, dᵢ, Uᵢ, gᵢ, fᵢ)
        if i == 0
            println("\n     Calls  ‖∇F(U)‖         ‖U‖            Stagnation       F(U)\n")
        end
        @printf("%10d", i) # Iterations
        @printf("%16.8e", norm(gᵢ)) # ‖∇F(U)‖
        #@printf("%16.8e", sum((Uᵢ.^2).*(T[2:end]-T[1:end-1]))) # L2 norm approximation square - ‖U‖²
        @printf("%16.8e", sum(abs.(Uᵢ).*(T[2:end]-T[1:end-1]))) # L1 norm approximation - ‖U‖
        @printf("%16.8e", norm(Uᵢ) > 1e-14 ? norm(sᵢ * dᵢ) / norm(Uᵢ) : norm(sᵢ * dᵢ)) # Stagnation
        @printf("%16.8e", fᵢ) # F(U)
        if i > 0
            if abs(fᵢ-f_old) ≤ 1e-12
                print(" ", symbols[2])
            else
                print(" ", symbols[floor(Int, sign(fᵢ - f_old))+2])
            end
        end
        f_old = fᵢ
    end
    return myprint
end

# --------------------------------------------------------------------------------------------------
# resolution

T_default = range(t0, tf, CTBase.__grid_size_direct_shooting())

# init=nothing, grid=nothing
sol = solve(ocp, :direct, :shooting, callbacks=(PrintCallback(my_cb_print(T_default)),))
sol_1 = sol
println(time_steps(sol))

# init=nothing, grid=T
# the grid T may be non uniform
N = 101
T = range(t0, tf, N)
sol = solve(ocp, :direct, :shooting, grid=T, callbacks=(PrintCallback(my_cb_print(T)),))
println(time_steps(sol))

# init=U, grid=nothing
# we assume U is given on a uniform grid
# the output grid is the default grid
N = 101
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
sol = solve(ocp, :direct, :shooting, init=U, callbacks=(PrintCallback(my_cb_print(T_default)),))
println(time_steps(sol))

# init=U, grid=T
# the grid T may be non uniform
N = 101
T = range(t0, tf, N)
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
sol = solve(ocp, :direct, :shooting, init=U, grid=T, callbacks=(PrintCallback(my_cb_print(T)),))
println(time_steps(sol))

# init=(T,U), grid=nothing
# if U is not given on a uniform grid, you must give the grid
# the output grid is the default grid
N = 101
T = range(t0, tf, N)
T = T.^2 # t0 = 0 and tf = 1 so it is ok
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
sol = solve(ocp, :direct, :shooting, init=(T, U), callbacks=(PrintCallback(my_cb_print(T_default)),))
println(time_steps(sol))

# init=(T,U), grid=T_
# if U is not given on a uniform grid, you must give the grid
N = 101
T = range(t0, tf, N)
T = T.^2 # t0 = 0 and tf = 1 so it is ok
U = [[u_sol(T[i])-1.0] for i = 1:N-1]
T_ = range(t0, tf, 301)
sol = solve(ocp, :direct, :shooting, init=(T, U), grid=T_, callbacks=(PrintCallback(my_cb_print(T_)),))
println(time_steps(sol))

# init=t->u(t), grid=nothing
u(t) = [u_sol(t)-1.0]
sol = solve(ocp, :direct, :shooting, init=u, callbacks=(PrintCallback(my_cb_print(T_default)),))
println(time_steps(sol))

# init=t->u(t), grid=T
N = 101
T = range(t0, tf, N)
u(t) = [u_sol(t)-1.0]
sol = solve(ocp, :direct, :shooting, init=u, grid=T, callbacks=(PrintCallback(my_cb_print(T)),))
println(time_steps(sol))

# init=sol, grid=nothing
sol = solve(ocp, :direct, :shooting, init=sol_1, callbacks=(PrintCallback(my_cb_print(T_default)),))
println(time_steps(sol))

# init=sol, grid=T
N = 101
T = range(t0, tf, N)
sol = solve(ocp, :direct, :shooting, init=sol_1, grid=T, callbacks=(PrintCallback(my_cb_print(T)),))
println(time_steps(sol))

# make direct solve to init a direct shooting
N = 201
T = range(t0, tf, N)
sol = solve(ocp, :direct, grid_size=N)
sol = solve(ocp, :direct, :shooting, init=sol, grid=T, callbacks=(PrintCallback(my_cb_print(T)),))
println(time_steps(sol))

include("../src/ControlToolbox.jl"); # nécessaire tant que pas un vrai package
import .ControlToolbox: plot , plot! # nécessaire tant que include et using relatif
using .ControlToolbox
using Plots
using Printf
using LinearAlgebra

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

# replace default callback
function myprint(i, sᵢ, dᵢ, Uᵢ, gᵢ, fᵢ)
    if i==0
        println("\n     Calls  ‖∇F(U)‖         Stagnation      \n")
    end
    @printf("%10d", i) # Iterations
    @printf("%16.8e", norm(gᵢ)) # ‖∇F(U)‖
    @printf("%16.8e", norm(Uᵢ)>1e-14 ? norm(sᵢ*dᵢ)/norm(Uᵢ) : norm(sᵢ*dᵢ)) # Stagnation
end
cbs = (PrintCallback(myprint), )
sol = solve(ocp, callbacks=cbs);

# add text to default print callback
function myprint2(i, sᵢ, dᵢ, Uᵢ, gᵢ, fᵢ)
    symbols=("--", "\\", "|", "/")
    print(" ", symbols[mod(i, 4)+1])
end
cbs = (PrintCallback(myprint2, priority=0), )
sol = solve(ocp, callbacks=cbs);

# add text to default print callback, saving old value of f
global old_f = 0.0
function myprint5(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
    global old_f
    symbols=("↘", "--", "↗")
    if i > 0
        print(" ", symbols[floor(Int, sign(fᵢ-old_f))+2])
    end
    old_f = fᵢ
end
cbs = (PrintCallback(myprint5, priority=0), )
sol = solve(ocp, callbacks=cbs);
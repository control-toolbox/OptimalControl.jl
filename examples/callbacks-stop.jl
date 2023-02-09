using OptimalControl
#
using Printf
using LinearAlgebra

# description of the optimal control problem
t0 = 0
tf = 1
x0 = [ -1, 0 ]
xf = [  0, 0 ]
ocp = Model()
state!(ocp, 2)   # dimension of the state
control!(ocp, 1) # dimension of the control
time!(ocp, [t0, tf])
constraint!(ocp, :initial, x0)
constraint!(ocp, :final,   xf)
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u[1])
objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)

# replace default stop callbacks
function mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, oTol, aTol, sTol, iterations)
    stop = false; stopping = nothing; success = nothing; message = nothing
    if i == 10
        stop = true
        stopping = :mystop
        message = "mystop"
        success = true
    end
    return stop, stopping, message, success
end
cbs = (StopCallback(mystop),)
sol = solve(ocp, :direct, :shooting, callbacks=cbs);

# add stop callback to existing ones
cbs = (StopCallback(mystop, priority=0),)
sol = solve(ocp, :direct, :shooting, callbacks=cbs);

# print (not replacing) and stop (replacing) callbacks
global old_f = 0.0
function myprint(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
    global old_f
    symbols = ("🔽", "--", "🔺")
    if i > 0
        print(" ", symbols[floor(Int, sign(fᵢ - old_f))+2])
    end
    old_f = fᵢ
end
cbs = (PrintCallback(myprint, priority=0), StopCallback(mystop, priority=1))
sol = solve(ocp, :direct, :shooting, callbacks=cbs);

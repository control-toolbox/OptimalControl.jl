try
    methods(OCP)
catch
    include("../src/ControlToolbox.jl"); # nécessaire tant que pas un vrai package
    import .ControlToolbox: plot, plot! # nécessaire tant que include et using relatif
    using .ControlToolbox
    using Plots
    using Printf
    using LinearAlgebra
end

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

# replace default callback
function mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, oTol, aTol, sTol, iterations)
    stop = false
    stopping = nothing
    success = nothing
    message = nothing
    if i == 10
        stop = true
        stopping = :mystop
        message = "mystop"
        success = true
    end
    return stop, stopping, message, success
end
cbs = (StopCallback(mystop),)
sol = solve(ocp, callbacks=cbs);

# add callback
cbs = (StopCallback(mystop, priority=0),)
sol = solve(ocp, callbacks=cbs);

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
sol = solve(ocp, callbacks=cbs);



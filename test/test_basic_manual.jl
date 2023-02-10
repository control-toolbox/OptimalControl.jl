t0 = 0.
tf = 1.

ocp = Model()

#
state!(ocp, 2)   # dimension of the state
control!(ocp, 1) # dimension of the control
time!(ocp, [t0, tf])
constraint!(ocp, :initial, [ -1.0, 0.0 ])
constraint!(ocp, :final,   [  0.0, 0.0 ])

#
A = [ 0.0 1.0
      0.0 0.0 ]
B = [ 0.0
      1.0 ]

constraint!(ocp, :dynamics, (x, u) -> A*x + B*u[1])
objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2) # default is to minimise

# solve
function my_callback_all(
      alg_mod::Cint,
      iter_count::Cint,
      obj_value::Float64,
      inf_pr::Float64,
      inf_du::Float64,
      mu::Float64,
      d_norm::Float64,
      regularization_size::Float64,
      alpha_du::Float64,
      alpha_pr::Float64,
      ls_trials::Cint,
   )
      return true
end

function my_callback(args...; kwargs...)
      println(args)
      println(kwargs)
      return true
end

sol = solve(ocp, grid_size=30, print_level=0, callback=my_callback)

# plot
plot(sol)

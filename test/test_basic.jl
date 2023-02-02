t0 = 0.
tf = 1.

ocp = Model()

#
state!(ocp, 2)
control!(ocp, 1)
time!(ocp, [t0, tf])
constraint!(ocp, :initial, [ -1.0, 0.0 ])
constraint!(ocp, :final,   [  0.0, 0.0 ])

#
A = [ 0.0 1.0
      0.0 0.0 ]
B = [ 0.0
      1.0 ]

constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
objective!(ocp, :lagrangian, (x, u) -> 0.5*u^2) # default is to minimise

(ξl, ξf, ξu), (ψl, ψf, ψu), (ϕl, ϕf, ϕu) = nlp_constraints(ocp)
val = ϕf(0.0, [ -1.0, 0.0 ], 1.0, [ 0.0, 0.0 ])
println("ϕf = ", val)
@test length(val) == 4 

#
@test ocp.state_dimension == 2
@test ocp.control_dimension == 1
@test typeof(ocp) == OptimalControlModel
@test ocp.initial_time == t0
@test ocp.final_time == tf
@test ocp.dynamics([0.; 1.], 1.0) ≈ [1.; 1.] atol=1e-8
@test ocp.lagrangian([0.; 0.], 1.0) ≈ 0.5 atol=1e-8

# from model to problem
# tbd

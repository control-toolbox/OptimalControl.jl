#
Hamiltonian = ControlToolbox.Flows.Hamiltonian
HamiltonianVectorField = ControlToolbox.Flows.HamiltonianVectorField
VectorField = ControlToolbox.Flows.VectorField
Flow = ControlToolbox.Flows.Flow

#
t0 = 0.0
tf = 1.0
x0 = [-1.0; 0.0]
p0 = [12.0; 6.0]

# --------------------------------------------------------------------------------------------
# Hamiltonian flow

# 
control(x, p) = p[2]
H(x, p) = p[1] * x[2] + p[2] * control(x, p) - 0.5 * control(x, p)^2
z = Flow(Hamiltonian(H))
xf, pf = z(t0, x0, p0, tf)
@test xf ≈ [0.0; 0.0] atol = 1e-5
@test pf ≈ [12.0; -6.0] atol = 1e-5

#
H(t, x, p, l) = p[1] * x[2] + p[2] * control(x, p) + 0.5 * l * control(x, p)^2
z = Flow(Hamiltonian(H), :nonautonomous)
xf, pf = z(t0, x0, p0, tf, -1.0)
@test xf ≈ [0.0; 0.0] atol = 1e-5
@test pf ≈ [12.0; -6.0] atol = 1e-5

# from a function
H(t, x, p, l) = p[1] * x[2] + p[2] * control(x, p) + 0.5 * l * control(x, p)^2
z = Flow(H, (:nonautonomous,))
xf, pf = z(t0, x0, p0, tf, -1.0)
@test xf ≈ [0.0; 0.0] atol = 1e-5
@test pf ≈ [12.0; -6.0] atol = 1e-5

# --------------------------------------------------------------------------------------------
# Form a Hamiltonian vector field

#
Hv(x, p) = [x[2], control(x, p), 0.0, -p[1]]
z = Flow(HamiltonianVectorField(Hv))
xf, pf = z(t0, x0, p0, tf)
@test xf ≈ [0.0; 0.0] atol = 1e-5
@test pf ≈ [12.0; -6.0] atol = 1e-5

#
Hv(t, x, p, l) = [x[2], control(x, p), 0.0, -p[1]]
z = Flow(HamiltonianVectorField(Hv), :nonautonomous)
xf, pf = z(t0, x0, p0, tf, 0.0)
@test xf ≈ [0.0; 0.0] atol = 1e-5
@test pf ≈ [12.0; -6.0] atol = 1e-5

# --------------------------------------------------------------------------------------------
# Form a vector field

#
V(z) = [z[2], z[4], 0.0, -z[3]]
z = Flow(VectorField(V))
zf = z(t0, [x0; p0], tf)
@test zf ≈ [0.0; 0.0; 12.0; -6.0] atol = 1e-5

#
V(t, z, l) = V(z)
z = Flow(VectorField(V), :nonautonomous)
zf = z(t0, [x0; p0], tf, 0.0)
@test zf ≈ [0.0; 0.0; 12.0; -6.0] atol = 1e-5
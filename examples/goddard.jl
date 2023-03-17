using OptimalControl

# Parameters
Cd = 310
Tmax = 3.5
β = 500
b = 2
N = 100
t0 = 0
r0 = 1
v0 = 0
vmax = 0.1
m0 = 1
mf = 0.6

# Problem definition
ocp = @def begin

    tf, variable
    t ∈ [ t0, tf ], time
    x ∈ R³,  state
    u ∈ R, control
    
    r = x₁
    v = x₂
    m = x₃
   
    x(t0) == [ r0, v0, m0 ]
    0  ≤ u(t) ≤ 1
    0  ≤ r(t),           (1)
    0  ≤ v(t) ≤ vmax,    (2)
    mf ≤ m(t) ≤ m0,      (3)

    ẋ(t) == F₀(x(t)) + u(t)*F₁(x(t))
 
    r(tf) -> max
    
end

function F₀(x)
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    F = [ v, -D/m - 1/r^2, 0 ]
    return F
end

function F₁(x)
    r, v, m = x
    F = [ 0, Tmax/m, -b*Tmax ]
    return F
end

# Solve and plot
sol = solve(ocp)
plot(sol)
savefig("fig_goddard.png")

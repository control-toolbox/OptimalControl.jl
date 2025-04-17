# parameters
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2
const t0 = 0
const r0 = 1
const v0 = 0
const vmax = 0.1
const m0 = 1
const mf = 0.6
const x0 = [r0, v0, m0]

function Goddard()

    # model    
    ocp = @def ocp begin

        # variables
        tf ∈ R, variable
        t ∈ [t0, tf], time
        x = (r, v, m) ∈ R³, state
        u ∈ R, control

        # constraints
        0 ≤ u(t) ≤ 1, (u_con)
        r(t) ≥ r0, (x_con_rmin)
        0 ≤ v(t) ≤ vmax, (x_con_vmax)
        x(t0) == x0, (initial_con)
        m(tf) == mf, (final_con)

        # dynamics
        ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

        # objective
        r(tf) → max
    end

    objective = 1.0125762700748699

    return ocp, objective
end

# dynamics
function F0(x)
    r, v, m = x
    D = Cd * v^2 * exp(-β * (r - 1))
    return [v, -D / m - 1 / r^2, 0]
end

function F1(x)
    r, v, m = x
    return [0, Tmax / m, -b * Tmax]
end
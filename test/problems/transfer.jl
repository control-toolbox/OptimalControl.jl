# Transfer optimal control problem definition used by tests and examples.
#
# Returns a NamedTuple with fields:
#   - ocp  :: the CTParser-defined optimal control problem
#   - obj  :: reference optimal objective value (Ipopt / MadNLP, Collocation)
#   - name :: a short problem name
#   - init :: NamedTuple of components for CTSolvers.initial_guess

asqrt(x; ε=1e-9) = sqrt(sqrt(x^2+ε^2))     # Avoid issues with AD

const μ = 5165.8620912                     # Earth gravitation constant

function F0(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    w = 1 + ex * cl + ey * sl
    F = [0, 0, 0, 0, 0, w^2 / (P * pdm)]
    return F
end

function F1(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    F = pdm * [0, sl, -cl, 0, 0, 0]
    return F
end

function F2(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    w = 1 + ex * cl + ey * sl
    F = pdm * [2 * P / w, cl + (ex + cl) / w, sl + (ey + sl) / w, 0, 0, 0]
    return F
end

function F3(x)
    P, ex, ey, hx, hy, L = x
    pdm = asqrt(P / μ)
    cl = cos(L)
    sl = sin(L)
    w = 1 + ex * cl + ey * sl
    pdmw = pdm / w
    zz = hx * sl - hy * cl
    uh = (1 + hx^2 + hy^2) / 2
    F = pdmw * [0, -zz * ey, zz * ex, uh * cl, uh * sl, zz]
    return F
end

function Transfer(; Tmax=60)

    cTmax = 3600^2 / 1e6; T = Tmax * cTmax     # Conversion from Newtons to kg x Mm / h²
    mass0 = 1500                               # Initial mass of the spacecraft
    β = 1.42e-02                               # Engine specific impulsion
    P0 = 11.625                                # Initial semilatus rectum
    ex0, ey0 = 0.75, 0                         # Initial eccentricity
    hx0, hy0 = 6.12e-2, 0                      # Initial ascending node and inclination
    L0 = π                                     # Initial longitude
    Pf = 42.165                                # Final semilatus rectum
    exf, eyf = 0, 0                            # Final eccentricity
    hxf, hyf = 0, 0                            # Final ascending node and inclination
    Lf = 3π                                    # Estimation of final longitude
    x0 = [P0, ex0, ey0, hx0, hy0, L0]          # Initial state
    xf = [Pf, exf, eyf, hxf, hyf, Lf]          # Final state
    
    ocp = @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (P, ex, ey, hx, hy, L) ∈ R⁶, state
        u ∈ R³, control
        x(0) == x0
        x[1:5](tf) == xf[1:5]
        mass = mass0 - β * T * t
        ẋ(t) == F0(x(t)) + T / mass * (u₁(t) * F1(x(t)) + u₂(t) * F2(x(t)) + u₃(t) * F3(x(t)))
        u₁(t)^2 + u₂(t)^2 + u₃(t)^2 ≤ 1
        tf → min
    end
    
    init = @init ocp begin 
        tf_i = 15
        x(t) := x0 + (xf - x0) * t / tf_i       # Linear interpolation
        u(t) := [0.1, 0.5, 0.]                  # Initial guess for the control
        tf := tf_i                              # Initial guess for final time
    end
    
    return (ocp=ocp, obj=14.79643132, name="transfer", init=init)
end
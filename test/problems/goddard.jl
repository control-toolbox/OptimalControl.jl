# Goddard rocket optimal control problem used by CTSolvers tests.

"""
    Goddard(; vmax=0.1, Tmax=3.5)

Return data for the classical Goddard rocket ascent, formulated as a
*maximization* of the final altitude `r(tf)`.

The function returns a NamedTuple with fields:

  * `ocp`  – CTParser/@def optimal control problem
  * `obj`  – reference optimal objective value
  * `name` – short problem name (`"goddard"`)
  * `init` – NamedTuple of components for `CTSolvers.initial_guess`, similar
             in spirit to `Beam()`.
"""
function Goddard(; vmax=0.1, Tmax=3.5)
    # constants
    Cd = 310
    beta = 500
    b = 2
    r0 = 1
    v0 = 0
    m0 = 1
    mf = 0.6
    x0 = [r0, v0, m0]

    @def goddard begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R^3, state
        u ∈ R, control

        0.01 ≤ tf ≤ Inf

        r = x[1]
        v = x[2]
        m = x[3]

        x(0) == x0
        m(tf) == mf

        r0 ≤ r(t) ≤ r0 + 0.1
        v0 ≤ v(t) ≤ vmax
        mf ≤ m(t) ≤ m0
        0 ≤ u(t) ≤ 1

        # Component-wise dynamics (Goddard rocket)
        D = Cd * v(t)^2 * exp(-beta * (r(t) - r0))
        g = 1 / r(t)^2
        T = Tmax * u(t)

        ∂(r)(t) == v(t)
        ∂(v)(t) == (T - D - m(t) * g) / m(t)
        ∂(m)(t) == -b * T

        r(tf) → max
    end

    # Components for a reasonable initial guess around a feasible trajectory.
    init = (state=[1.01, 0.05, 0.8], control=0.5, variable=[0.1])

    return (ocp=goddard, obj=1.01257, name="goddard", init=init)
end

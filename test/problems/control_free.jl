# Control-free optimal control problems for testing parameter estimation
# and dynamic optimization capabilities.

using OptimalControl

"""
    ExponentialGrowth()

Return data for the exponential growth rate estimation problem.

The problem consists in estimating the growth rate parameter `p` for:
- ẋ(t) = p * x(t)
- x(0) = 2.0

by minimizing the squared error with observed data x_obs(t) = 2.0 * exp(0.5 * t):
- ∫₀¹⁰ (x(t) - x_obs(t))² dt → min

The function returns a NamedTuple with fields:
  * `ocp`  – CTParser/@def optimal control problem
  * `obj`  – reference optimal objective value (≈0.0, perfect fit)
  * `name` – short problem name
  * `p_expected` – expected parameter value (0.5)
"""
function ExponentialGrowth()
    # observed data (analytical solution)
    data(t) = 2.0 * exp(0.5 * t)

    @def ocp begin
        p ∈ R, variable              # growth rate to estimate
        t ∈ [0, 10], time
        x ∈ R, state
        u ∈ R, control               # TO REMOVE WHEN POSSIBLE

        x(0) == 2.0

        ẋ(t) == p * x(t)

        ∫((x(t) - data(t))^2 + 1e-5*u(t)^2) → min  # fit to observed data # TO REMOVE u(t) when possible
    end

    return (
        ocp=ocp,
        obj=0.0,  # perfect fit expected
        name="exponential_growth",
        init=nothing,
        p_expected=0.5,
    )
end

"""
    HarmonicOscillator()

Return data for the harmonic oscillator pulsation optimization problem.

The problem consists in finding the minimal pulsation ω for:
- q̈(t) = -ω² * q(t)
- q(0) = 1.0, v(0) = 0.0
- q(1) = 0.0

by minimizing ω²:
- ω² → min

The analytical solution is ω = π/2 ≈ 1.5708.

The function returns a NamedTuple with fields:
  * `ocp`  – CTParser/@def optimal control problem
  * `obj`  – reference optimal objective value (π²/4 ≈ 2.4674)
  * `name` – short problem name
  * `ω_expected` – expected pulsation value (π/2)
"""
function HarmonicOscillator()
    @def ocp begin
        ω ∈ R, variable              # pulsation to optimize
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state
        u ∈ R, control               # TO REMOVE WHEN POSSIBLE

        q(0) == 1.0
        v(0) == 0.0
        q(1) == 0.0                  # final condition

        ẋ(t) == [v(t), -ω^2 * q(t)]

        ω^2 + 1e-5*∫(u(t)^2) → min   # minimize pulsation # TO REMOVE u(t) when possible
    end

    return (
        ocp=ocp,
        obj=π^2 / 4,  # ω² = (π/2)² = π²/4 ≈ 2.4674
        name="harmonic_oscillator",
        init=nothing,
        ω_expected=π / 2,  # ≈ 1.5708
    )
end

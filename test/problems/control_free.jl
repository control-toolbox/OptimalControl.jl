# Control-free problems, in both front-end forms.
#
# These exercise parameter estimation / dynamic optimisation: there is no
# control, only a `variable` to optimise. `ExponentialGrowth` is also the 1-D
# state case in the library, which makes it the natural fixture for the
# "1-D = scalar" contract in suite/shape/.

# ----------------------------------------------------------------------------
# Exponential growth — 1-D state, 1-D variable, Lagrange cost
# ----------------------------------------------------------------------------

"""
    ExponentialGrowth(form::Symbol=:abstract)

Growth-rate estimation: fit `ẋ = p·x`, `x(0) = 2` to the analytical data
`x_obs(t) = 2·exp(t/2)` by minimising `∫₀¹⁰ (x - x_obs)²`.

`data.p_expected` is the parameter the fit should recover (`0.5`).
"""
function ExponentialGrowth(form::Symbol=:abstract)
    check_form(form)
    return cached(:exponential_growth, form, ()) do
        return form === :abstract ? _exp_growth_abstract() : _exp_growth_functional()
    end
end

# Observed data (analytical solution)
_exp_growth_data(t) = 2.0 * exp(0.5 * t)

const _EXP_GROWTH_DATA = (p_expected=0.5,)

function _exp_growth_abstract()
    data = _exp_growth_data

    @def ocp begin
        p ∈ R, variable              # growth rate to estimate
        t ∈ [0, 10], time
        x ∈ R, state

        x(0) == 2.0

        ẋ(t) == p * x(t)

        ∫((x(t) - data(t))^2) → min  # fit to observed data
    end

    # perfect fit expected
    return TestProblem(:exponential_growth, :abstract, ocp, 0.0, nothing, _EXP_GROWTH_DATA)
end

function _exp_growth_functional()
    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 1, :p)
    CTModels.Building.time!(pre; t0=0.0, tf=10.0)
    CTModels.Building.state!(pre, 1)
    # Control-free: omit `control!` entirely — `control!(pre, 0)` is rejected,
    # a zero control dimension is expressed by never declaring one.

    function dyn!(r, t, x, u, v)
        r[1] = v[1] * x[1]
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    CTModels.Building.objective!(
        pre, :min; lagrange=(t, x, u, v) -> (x[1] - _exp_growth_data(t))^2
    )

    function f_boundary(r, x0, xf, v)
        r[1] = x0[1] - 2.0
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(1), ub=zeros(1), label=:exp_growth_x0
    )

    # ⚠️ Non-autonomous: the Lagrange cost reads `t` through the data function.
    CTModels.Building.time_dependence!(pre; autonomous=false)

    ocp = CTModels.Building.build(pre)

    return TestProblem(
        :exponential_growth, :functional, ocp, 0.0, nothing, _EXP_GROWTH_DATA
    )
end

# ----------------------------------------------------------------------------
# Harmonic oscillator — 2-D state, Mayer cost on the variable
# ----------------------------------------------------------------------------

"""
    HarmonicOscillator(form::Symbol=:abstract)

Minimal-pulsation problem: `q̈ = -ω²q`, `q(0) = 1`, `v(0) = 0`, `q(1) = 0`,
minimising `ω²`. The analytical solution is `ω = π/2`, so the objective is
`π²/4`.

`data.ω_expected` carries the analytical pulsation.
"""
function HarmonicOscillator(form::Symbol=:abstract)
    check_form(form)
    return cached(:harmonic_oscillator, form, ()) do
        return form === :abstract ? _harmonic_abstract() : _harmonic_functional()
    end
end

const _HARMONIC_OBJ = π^2 / 4          # ω² = (π/2)²
const _HARMONIC_DATA = (ω_expected=π / 2,)

function _harmonic_abstract()
    @def ocp begin
        ω ∈ R, variable              # pulsation to optimize
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state

        q(0) == 1.0
        v(0) == 0.0
        q(1) == 0.0                  # final condition

        ẋ(t) == [v(t), -ω^2 * q(t)]

        ω^2 → min   # minimize pulsation
    end

    return TestProblem(
        :harmonic_oscillator, :abstract, ocp, _HARMONIC_OBJ, nothing, _HARMONIC_DATA
    )
end

function _harmonic_functional()
    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 1, :ω)
    CTModels.Building.time!(pre; t0=0.0, tf=1.0)
    CTModels.Building.state!(pre, 2)
    # Control-free: omit `control!` entirely — `control!(pre, 0)` is rejected,
    # a zero control dimension is expressed by never declaring one.

    function dyn!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = -v[1]^2 * x[1]
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    # Mayer cost on the variable alone.
    CTModels.Building.objective!(pre, :min; mayer=(x0, xf, v) -> v[1]^2)

    function f_boundary(r, x0, xf, v)
        r[1] = x0[1] - 1.0
        r[2] = x0[2] - 0.0
        r[3] = xf[1] - 0.0
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(3), ub=zeros(3), label=:harmonic_boundary
    )

    CTModels.Building.time_dependence!(pre; autonomous=true)

    ocp = CTModels.Building.build(pre)

    return TestProblem(
        :harmonic_oscillator, :functional, ocp, _HARMONIC_OBJ, nothing, _HARMONIC_DATA
    )
end

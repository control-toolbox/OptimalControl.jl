# Double integrator problems, in both front-end forms.
#
# Three variants, each the canonical fixture for one indirect structure:
#
#   DoubleIntegratorTime              bang-bang, free final time  (NonFixed)
#   DoubleIntegratorEnergy            singular arc                (Fixed)
#   DoubleIntegratorEnergyConstrained three-arc, state constraint (Fixed)

# ----------------------------------------------------------------------------
# Time minimisation — bang-bang, free final time
# ----------------------------------------------------------------------------

"""
    DoubleIntegratorTime(form::Symbol=:abstract)

Minimise the final time for `ẋ = (x₂, u)`, `u ∈ [-1, 1]`, from `(-1, 0)` to
`(0, 0)`. The optimum is `tf = 2`, reached by one switch at `t = 1`.

`data` carries `x0`, `xf`, `t0`, `tf`, `u_max`, `u_min`.
"""
function DoubleIntegratorTime(form::Symbol=:abstract)
    check_form(form)
    return cached(:double_integrator_time, form, ()) do
        form === :abstract ? _di_time_abstract() : _di_time_functional()
    end
end

const _DI_TIME_OBJ = 2.0
const _DI_TIME_DATA = (
    x0=[-1.0, 0.0],
    xf=[0.0, 0.0],
    t0=0.0,
    tf=2.0,
    u_max=1.0,
    u_min=-1.0,
    # Reference shooting solution: one switch at t = 1.
    p0=[1.0, 1.0],
    switching_times=(1.0,),
)

function _di_time_abstract()
    @def ocp begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control

        -1 ≤ u(t) ≤ 1

        q(0) == -1
        v(0) == 0
        q(tf) == 0
        v(tf) == 0

        ẋ(t) == [v(t), u(t)]

        tf → min
    end

    return TestProblem(
        :double_integrator_time, :abstract, ocp, _DI_TIME_OBJ, nothing, _DI_TIME_DATA; methods=(:direct, :indirect)
    )
end

function _di_time_functional()
    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 1, :tf)
    CTModels.Building.time!(pre; t0=0.0, indf=1)
    CTModels.Building.state!(pre, 2, :x, [:q, :v])
    CTModels.Building.control!(pre, 1)

    function dyn!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    # Minimal time is a Mayer cost on the variable.
    CTModels.Building.objective!(pre, :min; mayer=(x0, xf, v) -> v[1])

    function f_boundary(r, x0, xf, v)
        r[1] = x0[1] + 1.0
        r[2] = x0[2] - 0.0
        r[3] = xf[1] - 0.0
        r[4] = xf[2] - 0.0
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(4), ub=zeros(4), label=:di_time_boundary
    )
    CTModels.Building.constraint!(
        pre, :control; rg=1:1, lb=[-1.0], ub=[1.0], label=:di_time_control_box
    )

    CTModels.Building.time_dependence!(pre; autonomous=true)

    ocp = CTModels.Building.build(pre)

    return TestProblem(
        :double_integrator_time, :functional, ocp, _DI_TIME_OBJ, nothing, _DI_TIME_DATA; methods=(:direct, :indirect)
    )
end

# ----------------------------------------------------------------------------
# Energy minimisation — singular arc, fixed horizon
# ----------------------------------------------------------------------------

"""
    DoubleIntegratorEnergy(form::Symbol=:abstract)

Minimise `½∫₀¹ u²` for `ẋ = (x₂, u)` from `(-1, 0)` to `(0, 0)`. The optimum
is `6`, with the singular control `u = p₂` and `p(0) = (12, 6)`.

`data` carries `x0`, `xf`, `t0`, `tf`, and `p0` — the known initial costate,
which makes this the cheapest shooting fixture in the library.
"""
function DoubleIntegratorEnergy(form::Symbol=:abstract)
    check_form(form)
    return cached(:double_integrator_energy, form, ()) do
        form === :abstract ? _di_energy_abstract() : _di_energy_functional()
    end
end

const _DI_ENERGY_OBJ = 6.0
const _DI_ENERGY_DATA = (
    x0=[-1.0, 0.0], xf=[0.0, 0.0], t0=0.0, tf=1.0, p0=[12.0, 6.0]
)

function _di_energy_abstract()
    @def ocp begin
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state
        u ∈ R, control

        x(0) == [-1, 0]
        x(1) == [0, 0]

        ∂(q)(t) == v(t)
        ∂(v)(t) == u(t)

        0.5∫(u(t)^2) → min
    end

    return TestProblem(
        :double_integrator_energy, :abstract, ocp, _DI_ENERGY_OBJ, nothing, _DI_ENERGY_DATA; methods=(:direct, :indirect)
    )
end

function _di_energy_functional()
    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 0)
    CTModels.Building.time!(pre; t0=0.0, tf=1.0)
    CTModels.Building.state!(pre, 2, :x, [:q, :v])
    CTModels.Building.control!(pre, 1)

    function dyn!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    CTModels.Building.objective!(pre, :min; lagrange=(t, x, u, v) -> 0.5 * u[1]^2)

    function f_boundary(r, x0, xf, v)
        r[1] = x0[1] + 1.0
        r[2] = x0[2] - 0.0
        r[3] = xf[1] - 0.0
        r[4] = xf[2] - 0.0
        return nothing
    end
    CTModels.Building.constraint!(
        pre, :boundary; f=f_boundary, lb=zeros(4), ub=zeros(4), label=:di_energy_boundary
    )

    CTModels.Building.time_dependence!(pre; autonomous=true)

    ocp = CTModels.Building.build(pre)

    return TestProblem(
        :double_integrator_energy,
        :functional,
        ocp,
        _DI_ENERGY_OBJ,
        nothing,
        _DI_ENERGY_DATA;
        methods=(:direct, :indirect),
    )
end

# ----------------------------------------------------------------------------
# Energy minimisation with a state constraint — three-arc structure
# ----------------------------------------------------------------------------

"""
    DoubleIntegratorEnergyConstrained(form::Symbol=:abstract)

As [`DoubleIntegratorEnergy`](@ref) with `v(t) ≤ 1.2`, which activates a
boundary arc between `t₁ = 0.25` and `t₂ = 0.75`.

`data` carries `v_max`, the known `p0`, and the two switching times.
"""
function DoubleIntegratorEnergyConstrained(form::Symbol=:abstract)
    check_form(form)
    return cached(:double_integrator_energy_constrained, form, ()) do
        form === :abstract ? _di_energy_cons_abstract() : _di_energy_cons_functional()
    end
end

const _DI_ENERGY_CONS_OBJ = 7.680030
const _DI_ENERGY_CONS_DATA = (
    x0=[-1.0, 0.0],
    xf=[0.0, 0.0],
    t0=0.0,
    tf=1.0,
    v_max=1.2,
    p0=[38.4, 9.6],
    switching_times=(0.25, 0.75),
)

function _di_energy_cons_abstract()
    @def ocp begin
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state
        u ∈ R, control

        v(t) ≤ 1.2

        x(0) == [-1, 0]
        x(1) == [0, 0]

        ∂(q)(t) == v(t)
        ∂(v)(t) == u(t)

        0.5∫(u(t)^2) → min
    end

    return TestProblem(
        :double_integrator_energy_constrained,
        :abstract,
        ocp,
        _DI_ENERGY_CONS_OBJ,
        nothing,
        _DI_ENERGY_CONS_DATA;
        methods=(:direct, :indirect),
    )
end

function _di_energy_cons_functional()
    pre = CTModels.PreModel()

    CTModels.Building.variable!(pre, 0)
    CTModels.Building.time!(pre; t0=0.0, tf=1.0)
    CTModels.Building.state!(pre, 2, :x, [:q, :v])
    CTModels.Building.control!(pre, 1)

    function dyn!(r, t, x, u, v)
        r[1] = x[2]
        r[2] = u[1]
        return nothing
    end
    CTModels.Building.dynamics!(pre, dyn!)

    CTModels.Building.objective!(pre, :min; lagrange=(t, x, u, v) -> 0.5 * u[1]^2)

    function f_boundary(r, x0, xf, v)
        r[1] = x0[1] + 1.0
        r[2] = x0[2] - 0.0
        r[3] = xf[1] - 0.0
        r[4] = xf[2] - 0.0
        return nothing
    end
    CTModels.Building.constraint!(
        pre,
        :boundary;
        f=f_boundary,
        lb=zeros(4),
        ub=zeros(4),
        label=:di_energy_cons_boundary,
    )
    CTModels.Building.constraint!(
        pre, :state; rg=2:2, lb=[-Inf], ub=[1.2], label=:di_energy_cons_v_box
    )

    CTModels.Building.time_dependence!(pre; autonomous=true)

    ocp = CTModels.Building.build(pre)

    return TestProblem(
        :double_integrator_energy_constrained,
        :functional,
        ocp,
        _DI_ENERGY_CONS_OBJ,
        nothing,
        _DI_ENERGY_CONS_DATA;
        methods=(:direct, :indirect),
    )
end

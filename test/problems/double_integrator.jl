# Double integrator problems, in both front-end forms.
#
# Three variants, each the canonical fixture for one indirect structure:
#
#   DoubleIntegratorTime              bang-bang, free final time  (NonFixed)
#   DoubleIntegratorEnergy            singular arc                (Fixed)
#   DoubleIntegratorEnergyConstrained three-arc, state constraint (Fixed)

"""
    _di_time_shoot_builder(ocp, d)

Bang-bang shooting derivation for [`DoubleIntegratorTime`](@ref). Flat vector
`ξ = [p0 (2); t1; tf]` — one switch, one free final time, 4 unknowns for 4
residuals (target state, switching condition, free-time transversality).
"""
function _di_time_shoot_builder(ocp, d)
    return function (; hamiltonian_type::Symbol=:total)
        t0, x0, xf = d.t0, d.x0, d.xf
        u_max, u_min = d.u_max, d.u_min

        H(x, p, u) = p[1] * x[2] + p[2] * u - 1

        f_max = OptimalControl.Flow(ocp, (x, p, v) -> u_max; hamiltonian_type)
        f_min = OptimalControl.Flow(ocp, (x, p, v) -> u_min; hamiltonian_type)

        function shoot!(s, ξ)
            p0 = ξ[1:2]
            τ1, τf = ξ[3], ξ[4]
            x1, p1 = f_max(t0, x0, p0, τ1; variable=τf)
            xf_, pf = f_min(τ1, x1, p1, τf; variable=τf)
            s[1:2] = xf_ - xf
            s[3] = p1[2]
            s[4] = H(xf_, pf, u_min)
            return nothing
        end

        ξ_exact = [d.p0; collect(d.switching_times); d.tf]
        ξ_guess = ξ_exact .* 1.05

        return shoot!, ξ_exact, ξ_guess
    end
end

"""
    _di_energy_shoot_builder(ocp, d)

Singular-arc shooting derivation for [`DoubleIntegratorEnergy`](@ref). Flat
vector `ξ = p0 (2)` — the cheapest fixture in the library: one arc, no
switching times, so the whole target-state residual is the shooting function.
"""
function _di_energy_shoot_builder(ocp, d)
    return function (; hamiltonian_type::Symbol=:total)
        t0, tf, x0, xf = d.t0, d.tf, d.x0, d.xf

        f = OptimalControl.Flow(ocp, (x, p) -> p[2]; hamiltonian_type)

        function shoot!(s, ξ)
            xf_, _ = f(t0, x0, ξ, tf)
            s .= xf_ .- xf
            return nothing
        end

        ξ_exact = collect(d.p0)
        ξ_guess = ξ_exact .* 1.1

        return shoot!, ξ_exact, ξ_guess
    end
end

"""
    _di_energy_cons_shoot_builder(ocp, d)

Three-arc shooting derivation for [`DoubleIntegratorEnergyConstrained`](@ref).
Flat vector `ξ = [p0 (2); t1; t2]` — entry/exit of the boundary arc where
`v = v_max`, 4 unknowns for 4 residuals (target state, constraint activation
at entry, switching condition).
"""
function _di_energy_cons_shoot_builder(ocp, d)
    return function (; hamiltonian_type::Symbol=:total)
        t0, tf, x0, xf, v_max = d.t0, d.tf, d.x0, d.xf, d.v_max

        g(x) = v_max - x[2]
        μ(p) = p[1]

        f_interior = OptimalControl.Flow(ocp, (x, p) -> p[2]; hamiltonian_type)
        f_boundary = OptimalControl.Flow(
            ocp, (x, p) -> 0.0; constraint=(x, u) -> g(x), multiplier=(x, p) -> μ(p),
            hamiltonian_type,
        )

        function shoot!(s, ξ)
            p0 = ξ[1:2]
            τ1, τ2 = ξ[3], ξ[4]
            x1, p1 = f_interior(t0, x0, p0, τ1)
            x2, p2 = f_boundary(τ1, x1, p1, τ2)
            xf_, _ = f_interior(τ2, x2, p2, tf)
            s[1:2] = xf_ - xf
            s[3] = g(x1)
            s[4] = p1[2]
            return nothing
        end

        ξ_exact = [d.p0; collect(d.switching_times)]
        ξ_guess = ξ_exact .* 1.05

        return shoot!, ξ_exact, ξ_guess
    end
end

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
        :double_integrator_time,
        :abstract,
        ocp,
        _DI_TIME_OBJ,
        nothing,
        _DI_TIME_DATA;
        methods=(:direct, :indirect),
        shoot_builder=_di_time_shoot_builder(ocp, _DI_TIME_DATA),
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
        :double_integrator_time,
        :functional,
        ocp,
        _DI_TIME_OBJ,
        nothing,
        _DI_TIME_DATA;
        methods=(:direct, :indirect),
        shoot_builder=_di_time_shoot_builder(ocp, _DI_TIME_DATA),
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
        :double_integrator_energy,
        :abstract,
        ocp,
        _DI_ENERGY_OBJ,
        nothing,
        _DI_ENERGY_DATA;
        methods=(:direct, :indirect),
        shoot_builder=_di_energy_shoot_builder(ocp, _DI_ENERGY_DATA),
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
        shoot_builder=_di_energy_shoot_builder(ocp, _DI_ENERGY_DATA),
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
        shoot_builder=_di_energy_cons_shoot_builder(ocp, _DI_ENERGY_CONS_DATA),
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
        shoot_builder=_di_energy_cons_shoot_builder(ocp, _DI_ENERGY_CONS_DATA),
    )
end
